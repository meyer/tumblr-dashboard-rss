module.exports.ucfirst = (s) ->
	s = "#{s}"
	"#{s.charAt(0).toUpperCase()}#{s.substr(1)}"

module.exports.howmany = (n, s, p = false) ->
	"#{n} #{if n == 1 then s else (p || "#{s}s")}"

module.exports.img = (src, w, h) ->
	if w then w = " width='#{w}'"
	if h then h = " height='#{h}'"
	"""
	<img src="#{src}"#{w || ""}#{h || ""}>
	"""
