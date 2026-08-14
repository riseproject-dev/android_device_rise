"""repo post-sync hook: materialise the Git LFS payloads.

repo knows nothing about Git LFS.  On a fresh checkout the tracked files
are left as their pointer text -- a few dozen bytes naming an object --
and whatever reads them fails on a file that is not what it claims to be.
The WebView APK is the visible case: signapk reports "zip END header not
found" while looking at 134 bytes of ASCII.

Fetching them here keeps a plain `repo sync` sufficient, with no extra
step to remember and nothing to configure per machine.
"""

import os
import shutil
import subprocess


# Projects whose .gitattributes routes files through LFS, as manifest paths.
LFS_PROJECTS = ("device/spacemit/common",)


def _pull(worktree):
    """Fetch the LFS objects of one worktree, returning an error or None."""
    # --local keeps the filter config inside this worktree: the hook stays
    # self-contained instead of writing to the user's ~/.gitconfig.
    for args in (("lfs", "install", "--local"), ("lfs", "pull")):
        result = subprocess.run(
            ("git", "-C", worktree) + args,
            capture_output=True,
            text=True,
        )
        if result.returncode:
            return (result.stderr or result.stdout).strip()
    return None


def main(repo_topdir=None, **kwargs):
    topdir = repo_topdir or os.getcwd()

    worktrees = [
        os.path.join(topdir, path)
        for path in LFS_PROJECTS
        if os.path.exists(os.path.join(topdir, path, ".git"))
    ]
    if not worktrees:
        return

    if not shutil.which("git-lfs"):
        print(
            "post-sync: git-lfs is not installed, leaving %d project(s) on "
            "their LFS pointers. Install it and re-run `repo sync`, or the "
            "WebView APK will not sign." % len(worktrees)
        )
        return

    for worktree in worktrees:
        error = _pull(worktree)
        if error:
            print("post-sync: git lfs pull failed in %s: %s" % (worktree, error))
