{Blog, User} = require 'tumblr'
RSS = require 'rss'
RSVP = require 'rsvp'
fs = require 'fs'

{buildRSSItems} = require('../utils/flickr')
{buildRSSFeed} = require('../utils/rss')

Flickr = require 'flickrapi'
config = require '../config/flickr'

# TODO: Promise-ify this?
module.exports = (request, response) ->
  Flickr.authenticate config.auth, (error, flickr) ->


    flickr.photos.getContactsPhotos config.photostream, (error, data) ->
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

      feedItems = buildRSSItems(data.photos.photo)

      feed = buildRSSFeed({
        title: 'Flickr Photostream'
        description: 'All yr photos broh'
        feed_url: "http://#{request.headers.host}#{request.url}"
        site_url: 'http://www.flickr.com'
      }, feedItems)

      response.set 'Content-Type', 'text/xml; charset=utf-8'
      response.send feed.xml('  ')
