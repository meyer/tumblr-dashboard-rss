import type { FeedItem } from '~/jsonfeed';
import type { FlickrPhoto } from '~/utils/flickr/schemas';
import { img } from '~/utils/utils';

// const niceDateStringFormat = 'MMMM Do YYYY [at] h:mm:ssa';

export const getFlickrImageURL = (p: FlickrPhoto) => {
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

  const imageSize = 'b';

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

  return `https://farm${p.farm}.staticflickr.com/${p.server}/${p.id}_${p.secret}_${imageSize}.jpg`;
};

const getBuddyIconURL = (p: FlickrPhoto) => {
  if (!p.iconserver || !p.iconfarm) {
    return 'https://www.flickr.com/images/buddyicon.gif';
  }
  return `http://farm${p.iconfarm}.staticflickr.com/${p.iconserver}/buddyicons/${p.owner}.jpg`;
};

const getPhotoPageURL = (p: FlickrPhoto) => {
  return `https://www.flickr.com/photos/${p.pathalias || p.owner}/${p.id}`;
};

const getUserURL = (p: FlickrPhoto) => {
  return `https://www.flickr.com/photos/${p.pathalias || p.owner}/`;
};

const getUserRepresentation = (p: FlickrPhoto) => {
  return `${img(getBuddyIconURL(p), 24, 24, { style: 'vertical-align: middle' })} ${getUserName(p, true)}`;
};

function getDescription(p: FlickrPhoto) {
  const desc = (
    (p.description &&
      typeof p.description._content === 'string' &&
      p.description._content) ||
    ''
  ).trim();

  if (desc.length > 0) {
    return `<blockquote><p>${desc}</p></blockquote>`;
  }
  return '<!-- No description set -->';
}

export const getUserName = (p: FlickrPhoto, withLink = false) => {
  let pathAlias = p.pathalias || p.ownername;
  if (withLink) {
    pathAlias = `<a href='${getUserURL(p)}'>${pathAlias}</a>`;
  }

  if (p.realname) {
    return `${p.realname} (${pathAlias})`;
  }
  if (p.ownername === p.pathalias) {
    return pathAlias;
  }
  return `${p.ownername} (${pathAlias})`;
};

const getTitle = (p: FlickrPhoto, isUserSpecific: boolean) => {
  const titlePrefix = isUserSpecific ? '' : `${getUserName(p)}: `;
  if (p.title.trim() !== '') {
    return `${titlePrefix}${p.title.trim()}`;
  }
  return `${titlePrefix}[no title]`;
};

function getTagLinks(p: FlickrPhoto) {
  if (p.tags.trim() === '') {
    return false;
  }
  return p.tags
    .split(' ')
    .map((t) => `<a href='https://www.flickr.com/search/?tags=${t}'>#${t}</a>`)
    .join(', ');
}

function getFooter(p: FlickrPhoto) {
  const tagLinks = getTagLinks(p);
  const ret = [];

  if (tagLinks) {
    ret.push(`<p>Tags: ${tagLinks}</p>`);
  }

  const takenDate = new Date(p.datetaken);
  const uploadDate = new Date(Number.parseInt(p.dateupload, 10) * 1000);

  // diff = getTimeDiffString(takenDate.diff(uploadDate), 'later')

  ret.push(`<p>Uploaded by ${getUserRepresentation(p)}</p>`);
  ret.push(`<p>Taken on ${takenDate.toUTCString()}</p>`);
  ret.push(`<p>Uploaded on ${uploadDate.toUTCString()}</p>`);

  return ret.join('\n');
}

export const getFeedItemForPhoto = (
  photo: FlickrPhoto,
  isUserSpecific = false
): FeedItem => ({
  title: getTitle(photo, isUserSpecific),
  content_html: [
    '<div>' +
      (photo.url_o && photo.o_width && photo.o_height
        ? img(
            photo.url_o,
            Number.parseInt(photo.o_width, 10),
            Number.parseInt(photo.o_height, 10)
          )
        : img(photo.url_l, photo.width_l, photo.height_l)) +
      '</div>',
    getDescription(photo),
    getFooter(photo),
  ].join('\n\n'),
  image: photo.url_o || photo.url_l,
  banner_image: photo.url_o || photo.url_l,
  external_url: getPhotoPageURL(photo),
  id: photo.id,
  tags: photo.tags.trim() ? photo.tags.split(' ') : undefined,
  authors: [
    {
      name: getUserName(photo),
      // avatar: getBuddyIconURL(photo),
      avatar: `https://live.staticflickr.com/${photo.iconserver}/buddyicons/${photo.owner}_r.jpg`,
      url: `https://www.flickr.com/people/${photo.owner}`,
    },
  ],
  date_published: new Date(
    Number.parseInt(photo.dateupload, 10) * 1000
  ).toUTCString(),
  date_modified: new Date(
    Number.parseInt(photo.lastupdate, 10) * 1000
  ).toUTCString(),
});
