RSS = require 'rss'
RSVP = require 'rsvp'
fs = require 'fs'

{ucfirst, img, howmany} = require('../utils')
{getBlogInfo, getPosts, buildRSSFeed} = require('../utils/tumblr')

module.exports = (request, response) ->
  console.log '============'
  RSVP.hash({
    userInfo: getBlogInfo()
    posts: getPosts('dashboard', request.query.post_count)
  }).then (results) ->

    # Write results to JSON file
    if process.env.VERBOSE_MODE
      fs.writeFile '../dashboard.json', JSON.stringify(results, null, '  ')

    feed = buildRSSFeed({
      title: "Tumblr Dashboard for #{results.userInfo.name}"
      description: "#{results.userInfo.name} follows some interesting people. this is the stuff they post on Tumblr."
      feed_url: "http://#{request.headers.host}#{request.url}"
      site_url: 'http://www.tumblr.com/dashboard'
    }, results.posts)

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
