#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
VERIFIER="${SCRIPT_DIR}/verify-source-tag.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/verify-source-tag-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

SOURCE_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
TAG_OBJECT_SHA="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
RUN_ID="987654321"
RUN_URL="https://github.com/Java-Chains/chains/actions/runs/${RUN_ID}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_success_fixtures() {
  printf '%s\trefs/tags/v2.0.0-beta8\n' "$TAG_OBJECT_SHA" > "$TMP_DIR/ls-remote"
  printf '%s\trefs/tags/v2.0.0-beta8^{}\n' "$SOURCE_SHA" >> "$TMP_DIR/ls-remote"
  printf '{"workflow_runs":[{"id":%s,"head_sha":"%s","event":"push","status":"completed","conclusion":"success","html_url":"%s"}]}\n' \
    "$RUN_ID" "$SOURCE_SHA" "$RUN_URL" > "$TMP_DIR/runs.json"
  printf '{"artifacts":[{"name":"tag-build-%s","expired":false}]}\n' \
    "$RUN_ID" > "$TMP_DIR/artifacts.json"
}

run_verifier() {
  RELEASE_VERSION="${TEST_VERSION:-2.0.0-beta8}" \
  SOURCE_REF="${TEST_SOURCE_REF:-v2.0.0-beta8}" \
  CHAINS_LS_REMOTE_FILE="$TMP_DIR/ls-remote" \
  CHAINS_WORKFLOW_RUNS_FILE="$TMP_DIR/runs.json" \
  CHAINS_WORKFLOW_ARTIFACTS_FILE="$TMP_DIR/artifacts.json" \
  VERIFIED_SOURCE_OUTPUT="$TMP_DIR/output" \
    "$VERIFIER"
}

assert_output() {
  grep -Fx "$1" "$TMP_DIR/output" >/dev/null || fail "missing output: $1"
}

write_success_fixtures
: > "$TMP_DIR/output"
run_verifier >/dev/null
assert_output "source_ref=v2.0.0-beta8"
assert_output "source_sha=$SOURCE_SHA"
assert_output "verification_run_id=$RUN_ID"
assert_output "verification_run_url=$RUN_URL"
assert_output "verification_artifact=tag-build-$RUN_ID"
echo "PASS: annotated source tag resolves to verified commit"

write_success_fixtures
if TEST_SOURCE_REF="v2-dev" run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "branch source_ref should be rejected"
fi
grep -F "source_ref must equal the release tag" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing branch rejection"
echo "PASS: branch source_ref rejected"

write_success_fixtures
printf '{"workflow_runs":[{"id":%s,"head_sha":"%s","event":"push","status":"completed","conclusion":"failure","html_url":"%s"}]}\n' \
  "$RUN_ID" "$SOURCE_SHA" "$RUN_URL" > "$TMP_DIR/runs.json"
if run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "failed upstream workflow should be rejected"
fi
grep -F "no successful tag-test-build.yml run" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing failed-run rejection"
echo "PASS: failed upstream run rejected"

write_success_fixtures
printf '{"artifacts":[{"name":"tag-build-%s","expired":true}]}\n' \
  "$RUN_ID" > "$TMP_DIR/artifacts.json"
if run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "expired build evidence should be rejected"
fi
grep -F "one unexpired artifact" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing expired-artifact rejection"
echo "PASS: expired build evidence rejected"

write_success_fixtures
if TEST_VERSION="2.0.0-beta8-internal" \
  TEST_SOURCE_REF="v2.0.0-beta8-internal" \
  run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "internal source should be rejected by public release"
fi
grep -F "public version must not contain internal" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing internal-version rejection"
echo "PASS: internal source rejected"

echo "PASS: verified source tag contract"
