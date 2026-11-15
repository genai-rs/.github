#!/usr/bin/env bash
# Print the workspace's publishable crates that crates.io does not have yet, one
# per line. cargo-semver-checks compares a crate with its latest release, so it
# cannot check a crate before its first release; the semver jobs leave these out.
#
# Usage (from the workspace root): bash unpublished-crates.sh
set -euo pipefail

cargo metadata --no-deps --format-version 1 |
  jq -r '.packages[] | select(.publish == null or (.publish | length) > 0) | .name' |
  while read -r name; do
    status=$(curl -s -o /dev/null -w '%{http_code}' \
      -A 'genai-rs-ci (https://github.com/genai-rs/.github)' \
      "https://crates.io/api/v1/crates/$name")
    case "$status" in
      200) ;;
      404) echo "$name" ;;
      *)
        echo "crates.io answered $status for $name" >&2
        exit 1
        ;;
    esac
  done
