gh-pages : TMPDIR := $(shell mktemp -d -t dns_erlang.gh-pages.xxxx)
gh-pages : BRANCH := $(shell git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1 /')
gh-pages : STASH := $(shell (test -z "`git status --porcelain`" && echo false) || echo true)
gh-pages : VERSION := $(shell sed -n 's/.*{vsn,.*"\(.*\)"}.*/\1/p' src/dns.app.src)

.PHONY: all doc clean test

all:
	@./rebar compile

doc:	
	@./rebar doc skip_deps=true

clean:
	@./rebar clean
	@rm -fr doc/*

gh-pages: test doc
	@echo "Building gh-pages for ${VERSION} in ${TMPDIR} from branch ${BRANCH}. Branch dirty: ${STASH}."
	sed 's/{{VERSION}}/${VERSION}/g' priv/index.html > ${TMPDIR}/index.html
	cp -r doc ${TMPDIR}/doc
	cp -r .eunit ${TMPDIR}/coverage
	(${STASH} && git stash save) || true
	git checkout gh-pages
	rsync -a --delete ${TMPDIR}/* .
	git add .
	git commit -a -m "update auto-generated docs"
	git checkout ${BRANCH}
	(${STASH} && git stash pop) || true
	rm -fr ${TMPDIR}

test:
	@./rebar eunit