const moment = require('moment')
const {img} = require('./index')

const niceDateStringFormat = 'MMMM Do YYYY [at] h:mm:ssa'

function getFlickrImageURL(p) {
  /*
  Image Sizes
  ===========
  s   small square 75x75
  q   large square 150x150
  t   thumbnail, 100 on longest side
  m   small, 240 on longest side
  n   small, 320 on longest side
  -   medium, 500 on longest side
  z   medium 640, 640 on longest side
  c   medium 800, 800 on longest side†
  b   large, 1024 on longest side*
  h   large 1600, 1600 on longest side†
  k   large 2048, 2048 on longest side†
  o   original image, either a jpg, gif or png, depending on source format
  */

  const imageSize = 'b'

  /*
  getContactsPhotos Structure
  ===========================
  {
    "farm": 1,
    "id": "21805173440",
    "isfamily": 0,
    "isfriend": 0,
    "ispublic": 1,
    "owner": "37386863@N03",
    "secret": "9784d42b5f",
    "server": "729",
    "title": "\u00a9 Richard Curtis",
    "username": "leica_camera"
  }

  with extras:
  ============
  {
    "id": "21805173440",
    "secret": "9784d42b5f",
    "server": "729",
    "farm": 1,
    "owner": "37386863@N03",
    "username": "leica_camera",
    "title": "© Richard Curtis",
    "ispublic": 1,
    "isfriend": 0,
    "isfamily": 0,
    "description": {
      "_content": "On his trip with the BBC to Mongolia, Richard Curtis captured the atmosphere of the eagle hunters' traditional Nadaam Games in his black and white series: <a href=\"http://bit.ly/RichardCurtisLeicaBlog\" rel=\"nofollow\">bit.ly/RichardCurtisLeicaBlog</a>\n\n\n"
    },
    "o_width": "1200",
    "o_height": "900",
    "dateupload": "1444136052",
    "datetaken": "2015-10-06 14:50:30",
    "datetakengranularity": 0,
    "datetakenunknown": "1",
    "ownername": "leica_camera",
    "iconserver": "8660",
    "iconfarm": 9,
    "tags": "horizontal msystem richardcurtis",
    "media": "photo",
    "media_status": "ready",
    "url_l": "https://farm1.staticflickr.com/729/21805173440_9784d42b5f_b.jpg",
    "height_l": "768",
    "width_l": "1024",
    "pathalias": "leica_camera"
  }

  */

  return `https://farm${p.farm}.staticflickr.com/${p.server}/${p.id}_${p.secret}_${imageSize}.jpg`
}

function getBuddyIconURL(p) {
  if (!p.iconserver || p.iconserver <= 0) {
    return 'https://www.flickr.com/images/buddyicon.gif'
  }
  return `http://farm${p.iconfarm}.staticflickr.com/${p.iconserver}/buddyicons/${p.owner}.jpg`
}

function getPhotoPageURL (p) {
  `https://www.flickr.com/photos/${p.pathalias || p.owner}/${p.id}`
}

function getUserURL (p) {
  `https://www.flickr.com/photos/${p.pathalias || p.owner}/`
}

function getUserRepresentation (p) {
  return `${img(getBuddyIconURL(p), 24, 24, {style: 'vertical-align: middle'})} ${getUserName(p, true)}`
}

function getDescription (p) {
  const desc = (
    p.description &&
    typeof p.description._content === 'string' &&
    p.description._content || ''
  ).trim()

  if (desc.length > 0) {
    return `<blockquote><p>${desc}</p></blockquote>`
  } else {
    return '<!-- No description set -->'
  }
}

function getUserName(p, withLink) {
  withLink = withLink || false

  let pathAlias = p.pathalias || p.ownername
  if (withLink) {
    pathAlias = `<a href='${getUserURL(p)}'>${pathAlias}</a>`
  }

  if (p.realname) {
    return `${p.realname} (${pathAlias})`
  } else {
    if (p.ownername === p.pathalias) {
      return pathAlias
    } else {
      return `${p.ownername} (${pathAlias})`
    }
  }
}

function getTitle(p) {
  if (p.title.trim() !== '') {
    return `${getUserName(p)}: ${p.title.trim()}`
  }
  return `${getUserName(p)}: [no title]`
}

function getTagLinks(p) {
  if (p.tags.trim() === '') { return false }
  return p.tags.split(' ').map(t => `<a href='https://www.flickr.com/search/?tags=${t}'>#${t}</a>`).join(', ')
}

function getFooter(p) {
  const tagLinks = getTagLinks(p)
  const ret = []

  if (tagLinks) {
    ret.push(`<p>Tags: ${tagLinks}</p>`)
  }

  const takenDate = moment(new Date(p.datetaken))
  const uploadDate = moment(new Date(p.dateupload * 1000))

  // diff = getTimeDiffString(takenDate.diff(uploadDate), 'later')

  ret.push(`<p>Uploaded by ${getUserRepresentation(p)}</p>`)
  ret.push(`<p>Taken on ${takenDate.format(niceDateStringFormat)} (local time)</p>`)
  ret.push(`<p>Uploaded on ${uploadDate.format(niceDateStringFormat)}</p>`)

  return ret.join('\n')
}

exports.buildRSSItems = function buildRSSItems(photos) {
  return photos.map(photo => ({
    title:       getTitle(photo),
    description: [].concat(
      `<div>${img(photo.url_l, photo.width_l, photo.height_l)}</div>`,
      getDescription(photo),
      getFooter(photo)
    ).join('\n\n'),
    url:         getPhotoPageURL(photo),
    guid:        photo.id,
    categories:  photo.tags.split(' '),
    author:      getUserName(photo),
    date:        new Date(photo.dateupload * 1000),
  }))
}
