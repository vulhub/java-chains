#!/usr/bin/env bash
# Validate the immutable build artifact shared by internal/public release packagers.
set -euo pipefail

die() {
  echo "ERROR: tag-build-artifact: $*" >&2
  exit 1
}

ARTIFACT_DIR="${TAG_BUILD_DIR:-}"
OUTPUT_FILE="${TAG_BUILD_OUTPUT:-${GITHUB_OUTPUT:-}}"

[ -n "$ARTIFACT_DIR" ] || die "TAG_BUILD_DIR is required"
[ -d "$ARTIFACT_DIR" ] || die "artifact directory does not exist: $ARTIFACT_DIR"

for name in EXPECTED_TAG EXPECTED_SOURCE_SHA EXPECTED_VERSION EXPECTED_EDITION EXPECTED_PROFILES; do
  [ -n "${!name:-}" ] || die "$name is required"
done

METADATA_FILE="$ARTIFACT_DIR/TAG-BUILD.txt"
CHECKSUM_FILE="$ARTIFACT_DIR/SHA256SUMS"
RELEASE_NOTES_FILE="$ARTIFACT_DIR/RELEASE-NOTES.md"
for file in "$ARTIFACT_DIR/java-chains.jar" "$ARTIFACT_DIR/java-chains-cli.jar" \
  "$ARTIFACT_DIR/chains-config/presets/official-presets.yaml" \
  "$METADATA_FILE" "$RELEASE_NOTES_FILE" "$CHECKSUM_FILE"; do
  [ -f "$file" ] || die "required artifact file missing: $file"
done
if [ "$EXPECTED_EDITION" = "internal" ]; then
  for file in "$ARTIFACT_DIR/lib/remote-method-guesser.jar" \
    "$ARTIFACT_DIR/lib/remote-method-guesser-LICENSE.txt" \
    "$ARTIFACT_DIR/lib/remote-method-guesser-UPSTREAM.md"; do
    [ -f "$file" ] || die "required internal artifact file missing: $file"
  done
fi

read_field() {
  local key="$1"
  local count value
  count="$(grep -c "^${key}=" "$METADATA_FILE" || true)"
  [ "$count" = "1" ] || die "metadata must contain exactly one ${key}= entry"
  value="$(grep "^${key}=" "$METADATA_FILE" | cut -d= -f2-)"
  [ -n "$value" ] || die "metadata field is empty: $key"
  printf '%s\n' "$value"
}

TAG="$(read_field tag)"
SOURCE_SHA="$(read_field source.commit)"
FRONTEND_SHA="$(read_field frontend.commit)"
REACT_FRONTEND_SHA="$(read_field frontend.react.commit)"
ELEMENT_FRONTEND_SHA="$(read_field frontend.element.commit)"
VERSION="$(read_field version)"
EDITION="$(read_field edition)"
PROFILES="$(read_field profiles)"

[ "$TAG" = "$EXPECTED_TAG" ] || die "tag mismatch: got=$TAG expected=$EXPECTED_TAG"
[ "$SOURCE_SHA" = "$EXPECTED_SOURCE_SHA" ] \
  || die "source SHA mismatch: got=$SOURCE_SHA expected=$EXPECTED_SOURCE_SHA"
[ "$VERSION" = "$EXPECTED_VERSION" ] \
  || die "version mismatch: got=$VERSION expected=$EXPECTED_VERSION"
[ "$EDITION" = "$EXPECTED_EDITION" ] \
  || die "edition mismatch: got=$EDITION expected=$EXPECTED_EDITION"
[ "$PROFILES" = "$EXPECTED_PROFILES" ] \
  || die "profiles mismatch: got=$PROFILES expected=$EXPECTED_PROFILES"
[[ "$SOURCE_SHA" =~ ^[0-9a-f]{40}$ ]] || die "invalid source SHA: $SOURCE_SHA"
[[ "$FRONTEND_SHA" =~ ^[0-9a-f]{40}$ ]] || die "invalid frontend SHA: $FRONTEND_SHA"
[[ "$REACT_FRONTEND_SHA" =~ ^[0-9a-f]{40}$ ]] || die "invalid React frontend SHA: $REACT_FRONTEND_SHA"
[[ "$ELEMENT_FRONTEND_SHA" =~ ^[0-9a-f]{40}$ ]] || die "invalid Element frontend SHA: $ELEMENT_FRONTEND_SHA"
[ "$FRONTEND_SHA" = "$REACT_FRONTEND_SHA" ] \
  || die "legacy frontend SHA must identify the default React SPA"

