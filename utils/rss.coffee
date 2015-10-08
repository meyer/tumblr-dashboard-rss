feed = null

mkFeedItem = (item) ->
  console.log " - Feed item: #{item.title} (#{item.date})"
  feed.item(item)

module.exports = ->
  new RSS(config)