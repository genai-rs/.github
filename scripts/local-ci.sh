#!/usr/bin/env bash
# Run the genai-rs CI checks locally and attest the result on GitHub.
#
# Usage (from the root of any genai-rs crate checkout):
#
#   bash ../.github/scripts/local-ci.sh [--push] [--rerun] [--no-post]
#   # or without a local clone of genai-rs/.github:
#   bash <(gh api repos/genai-rs/.github/contents/scripts/local-ci.sh -H 'Accept: application/vnd.github.raw') --push
#
# What it does:
#   1. refuses to run on a dirty working tree and records HEAD's SHA;
#   2. reads msrv / features / run-doc / run-semver-checks / generated-crate
#      from the repo's call of rust-ci.yml (.github/workflows/*.yml);
#   3. runs on this host: cargo fmt --check; clippy -D warnings and cargo test
#      on stable and on the MSRV toolchain; cargo doc with RUSTDOCFLAGS=-D
#      warnings; cargo semver-checks (non-generated crates); the repo's
#      `cargo +nightly udeps` command if a workflow runs it; and the repo's
#      `.github/local-ci-extra.sh` (equivalents of repo-specific jobs) if any;
#   4. on success posts a commit status `local-ci` = success on HEAD's SHA.
#      The `gate` job of rust-ci.yml / local-ci-gate.yml then skips the heavy
#      jobs for same-repo PRs whose head is that SHA. Pushes to main always
#      run full CI. On failure nothing is posted and the script exits non-zero.
#
# Options:
#   --push     push the current branch to origin after the checks pass and
#              right before posting the status (CI's gate waits ~60 s for it)
#   --rerun    after posting, re-run this SHA's pull_request workflow runs that
#              are still running (cancelled first) or failed, so they pick up
#              the attestation
#   --no-post  run the checks only; do not post a status
set -euo pipefail

PUSH=0
RERUN=0
POST=1
for arg in "$@"; do
  case "$arg" in
    --push) PUSH=1 ;;
    --rerun) RERUN=1 ;;
    --no-post) POST=0 ;;
    -h | --help)
      sed -n '2,/^set -euo/p' "$0" | sed '$d; s/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

say() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
die() {
  printf '\033[1;31mlocal-ci: %s\033[0m\n' "$*" >&2
  exit 1
}

cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  git status --short >&2
  die "working tree is dirty; commit or stash first (the attestation is for HEAD)"
fi

SHA=$(git rev-parse HEAD)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
[ -n "$REPO" ] || die "cannot determine the GitHub repository (gh repo view)"

sha_on_origin() { gh api "repos/$REPO/commits/$SHA" --silent >/dev/null 2>&1; }

if [ "$POST" = 1 ] && [ "$PUSH" = 0 ] && ! sha_on_origin; then
  die "$SHA is not on github.com/$REPO yet; push it first or pass --push"
fi
if [ "$PUSH" = 1 ] && [ "$BRANCH" = "HEAD" ]; then
  die "--push needs a branch (HEAD is detached)"
fi
if [ "$PUSH" = 1 ] && [ "$BRANCH" = "main" ]; then
  die "refusing to --push main; main always runs full CI"
fi

