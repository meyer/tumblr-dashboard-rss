const { buildRSSItems } = require('../utils/flickr')
const { buildRSSFeed } = require('../utils/rss')

const Flickr = require('flickrapi')
const config = require('../config/flickr')

// TODO: Promise-ify this?
module.exports = function flickrUserPhotostream(request, response) {
  return Flickr.authenticate(config.auth, function(error, flickr) {
    config.userPhotostream.user_id = request.params.nsid

    return flickr.people.getPhotos(config.userPhotostream, function(error, data) {
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
        console.log(`Loaded ${data.photos.photo.length} photos for ${request.params.nsid}`)
      } else {
        response.status(404)
        response.send('Photo object is not set')
        return
      }

      const feed = buildRSSFeed({
        formatter: buildRSSItems,
        request,
        title: `Flickr Photostream for ${request.params.nsid}`,
        description: `All photos taken by ${request.params.nsid}`,
        site_url: `http://www.flickr.com/photos/${request.params.nsid}`,
        data: data.photos.photo,
      })

      response.set('Content-Type', 'text/xml; charset=utf-8')
      return response.send(feed.xml('  '))
    })
  })
}
