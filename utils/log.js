module.exports = function debugLog() {
  if (process.env.NODE_ENV === 'development') {
    return console.log(Array.prototype.slice.call(arguments))
  }
}
