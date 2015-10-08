express = require 'express'
server = express()
router = express.Router()
colors = require 'colors'

require('dotenv').load()

server.use('/', router)

routes = {
	"/#{process.env.FLICKR_API_KEY}/flickr-photostream.rss":      './routes/flickr-photostream'
	"/#{process.env.FLICKR_API_KEY}/flickr-user/:nsid/feed.rss":  './routes/flickr-user-photostream'
	"/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-dashboard.rss":   './routes/tumblr-dashboard'
	"/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss":       './routes/tumblr-liked-images'
}

server.set "port", (process.env.PORT || 6969)

router.route('/').get (request, response) ->
	response.set "Content-Type", "text/plain; charset=utf-8"
	response.send "routes: #{Object.keys(routes).join(", ")}"

localURL = "http://localhost:#{server.get("port")}"
remoteURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com"

console.log ''

for route, handler of routes
	console.log "  " + "#{handler}".underline.green
	console.log "  " + "#{localURL}#{route}"
	console.log "  " + "#{remoteURL}#{route}"
	console.log ''
	server.get route, require(handler)

console.log "============"

server.listen server.get("port")