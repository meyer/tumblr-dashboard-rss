RSS = require 'rss'
RSVP = require 'rsvp'
fs = require 'fs'

{ucfirst, img, howmany} = require('../utils')
{getBlogInfo, getPosts, buildRSSFeed} = require('../utils/tumblr')

module.exports = (request, response) ->
  console.log '============'
  RSVP.hash({
    userInfo: getBlogInfo()
    likes: getPosts('likes', request.query.post_count)
  }).then (results) ->

    # Write results to JSON file
    if process.env.VERBOSE_MODE
      fs.writeFile '../lies.json', JSON.stringify(results, null, '  ')

    feed = buildRSSFeed({
      title: "Tumblr Likes for #{results.userInfo.name}"
      description: 'wow, look at all these posts you liked'
      feed_url: "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss"
      site_url: 'https://www.tumblr.com/likes'
    }, results.likes)

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
