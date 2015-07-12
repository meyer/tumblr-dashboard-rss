{Blog, User} = require "tumblr"
RSS = require "rss"
RSVP = require "rsvp"
fs = require "fs"

express = require "express"
server = express()

server.set "port", (process.env.PORT || 6969)

oauth =
	consumer_key:    process.env.TUMBLR_CONSUMER_KEY
	consumer_secret: process.env.TUMBLR_CONSUMER_SECRET
	token:           process.env.TUMBLR_TOKEN
	token_secret:    process.env.TUMBLR_TOKEN_SECRET

user = new User(oauth)
feedURL = "http://#{process.env.HEROKU_SUBDOMAIN}.herokuapp.com/#{process.env.TUMBLR_CONSUMER_KEY}.rss"

ucfirst = (s) -> s = "#{s}"; "#{s.charAt(0).toUpperCase()}#{s.substr(1)}"
howmany = (n, s, p = false) -> "#{n} #{if n == 1 then s else (p || "#{s}s")}"

img = (src, w, h) ->
	if w then w = " width=#{w}"
	if h then h = " height=#{h}"
	"""
	<img src="#{src}"#{w || ""}#{h || ""}>
	"""

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


server.get "/", (request, response) ->
	response.set "Content-Type", "text/plain; charset=utf-8"
	response.send "wow"

server.get "/#{process.env.TUMBLR_CONSUMER_KEY}.rss", (request, response) ->
	console.log "============"
	RSVP.hash({
		userInfo: getBlogInfo()
		posts: getDashboardPosts(request.query.post_count)
	}).then (results) ->

		# Write results to JSON file
		if process.env.VERBOSE_MODE
			fs.writeFile "./dashboard.json", JSON.stringify(results,null,"  ")

		feed = new RSS({
			title: "Tumblr Dashboard for #{results.userInfo.name}"
			description: ""
			feed_url: feedURL
			site_url: "http://www.tumblr.com/dashboard"
			# pubDate: result.posts[0].date
			# ttl: "20" # minutes
		})

		results.posts.forEach (post) ->
			console.log "============"
			console.log "#{post.id}"
			post_content = []
			post_title = []
			metadata = []

			if post.title && post.title != ""
				post_content.push "<h2>#{post.title}</h2>"

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

			console.log "post.type: #{post.type}"

			switch post.type
				when "text"
					post_content.push post.body

				when "photo"
					photos = post.photos.map((p) ->
						imgString = img(p.alt_sizes[0].url, p.alt_sizes[0].width, p.alt_sizes[0].height)
						if p.caption != ""
							imgString = "#{imgString}\n<p>#{p.caption}</p>"
						imgString
					).join("\n\n")

					post_content.push photos
					post_content.push post.caption if post.caption != ""

				when "quote"
					post_content.push "#{post.text}"
					post_content.push "<br><br>"
					post_content.push "&mdash;&thinsp;#{post.source}"

				when "link"
					desc = "#{post.description}".trim()
					console.log post.photos

					photos = false

					if post.photos
						photos = post.photos.map((p) ->
							console.log "PHOTO:", p
							imgString = img(p.original_size.url, p.original_size.width, p.original_size.height)
							imgString
						).join("\n<br>\n\n")

					post_content.push "<h3>#{post.title} <a href='#{post.url}'>#</a></h3>"
					post_content.push photos if photos
					post_content.push desc if desc != ""

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

			metadata.push howmany(post.note_count, "note")
			metadata.push "Liked" if post.liked
			metadata.push "Source: <a href='#{post.source_url}'>#{post.source_title}</a>" if post.source_url

			tags = post.tags.map (t) ->
				"<a href='http://#{post.blog_name}.tumblr.com/tagged/#{encodeURIComponent t}'>##{t}</a>"

			post_content.push "<p>#{tags.join(", ")}</p>" if tags.length > 0
			post_content.push "<hr>"
			post_content.push "<p>#{metadata.join(" • ")}</p>"

			console.log post_title.join(" • ")

			feed.item
				title:       post_title.join(" • ")
				description: post_content.join("\n\n")
				url:         post.post_url
				guid:        post.id
				categories:  post.tags
				author:      post.blog_name
				date:        post.date

		response.set "Content-Type", "text/xml; charset=utf-8"
		response.send feed.xml()

server.listen server.get("port"), ->
	console.log "============"
	console.log "Local URL:"
	console.log "http://localhost:#{server.get("port")}/#{process.env.TUMBLR_CONSUMER_KEY}.rss"
	console.log "------------"
	console.log "Remote URL:"
	console.log feedURL