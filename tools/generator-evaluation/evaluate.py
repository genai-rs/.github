# /// script
# requires-python = ">=3.11"
# dependencies = ["PyYAML==6.0.3", "jsonschema==4.25.1", "openapi-spec-validator==0.7.2"]
# ///
"""GEN01 fixture lint, immutable snapshot inventory, and bounded baseline probe."""
import argparse
import copy
import datetime
import hashlib
import json
import os
import platform
import re
from pathlib import Path
import shutil
import subprocess
import time
import yaml
from jsonschema import Draft202012Validator
from openapi_spec_validator import validate as validate_openapi

ROOT = Path(__file__).resolve().parent
MODEL = "src/models/realtime_beta_server_event_response_mcp_call_completed.rs"
METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}
URLS = {
    "openai": "https://raw.githubusercontent.com/openai/openai-openapi/main/openapi.yaml",
    "langfuse": "https://cloud.langfuse.com/generated/api/openapi.yml",
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def read(path):
    return json.loads(path.read_text())


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def run(args, **kwargs):
    return subprocess.run(["rtk", "proxy", *args], capture_output=True, **kwargs)


def nullable_to_jsonschema(value):
    if isinstance(value, dict):
        value = {k: nullable_to_jsonschema(v) for k, v in value.items()}
        if value.pop("nullable", False):
            value["type"] = [value["type"], "null"]
    elif isinstance(value, list):
        value = [nullable_to_jsonschema(v) for v in value]
    return value


def corpus_hash():
    digest = hashlib.sha256()
    for path in sorted((ROOT / "fixtures").glob("*.json")):
        digest.update(path.name.encode() + b"\0" + path.read_bytes())
    return digest.hexdigest()


def validate_fixtures():
    cases = read(ROOT / "fixtures/cases.json")
    assert cases["synthetic_only"] is True
    ids = [c["id"] for c in cases["cases"]]
    assert len(ids) == len(set(ids)), "duplicate case ID"
    for filename in ("openapi-3.0.1.json", "openapi-3.1.0.json"):
        spec = read(ROOT / "fixtures" / filename)
        validate_openapi(spec)
        operations = {op["operationId"] for item in spec["paths"].values()
                      for method, op in item.items() if method in METHODS}
        normalized = nullable_to_jsonschema(copy.deepcopy(spec))
        for case in cases["cases"]:
            assert case["operation_id"] in operations
            assert case["pass_criterion"] and "wire_input" in case and "expected" in case
            if case["layer"] == "generator_model":
                schema = {"components": normalized["components"],
                          "$ref": "#/components/schemas/" + case["schema"]}
                validator = Draft202012Validator(schema)
                assert validator.is_valid(case["wire_input"]) == case["expected"]["accept"], (filename, case["id"])
                if case["expected"]["accept"]:
                    assert validator.is_valid(case["expected"]["wire_output"])
    Draft202012Validator.check_schema(read(ROOT / "results.schema.json"))
    print(f"Validated 2 OpenAPI documents and {len(ids)} case contracts (22 model cases per dialect).")


def snapshot_manifest(directory):
    manifests = []
    for provider, url in URLS.items():
        raw = (directory / (provider + ".yaml")).read_bytes()
        spec = yaml.safe_load(raw)
        assert isinstance(spec, dict) and "openapi" in spec and "paths" in spec
        refs = set()
        def walk(value):
            if isinstance(value, dict):
                if "$ref" in value:
                    refs.add(value["$ref"])
                for child in value.values():
                    walk(child)
            elif isinstance(value, list):
                for child in value:
                    walk(child)
        walk(spec)
        unresolved = []
        for ref in sorted(refs):
            if not ref.startswith("#/"):
                continue
            try:
                node = spec
                for part in ref[2:].split("/"):
                    node = node[part.replace("~1", "/").replace("~0", "~")]
            except (KeyError, TypeError):
                unresolved.append(ref)
        operations = sorted(op.get("operationId", method.upper() + " " + path)
                            for path, item in spec["paths"].items()
                            for method, op in item.items() if method in METHODS)
        manifests.append({"url": url, "sha256": sha(raw), "bytes": len(raw),
                          "openapi": spec["openapi"], "operation_ids": operations,
                          "unresolved_local_refs": unresolved})
    return manifests


def validate_result(path):
    result = read(path)
    Draft202012Validator(read(ROOT / "results.schema.json")).validate(result)
    assert result["inputs"]["corpus_sha256"] == corpus_hash(), "result belongs to a different corpus"
    cases = {c["id"]: c for c in read(ROOT / "fixtures/cases.json")["cases"]}
    assert len(result["cases"]) == len(cases)
    assert {c["id"] for c in result["cases"]} == set(cases)
    for case in result["cases"]:
        assert case["layer"] == cases[case["id"]]["layer"]
    coverage = result["coverage"]
    groups = [coverage[k] for k in ("supported_operations", "missing_operations", "untested_operations")]
    flat = sum(groups, [])
    assert len(flat) == len(set(flat))
    assert len(coverage["expected_operations"]) == len(set(coverage["expected_operations"]))
    assert set(flat) == set(coverage["expected_operations"])
    if result["candidate"]["scope"] != "sampled_generated_module":
        for case in result["cases"]:
            if cases[case["id"]]["operation_id"] in coverage["missing_operations"]:
                assert case["status"] != "pass", "absent operation cannot pass"
    if coverage["status"] == "not_tested":
        assert not coverage["supported_operations"] and not coverage["missing_operations"]
    print(f"Validated result: {path}")


def baseline(args):
    validate_fixtures()
    source = args.baseline.resolve()
    revision = run(["git", "-C", str(source), "rev-parse", "HEAD"], check=True).stdout.decode().strip()
    raw = run(["git", "-C", str(source), "show", f"{revision}:{MODEL}"], check=True).stdout
    manifest = run(["git", "-C", str(source), "show", f"{revision}:Cargo.toml"], check=True).stdout.decode()
    generator = run(["git", "-C", str(source), "show", f"{revision}:scripts/generate.sh"], check=True).stdout
    version = re.search(rb'OPENAPI_GENERATOR_VERSION:-([^}]+)', generator)
    assert version, "Cannot identify the baseline generator default"
    crate = args.work.resolve() / "baseline-probe"
    crate.mkdir(parents=True, exist_ok=False)
    (crate / "src").mkdir()
    (crate / "src/baseline_model.rs").write_bytes(raw)
    deps = "\n".join(line for line in manifest.splitlines()
                     if any(line.startswith(name + " =") for name in ("serde", "serde_json", "bon")))
    (crate / "Cargo.toml").write_text('[package]\nname="gen01-baseline-probe"\nversion="0.0.0"\nedition="2021"\npublish=false\n[dependencies]\n' + deps + "\n")
    (crate / "src/lib.rs").write_text(r'''
// The original module imports crate::models but references no other model.
mod models {}
#[allow(unused_imports)]
mod baseline_model;
#[cfg(test)]
mod tests {
    use super::baseline_model::{RealtimeBetaServerEventResponseMcpCallCompleted, Type};
    #[test]
    fn dotted_wire() {
        let expected = if std::env::var_os("GEN01_INJECT_WRONG_WIRE").is_some() {
            "response_mcp_call_completed" // Deliberately wrong: harness must detect this.
        } else { "response.mcp_call.completed" };
        assert_eq!(serde_json::to_value(Type::ResponseMcpCallCompleted).unwrap(), expected);
    }
    #[test]
    fn closed_enum_rejects_unknown() {
        assert!(serde_json::from_str::<Type>(r#""future.event""#).is_err());
    }
    #[test]
    fn whole_model_roundtrip() {
        let wire = serde_json::json!({"event_id":"evt_1", "type":"response.mcp_call.completed",
            "output_index":0, "item_id":"item_1"});
        let model: RealtimeBetaServerEventResponseMcpCallCompleted = serde_json::from_value(wire.clone()).unwrap();
        assert_eq!(serde_json::to_value(model).unwrap(), wire);
    }
}
''')
    lock = ROOT / "results/baseline-probe.Cargo.lock"
    if lock.exists():
        shutil.copyfile(lock, crate / "Cargo.lock")
    env = dict(os.environ, CARGO_BUILD_JOBS="2")
    env.pop("GEN01_INJECT_WRONG_WIRE", None)
    command = ["cargo", "test", "--manifest-path", str(crate / "Cargo.toml")]
    if lock.exists():
        command.append("--locked")
    started = time.perf_counter()
    positive = run(command, env=env)
    elapsed = time.perf_counter() - started
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output / "baseline-positive.log").write_bytes(positive.stdout + positive.stderr)
    if positive.returncode:
        raise RuntimeError("Baseline probe failed; see baseline-positive.log. No passing result emitted.")
    env["GEN01_INJECT_WRONG_WIRE"] = "1"
    negative_command = command + ["tests::dotted_wire", "--", "--exact"]
    negative = run(negative_command, env=env)
    (args.output / "baseline-negative.log").write_bytes(negative.stdout + negative.stderr)
    assert negative.returncode == 101 and b"1 failed" in negative.stdout, "negative control did not detect fault"
    shutil.copyfile(crate / "Cargo.lock", args.output / "baseline-probe.Cargo.lock")
    cases = read(ROOT / "fixtures/cases.json")["cases"]
    operations = sorted({c["operation_id"] for c in cases})
    not_tested = lambda reason: {"status": "not_tested", "reason": reason}
    result = {
        "format_version": 1,
        "run": {"utc": datetime.datetime.now(datetime.timezone.utc).isoformat(), "platform": platform.platform(),
                "rustc": run(["rustc", "--version"], check=True).stdout.decode().strip(),
                "commands": ["rtk proxy env CARGO_BUILD_JOBS=2 " + " ".join(command),
                             "rtk proxy env CARGO_BUILD_JOBS=2 GEN01_INJECT_WRONG_WIRE=1 " + " ".join(negative_command)]},
        "candidate": {"name": "openai-client-base current checked-in model sample", "repository": "https://github.com/genai-rs/openai-client-base",
                      "revision": revision, "generator_version": version.group(1).decode(), "generator_revision": None,
                      "configuration": {"source": MODEL, "generation_script_sha256": sha(generator), "generation_rerun": False, "patches": "existing repository pipeline; not executed here"},
                      "scope": "sampled_generated_module", "source_sha256": sha(raw)},
        "inputs": {"corpus_sha256": corpus_hash(), "snapshots": snapshot_manifest(args.snapshots)},
        "cases": [{"id": c["id"], "layer": c["layer"],
                   "status": "pass" if c["id"] in ("enum.dotted", "enum.unknown-closed") else "not_tested",
                   "evidence": "baseline-positive.log: original Type enum sampled; synthetic generation not run"
                   if c["id"] in ("enum.dotted", "enum.unknown-closed") else "No candidate adapter executed this case in GEN01."} for c in cases],
        "coverage": {"status": "not_tested", "expected_operations": operations, "supported_operations": [],
                     "missing_operations": [], "untested_operations": operations, "type_fidelity_losses": []},
        "metrics": {"manual_patches": not_tested("No generation/patch pipeline rerun."),
                    "build_time": {"status": "measured", "value": round(elapsed, 3), "unit": "seconds",
                                   "method": "Wall time of sample cargo test including dependency resolution/download/build; new target directory, global Cargo cache warm/unspecified. Not full client build or generator benchmark."},
                    **{k: not_tested(v) for k, v in {
                        "peak_memory": "No process-tree memory measurement collected.",
                        "msrv": "Current rustc only; source rust-version declaration is not a tested MSRV.",
                        "output_determinism": "No pair of clean generator runs.",
                        "middleware_compatibility": "No transport adapter run.",
                        "public_api_migration_cost": "No candidate replacement or API diff."}.items()}},
        "negative_control": {"status": "pass", "expected_exit": 101, "observed_exit": negative.returncode,
                             "evidence": "baseline-negative.log: tests::dotted_wire intentionally expects underscores; assertion fails (one failed test). This is harness sensitivity, not a product defect."},
        "limitations": ["Only two corpus expectations sampled against an unchanged checked-in generated module; 27 cases remain not_tested.",
                        "Whole-model roundtrip is an extra probe, not full fixture or client coverage.",
                        "Full upstream snapshots were parsed and inventoried, not generated; unresolved references are reported without repair.",
                        "No unsupported candidate capability is inferred from an unexecuted case; use unsupported only with evidence.",
                        "No generator/client selection or production adoption decision is made."]}
    write(args.output / "baseline.json", result)
    validate_result(args.output / "baseline.json")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("validate")
    check = commands.add_parser("validate-result")
    check.add_argument("path", type=Path)
    snapshots = commands.add_parser("snapshots")
    snapshots.add_argument("directory", type=Path)
    snapshots.add_argument("output", type=Path)
    probe = commands.add_parser("baseline")
    probe.add_argument("--baseline", required=True, type=Path)
    probe.add_argument("--snapshots", required=True, type=Path)
    probe.add_argument("--work", required=True, type=Path)
    probe.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if args.command == "validate":
        validate_fixtures()
    elif args.command == "validate-result":
        validate_result(args.path)
    elif args.command == "snapshots":
        write(args.output, snapshot_manifest(args.directory))
    else:
        baseline(args)


if __name__ == "__main__":
    main()
