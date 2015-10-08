{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"

{ucfirst, img, howmany, getTimeDiffString} = require("../utils")
{getTitle, getDescription, getFooter, getPhotoPageURL, getUserName} = require('../utils-flickr')

Flickr = require "flickrapi"
flickrOptions = {
	nobrowser: true
	api_key: process.env.FLICKR_API_KEY
	secret: process.env.FLICKR_API_SECRET
	access_token: process.env.FLICKR_ACCESS_TOKEN
	access_token_secret: process.env.FLICKR_ACCESS_TOKEN_SECRET
}

feed = null

mkFeedItem = (item) ->
	console.log " - Feed item: #{item.title} (#{item.date})"
	feed.item(item)

# TODO: Promise-ify this?
module.exports = (request, response) ->
	Flickr.authenticate flickrOptions, (error, flickr) ->
		contactsPhotosOptions = {
			count: 50
			# page: 2
			# just_friends: false
			# single_photo: false
			include_self: false

			# https://www.flickr.com/services/api/flickr.photos.search.html
			extras: [
				# Not listed but useful:
				'realname'

				'description'
				# 'license'
				'date_upload'
				'date_taken'
				'owner_name'
				'icon_server'
				# 'original_format'
				'last_update'
				# 'geo'
				'tags'
				# 'machine_tags'
				'o_dims'
				# 'views'
				'media'
				'path_alias'
				# 'url_sq'
				# 'url_t'
				# 'url_s'
				# 'url_q'
				# 'url_m'
				# 'url_n'
				# 'url_z'
				# 'url_c'
				'url_l'
				# 'url_o'
			]
		}

		flickr.photos.getContactsPhotos contactsPhotosOptions, (error, data) ->
			if error
				response.status 500
				response.send error
				return

			if data.photos?.photo?
				console.log "Loaded #{data.photos.photo.length} photos"
			else
				response.status 404
				response.send 'Photo object is not set'
				return

			feed = new RSS({
				title: "Flickr Photostream"
				description: "All yr photos broh"
				feed_url: "http://#{request.headers.host}#{request.url}"
				site_url: "http://www.flickr.com"
				# pubDate: result.posts[0].date
				# ttl: "20" # minutes
			})

			data.photos.photo.forEach (p, idx, arr) ->
				mkFeedItem
					title:       getTitle(p),
					description: [].concat(
						"<div>#{img(p.url_l, p.width_l, p.height_l)}</div>"
						getDescription(p)
						getFooter(p)
					).join("\n\n")
					url:         getPhotoPageURL(p)
					guid:        p.id
					categories:  p.tags.split(' ')
					author:      getUserName(p)
					date:        new Date(p.dateupload * 1000)

			response.set "Content-Type", "text/xml; charset=utf-8"
			response.send feed.xml('  ')
