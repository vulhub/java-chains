#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
SCRIPT="$ROOT/.github/scripts/package-public-from-source.sh"

python3 - "$SCRIPT" <<'PY'
import sys

text = open(sys.argv[1], encoding="utf-8").read()


def require(needle: str) -> None:
    if needle not in text:
        raise SystemExit(f"package-public-from-source.sh must contain: {needle}")


def forbid(needle: str) -> None:
    if needle in text:
        raise SystemExit(f"package-public-from-source.sh must not contain: {needle}")


require("check-public-edition-surface.sh")
require("--source-only")
require("PublicInternalFeaturesGateTest")
require("install-local-deps.sh")
require("-Pfrontend")
require("TAG-BUILD.txt")
require("official-presets.yaml")
require("generate-release-notes.sh")
require("linux-x64-gnu")
require("edition=public")
require("profiles=frontend")
forbid("with-exploits")
forbid("with-rmi-workbench")
forbid("tag-build.tar.gz")
print("PASS: public-from-source packaging script contract")
PY
