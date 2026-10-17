;(() => {
"use strict"

const $$tr = $$("tbody tr")
const $$filtC = $$("#filt input[type=checkbox]")
const  $filtT =  $("#filt input[type=text]")

const main = () => {
	for (const $x of $$("#filt input"))
		$x.oninput = filt
	for (const $x of $$(".team-name, .speaker-name, .judge-name"))
		$x.onclick = filtThisPrsn
}

const filtThisPrsn = function() {
	const [field] = [...this.classList].find(x => x.endsWith("-name")).split("-")
	const text = norm(this.dataset.value ?? this.textContent)
		.replace(/\\/g, "\\\\")
		.replace(/"/g,  `\\"`)
	$filtT.value = `${field[0]}="${text}"`
	filt()
}

const filt = () => {
	clearTextsearch()
	const querys = getQuerys()
	for (const $tr of $$tr)
		$tr.classList.toggle("matches-filt", matchesQuerys($tr, querys))
}

const clearTextsearch = () => {
	for (const $x of $$("mark.matches-filt"))
		$x.outerHTML = $x.innerHTML
}

const getQuerys = () => {
	const r = $$filtC.filter($x => $x.checked).map($x => $x.name)
	const {t = [], s = [], j = [], q = []} = unquote($filtT.value)
		.split(/ +/).filter(x => x)
		.flatMap(s => [s, s.replace(/_/g, " ")].uniq())
		.mapGrpBy(grpQuerys)
	return {r, t, s, j, q: textsearch2regex(q)}
}

const unquote = (s) =>
	s.replace(/"(\\.|[^\\"])*("|$)/g, (m) => m
		.replace(/^"|"$/g, "")
		.replace(/\\(.)/g, "$1")
		.replace(/ /g, "_"))

const VALID_PRSN_TYPE = ["team", "t", "speaker", "s", "judge", "j"]
const grpQuerys = (q) => {
	let [k, v] = q.split("=", 2)
	if (!q.includes("=") || !VALID_PRSN_TYPE.includes(k))
		[k, v] = ["query", q]
	return [k[0], norm(v)]
}

const norm = (s) => rmEmoji(s).trim()
const rmEmoji = (s) => s.replace(/\p{Emoji_Presentation}/gu, "")

const textsearch2regex = (q) => q.length
	? new RegExp(q.map(escRegex).join("|"),
		q.join() === q.join().toLowerCase() ? "gi" : "g")
	: null

const matchesQuerys = ($tr, {r, t, s, j, q}) => {
	const roundIsEmpty = r.length === 0
	const otherIsEmpty = t.concat(s, j).length === 0 && !q
	const matchesR = matchesQuery($tr, r, "round")
	const matchesT = matchesQuery($tr, t, "team")
	const matchesS = matchesQuery($tr, s, "speaker")
	const matchesJ = matchesQuery($tr, j, "judge")
	const matchesQ = matchesTextsearch($tr, q)
	const matchesOther = matchesT || matchesS || matchesJ || matchesQ
	return (roundIsEmpty || matchesR) && (otherIsEmpty || matchesOther)
}

const matchesQuery = ($tr, q = [], field) =>
	$$(`.${field}-name`, $tr).reduce((acc, $x) => (
		$x.classList.toggle("matches-filt", [
			$x.dataset.value,
			$x.textContent,
			$x.title,
		].some(x => x && q.includes(norm(x))))
	) || acc, false)

const SEL_WHERE = ":is(th, td):is(.round-name, .room-name, .team, .panel)"
const SEL_CHILDLESS = ":not(:has(*))"
const SEL_TEXTSEARCH = (
	SEL_WHERE + SEL_CHILDLESS + ", " +
	SEL_WHERE + " " + SEL_CHILDLESS)
const REPL = `<mark class="matches-filt">$&</mark>`
const matchesTextsearch = ($tr, q) =>
	!!q && $$(SEL_TEXTSEARCH, $tr)
		.filter(($x) => !$x.classList.contains(".matches-filt"))
		.reduce((acc, $x) => $x.innerHTML !== (
			$x.innerHTML = $x.innerHTML.replace(q, REPL)
		) || acc, false)

main()
})();
