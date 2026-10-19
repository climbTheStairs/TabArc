#!/bin/sh
# dep: python3
p() { printf %s\\n "$@"; }
mkdir -p dat && cd dat || exit 1
< ../tabs.tsv tr \\t \@ |
while IFS=\@ read -r tourn _host _deb_fmt url _; do (
	tourn=$(p "$tourn" | tr '[:upper:]' '[:lower:]' | tr ' ' _)
	mkdir -p "$tourn" && cd "$tourn" || exit 1 # TODO: warn if fail
	[ -f 'done' ] && exit
	python3 ../../tabbycat_dl.py "$url" 2>&1 | tee -a err.log
	touch 'done'
) done
