#!/usr/bin/env bash
# Package java-chains-web-element (Vue / Element Plus) into
# java-chains-server target/generated-resources/static for product releases.
#
# Used by the java-chains release repository CI. Invoked from Maven -Pfrontend
# with -Dfrontend.working.directory=…/java-chains-web-element and
# -Dfrontend.package.script pointing at this file.
#
# Required env (absolute paths):
#   REPO_ROOT, CHAINS_WEB_DIR, OUT_STATIC_DIR
# Optional:
#   FRONTEND_TOOLS_DIR   (frontend-maven-plugin node; unused if pnpm is on PATH)
#   CHAINS_PACKAGE_SESSION / CHAINS_PACKAGE_MARKER
#   SOURCE_DATE_EPOCH
set -euo pipefail

die() { echo "ERROR: package-java-chains-web-element: $*" >&2; exit 1; }
note() { echo "package-java-chains-web-element: $*"; }

require_abs() {
  local name="$1" val="$2"
  [ -n "$val" ] || die "$name is required"
  case "$val" in
    /*) ;;
    *) die "$name must be absolute (got: $val)" ;;
  esac
}

require_abs REPO_ROOT "${REPO_ROOT:-}"
require_abs CHAINS_WEB_DIR "${CHAINS_WEB_DIR:-}"
require_abs OUT_STATIC_DIR "${OUT_STATIC_DIR:-}"

[ -d "$REPO_ROOT" ] || die "REPO_ROOT not a directory: $REPO_ROOT"
[ -d "$CHAINS_WEB_DIR" ] || die "CHAINS_WEB_DIR not a directory: $CHAINS_WEB_DIR"
[ -f "$CHAINS_WEB_DIR/package.json" ] || die "missing package.json under $CHAINS_WEB_DIR"
[ -f "$CHAINS_WEB_DIR/pnpm-lock.yaml" ] || die "missing pnpm-lock.yaml under $CHAINS_WEB_DIR"

case "$OUT_STATIC_DIR" in
  */src/*|*/src/main/resources/*|*/src/main/resources)
    die "OUT_STATIC_DIR must not be under src/: $OUT_STATIC_DIR"
    ;;
esac

command -v pnpm >/dev/null 2>&1 || die "pnpm not on PATH (release CI must setup-node + pnpm/action-setup)"
command -v node >/dev/null 2>&1 || die "node not on PATH"

NODE_VER_RAW="$(node -v 2>&1)" || die "node -v failed"
PNPM_VER_RAW="$(pnpm -v 2>&1)" || die "pnpm -v failed"
note "node=$NODE_VER_RAW pnpm=$PNPM_VER_RAW"
note "java-chains-web-element=$CHAINS_WEB_DIR"
note "out=$OUT_STATIC_DIR"

CHAINS_WEB_COMMIT="$(git -C "$REPO_ROOT" log -1 --format=%H -- java-chains-web-element)" \
  || die "failed to resolve latest commit touching java-chains-web-element/"
[ -n "$CHAINS_WEB_COMMIT" ] || die "empty java-chains-web-element commit"
REPOSITORY_BUILD_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD)" \
  || die "failed to resolve repository packaging HEAD"
CHAINS_WEB_COMMIT_CT="$(git -C "$REPO_ROOT" log -1 --format=%ct -- java-chains-web-element)" \
  || die "failed to resolve committer time for java-chains-web-element"

if [ -z "${SOURCE_DATE_EPOCH:-}" ]; then
  SOURCE_DATE_EPOCH="$CHAINS_WEB_COMMIT_CT"
  BUILD_TIME_SOURCE="git:java-chains-web-element%ct"
else
  BUILD_TIME_SOURCE="env:SOURCE_DATE_EPOCH"
fi
export SOURCE_DATE_EPOCH
case "$SOURCE_DATE_EPOCH" in
  ''|*[!0-9]*) die "SOURCE_DATE_EPOCH must be unix seconds (got: $SOURCE_DATE_EPOCH)" ;;
esac
if BUILD_TIME_ISO="$(date -u -d "@${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
  :
elif BUILD_TIME_ISO="$(date -u -r "${SOURCE_DATE_EPOCH}" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"; then
  :
else
  die "failed to format BUILD_TIME_ISO from SOURCE_DATE_EPOCH=$SOURCE_DATE_EPOCH"
fi

hash_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    sha256sum "$1" | awk '{print $1}'
  fi
}

LOCK_SHA="$(hash_file "$CHAINS_WEB_DIR/pnpm-lock.yaml")" \
  || die "failed to hash pnpm-lock.yaml"

cd "$CHAINS_WEB_DIR" || die "cannot cd to $CHAINS_WEB_DIR"

note "pnpm install --frozen-lockfile"
# Keep devDependencies for vite / vue-tsc regardless of ambient NODE_ENV.
env -u NODE_ENV pnpm install --frozen-lockfile

LOCK_SHA_AFTER="$(hash_file "$CHAINS_WEB_DIR/pnpm-lock.yaml")" \
  || die "failed to hash pnpm-lock.yaml after install"
[ "$LOCK_SHA" = "$LOCK_SHA_AFTER" ] || die "pnpm-lock.yaml mutated by install"

mkdir -p "$OUT_STATIC_DIR" || die "cannot mkdir OUT_STATIC_DIR"
find "$OUT_STATIC_DIR" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true

note "vue-tsc --noEmit + vite build → $OUT_STATIC_DIR"
export NODE_ENV=production
env -u NODE_ENV pnpm exec vue-tsc --noEmit
pnpm exec vite build --outDir "$OUT_STATIC_DIR" --emptyOutDir --sourcemap false

