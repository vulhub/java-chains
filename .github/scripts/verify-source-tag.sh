#!/usr/bin/env bash
# Resolve a public source tag and require successful upstream tag verification.
set -euo pipefail

die() {
  echo "ERROR: verified-source-tag: $*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
RELEASE_VERSION="${RELEASE_VERSION:-}"
SOURCE_REF="${SOURCE_REF:-}"
CHAINS_REPOSITORY="${CHAINS_REPOSITORY:-Java-Chains/chains}"
TAG_TEST_WORKFLOW="${TAG_TEST_WORKFLOW:-tag-test-build.yml}"
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

command -v jq >/dev/null 2>&1 || die "jq is required"

RUNS_FILE="${CHAINS_WORKFLOW_RUNS_FILE:-${TMP_DIR}/workflow-runs.json}"
if [ -z "${CHAINS_WORKFLOW_RUNS_FILE:-}" ]; then
  [ -n "${DEPENDENCY_REPO_TOKEN:-}" ] \
    || die "DEPENDENCY_REPO_TOKEN is required to read upstream Actions runs"
  if ! GH_TOKEN="$DEPENDENCY_REPO_TOKEN" gh api --method GET \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/${CHAINS_REPOSITORY}/actions/workflows/${TAG_TEST_WORKFLOW}/runs" \
    -f event=push -f head_sha="$SOURCE_SHA" -f status=success -f per_page=100 \
    > "$RUNS_FILE"; then
    die "cannot read upstream workflow runs; DEPENDENCY_REPO_TOKEN needs Actions: read on $CHAINS_REPOSITORY"
  fi
fi

RUN_ID="$(jq -r --arg sha "$SOURCE_SHA" '
  [
    .workflow_runs[]?
    | select(
        (.head_sha | ascii_downcase) == $sha
        and .event == "push"
        and .status == "completed"
        and .conclusion == "success"
      )
  ]
  | sort_by(.id)
  | last
  | .id // empty
' "$RUNS_FILE")"
[ -n "$RUN_ID" ] \
  || die "no successful ${TAG_TEST_WORKFLOW} run for tag=$SOURCE_REF sha=$SOURCE_SHA"

RUN_URL="$(jq -r --argjson id "$RUN_ID" '
  .workflow_runs[]? | select(.id == $id) | .html_url
' "$RUNS_FILE" | tail -n 1)"
[ -n "$RUN_URL" ] && [ "$RUN_URL" != "null" ] \
  || die "verified workflow run is missing html_url: $RUN_ID"

ARTIFACTS_FILE="${CHAINS_WORKFLOW_ARTIFACTS_FILE:-${TMP_DIR}/workflow-artifacts.json}"
if [ -z "${CHAINS_WORKFLOW_ARTIFACTS_FILE:-}" ]; then
  if ! GH_TOKEN="$DEPENDENCY_REPO_TOKEN" gh api --method GET \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "repos/${CHAINS_REPOSITORY}/actions/runs/${RUN_ID}/artifacts" \
    -f per_page=100 > "$ARTIFACTS_FILE"; then
    die "cannot read artifacts for upstream workflow run: $RUN_ID"
  fi
fi

ARTIFACT_NAME="tag-build-${RUN_ID}"
ARTIFACT_COUNT="$(jq -r --arg name "$ARTIFACT_NAME" '
  [.artifacts[]? | select(.name == $name and .expired == false)] | length
' "$ARTIFACTS_FILE")"
[ "$ARTIFACT_COUNT" = "1" ] \
  || die "verified run must have one unexpired artifact named $ARTIFACT_NAME"

if [ -n "$OUTPUT_FILE" ]; then
  {
    echo "source_ref=$SOURCE_REF"
    echo "source_sha=$SOURCE_SHA"
    echo "verification_run_id=$RUN_ID"
    echo "verification_run_url=$RUN_URL"
    echo "verification_artifact=$ARTIFACT_NAME"
  } >> "$OUTPUT_FILE"
fi

echo "verified-source-tag: tag=$SOURCE_REF sha=$SOURCE_SHA run=$RUN_ID artifact=$ARTIFACT_NAME"
