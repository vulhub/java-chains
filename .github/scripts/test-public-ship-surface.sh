#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
VERIFIER="${SCRIPT_DIR}/verify-public-ship-surface.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/public-ship-surface-test.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_jar() {
  local name="$1"
  local application_yml="$2"
  local internal_entry="${3:-}"
  local internal_class="${4:-}"
  local root="$TMP_DIR/$name-root"
  local jar_path="$TMP_DIR/$name.jar"

  mkdir -p "$root/BOOT-INF/classes" "$root/BOOT-INF/lib"
  printf '%s\n' "$application_yml" > "$root/BOOT-INF/classes/application.yml"
  if [ -n "$internal_entry" ]; then
    : > "$root/BOOT-INF/lib/$internal_entry"
  fi
  if [ -n "$internal_class" ]; then
    mkdir -p "$root/$(dirname "$internal_class")"
    : > "$root/$internal_class"
  fi

  python3 - "$root" "$jar_path" <<'PY'
import os
import sys
import zipfile

root, output = sys.argv[1:]
with zipfile.ZipFile(output, 'w') as archive:
    for directory, _, files in os.walk(root):
        for filename in files:
            path = os.path.join(directory, filename)
            archive.write(path, os.path.relpath(path, root))
PY
  printf '%s\n' "$jar_path"
}

expect_pass() {
  "$VERIFIER" "$1" >/dev/null || fail "expected verifier to accept $1"
}

expect_fail() {
  local jar_path="$1"
  local message="$2"
  if "$VERIFIER" "$jar_path" >"$TMP_DIR/stdout" 2>"$TMP_DIR/stderr"; then
    fail "expected verifier to reject $jar_path"
  fi
  grep -F "$message" "$TMP_DIR/stderr" >/dev/null \
    || fail "missing rejection message: $message"
}

ABSENT_KEYS_JAR="$(make_jar absent-keys $'chains:\n  mcp:\n    materialize:\n      allowed-directories: ${CHAINS_MCP_MATERIALIZE_DIRS:}')"
expect_pass "$ABSENT_KEYS_JAR"
echo "PASS: current marker-based configuration may omit legacy feature keys"

FALSE_KEYS_JAR="$(make_jar false-keys $'chains:\n  exploits:\n    enabled: false\n  rmi:\n    workbench:\n      enabled: false')"
expect_pass "$FALSE_KEYS_JAR"
echo "PASS: explicit false legacy feature keys are accepted"

EXPLOITS_ENABLED_JAR="$(make_jar exploits-enabled $'chains:\n  exploits:\n    enabled: true')"
expect_fail "$EXPLOITS_ENABLED_JAR" "chains.exploits.enabled must be absent or false"
echo "PASS: explicit exploit enablement is rejected"

RMI_ENABLED_JAR="$(make_jar rmi-enabled $'chains:\n  rmi:\n    workbench:\n      enabled: true')"
expect_fail "$RMI_ENABLED_JAR" "chains.rmi.workbench.enabled must be absent or false"
echo "PASS: explicit RMI workbench enablement is rejected"

INTERNAL_MODULE_JAR="$(make_jar internal-module 'chains: {}' 'java-chains-exploits-2.0.0.jar')"
expect_fail "$INTERNAL_MODULE_JAR" "public release embeds internal module: java-chains-exploits-"
echo "PASS: internal module jar is rejected"

INTERNAL_CLASS_JAR="$(make_jar internal-class 'chains: {}' '' \
  'BOOT-INF/classes/org/vulhub/javachains/web/adapter/canonical/controller/CanonicalRmiController.class')"
expect_fail "$INTERNAL_CLASS_JAR" "public release contains internal class:"
echo "PASS: internal controller class is rejected"
