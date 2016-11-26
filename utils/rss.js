const RSSFeed = require('rss')
const padStart = require('lodash.padstart')

exports.buildRSSFeed = function buildRSSFeed(o) {
  const feed = new RSSFeed({
    title: o.title,
    description: o.description,
    feed_url: `http://${o.request.headers.host}${o.request.url}`,
    site_url: o.site_url,
  })

  o.formatter(o.data).forEach(function(feedItem, idx, arr) {
    console.log(`- Feed item ${padStart(idx+1, `${arr.length}`.length, ' ')} of ${arr.length}: ${feedItem.title} (${feedItem.date})`)
    return feed.item(feedItem)
  })

  return feed
}
