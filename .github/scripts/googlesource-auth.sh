#!/bin/bash
# Authenticate the googlesource fetches of the job, as anonymous fetches are
# rate limited per IP, or remove that authentication with --remove.
#
# GOOGLESOURCE_COOKIES holds the cookie line of the googlesource password
# page, with commas instead of tabs. The /a/ prefix makes googlesource
# authenticate the request.
set -eo pipefail

cookies="$RUNNER_TEMP/gitcookies"
hosts="android chromium"

if [ "$1" = --remove ]; then
	rm -f "$cookies"
	git config --global --unset http.cookiefile || true
	for host in $hosts; do
		git config --global --remove-section "url.https://$host.googlesource.com/a/" || true
	done
	exit 0
fi

[ -n "$GOOGLESOURCE_COOKIES" ] || { echo "GOOGLESOURCE_COOKIES is not set." >&2; exit 1; }
(umask 077; printf '%s\n' "$GOOGLESOURCE_COOKIES" | tr , '\t' > "$cookies")
git config --global http.cookiefile "$cookies"
for host in $hosts; do
	git config --global "url.https://$host.googlesource.com/a/.insteadOf" "https://$host.googlesource.com/"
done
