module.exports = ->
  if process.env.DEV_MODE
    console.log Array.prototype.slice.call(arguments)
  else
    # do something?