# --- read the CI configuration ----------------------------------------------
CALLER=$(grep -l 'rust-ci.yml@' .github/workflows/*.yml 2>/dev/null | head -1 || true)
[ -n "$CALLER" ] || die "no workflow in .github/workflows calls genai-rs/.github rust-ci.yml"

# Print the value of `<key>:` inside the `with:` block of the rust-ci.yml call.
ci_input() {
  awk -v key="$1" '
    /rust-ci\.yml@/ { injob = 1; next }
    injob && /^  [A-Za-z0-9_-]+:[[:space:]]*$/ { injob = 0 }
    injob {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      if (index(line, key ":") == 1) {
        val = substr(line, length(key) + 2)
        sub(/^[[:space:]]+/, "", val)
        sub(/[[:space:]]+#.*$/, "", val)
        gsub(/^["\047]|["\047]$/, "", val)
        print val
        exit
      }
    }
  ' "$CALLER"
}

MSRV=$(ci_input msrv)
FEATURES=$(ci_input features)
FEATURES=${FEATURES:---all-features}
RUN_DOC=$(ci_input run-doc)
RUN_SEMVER=$(ci_input run-semver-checks)
GENERATED=$(ci_input generated-crate)
[ -n "$MSRV" ] || die "could not read msrv from $CALLER"

UDEPS_CMD=$(grep -ho 'cargo +nightly udeps.*' .github/workflows/*.yml 2>/dev/null | head -1 || true)
EXTRA=.github/local-ci-extra.sh
HOST=$(rustc -vV | sed -n 's/^host: //p')

echo "repo:      $REPO"
echo "commit:    $SHA ($BRANCH)"
echo "host:      $HOST"
echo "msrv:      $MSRV"
echo "features:  $FEATURES"
echo "doc:       ${RUN_DOC:-true}   semver-checks: $([ "${RUN_SEMVER:-true}" != false ] && [ "${GENERATED:-false}" != true ] && echo true || echo false)"
echo "udeps:     ${UDEPS_CMD:-no}"
echo "extra:     $([ -f "$EXTRA" ] && echo "$EXTRA" || echo no)"

rustup toolchain list | grep -q "^$MSRV" || rustup toolchain install "$MSRV" --profile minimal -c clippy
rustup component list --toolchain "$MSRV" --installed | grep -q '^clippy' || rustup component add clippy --toolchain "$MSRV"

# --- run the checks -----------------------------------------------------------
START=$SECONDS
RAN=()
step() {
  local label=$1
  shift
  say "$label: $*"
  local t=$SECONDS
  "$@" || die "$label failed"
  echo "($label: $((SECONDS - t))s)"
  RAN+=("$label")
}

# shellcheck disable=SC2086 # FEATURES is a list of flags
{
  step fmt cargo +stable fmt --all --check
  step clippy-stable cargo +stable clippy --all-targets $FEATURES -- -D warnings
  step clippy-msrv cargo "+$MSRV" clippy --all-targets $FEATURES -- -D warnings
  step test-stable cargo +stable test $FEATURES
  step test-msrv cargo "+$MSRV" test $FEATURES
  if [ "${RUN_DOC:-true}" != false ]; then
    step doc env RUSTDOCFLAGS="-D warnings" cargo +stable doc --no-deps $FEATURES
  fi
  if [ "${RUN_SEMVER:-true}" != false ] && [ "${GENERATED:-false}" != true ]; then
    command -v cargo-semver-checks >/dev/null || die "cargo-semver-checks missing: cargo install cargo-semver-checks --locked"
    step semver cargo +stable semver-checks
  fi
  if [ -n "$UDEPS_CMD" ]; then
    command -v cargo-udeps >/dev/null || die "cargo-udeps missing: cargo install cargo-udeps --locked"
    step udeps bash -c "$UDEPS_CMD"
  fi
  if [ -f "$EXTRA" ]; then
    step extra bash "$EXTRA"
  fi
}

if [ -n "$(git status --porcelain)" ]; then
  git status --short >&2
  die "the checks modified the working tree; not attesting"
fi
[ "$(git rev-parse HEAD)" = "$SHA" ] || die "HEAD moved while the checks ran; not attesting"

ELAPSED=$((SECONDS - START))
SUMMARY="${RAN[*]}"
DESC="ok: ${SUMMARY// /,} (stable+$MSRV) on $HOST in $((ELAPSED / 60))m$((ELAPSED % 60))s"
DESC=${DESC:0:140} # GitHub limit
say "all checks passed: $DESC"

if [ "$POST" = 0 ]; then
  echo "--no-post: not posting a status"
  exit 0
fi

if [ "$PUSH" = 1 ]; then
  say "pushing $BRANCH"
  git push origin "HEAD:refs/heads/$BRANCH"
fi
sha_on_origin || die "$SHA is not on github.com/$REPO; push it and re-run"

gh api -X POST "repos/$REPO/statuses/$SHA" \
  -f state=success -f context=local-ci -f description="$DESC" --silent
say "posted local-ci=success on $REPO@$SHA"

if [ "$RERUN" = 1 ]; then
  sleep 5
  gh run list -R "$REPO" --commit "$SHA" --event pull_request \
    --json databaseId,status,conclusion,workflowName \
    -q '.[] | select(.status != "completed" or (.conclusion != "success" and .conclusion != "skipped")) | "\(.databaseId) \(.status) \(.workflowName)"' |
    while read -r id status name; do
      if [ "$status" != completed ]; then
        echo "cancelling $name ($id)"
        gh run cancel -R "$REPO" "$id" >/dev/null || true
        for _ in $(seq 1 30); do
          [ "$(gh run view -R "$REPO" "$id" --json status -q .status)" = completed ] && break
          sleep 2
        done
      fi
      echo "re-running $name ($id)"
      gh run rerun -R "$REPO" "$id" || echo "could not re-run $id" >&2
    done
fi