server_seen=false
cli_seen=false
metadata_seen=false
release_notes_seen=false
preset_seen=false
rmg_jar_seen=false
rmg_license_seen=false
rmg_upstream_seen=false
line_count=0
while IFS= read -r line || [ -n "$line" ]; do
  line_count=$((line_count + 1))
  checksum="${line%% *}"
  filename="${line#*  }"
  [[ "$checksum" =~ ^[0-9a-f]{64}$ ]] || die "invalid checksum at line $line_count"
  [ "$filename" != "$line" ] || die "invalid checksum format at line $line_count"
  case "$filename" in
    java-chains.jar)
      [ "$server_seen" = false ] || die "duplicate checksum entry: $filename"
      server_seen=true
      ;;
    java-chains-cli.jar)
      [ "$cli_seen" = false ] || die "duplicate checksum entry: $filename"
      cli_seen=true
      ;;
    TAG-BUILD.txt)
      [ "$metadata_seen" = false ] || die "duplicate checksum entry: $filename"
      metadata_seen=true
      ;;
    RELEASE-NOTES.md)
      [ "$release_notes_seen" = false ] || die "duplicate checksum entry: $filename"
      release_notes_seen=true
      ;;
    chains-config/presets/*.yaml|chains-config/presets/*.yml)
      [ "$filename" != "chains-config/presets/user-presets.yaml" ] \
        || die "runtime user preset file must not be released"
      if [ "$filename" = "chains-config/presets/official-presets.yaml" ]; then
        [ "$preset_seen" = false ] || die "duplicate checksum entry: $filename"
        preset_seen=true
      fi
      ;;
    lib/remote-method-guesser.jar)
      [ "$EXPECTED_EDITION" = "internal" ] \
        || die "internal RMG sidecar must not be present in public artifacts"
      [ "$rmg_jar_seen" = false ] || die "duplicate checksum entry: $filename"
      rmg_jar_seen=true
      ;;
    lib/remote-method-guesser-LICENSE.txt)
      [ "$EXPECTED_EDITION" = "internal" ] \
        || die "internal RMG license must not be present in public artifacts"
      [ "$rmg_license_seen" = false ] || die "duplicate checksum entry: $filename"
      rmg_license_seen=true
      ;;
    lib/remote-method-guesser-UPSTREAM.md)
      [ "$EXPECTED_EDITION" = "internal" ] \
        || die "internal RMG provenance must not be present in public artifacts"
      [ "$rmg_upstream_seen" = false ] || die "duplicate checksum entry: $filename"
      rmg_upstream_seen=true
      ;;
    *) die "unexpected checksum target: $filename" ;;
  esac
done < "$CHECKSUM_FILE"

[ "$line_count" -ge 5 ] || die "SHA256SUMS must contain artifacts plus external preset catalogs"
[ "$server_seen" = true ] && [ "$cli_seen" = true ] && [ "$metadata_seen" = true ] \
  && [ "$release_notes_seen" = true ] && [ "$preset_seen" = true ] \
  || die "SHA256SUMS is missing a required entry"
if [ "$EXPECTED_EDITION" = "internal" ]; then
  [ "$rmg_jar_seen" = true ] && [ "$rmg_license_seen" = true ] \
    && [ "$rmg_upstream_seen" = true ] \
    || die "SHA256SUMS is missing an internal RMG sidecar entry"
fi

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$ARTIFACT_DIR" && sha256sum -c SHA256SUMS)
elif command -v shasum >/dev/null 2>&1; then
  (cd "$ARTIFACT_DIR" && shasum -a 256 -c SHA256SUMS)
else
  die "sha256sum or shasum is required"
fi

if [ -n "$OUTPUT_FILE" ]; then
  {
    echo "source_sha=$SOURCE_SHA"
    echo "frontend_sha=$FRONTEND_SHA"
    echo "frontend_react_sha=$REACT_FRONTEND_SHA"
    echo "frontend_element_sha=$ELEMENT_FRONTEND_SHA"
  } >> "$OUTPUT_FILE"
fi

echo "tag-build-artifact: OK tag=$TAG source=$SOURCE_SHA react=$REACT_FRONTEND_SHA element=$ELEMENT_FRONTEND_SHA edition=$EDITION"
