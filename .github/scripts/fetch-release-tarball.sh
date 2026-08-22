#!/usr/bin/env bash
# Download one tarball from a GitHub Release and extract it.
# Jobs share tagged / public-base bits this way instead of Actions artifacts.
set -euo pipefail

die() {
  echo "ERROR: fetch-release-tarball: $*" >&2
  exit 1
}

ASSET="${1:-}"
DEST="${2:-}"
[ -n "$ASSET" ] || die "usage: fetch-release-tarball.sh <asset.tar.gz> <dest-dir>"
[ -n "$DEST" ] || die "usage: fetch-release-tarball.sh <asset.tar.gz> <dest-dir>"

TAG_NAME="${CHAINS_RELEASE_TAG:-${GITHUB_REF_NAME:-}}"
REPO="${CHAINS_RELEASE_REPO:-${GITHUB_REPOSITORY:-}}"
[ -n "$TAG_NAME" ] || die "tag name is empty"
[ -n "$REPO" ] || die "repository is empty"
command -v gh >/dev/null 2>&1 || die "gh is required to fetch the tag release"

mkdir -p "$DEST"
WORKDIR="$(mktemp -d "${TMPDIR:-/tmp}/fetch-release-tarball.XXXXXX")"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

gh release download "$TAG_NAME" \
  --repo "$REPO" \
  --pattern "$ASSET" \
  --dir "$WORKDIR"

[ -f "$WORKDIR/$ASSET" ] || die "downloaded asset missing: $ASSET"
tar -xzf "$WORKDIR/$ASSET" -C "$DEST"
