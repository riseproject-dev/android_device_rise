#!/bin/bash
# Install the tools a job needs on the AOSP builder: the given Ubuntu
# packages, and repo, which comes from Google rather than from Ubuntu.
# repo checks the signature of its own source with gpg.
#
# usage: install-builder-tools.sh <package>...
set -eo pipefail

sudo apt-get update -q
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends gnupg "$@"

bin="${RISE_WORKSPACE:-$HOME/rise}/bin"
mkdir -p "$bin"
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$bin/repo"
chmod +x "$bin/repo"
echo "$bin" >> "$GITHUB_PATH"
