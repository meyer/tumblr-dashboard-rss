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
    config.userPhotostream.user_id = request.params.nsid

    flickr.people.getPhotos config.userPhotostream, (error, data) ->
      if error
        response.status 500
        response.send error
        return

      if data.photos?.photo?
        console.log "Loaded #{data.photos.photo.length} photos for #{request.params.nsid}"
      else
        response.status 404
        response.send 'Photo object is not set'
        return

      feed = buildRSSFeed({
        formatter: buildRSSItems
        request: request
        title: "Flickr Photostream for #{request.params.nsid}"
        description: "All photos taken by #{request.params.nsid}"
        site_url: "http://www.flickr.com/photos/#{request.params.nsid}"
        data: data.photos.photo
      })

      response.set 'Content-Type', 'text/xml; charset=utf-8'
      response.send feed.xml('  ')
