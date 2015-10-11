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

      feed = buildRSSFeed({
        formatter: buildRSSItems
        request: request
        title: 'Flickr Photostream'
        description: 'All yr photos broh'
        site_url: 'http://www.flickr.com'
        data: data.photos.photo
      })

      response.set 'Content-Type', 'text/xml; charset=utf-8'
      response.send feed.xml('  ')
