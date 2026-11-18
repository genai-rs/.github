#!/usr/bin/env bash
# Set a new crates.io token as the CARGO_REGISTRY_TOKEN secret of the repos that
# publish genai-rs crates. See docs/token-rotation.md.
#
# Usage:
#   rotate-crates-token.sh [--dry-run] [--from-cmd '<command>'] <repo>...
#   rotate-crates-token.sh --list
#
#   <repo>       owner/name, or `all` for every repo in the table below.
#   --from-cmd   run this command and use its output as the token, e.g. a
#                password manager: --from-cmd 'op read op://ci/crates-io/token'.
#                Without it, the token is read from stdin (a hidden prompt when
#                stdin is a terminal).
#   --dry-run    check the repos and the token, show what would change, set
#                nothing.
#   --list       print the repos and the crates each token must cover.
#
# The token is held in a shell variable only: it is never an argument of a
# command, never written to disk and never printed.
set -euo pipefail

SECRET=CARGO_REGISTRY_TOKEN

# repo | crates the token must be allowed to publish (crates.io crate scopes)
REPOS=(
  "genai-rs/openai-client-base|openai-client-base"
  "genai-rs/langfuse-client-base|langfuse-client-base"
  "genai-rs/openai-ergonomic|openai-ergonomic"
  "genai-rs/langfuse-ergonomic|langfuse-ergonomic langfuse-ergonomic-macros"
  "genai-rs/opentelemetry-langfuse|opentelemetry-langfuse"
  "genai-rs/genai-agents|genai-agents genai-agents-openai genai-agents-sqlite genai-agents-mcp genai-agents-eval genai-agents-macros"
  "timvw/openapi-generator-timvw-rust|timvw-rust-runtime"
)

die() { echo "error: $*" >&2; exit 1; }

crates_of() {
  local entry
  for entry in "${REPOS[@]}"; do
    if [[ ${entry%%|*} == "$1" ]]; then echo "${entry#*|}"; return 0; fi
  done
  return 1
}

updated_at() {
  gh secret list --repo "$1" --json name,updatedAt \
    --jq ".[] | select(.name == \"$SECRET\") | .updatedAt"
}

dry_run=false
from_cmd=""
targets=()
while (($#)); do
  case $1 in
    --dry-run) dry_run=true ;;
    --from-cmd) (($# >= 2)) || die "--from-cmd needs a command"; from_cmd=$2; shift ;;
    --list)
      for entry in "${REPOS[@]}"; do printf '%-40s %s\n' "${entry%%|*}" "${entry#*|}"; done
      exit 0 ;;
    -h | --help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    all) for entry in "${REPOS[@]}"; do targets+=("${entry%%|*}"); done ;;
    -*) die "unknown option $1" ;;
    *) crates_of "$1" >/dev/null || die "$1 is not in the table (see --list)"; targets+=("$1") ;;
  esac
  shift
done
((${#targets[@]})) || die "name at least one repo, or all (see --help)"

command -v gh >/dev/null || die "gh is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not logged in"

# Check every repo first, so a missing permission stops before anything changes.
# (Indexed like targets; no associative arrays, so macOS's bash 3.2 runs it.)
before=()
for repo in "${targets[@]}"; do
  stamp=$(updated_at "$repo") || die "cannot read the secrets of $repo (needs admin access)"
  before+=("$stamp")
done

if [[ -n $from_cmd ]]; then
  token=$(bash -c "$from_cmd") || die "--from-cmd failed"
elif [[ -t 0 ]]; then
  read -rsp "crates.io token: " token
  echo >&2
else
  IFS= read -r token || true
fi
token=${token//[$'\r\n']/}
[[ -n $token ]] || die "no token given"
# crates.io tokens start with "cio"; anything else is likely a paste mistake.
[[ $token == cio* ]] || die "that does not look like a crates.io token (no cio prefix)"

echo "The token must be allowed to publish (publish-update scope):"
for repo in "${targets[@]}"; do
  printf '  %-40s %s\n' "$repo" "$(crates_of "$repo")"
done

changed=0
for i in "${!targets[@]}"; do
  repo=${targets[$i]}
  was=${before[$i]:-never}
  if $dry_run; then
    printf '%-40s would set %s (now updated %s)\n' "$repo" "$SECRET" "$was"
    continue
  fi
  printf '%s' "$token" | gh secret set "$SECRET" --repo "$repo"
  after=$(updated_at "$repo")
  if [[ -n $after && $after != "$was" ]]; then
    printf '%-40s %s updated %s (was %s)\n' "$repo" "$SECRET" "$after" "$was"
    changed=$((changed + 1))
  else
    echo "error: $repo: $SECRET did not change" >&2
  fi
done
unset token

if $dry_run; then
  echo "Dry run: nothing was set."
elif ((changed != ${#targets[@]})); then
  die "updated $changed of ${#targets[@]} repos"
else
  echo "Updated $changed repos. Revoke the old token on crates.io once a release has published with the new one."
fi
