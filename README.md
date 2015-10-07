# Social RSS Feeds

Somehow internet geniuses have taken the simple idea of a feed and turned it into a mess of apps and engagement bullshit. This is an opinionated step in the other direction.

This here thing turns different feeds (only Tumblr for now, working on Flickr at the moment) into an RSS feed. It’s built with Heroku in mind, but it should run on just about anything.

# Tokens

## Tumblr

The easiest way to get required Tumblr keys is to click “Explore API” on the [Tumblr app index page][tumblr-app-index] after you’ve generated a new application.

![Keys!](README-generate-keys.png)

That’ll take you to a developer console with your generated user tokens prefilled. Handy!

## Flickr

Coming soon.


# Configuratin’

Once you’ve got those tokens, set your environment variables on Heroku.

```sh
heroku config:set HEROKU_SUBDOMAIN=your-heroku-app
heroku config:set TUMBLR_CONSUMER_KEY=YourConsumerKey
heroku config:set TUMBLR_CONSUMER_SECRET=YourConsumerSecret
heroku config:set TUMBLR_TOKEN=YourTumblrToken
heroku config:set TUMBLR_TOKEN_SECRET=YourTokenSecret
```

If you want to run this biz locally, make a `.env` file in the root of this folder with those variables set.

```sh
HEROKU_SUBDOMAIN=tumblr-dash-rss

TUMBLR_CONSUMER_KEY=YourConsumerKey
TUMBLR_CONSUMER_SECRET=YourConsumerSecret
TUMBLR_TOKEN=YourTumblrToken
TUMBLR_TOKEN_SECRET=YourTokenSecret

FLICKR_ACCESS_TOKEN_SECRET=
FLICKR_ACCESS_TOKEN=
FLICKR_API_SECRET=***
FLICKR_API_KEY=***

VERBOSE_MODE=yep
```

Once everything’s up and running, your RSS feed will be available at `http://HEROKU_SUBDOMAIN.herokuapp.com/TUMBLR_CONSUMER_KEY.rss`.

Questions/problems? File an issue and/or bug me [on Twitter][@meyer].

[tumblr-app-index]:https://www.tumblr.com/oauth/apps
[@meyer]: http://twitter.com/meyer