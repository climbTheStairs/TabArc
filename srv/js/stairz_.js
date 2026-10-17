const runIfFn = (x, ...args) => typeof(x) === "function" ? x(args) : x
const $$ = (sel, $par=document) => [...$par.querySelectorAll(sel)]
const $  = (sel, $par=document, failIfMult=false) => {
	const [$x, ...rest] = $$(sel, $par)
	if (rest.length && runIfFn(failIfMult, sel, $par))
		return null
	return $x ?? null
}

const escRegex = (s) => s.replace(/[\]\[\\^$*+?.()|{}]/g, "\\$&")

const transpose = (a, enforceRectangular = true) => {
	if (a.length === 0 || a[0].length === 0)
		return []
	let i
	if (enforceRectangular && (
		i = a.findIndex(r => r.length !== a[0].length)
	) !== -1)
		throw new RangeError(`row ${i} has unequal length: ${a[i].length}`)
	return a[0].map((_, colIdx) => a.map(row => row[colIdx]))
}
const mapGrpBy = (arr, callback, thisArg) => {
	const [k, v] = transpose(arr.map(callback, thisArg))
	return Object.groupBy(v ?? [], (_, i) => k[i])
}
const mapEntries = (obj, callback, thisArg) =>
	Object.fromEntries(Object.entries(obj).map(callback, thisArg))

Array.prototype.uniq = function() {
	return [...new Set(this)]
}
Array.prototype.grpBy = function(callback) {
	return Object.groupBy(this, callback)
}
Array.prototype.transpose = function(warn) {
	return transpose(this, warn)
}
Array.prototype.mapGrpBy = function(callback, thisArg) {
	return mapGrpBy(this, callback, thisArg)
}
Object.prototype.mapEntries = function(callback, thisArg) {
	return mapEntries(this, callback, thisArg)
}
