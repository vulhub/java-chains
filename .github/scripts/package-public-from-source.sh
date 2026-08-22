#!/usr/bin/env bash
# Checkout-local public packaging for vulhub/java-chains.
# Runs cheap public-edition tests, then builds -Pfrontend server + CLI.
set -euo pipefail

die() {
  echo "ERROR: package-public-from-source: $*" >&2
  exit 1
}

note() {
  echo "package-public-from-source: $*"
}

SOURCE_DIR="${SOURCE_DIR:-}"
OUTPUT_DIR="${OUTPUT_DIR:-}"
EXPECTED_VERSION="${EXPECTED_VERSION:-}"
EXPECTED_TAG="${EXPECTED_TAG:-}"
SOURCE_SHA="${SOURCE_SHA:-}"

[ -n "$SOURCE_DIR" ] || die "SOURCE_DIR is required"
[ -n "$OUTPUT_DIR" ] || die "OUTPUT_DIR is required"
[ -n "$EXPECTED_VERSION" ] || die "EXPECTED_VERSION is required"
[ -n "$EXPECTED_TAG" ] || die "EXPECTED_TAG is required"
[ -n "$SOURCE_SHA" ] || die "SOURCE_SHA is required"
[ -d "$SOURCE_DIR" ] || die "SOURCE_DIR is not a directory: $SOURCE_DIR"
[ -f "$SOURCE_DIR/pom.xml" ] || die "SOURCE_DIR is not a chains checkout: $SOURCE_DIR"

SOURCE_DIR="$(cd "$SOURCE_DIR" && pwd)"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

cd "$SOURCE_DIR"

ACTUAL_SOURCE_SHA="$(git rev-parse HEAD)"
[ "$ACTUAL_SOURCE_SHA" = "$SOURCE_SHA" ] \
  || die "Source SHA changed: expected=$SOURCE_SHA checkout=$ACTUAL_SOURCE_SHA"

VERSION_LC="$(printf '%s' "$EXPECTED_VERSION" | tr '[:upper:]' '[:lower:]')"
[[ "$VERSION_LC" != *internal* ]] || die "public version must not contain internal: $EXPECTED_VERSION"

POM_VERSION="$(python3 - "$SOURCE_DIR/pom.xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

ns = {"m": "http://maven.apache.org/POM/4.0.0"}
root = ET.parse(sys.argv[1]).getroot()
version = root.findtext("m:version", default="", namespaces=ns).strip()
chains = root.findtext("m:properties/m:chains-version", default="", namespaces=ns).strip()
print(version)
print(chains)
PY
)"
ROOT_VERSION="$(printf '%s' "$POM_VERSION" | sed -n '1p')"
CHAINS_VERSION="$(printf '%s' "$POM_VERSION" | sed -n '2p')"
[ "$ROOT_VERSION" = "$EXPECTED_VERSION" ] \
  || die "root pom version mismatch: got=$ROOT_VERSION expected=$EXPECTED_VERSION"
[ "$CHAINS_VERSION" = "$EXPECTED_VERSION" ] \
  || die "chains-version mismatch: got=$CHAINS_VERSION expected=$EXPECTED_VERSION"

[ -x "$SOURCE_DIR/scripts/ci/check-public-edition-surface.sh" ] \
  || die "missing public-edition surface check"
note "public-edition source preflight"
"$SOURCE_DIR/scripts/ci/check-public-edition-surface.sh" --source-only

if [ -x "$SOURCE_DIR/scripts/ci/install-local-deps.sh" ]; then
  note "install local Maven deps"
  "$SOURCE_DIR/scripts/ci/install-local-deps.sh"
fi

note "public-edition unit contract PublicInternalFeaturesGateTest"
mvn -B -pl java-chains-server -am \
  -Dtest=PublicInternalFeaturesGateTest \
  -Dsurefire.failIfNoSpecifiedTests=false \
  test

note "package public edition (-Pfrontend only)"
mvn -B --threads 1C -pl java-chains-server,java-chains-cli -am clean package \
  -DskipTests \
  -Pfrontend

