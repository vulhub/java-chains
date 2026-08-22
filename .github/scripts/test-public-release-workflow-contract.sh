#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
RELEASE_WORKFLOW="$ROOT/.github/workflows/build-and-release.yml"
RELEASE_MANIFEST="$ROOT/.github/release-manifest.yml"
VERIFY_SOURCE="$ROOT/.github/scripts/verify-source-tag.sh"

python3 - "$RELEASE_WORKFLOW" "$RELEASE_MANIFEST" "$VERIFY_SOURCE" <<'PY'
import re
import sys

workflow = open(sys.argv[1], encoding="utf-8").read()
manifest = open(sys.argv[2], encoding="utf-8").read()
verify_source = open(sys.argv[3], encoding="utf-8").read()


def job(text: str, name: str) -> str:
    match = re.search(
        rf"(?ms)^  {re.escape(name)}:\s*\n(.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\Z)",
        text,
    )
    if not match:
        raise SystemExit(f"missing job: {name}")
    return match.group(1)


resolve = job(workflow, "resolve_release_meta")
build = job(workflow, "build")
create = job(workflow, "create_release")
bundle = job(workflow, "bundle_assets")
standard = job(workflow, "upload_standard_assets")
docker_build = job(workflow, "docker_build")
docker_merge = job(workflow, "docker_merge")

for forbidden in ("actions/upload-artifact", "actions/download-artifact"):
    if forbidden in workflow:
        raise SystemExit(f"public release must not use Actions artifacts: found {forbidden}")

if "public version must not contain internal" not in resolve:
    raise SystemExit("resolve job must reject internal versions before packaging")
if "test-public-release-workflow-contract.sh" not in resolve:
    raise SystemExit("resolve job must run the public release workflow contract test")
if "test-verify-source-tag.sh" not in resolve:
    raise SystemExit("resolve job must run the source-tag verifier tests")
if "test-verify-tag-build-artifact.sh" not in resolve:
    raise SystemExit("resolve job must run the tagged-build verifier tests")
if "test-fetch-release-tarball.sh" not in resolve:
    raise SystemExit("resolve job must run the release-tarball fetch tests")

if "CHAINS_WORKFLOW_ARTIFACTS" in verify_source or "/artifacts" in verify_source:
    raise SystemExit("source-tag verifier must not inspect Actions artifacts")
if 'ASSET_NAME="tag-build.tar.gz"' not in verify_source:
    raise SystemExit("source-tag verifier must require the source GitHub Release tarball")
if "releases/tags/" not in verify_source:
    raise SystemExit("source-tag verifier must read the source GitHub Release")

if ".github/scripts/fetch-release-tarball.sh tag-build.tar.gz tagged-build" not in build:
    raise SystemExit("build job must fetch tag-build.tar.gz from the source GitHub Release")
if "CHAINS_RELEASE_REPO: Java-Chains/chains" not in build:
    raise SystemExit("build job must fetch tagged bits from Java-Chains/chains")
if "EXPECTED_EDITION: public" not in build:
    raise SystemExit("build job must require the public tagged edition")
if "EXPECTED_PROFILES: frontend" not in build:
    raise SystemExit("build job must require public Maven profiles=frontend")
if "verify-tag-build-artifact.sh" not in build:
    raise SystemExit("build job must verify tagged artifact metadata and checksums")
if "verify-public-ship-surface.sh" not in build:
    raise SystemExit("build job must verify the public server jar surface")
if "tagged-build/lib" not in build:
    raise SystemExit("build job must reject an internal RMG sidecar layout")
if "public-base.tar.gz" not in build:
    raise SystemExit("build job must push public-base.tar.gz to the product GitHub Release")

for forbidden in (
    "actions/setup-java",
    "stCarolas/setup-maven",
    "actions/setup-node",
    "pnpm/action-setup",
    "install-local-deps.sh",
    "mvn ",
    "java-chains-exploits",
    "java-chains-rmi-rmg",
    "package-java-chains-web-element.sh",
    "frontend.working.directory",
    "with-exploits",
    "with-rmi-workbench",
):
    if forbidden in build:
        raise SystemExit(f"public release must not rebuild or include internal bits: found {forbidden}")

if "java-chains-web-element" in build:
    raise SystemExit("build job must not check out or rebuild java-chains-web-element")

if ".github/scripts/fetch-release-tarball.sh public-base.tar.gz base" not in create:
    raise SystemExit("release creation must fetch public-base from the product GitHub Release")
if "base/RELEASE-NOTES.md" not in create:
    raise SystemExit("release creation must publish the verified generated notes")
if "React" not in create or "/element/" not in create:
    raise SystemExit("release notes must describe both public SPAs")
if "already exists, skip creation" in create:
    raise SystemExit("existing product releases must be updated instead of skipped")

if ".github/scripts/fetch-release-tarball.sh public-base.tar.gz base" not in bundle:
    raise SystemExit("platform bundles must fetch public-base from the product GitHub Release")
if ".github/scripts/fetch-release-tarball.sh public-base.tar.gz base" not in standard:
    raise SystemExit("standard asset upload must fetch public-base from the product GitHub Release")
if "java-chains-cli-remote" in standard:
    raise SystemExit("public CLI archive must not advertise the internal remote CLI jar")

if ".github/scripts/fetch-release-tarball.sh public-base.tar.gz base" not in docker_build:
    raise SystemExit("docker build must fetch public-base from the product GitHub Release")
if "docker-digest-" not in docker_build:
    raise SystemExit("docker build must publish digest files to the product GitHub Release")
if "docker-digest-" not in docker_merge:
    raise SystemExit("docker merge must read digest files from the product GitHub Release")

if "Java-Chains/chains" not in manifest:
    raise SystemExit("release manifest must keep pointing at the source repository")
if "tag-build.tar.gz" not in manifest:
    raise SystemExit("release manifest must document that packaging consumes tag-build.tar.gz")
if not re.search(r"(?m)^\s+ref:\s+[0-9a-f]{40}\s*$", manifest):
    raise SystemExit("chains-config manifest must pin an immutable commit")

print("PASS: public release consumes the verified public tag-build tarball without rebuilding")
PY
