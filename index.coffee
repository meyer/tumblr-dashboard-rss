express = require "express"
server = express()

routes = {
	tumblr: require("./routes/tumblr")
}

server.set "port", (process.env.PORT || 6969)

{
	getBlogInfo
	getDashboardPosts
	ucfirst
	howmany
	img
} = require("./utils")

server.get "/", (request, response) ->
	response.set "Content-Type", "text/plain; charset=utf-8"
	response.send "routes: #{Object.keys(routes).join(", ")}"

server.get "/#{process.env.TUMBLR_CONSUMER_KEY}.rss", routes.tumblr

server.listen server.get("port"), ->
	console.log "============"
	console.log "Routes: #{Object.keys(routes).join(", ")}"
	console.log "------------"
	console.log "Local RSS URL:"
	console.log "http://localhost:#{server.get("port")}/#{process.env.TUMBLR_CONSUMER_KEY}.rss"
	console.log "------------"
	console.log "Remote RSS URL:"
	console.log "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}.rss"