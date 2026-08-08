#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTH_SCRIPT="${SCRIPT_DIR}/git-authed.sh"
AUTH_KEY="http.https://github.com/.extraheader"
TEST_TOKEN="github_pat_test_value"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/git-authed-test.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

git -C "$TMP_DIR" init -q
git -C "$TMP_DIR" config --local "$AUTH_KEY" \
  "AUTHORIZATION: basic cGVyc2lzdGVkLXRva2VuOg=="

# actions/checkout@v4 persists an Authorization extraHeader. The wrapper must
# reset inherited headers before adding its own, or Git sends both values.
WITH_USER_OUTPUT="$(
  cd "$TMP_DIR"
  env \
    DEPENDENCY_REPO_TOKEN="$TEST_TOKEN" \
    DEPENDENCY_REPO_USERNAME="token-owner" \
    "$AUTH_SCRIPT" config --get-all "$AUTH_KEY" 2>/dev/null
)"

WITH_USER_LINE_COUNT="$(printf '%s\n' "$WITH_USER_OUTPUT" | wc -l | tr -d ' ')"
[ "$WITH_USER_LINE_COUNT" = "3" ] || \
  fail "expected inherited header, reset marker, and replacement header; got ${WITH_USER_LINE_COUNT} entries"
[ -z "$(printf '%s\n' "$WITH_USER_OUTPUT" | sed -n '2p')" ] || \
  fail "expected an empty extraHeader reset marker before the replacement header"

EXPECTED_WITH_USER="AUTHORIZATION: basic $(
  printf '%s:%s' "token-owner" "$TEST_TOKEN" | base64 | tr -d '\n'
)"
[ "$(printf '%s\n' "$WITH_USER_OUTPUT" | sed -n '3p')" = "$EXPECTED_WITH_USER" ] || \
  fail "replacement Authorization header is incorrect"

# The username is syntactically required by HTTP Basic but is not used by
# GitHub to authenticate a PAT. A stable non-empty default avoids a second
# secret that can drift independently of the token.
WITHOUT_USER_OUTPUT="$(
  cd "$TMP_DIR"
  env -u DEPENDENCY_REPO_USERNAME \
    DEPENDENCY_REPO_TOKEN="$TEST_TOKEN" \
    "$AUTH_SCRIPT" config --get-all "$AUTH_KEY" 2>/dev/null
)"

EXPECTED_WITHOUT_USER="AUTHORIZATION: basic $(
  printf '%s:%s' "x-access-token" "$TEST_TOKEN" | base64 | tr -d '\n'
)"
[ "$(printf '%s\n' "$WITHOUT_USER_OUTPUT" | sed -n '3p')" = "$EXPECTED_WITHOUT_USER" ] || \
  fail "fine-grained PAT should work with the non-empty default username"

echo "PASS: git-authed.sh replaces inherited GitHub Authorization headers"
