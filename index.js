const express = require('express')
require('colors')

const server = express()

require('dotenv').load()

const routes = {
  flickr: {
    'flickr-photostream.rss':     'flickr-photostream',
    'flickr-user/:nsid/feed.rss': 'flickr-user-photostream',
  },
  tumblr: {
    'tumblr-dashboard.rss':         'tumblr-dashboard',
    'tumblr-likes.rss':             'tumblr-likes',
    'tumblr-user/:userid/feed.rss': 'tumblr-user',
  },
}

const routePrefixes = {
  flickr: process.env.FLICKR_API_KEY,
  tumblr: process.env.TUMBLR_CONSUMER_KEY,
}

server.set('port', (process.env.PORT || 6969))

server.use('/', function(request, response, next) {
  console.log(`${new Date} - ${request.method.green} ${request.originalUrl}`)
  next()
})

const remoteURL = `http://${process.env.HEROKU_SUBDOMAIN}.herokuapp.com/`
const localURL = `http://localhost:${server.get('port')}/`

console.log('============')
console.log('')

for (const category in routes) {
  const routeObj = routes[category]
  for (const route in routeObj) {
    const handler = routeObj[route]
    if (!routePrefixes[category]) {
      throw `Route prefix not set for category \`${category}\``
    }

    console.log(`  ${handler.underline.green}`)
    console.log(`  ${process.env.NODE_ENV === 'development' ? ' ' : '>'} ${remoteURL}${routePrefixes[category]}/${route}`)
    console.log(`  ${process.env.NODE_ENV === 'development' ? '>' : ' '} ${localURL}${route}`)
    console.log('')

    if (process.env.NODE_ENV === 'development') {
      server.get(`/${route}`, require(`./routes/${handler}`))
    } else {
      server.get(`/${routePrefixes[category]}/${route}`, require(`./routes/${handler}`))
    }
  }
}

console.log('============')

server.listen(server.get('port'))
