import { invariant } from '@workers-utils/common';
import * as s from 'superstruct';
import { getFeedItemForPhoto } from '~/utils/flickr/flickr';
import {
  getFlickrAuthDataFromKV,
  queryFlickrApi,
} from '~/utils/flickr/flickrApi';
import { photostreamSchema } from '~/utils/flickr/schemas';
import type { JSONFeedGetter } from '~/utils/makeJsonFeedRoute';

export const getUserPhotostreamFeed: JSONFeedGetter = async (context) => {
  const { uuid, nsid } = context.params;
  invariant(nsid, 'Missing nsid');
  invariant(uuid, 'Missing uuid');
  const authData = await getFlickrAuthDataFromKV(uuid, context.locals);

  const photostream = await queryFlickrApi(
    context.locals,
    authData,
    'flickr.people.getPhotos',
    {
      user_id: nsid,
      per_page: '100',
      safe_search: '3',
      content_types: [
        0, // photos
        1, // screenshots
        2, // "other"
        3, // virtual photos
      ].join(','),
      // https://www.flickr.com/services/api/flickr.photos.search.html
      extras: [
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
    }
  );

  s.assert(photostream, photostreamSchema);
  const feedItems = photostream.photos.photo.map((photo) =>
    getFeedItemForPhoto(photo, photo.pathalias === nsid || photo.owner === nsid)
  );

  return {
    title: `Flickr Photostream for ${nsid}`,
    description: `All photos taken by ${nsid}`,
    home_page_url: `http://www.flickr.com/photos/${nsid}`,
    version: 'https://jsonfeed.org/version/1.1',
    items: feedItems,
  };
};
