RSS = require "rss"

module.exports = (request, response) ->
	# Beginning of today
	today = new Date()
	today.setHours(0, 0, 0, 0)
	timestamp = new Date(today - today.getDay() * 24 * 60 * 60 * 1000)

	feed = new RSS({
		title: "This is an empty feed"
		description: "Remove from your RSS reader breh"
		feed_url: "http://example.com"
		site_url: "http://example.com"
		pubDate: timestamp
	})

	feed.item {
		title:       'This RSS feed is empty. Remove it from your RSS reader, maaan'
		description: 'This RSS feed is empty. Remove it from your RSS reader, maaan'
		guid:        timestamp / 1000
		author:      'Mr. Nobody'
		date:        timestamp
	}

	response.set "Content-Type", "text/xml; charset=utf-8"
	response.send feed.xml("  ")