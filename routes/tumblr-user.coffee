RSVP = require 'rsvp'
fs = require 'fs'

{getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
{buildRSSFeed} = require('../utils/rss')

module.exports = (request, response) ->
  console.log "Loading posts for #{request.params.userid}.tumblr.com"

  results = {}

  RSVP.hash({
    userInfo: getBlogInfo(request.params.userid)
    posts: getPosts(request.params.userid, request.query.post_count)
  }).then((results) ->
    feed = buildRSSFeed({
      formatter: buildRSSItems
      request: request
      title: "Tumblr posts for #{results.userInfo.name}"
      description: 'wow, look at all these posts'
      site_url: "https://#{request.params.userid}.tumblr.com"
      data: results
    })

    response.set 'Content-Type', 'text/xml; charset=utf-8'
    response.send feed.xml()
  , (err) ->
    response.set 'Content-Type', 'text/plain; charset=utf-8'
    response.send err
  )
