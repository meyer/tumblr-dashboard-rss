{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"

Flickr = require "flickrapi",
flickrOptions = {
	nobrowser: true
	api_key: process.env.FLICKR_API_KEY
	secret: process.env.FLICKR_API_SECRET
	access_token: process.env.FLICKR_ACCESS_TOKEN
	access_token_secret: process.env.FLICKR_ACCESS_TOKEN_SECRET
}

module.exports = (request, response) ->
	Flickr.authenticate flickrOptions, (error, flickr) ->
		flickr.people.getPhotos({user_id: process.env.FLICKR_USER_ID}, (error, d) ->
			console.log 'callbaaaaaack:', JSON.stringify(d, null, '  ')
		)

		response.set "Content-Type", "application/json; charset=utf-8"
		response.send 'yesss'