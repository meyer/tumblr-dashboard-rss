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

# look at me, parsing HTML with regular expressions
module.exports.wrapHTMLMaybe = (text, tag) ->
  text = "#{text}".trim()

  # Text starts/ends with HTML tags
  rStart = /^\<(\w+)\>/
  rEnd = /\<\/(\w+)\>$/

  # End tags exist in text
  rTag = /\<\/(?:p|a|em|strong|blockquote|h1|h2|h3|h4|h5|h6)\>/

  openingTag = text.match(rStart)
  closingTag = text.match(rEnd)

  console.log 'Text:', text
  console.log '- tag:', tag
  console.log '- openingTag:', openingTag && openingTag[1] || '(none)'
  console.log '- closingTag:', closingTag && closingTag[1] || '(none)'

  # if rTag.test(text)
  if openingTag && openingTag[1] == tag
    return text
  else
    return "<#{tag}>\n\n#{text}\n\n</#{tag}>"

# module.exports.flickr = require './flickr'
