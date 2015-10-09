express = require 'express'
server = express()
colors = require 'colors'

require('dotenv').load()

routes =
  flickr:
    "flickr-photostream.rss":      'flickr-photostream'
    "flickr-user/:nsid/feed.rss":  'flickr-user-photostream'
  tumblr:
    "tumblr-dashboard.rss":  'tumblr-dashboard'
    "tumblr-likes.rss":      'tumblr-liked-images'

server.set 'port', (process.env.PORT || 6969)

server.use '/', (request, response, next) ->
  console.log "#{new Date} - #{request.method.green} #{request.originalUrl}"
  next()

remoteURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/"
localURL = "http://localhost:#{server.get("port")}/"

isLocal = /\.local$/.test(require('os').hostname())

routePrefixes =
  flickr: process.env.FLICKR_API_KEY
  tumblr: process.env.TUMBLR_CONSUMER_KEY

console.log '============'
console.log ''

for category, routeObj of routes
  for route, handler of routeObj
    remotePrefix = if routePrefixes[category] then "#{routePrefixes[category]}/" else ''

    console.log "  #{handler.underline.green}"
    console.log "  #{isLocal && ' ' || '>'} #{remoteURL}#{remotePrefix}#{route}"
    console.log "  #{isLocal && '>' || ' '} #{localURL}#{route}"
    console.log ''

    if isLocal
      server.get "/#{route}", require("./routes/#{handler}")
    else
      server.get "/#{remotePrefix}#{route}", require("./routes/#{handler}")

console.log '============'

server.listen server.get('port')