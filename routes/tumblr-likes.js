const RSVP = require('rsvp')

const {getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
const {buildRSSFeed} = require('../utils/rss')

module.exports = function tumblrLikes(request, response) {
  return RSVP.hash({
    userInfo: getBlogInfo(),
    likes: getPosts('likes', request.query.post_count),
  }).then(function(data) {
    const feed = buildRSSFeed({
      formatter: buildRSSItems,
      request,
      title: `Tumblr Likes for ${data.userInfo.name}`,
      description: 'wow, look at all these posts you liked',
      site_url: 'https://www.tumblr.com/likes',
      data,
    })

    response.set('Content-Type', 'text/xml; charset=utf-8')
    return response.send(feed.xml())
  })
}
