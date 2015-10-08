module.exports.ucfirst = (s) ->
	s = "#{s}"
	"#{s.charAt(0).toUpperCase()}#{s.substr(1)}"

module.exports.howmany = (n, s, p = false) ->
	"#{n} #{if n == 1 then s else (p || "#{s}s")}"

module.exports.img = (src, width, height, opts) ->
	opts ||= {}
	opts.src = src
	opts.width = width
	opts.height = height
	"<img #{Object.keys(opts).map((k) -> if opts[k] then "#{k}=\"#{opts[k]}\"" else '').join(' ')}>"

module.exports.getTimeDiffString = (t, p) ->
	t = Math.abs(t)
	pfx = if p then " #{p}" else ''

	if t <= 1000 then return ''

	if (t /= 1000) < 60 then return "#{Math.round(t * 10) / 10} seconds#{pfx}"
	if (t /= 60)   < 60 then return "#{Math.round(t * 10) / 10} minutes#{pfx}"
	if (t /= 60)   < 24 then return "#{Math.round(t * 10) / 10} hours#{pfx}"
	if (t /= 24)   <  7 then return "#{Math.round(t * 10) / 10} days#{pfx}"

	return "#{Math.round(t / 7 * 10) / 10} weeks#{pfx}"

# module.exports.flickr = require './flickr'