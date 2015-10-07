{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"
moment = require 'moment'

{ucfirst, img, howmany} = require("../utils")

getFlickrImageURL = (o) ->
	###
	Image Sizes
	===========
	s   small square 75x75
	q   large square 150x150
	t   thumbnail, 100 on longest side
	m   small, 240 on longest side
	n   small, 320 on longest side
	-   medium, 500 on longest side
	z   medium 640, 640 on longest side
	c   medium 800, 800 on longest side†
	b   large, 1024 on longest side*
	h   large 1600, 1600 on longest side†
	k   large 2048, 2048 on longest side†
	o   original image, either a jpg, gif or png, depending on source format
	###

	imageSize = 'b'

	###
	getContactsPhotos Structure
	===========================
	{
		"farm": 1,
		"id": "21805173440",
		"isfamily": 0,
		"isfriend": 0,
		"ispublic": 1,
		"owner": "37386863@N03",
		"secret": "9784d42b5f",
		"server": "729",
		"title": "\u00a9 Richard Curtis",
		"username": "leica_camera"
	}

	with extras:
	============
	{
		"id": "21805173440",
		"secret": "9784d42b5f",
		"server": "729",
		"farm": 1,
		"owner": "37386863@N03",
		"username": "leica_camera",
		"title": "© Richard Curtis",
		"ispublic": 1,
		"isfriend": 0,
		"isfamily": 0,
		"description": {
			"_content": "On his trip with the BBC to Mongolia, Richard Curtis captured the atmosphere of the eagle hunters' traditional Nadaam Games in his black and white series: <a href=\"http://bit.ly/RichardCurtisLeicaBlog\" rel=\"nofollow\">bit.ly/RichardCurtisLeicaBlog</a>\n\n\n"
		},
		"o_width": "1200",
		"o_height": "900",
		"dateupload": "1444136052",
		"datetaken": "2015-10-06 14:50:30",
		"datetakengranularity": 0,
		"datetakenunknown": "1",
		"ownername": "leica_camera",
		"iconserver": "8660",
		"iconfarm": 9,
		"tags": "horizontal msystem richardcurtis",
		"media": "photo",
		"media_status": "ready",
		"url_l": "https://farm1.staticflickr.com/729/21805173440_9784d42b5f_b.jpg",
		"height_l": "768",
		"width_l": "1024",
		"pathalias": "leica_camera"
	}

	###

	"https://farm#{o.farm}.staticflickr.com/#{o.server}/#{o.id}_#{o.secret}_#{imageSize}.jpg"

getBuddyIconURL = (o) ->
	unless o.iconserver && o.iconserver > 0
		return 'https://www.flickr.com/images/buddyicon.gif'
	"http://farm#{o.iconfarm}.staticflickr.com/#{o.iconserver}/buddyicons/#{o.owner}.jpg"

getPhotoPageURL = (o) ->
	"https://www.flickr.com/photos/#{o.owner}/#{o.id}"

getUserRepresentation = (o) ->
	"<table><tr><td style='vertical-align:middle'>#{img(getBuddyIconURL(o), 24, 24)}</td><th style='vertical-align:middle'>#{getUserName(o)}</th></tr></table>"

getDescription = (o) ->
	if o.description?._content?.trim() != ''
		"#{getUserRepresentation(o)}\n<p>#{o.description._content.trim()}</p>"
	else
		"#{getUserRepresentation(o)}\n<!-- No description set -->"

getUserName = (o) ->
	if o.username && o.username != o.ownername
		return "#{o.ownername} (#{o.username})"
	o.ownername

getTitle = (o) ->
	if o.title.trim() != ''
		return "#{ucfirst o.media}: #{o.title.trim()}"
	"#{ucfirst o.media}: #{o.username}"

Flickr = require "flickrapi"
flickrOptions = {
	nobrowser: true
	api_key: process.env.FLICKR_API_KEY
	secret: process.env.FLICKR_API_SECRET
	access_token: process.env.FLICKR_ACCESS_TOKEN
	access_token_secret: process.env.FLICKR_ACCESS_TOKEN_SECRET
}

niceDateStringFormat = 'MMMM Do YYYY [at] h:mm:ssa'

getTagLinks = (o) ->
	if o.tags.trim() == '' then return false
	o.tags.split(' ').map((t) ->
		"<a href='https://www.flickr.com/search/?tags=#{t}'>##{t}</a>"
	).join(', ')

getFooter = (p) ->
	ret = []
	if tagLinks = getTagLinks(p)
		ret.push "<tr><th align='left'>Tags</th><td>#{tagLinks}</td></tr>"

	ret.push "<tr><th align='left'>Taken</th><td>#{moment(new Date(p.datetaken)).format(niceDateStringFormat)}</td></tr>"
	ret.push "<tr><th align='left'>Uploaded</th><td>#{moment(new Date(p.dateupload * 1000)).format(niceDateStringFormat)}</td></tr>"

	return "<table>#{ret.join('\n')}</table>"

module.exports = (request, response) ->
	Flickr.authenticate flickrOptions, (error, flickr) ->
		options = {
			count: 50
			# just_friends: false
			# single_photo: false
			include_self: false

			# https://www.flickr.com/services/api/flickr.photos.search.html
			extras: [
				'description'
				# 'license'
				'date_upload'
				'date_taken'
				'owner_name'
				'icon_server'
				# 'original_format'
				# 'last_update'
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

		flickr.photos.getContactsPhotos options, (error, data) ->
			console.log 'Error? ', error
			console.log JSON.stringify(data, null, '  ')

			unless data.photos?.photo?
				console.log 'Photo object is not set'
				response.send 404

			feed = new RSS({
				title: "Flickr Photostream"
				description: "All yr photos broh"
				feed_url: "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.FLICKR_API_KEY}/flickr-photostream.rss"
				site_url: "http://www.flickr.com"
				# pubDate: result.posts[0].date
				# ttl: "20" # minutes
			})

			data.photos.photo.forEach (p, idx, arr) ->
				feed.item
					title:       getTitle(p),
					description: [].concat(
						"<div>#{img(p.url_l, p.width_l, p.height_l)}</div>"
						getDescription(p)
						"<hr>"
						getFooter(p)
					).join("\n\n")
					url:         getPhotoPageURL(p)
					guid:        p.id
					categories:  p.tags.split(' ')
					author:      getUserName(p)
					date:        new Date(p.dateupload * 1000)

			response.set "Content-Type", "text/xml; charset=utf-8"
			response.send feed.xml('  ')
