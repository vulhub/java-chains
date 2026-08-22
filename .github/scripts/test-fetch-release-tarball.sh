#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SCRIPT="$SCRIPT_DIR/fetch-release-tarball.sh"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/fetch-release-tarball-test.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

fail() {
  echo "FAIL: fetch-release-tarball: $*" >&2
  exit 1
}

mkdir -p "$TMP_DIR/src"
printf 'payload\n' > "$TMP_DIR/src/hello.txt"
tar -C "$TMP_DIR/src" -czf "$TMP_DIR/hello.tar.gz" .

mkdir -p "$TMP_DIR/bin"
cat > "$TMP_DIR/bin/gh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
pattern=""
dir=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    --pattern)
      pattern="\$2"
      shift 2
      ;;
    --dir)
      dir="\$2"
      shift 2
      ;;
    --repo)
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
[ -n "\$pattern" ] || exit 91
[ -n "\$dir" ] || exit 92
cp "$TMP_DIR/\$pattern" "\$dir/\$pattern"
EOF
chmod +x "$TMP_DIR/bin/gh"

PATH="$TMP_DIR/bin:$PATH" \
  CHAINS_RELEASE_TAG=v2.0.0-test \
  CHAINS_RELEASE_REPO=Java-Chains/chains \
  "$SCRIPT" hello.tar.gz "$TMP_DIR/out" \
  || fail "fetch script failed against a fake gh"

[ -f "$TMP_DIR/out/hello.txt" ] || fail "extracted payload missing"
grep -F "payload" "$TMP_DIR/out/hello.txt" >/dev/null || fail "extracted payload mismatch"

echo "PASS: fetch-release-tarball"
