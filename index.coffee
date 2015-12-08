express = require 'express'
server = express()
colors = require 'colors'
log = require './utils/log'

require('dotenv').load()

routes =
  flickr:
    'flickr-photostream.rss':      'flickr-photostream'
    'flickr-user/:nsid/feed.rss':  'flickr-user-photostream'
  tumblr:
    'tumblr-dashboard.rss':         'tumblr-dashboard'
    'tumblr-likes.rss':             'tumblr-likes'
    'tumblr-user/:userid/feed.rss': 'tumblr-user'

routePrefixes =
  flickr: process.env.FLICKR_API_KEY
  tumblr: process.env.TUMBLR_CONSUMER_KEY

server.set 'port', (process.env.PORT || 6969)

server.use '/', (request, response, next) ->
  console.log "#{new Date} - #{request.method.green} #{request.originalUrl}"
  next()

remoteURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/"
localURL = "http://localhost:#{server.get("port")}/"

console.log '============'
console.log ''

for category, routeObj of routes
  for route, handler of routeObj
    unless routePrefixes[category]
      throw "Route prefix not set for category `#{category}`"

    console.log '  ' + handler.underline.green
    console.log '    ' + remoteURL + routePrefixes[category] + '/' + route
    console.log '    ' + localURL + route
    console.log ''

    if process.env.DEV_MODE
      server.get "/#{route}", require("./routes/#{handler}")
    else
      server.get "/#{routePrefixes[category]}/#{route}", require("./routes/#{handler}")

console.log '============'

server.listen server.get('port')
