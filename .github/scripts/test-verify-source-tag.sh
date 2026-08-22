#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
VERIFIER="${SCRIPT_DIR}/verify-source-tag.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/verify-source-tag-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

SOURCE_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
TAG_OBJECT_SHA="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

write_success_fixtures() {
  printf '%s\trefs/tags/v2.0.0-beta8\n' "$TAG_OBJECT_SHA" > "$TMP_DIR/ls-remote"
  printf '%s\trefs/tags/v2.0.0-beta8^{}\n' "$SOURCE_SHA" >> "$TMP_DIR/ls-remote"
}

run_verifier() {
  RELEASE_VERSION="${TEST_VERSION:-2.0.0-beta8}" \
    SOURCE_REF="${TEST_SOURCE_REF:-v2.0.0-beta8}" \
  CHAINS_LS_REMOTE_FILE="$TMP_DIR/ls-remote" \
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
if grep -q 'verification_run_id=' "$TMP_DIR/output"; then
  fail "source-tag resolver must not require upstream Tag Test evidence"
fi
if grep -q 'verification_artifact=' "$TMP_DIR/output"; then
  fail "source-tag resolver must not require tag-build.tar.gz"
fi
echo "PASS: annotated source tag resolves to commit"

write_success_fixtures
if TEST_SOURCE_REF="main" run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "branch source_ref should be rejected"
fi
grep -F "source_ref must equal the release tag" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing branch rejection"
echo "PASS: branch source_ref rejected"

write_success_fixtures
: > "$TMP_DIR/ls-remote"
if run_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "missing source tag should be rejected"
fi
grep -F "source tag does not exist" "$TMP_DIR/stderr" >/dev/null \
  || fail "missing tag rejection"
echo "PASS: missing source tag rejected"

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