pick_first() {
  local candidate
  for candidate in "$@"; do
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

SERVER_JAR="$(pick_first \
  "java-chains-server-${EXPECTED_VERSION}-exec.jar" \
  "java-chains-server/target/java-chains-server-${EXPECTED_VERSION}-exec.jar" \
  "java-chains-server/target/java-chains-${EXPECTED_VERSION}-exec.jar" \
  "java-chains-${EXPECTED_VERSION}-exec.jar" \
)" || true
CLI_JAR="$(pick_first \
  "java-chains-cli/target/java-chains-cli-${EXPECTED_VERSION}-jar-with-dependencies.jar" \
  "java-chains-cli/target/java-chains-cli-${EXPECTED_VERSION}.jar" \
)" || true

[ -n "${SERVER_JAR:-}" ] && [ -f "$SERVER_JAR" ] || die "public server artifact missing"
[ -n "${CLI_JAR:-}" ] && [ -f "$CLI_JAR" ] || die "public CLI artifact missing"
[ -f "chains-config/presets/official-presets.yaml" ] \
  || die "external preset catalog missing"

jar tf "$SERVER_JAR" > "$OUTPUT_DIR/tagged-server-contents.txt"
jar tf "$CLI_JAR" > "$OUTPUT_DIR/tagged-cli-contents.txt"
if grep -E '(^|/)(default-chains|official-presets)\.ya?ml$' "$OUTPUT_DIR/tagged-server-contents.txt" >/dev/null; then
  die "public server artifact embeds preset catalogs"
fi
if grep -E '(^|/)(default-chains|official-presets)\.ya?ml$' "$OUTPUT_DIR/tagged-cli-contents.txt" >/dev/null; then
  die "public CLI artifact embeds preset catalogs"
fi
for internal_jar in java-chains-exploits- java-chains-rmi-rmg-; do
  if grep -F "BOOT-INF/lib/${internal_jar}" "$OUTPUT_DIR/tagged-server-contents.txt" >/dev/null; then
    die "public artifact embeds internal module: ${internal_jar}"
  fi
done
for internal_class in \
  "BOOT-INF/classes/org/vulhub/javachains/web/adapter/canonical/controller/CanonicalRmiController.class" \
  "BOOT-INF/classes/org/vulhub/javachains/web/adapter/canonical/controller/CanonicalExploitsController.class"
do
  if grep -Fx "$internal_class" "$OUTPUT_DIR/tagged-server-contents.txt" >/dev/null; then
    die "public artifact contains internal class: ${internal_class}"
  fi
done

REACT_FRONTEND_SHA="$(git log -1 --format=%H -- java-chains-web)"
ELEMENT_FRONTEND_SHA="$(git log -1 --format=%H -- java-chains-web-element)"
[[ "$REACT_FRONTEND_SHA" =~ ^[0-9a-f]{40}$ ]] \
  || die "Invalid React frontend commit: $REACT_FRONTEND_SHA"
[[ "$ELEMENT_FRONTEND_SHA" =~ ^[0-9a-f]{40}$ ]] \
  || die "Invalid Element frontend commit: $ELEMENT_FRONTEND_SHA"

cp "$SERVER_JAR" "$OUTPUT_DIR/java-chains.jar"
cp "$CLI_JAR" "$OUTPUT_DIR/java-chains-cli.jar"
mkdir -p "$OUTPUT_DIR/chains-config/presets"
cp chains-config/presets/official-presets.yaml \
  "$OUTPUT_DIR/chains-config/presets/official-presets.yaml"

{
  echo "tag=${EXPECTED_TAG}"
  echo "source.commit=${SOURCE_SHA}"
  echo "frontend.commit=${REACT_FRONTEND_SHA}"
  echo "frontend.react.commit=${REACT_FRONTEND_SHA}"
  echo "frontend.element.commit=${ELEMENT_FRONTEND_SHA}"
  echo "version=${EXPECTED_VERSION}"
  echo "edition=public"
  echo "profiles=frontend"
} > "$OUTPUT_DIR/TAG-BUILD.txt"

if ! git rev-parse --verify --quiet "${EXPECTED_TAG}^{commit}" >/dev/null; then
  die "source tag is missing locally: $EXPECTED_TAG"
fi

CHAINS_RELEASE_NOTES_TAG="${EXPECTED_TAG}" \
CHAINS_RELEASE_NOTES_EDITION="public" \
CHAINS_RELEASE_NOTES_OUTPUT="$OUTPUT_DIR/RELEASE-NOTES.md" \
CHAINS_RELEASE_NOTES_REPOSITORY="${CHAINS_RELEASE_NOTES_REPOSITORY:-Java-Chains/chains}" \
CHAINS_RELEASE_NOTES_SERVER_URL="${CHAINS_RELEASE_NOTES_SERVER_URL:-https://github.com}" \
  "$SOURCE_DIR/scripts/ci/generate-release-notes.sh"

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$@"
  else
    shasum -a 256 "$@"
  fi
}

(
  cd "$OUTPUT_DIR"
  find java-chains.jar java-chains-cli.jar TAG-BUILD.txt RELEASE-NOTES.md chains-config/presets \
    -type f ! -name 'user-presets.yaml' -print \
    | LC_ALL=C sort \
    | while IFS= read -r artifact; do sha256_file "$artifact"; done > SHA256SUMS
)

note "staged $OUTPUT_DIR"
