#!/bin/sh
p() { printf %s\\n "$@"; }
< ~/doc/deb/tabs.tsv tr \\t \@ |
while IFS=\@ read -r date tourn _ url _; do (
	[ "${url#'https://'}" != "$url" ] || exit
	readonly yyyy=${date%%-*}
	readonly tourn=${yyyy}_$(p "$tourn" | tr A-Z' ' a-z_)
	mkdir -p "$tourn" && cd "$tourn" # TODO: warn if fail
	[ -f 'done' ] && exit
	~/dl/PROJ/Tp.autopt/in/tabbycat_dl.py "$url" 2>&1 | tee -a err.log
	touch 'done'
) done
