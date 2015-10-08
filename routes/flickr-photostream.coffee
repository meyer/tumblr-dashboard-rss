{Blog, User} = require 'tumblr'
RSS = require 'rss'
RSVP = require 'rsvp'
fs = require 'fs'

{ucfirst, img, howmany, getTimeDiffString} = require('../utils')
{getTitle, getDescription, getFooter, getPhotoPageURL, getUserName} = require('../utils/flickr')

Flickr = require 'flickrapi'
config = require '../config/flickr'

feed = null

mkFeedItem = (item) ->
  console.log " - Feed item: #{item.title} (#{item.date})"
  feed.item(item)

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

      feed = new RSS({
        title: 'Flickr Photostream'
        description: 'All yr photos broh'
        feed_url: "http://#{request.headers.host}#{request.url}"
        site_url: 'http://www.flickr.com'
      })

      data.photos.photo.forEach (p, idx, arr) ->
        mkFeedItem
          title:       getTitle(p),
          description: [].concat(
            "<div>#{img(p.url_l, p.width_l, p.height_l)}</div>"
            getDescription(p)
            getFooter(p)
          ).join('\n\n')
          url:         getPhotoPageURL(p)
          guid:        p.id
          categories:  p.tags.split(' ')
          author:      getUserName(p)
          date:        new Date(p.dateupload * 1000)

      response.set 'Content-Type', 'text/xml; charset=utf-8'
      response.send feed.xml('  ')
