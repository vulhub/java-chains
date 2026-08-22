#!/usr/bin/env bash
# Verify that a packaged public server jar cannot expose internal-only modules.
set -euo pipefail

die() {
  echo "ERROR: public-ship-surface: $*" >&2
  exit 1
}

SERVER_JAR="${1:-}"
[ -n "$SERVER_JAR" ] || die "server jar path is required"
[ -f "$SERVER_JAR" ] || die "server jar does not exist: $SERVER_JAR"
command -v unzip >/dev/null 2>&1 || die "unzip is required"
command -v ruby >/dev/null 2>&1 || die "ruby is required"

CONTENTS_FILE="$(mktemp "${TMPDIR:-/tmp}/public-jar-contents.XXXXXX")"
APPLICATION_YML="$(mktemp "${TMPDIR:-/tmp}/public-application.XXXXXX")"
trap 'rm -f "$CONTENTS_FILE" "$APPLICATION_YML"' EXIT INT TERM

unzip -Z1 "$SERVER_JAR" > "$CONTENTS_FILE" \
  || die "cannot list server jar: $SERVER_JAR"

for internal_jar in java-chains-exploits- java-chains-rmi-rmg-; do
  if grep -F "BOOT-INF/lib/${internal_jar}" "$CONTENTS_FILE" >/dev/null; then
    die "public release embeds internal module: ${internal_jar}"
  fi
done

for internal_class in \
  "BOOT-INF/classes/org/vulhub/javachains/web/adapter/canonical/controller/CanonicalRmiController.class" \
  "BOOT-INF/classes/org/vulhub/javachains/web/adapter/canonical/controller/CanonicalExploitsController.class" \
  "BOOT-INF/classes/org/vulhub/javachains/internal/tools/CanonicalInternalToolsController.class"
do
  if grep -Fx "$internal_class" "$CONTENTS_FILE" >/dev/null; then
    die "public release contains internal class: ${internal_class}"
  fi
done

unzip -p "$SERVER_JAR" BOOT-INF/classes/application.yml > "$APPLICATION_YML" \
  || die "packaged application.yml is missing"

# Internal capabilities are decided by optional marker classes. Public jars must
# not contain those modules (checked above). The old configuration keys may be
# absent; if a legacy package still declares them, it must not enable them.
ruby - "$APPLICATION_YML" <<'RUBY'
require 'yaml'

path = ARGV.fetch(0)
config = YAML.safe_load(File.read(path), aliases: false) || {}

checks = {
  'chains.exploits.enabled' => %w[chains exploits enabled],
  'chains.rmi.workbench.enabled' => %w[chains rmi workbench enabled]
}

checks.each do |label, keys|
  value = keys.reduce(config) do |current, key|
    current.is_a?(Hash) ? current[key] : nil
  end
  next if value.nil? || value == false

  abort("#{label} must be absent or false in public release jar")
end
RUBY

echo "public-ship-surface: verified $SERVER_JAR"
