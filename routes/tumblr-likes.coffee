RSVP = require 'rsvp'
fs = require 'fs'

{getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
{buildRSSFeed} = require('../utils/rss')

module.exports = (request, response) ->
  RSVP.hash({
    userInfo: getBlogInfo()
    likes: getPosts('likes', request.query.post_count)
  }).then (results) ->
    feed = buildRSSFeed({
      formatter: buildRSSItems
      request: request
      title: "Tumblr Likes for #{results.userInfo.name}"
      description: 'wow, look at all these posts you liked'
      site_url: 'https://www.tumblr.com/likes'
      data: results
    })

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
