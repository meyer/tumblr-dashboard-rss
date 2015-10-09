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

routePrefixes =
  flickr: process.env.FLICKR_API_KEY
  tumblr: process.env.TUMBLR_CONSUMER_KEY

console.log '============'
console.log ''

for category, routeObj of routes
  for route, handler of routeObj
    remotePrefix = if routePrefixes[category] then "#{routePrefixes[category]}/" else ''
    # i am good at javascropt
    um = if process.env.DEV_MODE then '  ' else '> '
    uh = if process.env.DEV_MODE then '> ' else '  '

    console.log "  #{handler.underline.green}"
    console.log "  #{um}#{remoteURL}#{remotePrefix}#{route}"
    console.log "  #{uh}#{localURL}#{route}"
    console.log ''

    if process.env.DEV_MODE
      server.get "/#{route}", require("./routes/#{handler}")
    else
      server.get "/#{remotePrefix}#{route}", require("./routes/#{handler}")

console.log '============'

server.listen server.get('port')