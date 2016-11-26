const {getBlogInfo, getPosts, buildRSSItems} = require('../utils/tumblr')
const {buildRSSFeed} = require('../utils/rss')

module.exports = function tumblrDashboard(request, response) {
  return Promise.all([
    getBlogInfo(),
    getPosts('dashboard', request.query.post_count),
  ]).then(function([userInfo, posts]) {
    const data = {userInfo, posts};
    const feed = buildRSSFeed({
      formatter: buildRSSItems,
      request,
      title: `Tumblr Dashboard for ${data.userInfo.name}`,
      description: `${data.userInfo.name} follows some interesting people. this is the stuff they post on Tumblr.`,
      site_url: 'http://www.tumblr.com/dashboard',
      data,
    })

    response.set('Content-Type', 'text/xml; charset=utf-8')
    return response.send(feed.xml())
  })
}
