tumblr = require 'tumblr'
RSVP = require 'rsvp'
lodash = require 'lodash'

{ucfirst, img, howmany, getTimeDiffString, padLeft} = require('./index')

tumblrConfig = require '../config/tumblr'

user = new tumblr.User(tumblrConfig)

module.exports.getBlogInfo = ->
  new RSVP.Promise (resolve, reject) ->
    user.info (err, response) ->
      if err
        reject(err)
      else
        resolve(response.user)

module.exports.getPosts = (src, postCount = 60) ->
  limit = 20
  ic = Math.ceil(postCount / limit)
  mod = postCount % limit
  offset = 0

  typeSingular = ''
  typePlural = ''
  responseKey = ''

  switch src
    when 'dashboard'
      typeSingular = 'DASHBOARD POST'
      typePlural = 'DASHBOARD POSTS'
      responseKey = 'posts'
    when 'likes'
      typeSingular = 'LIKED POST'
      typePlural = 'LIKED POSTS'
      responseKey = 'liked_posts'
    else
      throw "src `#{src}` not supported"

  console.log "POSTS TO LOAD: #{howmany postCount, "post"} in #{howmany ic, "batch", "batches"}"

  # Return array of promises
  promises = [1..ic].map (idx) ->
    batchSize = if idx == ic && mod != 0 then mod else limit

    console.log "* LOADING #{howmany batchSize, typeSingular, typePlural}"

    return new RSVP.Promise (resolve, reject) ->
      options = {
        reblog_info: true
        # notes_info: true
        limit: batchSize
        offset: offset
      }

      user[src] options, (error, response) ->
        if error
          reject(error)
          throw error
        else
          resolve(response[responseKey])

      offset += batchSize

  RSVP.all(promises).then (posts) ->
    Array.prototype.concat.apply([], posts)

module.exports.buildRSSItems = (posts, rssConfig={showLikeStatus: true}) ->
  feedItems = posts.map (post, idx, arr) ->
    item = null

    console.log "- Post #{lodash.padLeft idx+1, "#{arr.length}".length, ' '} of #{arr.length}: #{lodash.padLeft post.id, 13, ' '} (#{post.type})"

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
      # else
      #   console.log "post author is the same as reblogger"

      post_title.push "#{post.blog_name} ⇄ #{reblog_src}"
    else
      if post.type == "answer"
        post_title.push "#{post.blog_name} → #{post.asking_name}"
      else
        post_title.push "#{post.blog_name}"

    post_footer.push "<p>#{howmany(post.note_count, "note")}</p>"
    post_footer.push "<p>#{tags.join(", ")}</p>" if tags.length > 0
    post_footer.push "<p>Source: <a href='#{post.source_url}'>#{post.source_title}</a></p>" if post.source_url
    post_footer.push "<p>&check; Liked</p>" if post.liked && rssConfig.showLikeStatus

    # tumblr://x-callback-url/blog?blogName=tumblr-username
    # tumblr://x-callback-url/blog?blogName=tumblr-username&postID=post-id
    post_footer.push "<p><a href='tumblr://x-callback-url/blog?blogName=#{post.blog_name}&postID=#{post.id}'>View in Tumblr app</a></p>"

    switch post.type
      when "photo", "link"
        desc = []

        if post.caption then desc.push "#{post.caption}".trim()

        # Link posts
        if post.description then desc.push "#{post.description}".trim()
        if post.excerpt then desc.push "#{post.excerpt}".trim()


        if post.photos
          return post.photos.map((p, idx, arr) ->
            titleSuffix = ""
            if arr.length > 1
              titleSuffix = " (#{idx+1} of #{arr.length})"

            p.title = post_title.join(" • ") + titleSuffix

            # Photo posts
            caption = if p.caption && p.caption != '' then "<p>#{p.caption.trim()}</p>" else []

            p.desc = [].concat(
              '<div>'
              img(p.original_size.url, p.original_size.width, p.original_size.height)
              '</div>'
              '<blockquote>'
              caption
              desc
              '</blockquote>'
              post_footer
            ).join('\n\n')

            p.guid = p.original_size.url

            post_date = new Date(post.date)
            p.date = new Date(post_date.getTime() + idx * 1000)

            p
          ).reverse().map (p) ->
            {
              title:       p.title
              description: p.desc
              url:         post.post_url
              guid:        p.guid
              categories:  post.tags
              author:      post.blog_name
              date:        p.date
            }
        else
          console.log "!!! #{post.type} without photos"
          if post.type == 'link'
            post_content.push "<h3>#{post_title.join(" • ")} <a href='#{post.url}'>#</a></h3>"

            post_content.push '<blockquote>'
            post_content.push desc
            post_content.push '</blockquote>'

          else
            post_content.push "<h3>Empty Photo Post :....(</h3>"

      when "text"
        post_content.push post.body

      when "quote"
        post_content.push '<blockquote>'
        post_content.push "<p>#{post.text}</p>"
        post_content.push "<p>&mdash;&thinsp;#{post.source}</p>"
        post_content.push '</blockquote>'

      when "chat"
        post_content.push "<table>"

        post.dialogue.forEach (line) ->
          post_content.push """
          <tr>
            <th align="left">#{line.name}</th>
            <td>#{line.phrase}</td>
          </tr>
          """

        post_content.push "</table>"

      when "audio"
        post_content.push post.player
        post_content.push post.caption

      when "video"
        post_content.push post.player.pop().embed_code

      when "answer"
        asker = [
          "<a href='#{post.asking_url}'>"
          img("http://api.tumblr.com/v2/blog/#{post.asking_name}.tumblr.com/avatar/128", 128, 128, {style: "vertical-align: middle"}),
          post.asking_name
          '</a>'
        ].join('')

        if post.asking_name == "Anonymous"
          asker = [
            img("https://secure.assets.tumblr.com/images/anonymous_avatar_128.gif", 128, 128, {style: "vertical-align: middle"})
            post.asking_name
          ].join('')

        post_content.push "<blockquote><p>#{asker}: #{post.question}</p></blockquote>"
        post_content.push post.answer


      else
        console.log "Unsupported post type: #{post.type}"
        post_content.push "#{ucfirst post.type} posts not supported (yet!)"


    {
      title:       post_title.join(" • ")
      description: [].concat(
        post_content,
        post_footer
      ).join("\n\n")
      url:         post.post_url
      guid:        post.post_url
      categories:  post.tags
      author:      post.blog_name
      date:        post.date
    }

  Array.prototype.concat.apply([], feedItems)