{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"

# tumblr://x-callback-url/blog?blogName=tumblr-username
# tumblr://x-callback-url/blog?blogName=tumblr-username&postID=post-id

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

getDashboardPosts = (postCount = 60) ->
	limit = 20
	ic = Math.ceil(postCount / limit)
	mod = postCount % limit
	offset = 0

	console.log "POSTS TO LOAD: #{howmany postCount, "post"} in #{howmany ic, "batch", "batches"}"

	# Return array of promises
	RSVP.all([1..ic].map (idx) ->
		batchSize = if idx == ic && mod != 0 then mod else limit
		console.log "* LOADING #{howmany batchSize, "POST", "POSTS"}"
		new RSVP.Promise (resolve, reject) ->
			user.dashboard {
				reblog_info: true
				# notes_info: true
				limit: batchSize
				offset: offset
			}, (error, response) ->
				if error
					reject(error)
				else
					resolve(response.posts)

			offset += batchSize

	).then (posts) ->
		# Turn array of arrays into a single array
		Array.prototype.concat.apply([], posts)


module.exports = (request, response) ->
	console.log "============"
	RSVP.hash({
		userInfo: getBlogInfo()
		posts: getDashboardPosts(request.query.post_count)
	}).then (results) ->

		# Write results to JSON file
		if process.env.VERBOSE_MODE
			fs.writeFile "../dashboard.json", JSON.stringify(results,null,"  ")

		feed = new RSS({
			title: "Tumblr Dashboard for #{results.userInfo.name}"
			description: ""
			feed_url: "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}/tumblr-dashboard.rss"
			site_url: "http://www.tumblr.com/dashboard"
			# pubDate: result.posts[0].date
			# ttl: "20" # minutes
		})

		results.posts.forEach (post) ->
			console.log "============"
			console.log "#{post.id}"

			post_title = []
			post_content = []
			post_footer = []

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

			post_footer.push "<p>#{tags.join(", ")}</p>" if tags.length > 0
			post_footer.push "<p>Source: <a href='#{post.source_url}'>#{post.source_title}</a></p>" if post.source_url
			post_footer.push "<p>&check; Liked</p>" if post.liked
			post_footer.push "<p><a href='tumblr://x-callback-url/blog?blogName=#{post.blog_name}&postID=#{post.id}'>View in Tumblr app</a></p>"

			switch post.type
				when "photo"
					post.photos.forEach (p, idx, arr) ->
						titleSuffix = ""
						if arr.length > 1
							titleSuffix = " (#{idx+1} of #{arr.length})"

						desc = []
						desc.push(p.caption) if p.caption != ""
						desc.push(post.caption) if post.caption != ""

						newFeedItem =
							title:       post_title.join(" • ") + titleSuffix
							description: [].concat(
								img(p.original_size.url, p.original_size.width, p.original_size.height),
								desc,
								post_footer,
							).join('\n\n')
							url:         post.post_url
							guid:        "#{post.id}-#{('000'+idx).slice(-2)}"
							categories:  post.tags
							author:      post.blog_name
							date:        post.date

						feed.item newFeedItem

						console.log "Photo post -- individual image", JSON.stringify(newFeedItem, null, '  '), '\n\n'
					return

				when "link"
					if post.photos
						post.photos.forEach (p, idx, arr) ->

							titleSuffix = ""
							if arr.length > 1
								titleSuffix = " (#{idx+1} of #{arr.length})"

							desc = []
							desc.push("<blockquote><p>#{post.excerpt}</p></blockquote>") if post.excerpt != ''
							desc.push(post.description) if post.description

							newFeedItem =
								title:       post_title.join(" • ") + titleSuffix
								description: [].concat(
									img(p.original_size.url, p.original_size.width, p.original_size.height),
									desc,
									post_footer,
								).join('\n\n')
								url:         post.post_url
								guid:        "#{post.id}-#{('000'+idx).slice(-2)}"
								categories:  post.tags
								author:      post.blog_name
								date:        post.date

							console.log "Link post -- individual image", JSON.stringify(newFeedItem, null, '  '), '\n\n'

							feed.item newFeedItem
						return
					else
						post_content.push "<h3>#{post.title} <a href='#{post.url}'>#</a></h3>"
						post_content.push photos if photos
						post_content.push desc if desc != ""

				when "text"
					post_content.push post.body

				when "quote"
					post_content.push "#{post.text}"
					post_content.push "<br><br>"
					post_content.push "&mdash;&thinsp;#{post.source}"

				when "chat"
					post_content.push "<table>"

					post.dialogue.forEach (line) ->
						post_content.push """
						<tr>
							<th>#{line.name}</th>
							<td>#{line.phrase}</td>
						</tr>
						"""

					post_content.push "</table>"

				when "audio"
					post_content.push post.player

					# post_content.push """
					# <p>#{post.source_title} <a href="#{post.source_url}">#</a></p>
					# """

					post_content.push post.caption

				when "video"
					post_content.push post.player.pop().embed_code

					# post_content.push """
					# <p>#{post.source_title} <a href="#{post.source_url}">#</a></p>
					# """

				when "answer"
					asker = """
					<a href="#{post.asking_url}">
						<img src="http://api.tumblr.com/v2/blog/#{post.asking_name}.tumblr.com/avatar/128" height="128" width="128">
						#{post.asking_name}</a>
					"""

					if post.asking_name == "Anonymous"
						asker = """
						<img src="https://secure.assets.tumblr.com/images/anonymous_avatar_128.gif" height="128" width="128">
						#{post.asking_name}
						"""

					post_content.push "<h3>#{asker}: #{post.question}</h3>"
					post_content.push post.answer


				else
					console.log "Unsupported post type: #{post.type}"
					post_content.push "#{ucfirst post.type} posts not supported (yet!)"


			feed.item
				title:       post_title.join(" • ")
				description: [].concat(
					post_content,
					post_footer
				).join("\n\n")
				url:         post.post_url
				guid:        "#{post.id}-0001"
				categories:  post.tags
				author:      post.blog_name
				date:        post.date

			console.log post_title.join(" • ")

		response.set "Content-Type", "text/xml; charset=utf-8"
		response.send feed.xml()
