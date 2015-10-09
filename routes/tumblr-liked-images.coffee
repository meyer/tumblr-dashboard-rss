RSVP = require 'rsvp'
fs = require 'fs'

{getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
{buildRSSFeed} = require('../utils/rss')

module.exports = (request, response) ->
  RSVP.hash({
    userInfo: getBlogInfo()
    likes: getPosts('likes', request.query.post_count)
  }).then (results) ->
    feedItems = buildRSSItems(results.likes, {showLikeStatus: false})

    feed = buildRSSFeed({
      title: "Tumblr Likes for #{results.userInfo.name}"
      description: 'wow, look at all these posts you liked'
      feed_url: "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss"
      site_url: 'https://www.tumblr.com/likes'
    }, feedItems)

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
