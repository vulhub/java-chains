#!/usr/bin/env bash
# Git over HTTPS with DEPENDENCY_REPO_TOKEN (classic or fine-grained PAT).
#
# Uses HTTP Basic via http.extraHeader. GitHub authenticates the token, not the
# username, so x-access-token is a stable default for every PAT type.
set -euo pipefail

: "${DEPENDENCY_REPO_TOKEN:?DEPENDENCY_REPO_TOKEN is required}"

USER_NAME="${DEPENDENCY_REPO_USERNAME:-x-access-token}"
BASIC="$(printf '%s:%s' "$USER_NAME" "$DEPENDENCY_REPO_TOKEN" | base64 | tr -d '\n')"
AUTH_KEY="http.https://github.com/.extraheader"
export GIT_TERMINAL_PROMPT=0

# An empty http.extraHeader resets inherited values before the replacement is
# added. Without it, actions/checkout@v4's persisted header and this header are
# both sent, and GitHub rejects the request as invalid authentication.
exec git \
  -c "${AUTH_KEY}=" \
  -c "${AUTH_KEY}=AUTHORIZATION: basic ${BASIC}" \
  "$@"
