express = require "express"
server = express()
router = express.Router()
expressListRoutes = require 'express-list-routes'

require('dotenv').load()

server.use('/', router)

routes = {
	tumblrOld: require("./routes/tumblr-old")
	tumblrDash: require('./routes/tumblr-dashboard')
	tumblrLikes: require("./routes/tumblr-liked-images")
	flickrPhotostream: require("./routes/flickr-photostream")
}

server.set "port", (process.env.PORT || 6969)

router.route('/').get (request, response) ->
	response.set "Content-Type", "text/plain; charset=utf-8"
	response.send "routes: #{Object.keys(routes).join(", ")}"

router.route("/#{process.env.FLICKR_API_KEY}/flickr-photostream.rss").get(routes.flickrPhotostream)
router.route("/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-dashboard.rss").get(routes.tumblrDash)
router.route("/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss").get(routes.tumblrLikes)

# TODO: deprecate
router.route("/#{process.env.TUMBLR_CONSUMER_KEY}.rss").get(routes.tumblrOld)

localURL = "http://localhost:#{server.get("port")}"
remoteURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com"

expressListRoutes({ prefix:  localURL },  'Local routes:', router )
expressListRoutes({ prefix: remoteURL }, 'Remote routes:', router )

server.listen server.get("port"), ->
	console.log "============"