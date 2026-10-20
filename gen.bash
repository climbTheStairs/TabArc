#!/bin/bash
# dep: bash, jq
readonly HT=$(printf \\t) RS=$(printf \\036)
p() { printf %s\\n "$@"; }
awk()  { command awk -F "$HT" -v OFS="$HT" "$@"; }
join() { command join -t"$HT" "$@"; }
sort() { command sort -t"$HT" "$@"; }
myjoin() { join -1"$2" -2"$4" $5 <(sort -k"$2" "$1") <(sort -k"$4" "$3"); }
fail() { >&2 p "${0##*/}: $1"; exit 1; }

main() (
	readonly tourn=$1 ftourn=$2
	cd "dat/$ftourn" || fail "cd dat/$ftourn failed"
	>&2 p "INFO: $tourn: gen"
	jq -cs add -- *_pairings.json > pairings.json &&
	jq -cs add -- *_ballots.json > ballots.json ||
		fail "ERR: $tourn: *_pairings.json or *_ballots.json not exist"
	for f in adjudicators.json rounds.json teams.json venues.json; do
		[ -f "$f" ] || fail "ERR: $tourn: file $f not exist"
	done
	cat << EOF
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width" />
	<title>$tourn: Results</title>
	<link rel="stylesheet" href="css/reset.css" />
	<link rel="stylesheet" href="css/main.css" />
</head>
<body>
<form id="filt">
	<fieldset>
		<legend>Rounds</legend>
EOF
	jq -r '.[] | [.seq, .name, .abbreviation] | join("\t")' rounds.json |
	while IFS=$HT read -r rid rname rabbr; do
		cat << EOF
		<input type="checkbox" id="filt-round-$rid" name="$rid" />
		<label for="filt-round-$rid" title="$rname">$rabbr</label>
EOF
	done
	cat << 'EOF'
	</fieldset>
	<fieldset>
		<legend>Text search</legend>
		<div id="textsearch-container">
			<input type="text" id="textsearch" />
		</div>
	</fieldset>
</form>
<hr />
<div id="table-scrollbox">
	<table>
		<colgroup>
			<col class="round-name"		style="width: 64px;" />
			<col class="room-name"		style="width: 100px;" />
			<col class="room-points"	style="width: 64px;" />
		</colgroup>
		<thead>
			<tr>
				<th rowspan="2">Round</th>
				<th colspan="2">Room</th>
				<th colspan="4">Teams</th>
				<th rowspan="2">Adjudicators</th>
			</tr>
			<tr>
				<th>Name</th>
				<th>Points</th>
				<th>OG</th>
				<th>OO</th>
				<th>CG</th>
				<th>CO</th>
			</tr>
		</thead>
		<tbody>
EOF
	cat <(
		jq_run pairing			venues.json pairings.json
	) |
	myjoin - 1 <(
		jq_run pairing_speaker	teams.json ballots.json &&
		jq_run pairing_judge	pairings.json
	) 1 |
	myjoin - 4 <(
		jq_run speaker			teams.json &&
		jq_run judge			adjudicators.json
	) 1 |
	myjoin - 3 <(
		jq_run round			rounds.json
	) 1 |
	awk '{sub(/^c/, "p", $5); sub(/^j/, "q", $5)} 1' | # make .role sortable
	sort -k3,3n -k5,5 | # sort by pairing, role
	cut -f1,4- | # rm ids
	awk -vORS="$RS" 'END {printf ".\n"}
NR != 1 && ($1 SUBSEP $2) != (rid SUBSEP venue) {printf ".\n"}
{
	rid=$1; rname=$8; rabbr=$9; venue=$2; role=$3

	# Print judge
	if (sub(/^q/, "", role) == 1) {
		print role, $5
		next
	}

	# Save speaker
	spts[role]=$4+0 # rm decimal iff .0
	names[role]=$5
	teams_l[role]=$6
	teams_s[role]=$7

	# Print all speakers in room
	if (role != "po2")
		next
	og=teams_l["og1"]; oo=teams_l["oo1"]; cg=teams_l["pg1"]; co=teams_l["po1"]
	avg=(tot_tpt[og]+tot_tpt[oo]+tot_tpt[cg]+tot_tpt[co])/4
	# An extra empty field is printed here
	# to help sorting since everything will be joined into a single line.
	print rid, rname, rabbr, venue, avg, ""
	og_spt=spts["og1"]+spts["og2"]
	oo_spt=spts["oo1"]+spts["oo2"]
	cg_spt=spts["pg1"]+spts["pg2"]
	co_spt=spts["po1"]+spts["po2"]
	og_tpt=(og_spt>oo_spt)+(og_spt>cg_spt)+(og_spt>co_spt)
	oo_tpt=(oo_spt>og_spt)+(oo_spt>cg_spt)+(oo_spt>co_spt)
	cg_tpt=(cg_spt>og_spt)+(cg_spt>oo_spt)+(cg_spt>co_spt)
	co_tpt=(co_spt>og_spt)+(co_spt>oo_spt)+(co_spt>cg_spt)
	tot_tpt[og]+=og_tpt
	tot_tpt[oo]+=oo_tpt
	tot_tpt[cg]+=cg_tpt
	tot_tpt[co]+=co_tpt
	print og, teams_s["og1"], og_tpt, tot_tpt[og], names["og1"], spts["og1"], names["og2"], spts["og2"]
	print oo, teams_s["oo1"], oo_tpt, tot_tpt[oo], names["oo1"], spts["oo1"], names["oo2"], spts["oo2"]
	print cg, teams_s["pg1"], cg_tpt, tot_tpt[cg], names["pg1"], spts["pg1"], names["pg2"], spts["pg2"]
	print co, teams_s["po1"], co_tpt, tot_tpt[co], names["po1"], spts["po1"], names["po2"], spts["po2"]
	# nec to empty in case of missing fields (e.g. team w 1 speaker in outround)
	split("", spts); split("", names); split("", teams_s); split("", teams_l)
}' |
	awk '$1 != "chair"' | # TODO
	sort -k1,1n -k5,5rn -k 4,4n | # sort by round, avg, venue
	tr \\036 \\n |
	esc_html |
	while IFS=$HT read -r rid rname rabbr venue avg _; do
		cat << EOF
			<tr class="matches-filt">
				<th class="round-name" data-value="$rid" title="$rname">$rabbr</th>
				<td class="room-name">$venue</td>
				<td class="room-points">$avg</td>
EOF
		is_inround=
		[ "${rname#'Round '}" != "$rname" ] && is_inround=1 # TODO: better way to do this
		i=0; while
			i=$((i+1))
			[ "$i" -le 4 ] &&
			IFS=$HT read -r tname tabbr tpt tot_tpt s1 s1s s2 s2s
		do cat << EOF
				<td class="team">
					<p data-points-gained="$tpt">${is_inround:+"<span class=\"points\">(=$tot_tpt)</span> "}<span class="team-name" data-value="$tname" title="$tname">$tabbr</span></p>
					<p>${is_inround:+"<span class=\"speaks\" data-value=\"$s1s\" style=\"--spk: $s1s;\" title=\"$s1s\">$s1s</span> "}<span class="speaker-name" title="$s1">$s1</span></p>
					<p>${is_inround:+"<span class=\"speaks\" data-value=\"$s2s\" style=\"--spk: $s2s;\" title=\"$s2s\">$s2s</span> "}<span class="speaker-name" title="$s2">$s2</span></p>
				</td>
EOF
		done
		cat << EOF
				<td class="panel"><p>
EOF
		while
			IFS=$HT read -r role name &&
			[ "$role" != . ]
		do cat << EOF
					<span class="judge-name $role" title="$name">$name</span>,
EOF
		done | sed '$s/,$//'
		cat << EOF
				</p></td>
			</tr>
EOF
	done
	cat << 'EOF'
		</tbody>
	</table>
</div>
<script src="js/stairz_.js"></script>
<script src="js/filt.js"></script>
</body>
</html>
EOF
)

jq_run() {
	fn=$1; shift
	jq -csL ../.. "include \"jq\"; $fn" "$@" | ../../lib/json2tsv -s | tail -n+2
}

esc_html() {
	sed 's/[&]/\&amp;/g; s/[<]/\&lt/g; s/["]/\&quot;/g;'
}

for tourn do
	ftourn=$(p "$tourn" | tr '[:upper:]' '[:lower:]' | tr ' ' _)
	dest="srv/$ftourn.html"
	main "$tourn" "$ftourn" > "$dest" || rm "$dest"
done
