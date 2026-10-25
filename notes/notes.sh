#!/usr/bin/env sh
# The release notes of a version on main: the commit titles since the release
# before, by type, each from a capital. Fails where the version is no release.
# Without its tag it reads HEAD, so it runs in the project before the tag too,
# as tags never move.
#
#   ../workflows/notes/notes.sh 2.1.0 && git tag 2.1.0 && git push origin 2.1.0
set -eu

version="$1"
fail() {
    echo "notes.sh: $*" >&2
    exit 1
}

printf '%s\n' "$version" | grep -Eqx '[0-9]+\.[0-9]+\.[0-9]+' || fail "${version} is no version like 2.1.0"

ref="$version"
git rev-parse -q --verify "refs/tags/${version}" >/dev/null || ref=HEAD

status=0
git merge-base --is-ancestor "$ref" origin/main || status=$?
case $status in
0) ;;
1) fail "${ref} is not on origin/main" ;;
*) exit "$status" ;;
esac

# Release tags, v2.0.0 included. The date tags of 1.9.0 have one dot.
pattern='[0-9]*.[0-9]*.[0-9]*'
range="$ref"
previous="the first commit"
if [ -n "$(git tag --list "$pattern" "v${pattern}" --merged "$ref" --no-contains "$ref")" ]; then
    previous="$(git describe --tags --abbrev=0 --match "$pattern" --match "v${pattern}" "${ref}^")"
    newest="$(printf '%s\n%s\n' "${previous#v}" "$version" | sort -V | tail -n 1)"
    if [ "$newest" != "$version" ] || [ "${previous#v}" = "$version" ]; then
        fail "${version} is not above ${previous}"
    fi
    range="${previous}..${ref}"
fi

titles="$(git log --format=%s "$range")"
tab="$(printf '\t')"
notes="$(printf '%s\n' "$titles" | awk -v OFS="$tab" '
    function capital(s) { return toupper(substr(s, 1, 1)) substr(s, 2) }
    $0 == "" { next }
    { sub(/ \(#[0-9]+\)$/, "") }
    !match($0, /^[a-z]+(\([^)]+\))?!?: /) { print 5, capital($0); next }
    {
        head = substr($0, 1, RLENGTH - 2)
        text = capital(substr($0, RLENGTH + 1))
        type = head
        sub(/[(!].*/, "", type)
        if (match(head, /\(.*\)/)) text = "**" substr(head, RSTART + 1, RLENGTH - 2) ":** " text
        if (head ~ /!$/) print 1, text
        else if (type == "feat") print 2, text
        else if (type == "fix") print 3, text
        else if (type == "perf") print 4, text
    }' | LC_ALL=C sort -t "$tab" -k1,1n -k2f | awk -F "$tab" '
    BEGIN {
        title[1] = "⚠ BREAKING CHANGES"
        title[2] = "Features"
        title[3] = "Bug Fixes"
        title[4] = "Performance Improvements"
        title[5] = "Other Changes"
    }
    $1 != section {
        if (section) print ""
        print "### " title[$1] "\n"
        section = $1
    }
    { print "* " $2 }')"

[ -n "$notes" ] || fail "nothing for users since ${previous}"
printf '%s\n' "$notes"
