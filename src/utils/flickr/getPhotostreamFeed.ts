import { invariant } from '@workers-utils/common';
import * as s from 'superstruct';
import { getFeedItemForPhoto } from '~/utils/flickr/flickr';
import {
  getFlickrAuthDataFromKV,
  queryFlickrApi,
} from '~/utils/flickr/flickrApi';
import { photostreamSchema } from '~/utils/flickr/schemas';
import type { JSONFeedGetter } from '~/utils/makeJsonFeedRoute';

export const getPhotostreamFeed: JSONFeedGetter = async (context) => {
  const { uuid } = context.params;
  invariant(uuid, 'Missing uuid');

  const authData = await getFlickrAuthDataFromKV(uuid, context.locals);

  const getContactsPhotosOptions = {
    count: '50',
    extras: [
      // Not listed but useful:
      'realname',

      'description',
      // 'license',
      'date_upload',
      'date_taken',
      'owner_name',
      'icon_server',
      // 'original_format',
      'last_update',
      // 'geo',
      'tags',
      // 'machine_tags',
      'o_dims',
      // 'views',
      'media',
      'path_alias',
      // 'url_sq',
      // 'url_t',
      // 'url_s',
      // 'url_q',
      // 'url_m',
      // 'url_n',
      // 'url_z',
      // 'url_c',
      'url_l',
      'url_o',
    ].join(','),
  };

  const photostream = await queryFlickrApi(
    context.locals,
    authData,
    'flickr.photos.getContactsPhotos',
    getContactsPhotosOptions
  );

  s.assert(photostream, photostreamSchema);
  const feedItems = photostream.photos.photo.map((photo) =>
    getFeedItemForPhoto(
      photo,
      photo.pathalias === authData.nsid || photo.owner === authData.nsid
    )
  );

  return {
    title: 'Flickr Photostream',
    description: 'All yr photos broh',
    home_page_url: 'https://www.flickr.com/photos/' + authData.nsid,
    version: 'https://jsonfeed.org/version/1.1',
    items: feedItems,
  };
};
