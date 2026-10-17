include "";

def ssin(e; n): e | split("/")[n] | tonumber;

def speaker: # teams.json
	.[0][] |
	(.long_name  // .code_name) as $t |
	(.short_name // .code_name) as $tabbr |
	.speakers[] |
	{s: .id, name, $t, $tabbr};

def judge: # adjudicators.json
	.[0][] |
	{s: .id, name, t: .independent, tabbr: .adj_core}; # TODO

def pairing: # venues.json pairings.json
	(.[0] | obj(.url; .display_name)) as $vv |
	.[1][] | $vv[.venue] as $v | ssin(.url; -3) as $r |
	{p: .id, $r, $v};

def pairing_judge: # pairings.json
	.[0][] | .id as $p |
	.adjudicators |
	.chairs=[.chair] | .panelists=.panellists | del(.chair, .panellists) |
	to_entries[] | "j" + .key[:-1] as $role | .value[] |
	{$p, s: ssin(.; -1), $role, score: ""};

#def speech_from_ballots:
def pairing_speaker: # teams.json ballots.json
	(.[0] | obj(.id; .speakers | map({speaker: .url}))) as $tt |
	.[1][] | ssin(.url; -3) as $p |
	.result.sheets[0].teams[] | .side as $side |
	if .speeches then .speeches else
		(.win | bool2int) as $score |
		$tt["\(ssin(.team; -1))"] |
		map(.score=$score)
	end |
	addidxprop[] |
	ssin(.speaker; -1) as $s |
	$side + (.i+1 | tostring) as $role |
	{$p, $s, $role, score};

def _speech_from_ssr_pairings:
	grpby_toobj(ssin(.url; -3)) |
	map_values(map(
		.id as $p |
		.teams | sel(.) |
		obj(ssin(.team; -1); {$p, side})
	) | add);

def _speech_from_ssr_teams:
	map(.id as $t | .speakers | obj(.id; $t)) | add;

def speech_from_ssr: # pairings.json teams.json speakers_standings_rounds.json
	(.[0] | _speech_from_ssr_pairings) as $pp |
	(.[1] | _speech_from_ssr_teams) as $tt |
	.[2][] | ssin(.speaker; -1) as $s |
	.rounds[] |
		ssin(.round; -1) as $r |
		$tt["\($s)"] as $t |
		$pp["\($r)"]["\($t)"] as {$p, $side} |
	.speeches[] | .position as $pos |
	$side + (.position | tostring) as $role |
	{$p, $s, $role, score};

def round: # rounds.json
	.[0][] | {r: .seq, name, abbreviation};

