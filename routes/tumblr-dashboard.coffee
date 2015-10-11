RSVP = require 'rsvp'
fs = require 'fs'

{getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
{buildRSSFeed} = require('../utils/rss')

module.exports = (request, response) ->
  RSVP.hash({
    userInfo: getBlogInfo()
    posts: getPosts('dashboard', request.query.post_count)
  }).then (results) ->
    feed = buildRSSFeed({
      formatter: buildRSSItems
      request: request
      title: "Tumblr Dashboard for #{results.userInfo.name}"
      description: "#{results.userInfo.name} follows some interesting people. this is the stuff they post on Tumblr."
      site_url: 'http://www.tumblr.com/dashboard'
      data: results
    })

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
