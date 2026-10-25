#!/usr/bin/env sh
# notes.sh in a throwaway repository, without the user's git config.
set -eu

notes="$(cd "$(dirname "$0")" && pwd)/notes.sh"
repo="$(mktemp -d)"
trap 'rm -rf "$repo"' EXIT
cd "$repo"
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1

git init -q -b main
commit() {
    git -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m "$1"
    git update-ref refs/remotes/origin/main HEAD
}
expect() {
    if [ "$1" != "$2" ]; then
        printf 'notes-test.sh: expected\n%s\nbut got\n%s\n' "$2" "$1" >&2
        exit 1
    fi
}
refuses() {
    if sh "$notes" "$1" >/dev/null 2>&1; then
        echo "notes-test.sh: $1 passed, $2" >&2
        exit 1
    fi
}

commit 'feat: the first (#1)'
expect "$(sh "$notes" 1.0.0)" '### Features

* the first'
git tag 1.0.0

commit 'fix: a crash (#2)'
commit 'feat(shell): word keys'
commit 'docs: a readme'
commit 'feat!: a new format'
commit 'an untyped change'
expect "$(sh "$notes" 1.1.0)" '### ⚠ BREAKING CHANGES

* a new format

### Features

* **shell:** word keys

### Bug Fixes

* a crash

### Other Changes

* an untyped change'

refuses v1.1.0 'though it is no version'
refuses 0.9.0 'though it is below 1.0.0'

git tag 1.1.0
commit 'docs: more'
refuses 1.2.0 'though nothing changed for users'

git switch -q -c side
git -c user.name=test -c user.email=test@example.com commit -q --allow-empty -m 'fix: off main'
refuses 1.2.0 'though HEAD is not on main'
