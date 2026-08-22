#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
VERIFIER="$SCRIPT_DIR/verify-tag-build-artifact.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/tag-build-artifact-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

SOURCE_SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
REACT_FRONTEND_SHA="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
ELEMENT_FRONTEND_SHA="cccccccccccccccccccccccccccccccccccccccc"

fail() {
  echo "FAIL: tag-build-artifact: $*" >&2
  exit 1
}

write_public_fixture() {
  rm -rf "$TMP_DIR/artifact"
  mkdir -p "$TMP_DIR/artifact/chains-config/presets"
  printf 'server\n' > "$TMP_DIR/artifact/java-chains.jar"
  printf 'cli\n' > "$TMP_DIR/artifact/java-chains-cli.jar"
  printf 'version: 1\npresets: []\n' \
    > "$TMP_DIR/artifact/chains-config/presets/official-presets.yaml"
  printf '## What\x27s Changed\n\n**Full Changelog**: [old...new](https://example.invalid/compare/old...new)\n' \
    > "$TMP_DIR/artifact/RELEASE-NOTES.md"
  {
    echo "tag=v2.0.0-beta8"
    echo "source.commit=$SOURCE_SHA"
    echo "frontend.commit=$REACT_FRONTEND_SHA"
    echo "frontend.react.commit=$REACT_FRONTEND_SHA"
    echo "frontend.element.commit=$ELEMENT_FRONTEND_SHA"
    echo "version=2.0.0-beta8"
    echo "edition=public"
    echo "profiles=frontend"
  } > "$TMP_DIR/artifact/TAG-BUILD.txt"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$TMP_DIR/artifact" && sha256sum java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
      chains-config/presets/official-presets.yaml > SHA256SUMS)
  else
    (cd "$TMP_DIR/artifact" && shasum -a 256 java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
      chains-config/presets/official-presets.yaml > SHA256SUMS)
  fi
}

run_public_verifier() {
  TAG_BUILD_DIR="$TMP_DIR/artifact" \
  TAG_BUILD_OUTPUT="$TMP_DIR/output" \
  EXPECTED_TAG="v2.0.0-beta8" \
  EXPECTED_SOURCE_SHA="$SOURCE_SHA" \
  EXPECTED_VERSION="2.0.0-beta8" \
  EXPECTED_EDITION="${TEST_EDITION:-public}" \
  EXPECTED_PROFILES="${TEST_PROFILES:-frontend}" \
    "$VERIFIER"
}

write_public_fixture
: > "$TMP_DIR/output"
run_public_verifier >/dev/null
grep -Fx "source_sha=$SOURCE_SHA" "$TMP_DIR/output" >/dev/null \
  || fail "missing source_sha output"
grep -Fx "frontend_sha=$REACT_FRONTEND_SHA" "$TMP_DIR/output" >/dev/null \
  || fail "missing frontend_sha output"
grep -Fx "frontend_react_sha=$REACT_FRONTEND_SHA" "$TMP_DIR/output" >/dev/null \
  || fail "missing frontend_react_sha output"
grep -Fx "frontend_element_sha=$ELEMENT_FRONTEND_SHA" "$TMP_DIR/output" >/dev/null \
  || fail "missing frontend_element_sha output"
echo "PASS: verified public artifact accepted"

write_public_fixture
python3 - "$TMP_DIR/artifact/TAG-BUILD.txt" <<'PY'
from pathlib import Path
import sys
path = Path(sys.argv[1])
text = path.read_text()
path.write_text(text.replace("edition=public", "edition=internal"))
PY
if run_public_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "internal edition unexpectedly accepted as public"
fi
grep -F "edition mismatch" "$TMP_DIR/stderr" >/dev/null \
  || fail "edition mismatch did not report its cause"
echo "PASS: internal edition rejected"

write_public_fixture
{
  echo "tag=v2.0.0-beta8"
  echo "source.commit=$SOURCE_SHA"
  echo "frontend.commit=$REACT_FRONTEND_SHA"
  echo "frontend.react.commit=$REACT_FRONTEND_SHA"
  echo "frontend.element.commit=$ELEMENT_FRONTEND_SHA"
  echo "version=2.0.0-beta8"
  echo "edition=public"
  echo "profiles=frontend,with-exploits,with-rmi-workbench"
} > "$TMP_DIR/artifact/TAG-BUILD.txt"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$TMP_DIR/artifact" && sha256sum java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
    chains-config/presets/official-presets.yaml > SHA256SUMS)
else
  (cd "$TMP_DIR/artifact" && shasum -a 256 java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
    chains-config/presets/official-presets.yaml > SHA256SUMS)
fi
if run_public_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "internal Maven profiles unexpectedly accepted as public"
fi
grep -F "profiles mismatch" "$TMP_DIR/stderr" >/dev/null \
  || fail "profiles mismatch did not report its cause"
echo "PASS: internal profiles rejected"

write_public_fixture
mkdir -p "$TMP_DIR/artifact/lib"
printf 'rmg\n' > "$TMP_DIR/artifact/lib/remote-method-guesser.jar"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$TMP_DIR/artifact" && sha256sum java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
    chains-config/presets/official-presets.yaml lib/remote-method-guesser.jar > SHA256SUMS)
else
  (cd "$TMP_DIR/artifact" && shasum -a 256 java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md \
    chains-config/presets/official-presets.yaml lib/remote-method-guesser.jar > SHA256SUMS)
fi
if run_public_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "public artifact with RMG sidecar unexpectedly accepted"
fi
grep -F "internal RMG sidecar must not be present in public artifacts" "$TMP_DIR/stderr" >/dev/null \
  || fail "public RMG sidecar did not report its cause"
echo "PASS: public RMG sidecar rejected"

write_public_fixture
printf 'tampered\n' >> "$TMP_DIR/artifact/java-chains.jar"
if run_public_verifier >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
  fail "checksum mismatch unexpectedly passed"
fi
grep -F "FAILED" "$TMP_DIR/stdout" "$TMP_DIR/stderr" >/dev/null \
  || fail "checksum mismatch did not report failure"
echo "PASS: checksum mismatch rejected"

echo "PASS: tagged public build artifact contract"
