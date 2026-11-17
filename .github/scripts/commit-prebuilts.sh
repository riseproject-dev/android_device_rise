#!/bin/bash
# Commit the prebuilts staged by the builder jobs and push them as the
# riseproject-dev App. Each directory of <prebuilts> holds:
#   path            the path of the prebuilts in this repository
#   prebuilts.tar   its new content, relative to the repository root
#   message         the commit message
#
# usage: commit-prebuilts.sh <prebuilts> <allowed path>...
# Runs in the device/rise checkout, with GH_TOKEN, APP_SLUG and BRANCH set.
set -eo pipefail

prebuilts=$(realpath "$1")
shift

# The account id in the address ties the commits to the App bot.
bot_id=$(gh api "users/$APP_SLUG%5Bbot%5D" --jq .id)
git config user.name "${APP_SLUG}[bot]"
git config user.email "$bot_id+${APP_SLUG}[bot]@users.noreply.github.com"
# Store the new LFS files as pointers and upload them on push.
git lfs install --local

for dir in "$prebuilts"/*/; do
	path=$(cat "$dir/path")
	# The builder runs code from every synced project: only let it update
	# the paths its workflow builds. Compare whole strings, as the path it
	# hands over may span several lines.
	allowed=false
	for p in "$@"; do
		[ "$path" = "$p" ] && allowed=true
	done
	if [ "$allowed" != true ]; then
		echo "Refusing prebuilts for unexpected path '$path'." >&2
		exit 1
	fi
	rm -rf "$path"
	tar -xf "$dir/prebuilts.tar" -- "$path"
	git add -A -- "$path"
	if git diff --cached --quiet; then
		echo "$path unchanged, nothing to commit."
		continue
	fi
	git commit -s -q -F "$dir/message"
done

if [ "$(git rev-list --count "origin/$BRANCH..HEAD")" -eq 0 ]; then
	exit 0
fi
git remote set-url origin "https://x-access-token:$GH_TOKEN@github.com/$GITHUB_REPOSITORY"
git pull -q --rebase origin "$BRANCH"
git push origin "HEAD:$BRANCH"
