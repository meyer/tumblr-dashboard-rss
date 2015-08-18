{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"

user = new User({
	consumer_key:    process.env.TUMBLR_CONSUMER_KEY
	consumer_secret: process.env.TUMBLR_CONSUMER_SECRET
	token:           process.env.TUMBLR_TOKEN
	token_secret:    process.env.TUMBLR_TOKEN_SECRET
})

{ucfirst, img, howmany} = require("../utils")

getBlogInfo = ->
	new RSVP.Promise (resolve, reject) ->
		user.info (err, response) ->
			if err
				reject(err)
			else
				resolve(response.user)

getUserLikes = (postCount = 60) ->
	limit = 20
	ic = Math.ceil(postCount / limit)
	mod = postCount % limit
	offset = 0

	console.log "POSTS TO LOAD: #{howmany postCount, "post"} in #{howmany ic, "batch", "batches"}"

	# Return array of promises
	RSVP.all([1..ic].map (idx) ->
		batchSize = if idx == ic && mod != 0 then mod else limit
		console.log "* LOADING #{howmany batchSize, "LIKED POST", "LIKED POSTS"}"
		new RSVP.Promise (resolve, reject) ->
			user.likes {
				# notes_info: true
				limit: batchSize
				offset: offset
				# TODO: use before/after instead of offset
			}, (error, response) ->
				if error
					reject(error)
				else
					resolve(response.liked_posts)

			offset += batchSize

	).then (posts) ->
		# Turn array of arrays into a single array
		Array.prototype.concat.apply([], posts)


module.exports = (request, response) ->
	console.log "============"
	RSVP.hash({
		userInfo: getBlogInfo()
		likes: getUserLikes(request.query.post_count)
	}).then (results) ->

		# Write results to JSON file
		if process.env.VERBOSE_MODE
			fs.writeFile "../likes.json", JSON.stringify(results, null, "  ")

		# response.set "Content-Type", "application/json; charset=utf-8"
		# response.send JSON.stringify(results, null, '  ')
		# return

		# console.log JSON.stringify(results.likes, null, '  ')

		feed = new RSS({
			title: "Tumblr Likes for #{results.userInfo.name}"
			description: ""
			feed_url: "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-likes.rss"
			site_url: "https://www.tumblr.com/likes"
			# pubDate: result.posts[0].date
			# ttl: "20" # minutes
		})

		results.likes.forEach (post) ->
			console.log "============"
			console.log "#{post.id}"
			post_content = []
			post_title = []

			tags = post.tags.map (t) ->
				"<a href=\"http://#{post.blog_name}.tumblr.com/tagged/#{encodeURIComponent t}\">##{t}</a>"

			if post.title && post.title != ''
				post_title.push post.title
			else
				post_title.push "#{ucfirst post.type}"

			# Add reblog info
			# TODO: Handle answers specially. x answered y, x ⇄ y answered z
			if post.reblogged_from_name
				reblog_src = post.reblogged_from_name
				if post.reblogged_root_name != post.reblogged_from_name
					reblog_src = "#{post.reblogged_from_name} … #{post.reblogged_root_name}"
				else
					console.log "post author is the same as reblogger"

				post_title.push "#{post.blog_name} ⇄ #{reblog_src}"
			else
				if post.type == "answer"
					post_title.push "#{post.blog_name} → #{post.asking_name}"
				else
					post_title.push "#{post.blog_name}"

			console.log "post.type: #{post.type} -- #{JSON.stringify post, null, '  '}"

			like_date = new Date(post.liked_timestamp * 1000)

			console.log "LIKE DATE:", like_date

			switch post.type
				when "photo"
					post.photos.forEach (p, idx, arr) ->
						titleSuffix = ""
						if arr.length > 1
							titleSuffix = " (#{idx+1} of #{arr.length})"

						newFeedItem =
							title:       post_title.join(" • ") + titleSuffix
							description: [
								img(p.original_size.url, p.original_size.width, p.original_size.height)
								if p.caption != "" then p.caption else []
								if post.caption != "" then post.caption else []
								if tags.length > 0 then "<p>#{tags.join(", ")}</p>" else []
							].join('\n\n')
							url:         post.post_url
							guid:        "#{post.id}-#{('000'+idx).slice(-2)}"
							categories:  post.tags
							author:      post.blog_name
							date:        like_date

						feed.item newFeedItem

						console.log "Photo post -- individual image", JSON.stringify(newFeedItem, null, '  '), '\n\n'



				when "link"
					if post.photos
						post.photos.forEach (p, idx, arr) ->

							titleSuffix = ""
							if arr.length > 1
								titleSuffix = " (#{idx+1} of #{arr.length})"

							newFeedItem =
								title:       post_title.join(" • ") + titleSuffix
								description: [].concat(
									img(p.original_size.url, p.original_size.width, p.original_size.height),
									if post.excerpt != '' then "<blockquote><p>#{post.excerpt}</p></blockquote>" else []
									if post.description != '' then post.description else []
									if tags.length > 0 then "<p>#{tags.join(", ")}</p>" else []
								).join('\n\n')
								url:         post.post_url
								guid:        "#{post.id}-#{('000'+idx).slice(-2)}"
								categories:  post.tags
								author:      post.blog_name
								date:        like_date

							console.log "Link post -- individual image", JSON.stringify(newFeedItem, null, '  '), '\n\n'

							feed.item newFeedItem


				# when "video"
					# post_content.push post.player.pop().embed_code

					# post_content.push """
					# <p>#{post.source_title} <a href="#{post.source_url}">#</a></p>
					# """

				else
					console.log "Unsupported post type: #{post.type}"
					post_content.push "#{ucfirst post.type} posts not supported (yet!)"

			console.log post_title.join(" • ")


		response.set "Content-Type", "text/xml; charset=utf-8"
		response.send feed.xml()
