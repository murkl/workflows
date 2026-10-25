# Recipes are bash and stop at the first failing command, in pipes too.
SHELL       := bash
.SHELLFLAGS := -eu -o pipefail -c

SCRIPTS := $(wildcard notes/*.sh settings/*.sh)

.PHONY: check lint test github

# The one command that has to pass before a commit.
check: lint test

lint:
	shellcheck -s sh -S style $(SCRIPTS)
	shfmt -d -ln posix -i 4 $(SCRIPTS)
	python3 -I -c 'import ast, sys; ast.parse(open(sys.argv[1]).read(), sys.argv[1])' banner/banner.py
	actionlint
	zizmor --offline --persona auditor .

test:
	notes/notes-test.sh

# The repository's settings on GitHub, out of .github/settings/. Run by hand as
# an admin: a workflow may not change the rules it is held to.
github:
	settings/settings.sh