[ -f "$OUT_STATIC_DIR/index.html" ] || die "build missing index.html under $OUT_STATIC_DIR"

VITE_PKG="$CHAINS_WEB_DIR/node_modules/vite/package.json"
[ -f "$VITE_PKG" ] || die "vite not installed: $VITE_PKG"
VITE_VERSION="$(node --input-type=commonjs -e "console.log(require(process.argv[1]).version)" "$VITE_PKG")" \
  || die "failed to read vite version"

MANIFEST_NAME=".build-provenance.json"
CONTENT_LISTING="$(mktemp)"
trap 'rm -f "$CONTENT_LISTING"' EXIT

(
  cd "$OUT_STATIC_DIR" || exit 1
  find . -type f ! -name "$MANIFEST_NAME" -print | LC_ALL=C sort | while IFS= read -r rel; do
    rel_norm="${rel#./}"
    file_sha="$(hash_file "$rel")"
    printf '%s\t%s\n' "$rel_norm" "$file_sha"
  done
) >"$CONTENT_LISTING" || die "failed to build content listing"

CONTENT_HASH="$(hash_file "$CONTENT_LISTING")"
FILE_COUNT="$(wc -l <"$CONTENT_LISTING" | tr -d ' ')"

OPENAPI_PATH="$REPO_ROOT/java-chains-server/src/main/resources/openapi/canonical-v0.yaml"
OPENAPI_SHA=""
if [ -f "$OPENAPI_PATH" ]; then
  OPENAPI_SHA="$(hash_file "$OPENAPI_PATH")"
fi

MANIFEST_PATH="$OUT_STATIC_DIR/$MANIFEST_NAME"
export _PROV_OUT="$MANIFEST_PATH"
export _PROV_COMMIT="$CHAINS_WEB_COMMIT"
export _PROV_REPO_COMMIT="$REPOSITORY_BUILD_COMMIT"
export _PROV_LOCK="$LOCK_SHA_AFTER"
export _PROV_OPENAPI="$OPENAPI_SHA"
export _PROV_NODE="$NODE_VER_RAW"
export _PROV_PNPM="$PNPM_VER_RAW"
export _PROV_VITE="$VITE_VERSION"
export _PROV_HASH="$CONTENT_HASH"
export _PROV_FILES="$FILE_COUNT"
export _PROV_TIME="$BUILD_TIME_ISO"
export _PROV_EPOCH="$SOURCE_DATE_EPOCH"
export _PROV_TIME_SRC="$BUILD_TIME_SOURCE"

node --input-type=commonjs <<'NODE'
const fs = require('fs');
const manifest = {
  schemaVersion: 1,
  source: 'java-chains-web-element',
  chainsWebCommit: process.env._PROV_COMMIT,
  repositoryBuildCommit: process.env._PROV_REPO_COMMIT,
  pnpmLockSha256: process.env._PROV_LOCK,
  openapiCanonicalSha256: process.env._PROV_OPENAPI || null,
  nodeVersionResolved: process.env._PROV_NODE,
  pnpmVersionResolved: process.env._PROV_PNPM,
  viteVersion: process.env._PROV_VITE,
  buildTime: process.env._PROV_TIME,
  buildTimeUnix: Number(process.env._PROV_EPOCH),
  buildTimeSource: process.env._PROV_TIME_SRC,
  contentHash: process.env._PROV_HASH,
  contentHashAlgorithm: 'sha256',
  contentFileCount: Number(process.env._PROV_FILES),
  outputDirHint: 'java-chains-server/target/generated-resources/static',
  notes: [
    'Product release SPA is java-chains-web-element (Vue3 + Element Plus).',
    'Built with pnpm (frozen lockfile) + vite; not the React java-chains-web path.',
  ],
};
fs.writeFileSync(process.env._PROV_OUT, JSON.stringify(manifest, null, 2) + '\n', 'utf8');
NODE

[ -f "$MANIFEST_PATH" ] || die "manifest not written: $MANIFEST_PATH"

SRC_STATIC="$REPO_ROOT/java-chains-server/src/main/resources/static"
if [ -e "$SRC_STATIC" ]; then
  die "source pollution: $SRC_STATIC exists after build"
fi

if [ -n "${CHAINS_PACKAGE_SESSION:-}" ]; then
  MARKER_PATH="${CHAINS_PACKAGE_MARKER:-}"
  [ -n "$MARKER_PATH" ] || die "CHAINS_PACKAGE_MARKER is required when CHAINS_PACKAGE_SESSION is set"
  case "$MARKER_PATH" in
    /*) ;;
    *) die "CHAINS_PACKAGE_MARKER must be absolute (got: $MARKER_PATH)" ;;
  esac
  mkdir -p "$(dirname "$MARKER_PATH")" || die "cannot mkdir for marker"
  {
    printf 'session=%s\n' "$CHAINS_PACKAGE_SESSION"
    printf 'source=java-chains-web-element\n'
    printf 'chainsWebCommit=%s\n' "$CHAINS_WEB_COMMIT"
    printf 'contentHash=%s\n' "$CONTENT_HASH"
    printf 'writtenBy=package-java-chains-web-element.sh\n'
  } >"$MARKER_PATH" || die "failed to write package marker"
  note "wrote session marker $MARKER_PATH"
fi

note "OK commit=$CHAINS_WEB_COMMIT contentHash=$CONTENT_HASH files=$FILE_COUNT"
