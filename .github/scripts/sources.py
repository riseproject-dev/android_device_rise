#!/usr/bin/env python3
"""Track the RISE sources a prebuilt directory was built from.

A prebuilt update commit lists the URL, branch and head commit of each
source, like the bootloader updates. The check compares those commits with
the current heads of the sources, the message subcommand writes that list
for a new update commit.

Sources are given either as "name@branch" (a riseproject-dev repository) or
as a repo manifest URL, of which only the riseproject-dev projects count.
"""

import argparse
import json
import os
import re
import subprocess
import urllib.request
import xml.etree.ElementTree as ET

RISE = "https://github.com/riseproject-dev/"


def sources(args):
    """Return (name, branch, checkout path) for every source."""
    result = [(s.split("@")[0], s.split("@")[1], None) for s in args.source]
    if args.manifest:
        root = ET.fromstring(urllib.request.urlopen(args.manifest).read())
        remotes = {r.get("name"): r.get("fetch") for r in root.iter("remote")}
        for project in root.iter("project"):
            if remotes.get(project.get("remote")) == RISE:
                result.append((project.get("name"), project.get("revision"),
                               project.get("path")))
    return result


def git(*cmd):
    return subprocess.run(["git", *cmd], check=True, capture_output=True,
                          text=True).stdout.strip()


def check(args):
    # Skip commits touching the directory without rebuilding it.
    url = (f"repos/{os.environ['GITHUB_REPOSITORY']}/commits"
           f"?sha={args.branch}&path={args.path}&per_page=30")
    commits = json.loads(subprocess.run(["gh", "api", url], check=True,
                                        capture_output=True, text=True).stdout)
    message = next((c["commit"]["message"] for c in commits
                    if args.marker in c["commit"]["message"]), "")
    built = set(re.findall(r"\b[0-9a-f]{7,40}\b", message))

    changed = False
    for name, branch, _ in sources(args):
        head = git("ls-remote", RISE + name, "refs/heads/" + branch).split()[0]
        state = "built" if any(head.startswith(s) for s in built) else "new"
        print(f"{name} {branch} {head} {state}")
        changed |= state == "new"

    build = changed or os.environ.get("FORCE") == "true"
    with open(os.environ["GITHUB_OUTPUT"], "a") as out:
        out.write(f"build={str(build).lower()}\n")


def message(args):
    for name, branch, path in sources(args):
        checkout = os.path.join(args.checkout, path) if path else args.checkout
        print(f"- Project: {path or name}:\nURL: {RISE}{name}\nBranch: {branch}\n"
              f"HEAD: {git('-C', checkout, 'log', '-1', '--format=%h %s')}\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["check", "message"])
    parser.add_argument("--source", action="append", default=[],
                        help="riseproject-dev repository as name@branch")
    parser.add_argument("--manifest", help="repo manifest URL")
    parser.add_argument("--branch", default="android-17",
                        help="branch holding the prebuilts")
    parser.add_argument("--path", help="prebuilt directory (check)")
    parser.add_argument("--marker", help="text identifying update commits (check)")
    parser.add_argument("--checkout", help="source checkout or repo workspace (message)")
    args = parser.parse_args()
    check(args) if args.command == "check" else message(args)


if __name__ == "__main__":
    main()
