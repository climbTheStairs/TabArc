#!/bin/sh
readonly HT=$(printf \\t) RS=$(printf \\036)
p() { printf %s\\n "$@"; }
cat << EOF
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width" />
	<title>Motions - TabArc</title>
	<style>tbody tr:nth-child(odd) {
	background: #eee;
}</style>
</head>
<body>
<table>
	<thead>
		<tr>
			<th>Tournament + Round</th>
			<th>Motion</th>
		</tr>
	</thead>
	<tbody>
EOF
for f in */motions.json; do
	d=${f%/*}
	jq -cs --arg tourn "$d" \
		'(.[0] | obj(.seq; .name)) as $rr | .[1] | unique[] |
		[$tourn, ([$rr[.rounds[].round | split("/")[-1]]] | join(", ")), .info_slide_plain, .text]' \
		"$d/rounds.json" "$f"
done | json2tsv -s | tail -n+2 | sort |
tr \\t \\036 |
while IFS=$RS read -r tourn round infoslide mot; do
	infoslide=${infoslide:+"<details><summary>Infoslide:</summary><p>$infoslide</p></details>"}
	mot=$(p "$mot" | sed -E \
		-e 's/(^| )[Tt]his [Hh]ouse/\1TH/' \
		-e 's/(^| )TH( [Bb]elieves|B) [Tt]hat/\1THBT/' \
		-e 's/(^| )TH(, as .+, )? ?[Ww]ould/\1TH\2W/' \
		-e 's/(^| )TH(, as .+, )? ?[Ss]upports/\1TH\2S/' \
		-e 's/(^| )TH(, as .+, )? ?[Oo]pposes/\1TH\2O/' \
		-e 's/(^| )TH(, as .+, )? ?[Rr]egrets/\1TH\2R/' \
		-e 's/(^| )TH(, as .+, )? ?[Pp]refers/\1TH\2P/' \
		-e 's/(^| )TH(, as .+, )? ?[Hh]opes/\1TH\2H/' \
		-e 's/([^.?!])$/\1./')
	cat << EOF
		<tr>
			<th>$tourn $round</th>
			<td>$infoslide<p>$mot</p></td>
		</tr>
EOF
done
cat << EOF
	</tbody>
</table>
</body>
</html>
EOF
