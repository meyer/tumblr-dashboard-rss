const {buildRSSItems} = require('../utils/flickr')
const {buildRSSFeed} = require('../utils/rss')

const Flickr = require('flickrapi')
const config = require('../config/flickr')

// TODO: Promise-ify this?
module.exports = function flickrPhotostream(request, response) {
  return Flickr.authenticate(config.auth, (error, flickr) =>


    flickr.photos.getContactsPhotos(config.photostream, function(error, data) {
      if (error) {
        response.status(500)
        response.send(error)
        return
      }

      if (
        data.photos &&
        data.photos.photo &&
        Array.isArray(data.photos.photo)
      ) {
        console.log(`Loaded ${data.photos.photo.length} photos`)
      } else {
        response.status(404)
        response.send('Photo object is not set')
        return
      }

      const feed = buildRSSFeed({
        formatter: buildRSSItems,
        request,
        title: 'Flickr Photostream',
        description: 'All yr photos broh',
        site_url: 'http://www.flickr.com',
        data: data.photos.photo,
      })

      response.set('Content-Type', 'text/xml; charset=utf-8')
      return response.send(feed.xml('  '))
    })
  )
}
