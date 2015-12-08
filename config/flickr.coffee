module.exports = {}

module.exports.auth = {
  nobrowser: true
  api_key:             process.env.FLICKR_API_KEY
  secret:              process.env.FLICKR_API_SECRET
  access_token:        process.env.FLICKR_ACCESS_TOKEN
  access_token_secret: process.env.FLICKR_ACCESS_TOKEN_SECRET
}

module.exports.photostream = {
  count: 50
  # page: 2
  # just_friends: false
  # single_photo: false
  include_self: false

  # https://www.flickr.com/services/api/flickr.photos.search.html
  extras: [
    # Not listed but useful:
    'realname'

    'description'
    # 'license'
    'date_upload'
    'date_taken'
    'owner_name'
    'icon_server'
    # 'original_format'
    'last_update'
    # 'geo'
    'tags'
    # 'machine_tags'
    'o_dims'
    # 'views'
    'media'
    'path_alias'
    # 'url_sq'
    # 'url_t'
    # 'url_s'
    # 'url_q'
    # 'url_m'
    # 'url_n'
    # 'url_z'
    # 'url_c'
    'url_l'
    # 'url_o'
  ]
}

module.exports.userPhotostream = {
  # Max 100
  per_page: 100

  user_id: null

  authenticated: true

  # page: 1

  ###
  content type
  ============
  1 for photos only
  2 for screenshots only
  3 for 'other' only
  4 for photos and screenshots
  5 for screenshots and 'other'
  6 for photos and 'other'
  7 for photos, screenshots, and 'other' (all)
  ###
  content_type: 7

  # https://www.flickr.com/services/api/flickr.photos.search.html
  extras: [
    # Not listed but useful:
    'realname'

    'description'
    # 'license'
    'date_upload'
    'date_taken'
    'owner_name'
    'icon_server'
    # 'original_format'
    'last_update'
    # 'geo'
    'tags'
    # 'machine_tags'
    'o_dims'
    # 'views'
    'media'
    'path_alias'
    # 'url_sq'
    # 'url_t'
    # 'url_s'
    # 'url_q'
    # 'url_m'
    # 'url_n'
    # 'url_z'
    # 'url_c'
    'url_l'
    # 'url_o'
  ]
}
