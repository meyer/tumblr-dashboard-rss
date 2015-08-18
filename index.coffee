express = require "express"
server = express()
router = express.Router()
expressListRoutes = require 'express-list-routes'

require('dotenv').load()

server.use('/', router)

routes = {
	tumblr: require("./routes/tumblr")
	tumblrLikes: require("./routes/tumblr-liked-images")
	flickr: require("./routes/flickr")
}

server.set "port", (process.env.PORT || 6969)

router.route('/').get (request, response) ->
	response.set "Content-Type", "text/plain; charset=utf-8"
	response.send "routes: #{Object.keys(routes).join(", ")}"

router.route("/#{process.env.FLICKR_API_KEY}/flickr-photostream.rss").get(routes.flickr)
router.route("/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-dashboard.rss").get(routes.tumblr)
router.route("/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss").get(routes.tumblrLikes)

router.route("/#{process.env.TUMBLR_CONSUMER_KEY}.rss").get(routes.tumblr)

localURL = "http://localhost:#{server.get("port")}"
remoteURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com"

expressListRoutes({ prefix:  localURL },  'Local routes:', router )
expressListRoutes({ prefix: remoteURL }, 'Remote routes:', router )

server.listen server.get("port"), ->
	console.log "============"