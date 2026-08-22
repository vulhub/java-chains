#!/usr/bin/env bash
# Resolve a public source tag on Java-Chains/chains.
# Packaging happens in this repository from that commit; a successful source
# Tag Test / tag-build.tar.gz is not required.
set -euo pipefail

die() {
  echo "ERROR: verified-source-tag: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-}"
SOURCE_REF="${SOURCE_REF:-}"
CHAINS_REPOSITORY="${CHAINS_REPOSITORY:-Java-Chains/chains}"
OUTPUT_FILE="${VERIFIED_SOURCE_OUTPUT:-${GITHUB_OUTPUT:-}}"
AUTH_SCRIPT="${CHAINS_GIT_AUTH_SCRIPT:-${SCRIPT_DIR}/git-authed.sh}"

[ -n "$RELEASE_VERSION" ] || die "RELEASE_VERSION is required"
if ! [[ "$RELEASE_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?$ ]]; then
  die "invalid public version: $RELEASE_VERSION"
fi
VERSION_LC="$(printf '%s' "$RELEASE_VERSION" | tr '[:upper:]' '[:lower:]')"
[[ "$VERSION_LC" != *internal* ]] || die "public version must not contain internal"

EXPECTED_TAG="v${RELEASE_VERSION}"
if [ -z "$SOURCE_REF" ]; then
  SOURCE_REF="$EXPECTED_TAG"
fi
[ "$SOURCE_REF" = "$EXPECTED_TAG" ] \
  || die "source_ref must equal the release tag: got=$SOURCE_REF expected=$EXPECTED_TAG"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/verified-source-tag.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

LS_REMOTE_FILE="${CHAINS_LS_REMOTE_FILE:-${TMP_DIR}/ls-remote.txt}"
if [ -z "${CHAINS_LS_REMOTE_FILE:-}" ]; then
  [ -n "${DEPENDENCY_REPO_TOKEN:-}" ] \
    || die "DEPENDENCY_REPO_TOKEN is required to read $CHAINS_REPOSITORY"
  [ -x "$AUTH_SCRIPT" ] || die "git authentication wrapper is not executable: $AUTH_SCRIPT"
  DEPENDENCY_REPO_TOKEN="$DEPENDENCY_REPO_TOKEN" \
    "$AUTH_SCRIPT" ls-remote "https://github.com/${CHAINS_REPOSITORY}.git" \
      "refs/tags/${SOURCE_REF}" "refs/tags/${SOURCE_REF}^{}" > "$LS_REMOTE_FILE"
fi

TAG_REF="refs/tags/${SOURCE_REF}"
PEELED_REF="${TAG_REF}^{}"
SOURCE_SHA="$(awk -v ref="$PEELED_REF" '$2 == ref { print $1; exit }' "$LS_REMOTE_FILE")"
if [ -z "$SOURCE_SHA" ]; then
  SOURCE_SHA="$(awk -v ref="$TAG_REF" '$2 == ref { print $1; exit }' "$LS_REMOTE_FILE")"
fi
[ -n "$SOURCE_SHA" ] || die "source tag does not exist in $CHAINS_REPOSITORY: $SOURCE_REF"
if ! [[ "$SOURCE_SHA" =~ ^[0-9a-fA-F]{40}$ ]]; then
  die "source tag resolved to an invalid commit id: $SOURCE_SHA"
fi
SOURCE_SHA="$(printf '%s' "$SOURCE_SHA" | tr '[:upper:]' '[:lower:]')"

if [ -n "$OUTPUT_FILE" ]; then
  {
    echo "source_ref=$SOURCE_REF"
    echo "source_sha=$SOURCE_SHA"
  } >> "$OUTPUT_FILE"
fi

echo "verified-source-tag: tag=$SOURCE_REF sha=$SOURCE_SHA"
