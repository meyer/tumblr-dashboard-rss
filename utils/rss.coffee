RSSFeed = require 'rss'
lodash = require 'lodash'

# Thin wrapper around node-rss, mainly for logging purposes
module.exports.buildRSSFeed = (config, feedItems) ->
  feed = new RSSFeed(config)

  feedItems.forEach (feedItem, idx, arr) ->
    console.log "- Feed item #{lodash.padLeft idx+1, "#{arr.length}".length, " "} of #{arr.length}: #{feedItem.title} (#{feedItem.date})"
    feed.item(feedItem)

  feed