RSSFeed = require 'rss'
lodash = require 'lodash'

# TODO: cool invariant shit
module.exports.buildRSSFeed = (o) ->
  feed = new RSSFeed({
    title: o.title
    description: o.description
    feed_url: "http://#{o.request.headers.host}#{o.request.url}"
    site_url: o.site_url
  })

  feedItems = o.formatter(o.data)

  feedItems.forEach (feedItem, idx, arr) ->
    console.log "- Feed item #{lodash.padLeft idx+1, "#{arr.length}".length, " "} of #{arr.length}: #{feedItem.title} (#{feedItem.date})"
    feed.item(feedItem)

  feed