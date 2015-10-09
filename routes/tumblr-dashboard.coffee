RSVP = require 'rsvp'
fs = require 'fs'

{getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
{buildRSSFeed} = require('../utils/rss')

module.exports = (request, response) ->
  RSVP.hash({
    userInfo: getBlogInfo()
    posts: getPosts('dashboard', request.query.post_count)
  }).then (results) ->
    feedItems = buildRSSItems(results.posts)

    feed = buildRSSFeed({
      title: "Tumblr Dashboard for #{results.userInfo.name}"
      description: "#{results.userInfo.name} follows some interesting people. this is the stuff they post on Tumblr."
      feed_url: "http://#{request.headers.host}#{request.url}"
      site_url: 'http://www.tumblr.com/dashboard'
    }, feedItems)

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
