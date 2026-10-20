#!/bin/sh
readonly HT=$(printf \\t) RS=$(printf \\036)
p() { printf %s\\n "$@"; }
cat << EOF
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8" />
	<meta name="viewport" content="width=device-width" />
	<title>Index - TabArc</title>
</head>
<body>
<ul>
EOF
< tabs.tsv tr \\t \\036 |
while IFS=$RS read -r tourn _; do
	fname=$(p "$tourn" | tr '[:upper:]' '[:lower:]' | tr ' ' _).html
	cat << EOF
	<li><a href="$fname">$tourn</a></li>
EOF
done
cat << EOF
</ol>
</body>
</html>
EOF
