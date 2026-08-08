#!/bin/sh
# Ensure bind-mounted chains-config is writable by appuser, then drop privileges.
# FakeMySQL LOCAL INFILE captures are persisted under:
#   chains-config/cache/fake-server-files/
# Empty host mounts (./chains-config created as root:root) otherwise yield
# AccessDeniedException and appear as "cannot read files" in the UI.
set -eu

APP_USER="${CHAINS_APP_USER:-appuser}"
APP_GROUP="${CHAINS_APP_GROUP:-appgroup}"
CONFIG_DIR="${CHAINS_CONFIG_DIR:-/chains/chains-config}"

ensure_dir_writable_by_app() {
  dir="$1"
  mkdir -p "$dir"
  if ! runuser -u "$APP_USER" -- test -w "$dir" 2>/dev/null; then
    chown "$APP_USER:$APP_GROUP" "$dir" || true
  fi
}

if [ "$(id -u)" = "0" ]; then
  mkdir -p "$CONFIG_DIR"
  # Host bind mounts often create the volume root as root:root (mode 755).
  # Chown the directory inode (not a recursive tree walk) so appuser can create
  # cache/plugin/preset children without rewriting user plugin contents.
  if ! runuser -u "$APP_USER" -- test -w "$CONFIG_DIR" 2>/dev/null; then
    chown "$APP_USER:$APP_GROUP" "$CONFIG_DIR" || true
  fi

  ensure_dir_writable_by_app "$CONFIG_DIR/cache"
  ensure_dir_writable_by_app "$CONFIG_DIR/cache/fake-server-files"
  ensure_dir_writable_by_app "$CONFIG_DIR/plugins"
  ensure_dir_writable_by_app "$CONFIG_DIR/presets"
  ensure_dir_writable_by_app "$CONFIG_DIR/plugin-data"

  # Previous root-owned captures under cache/ would still be unreadable; reclaim cache only.
  if [ -d "$CONFIG_DIR/cache" ]; then
    chown -R "$APP_USER:$APP_GROUP" "$CONFIG_DIR/cache" 2>/dev/null || true
  fi

  if command -v setpriv >/dev/null 2>&1; then
    exec setpriv --reuid="$APP_USER" --regid="$APP_GROUP" --init-groups -- "$@"
  fi
  exec runuser -u "$APP_USER" -- "$@"
fi

exec "$@"
