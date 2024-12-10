import { invariant } from '@workers-utils/common';
import type { JSONFeedGetter } from '~/utils/makeJsonFeedRoute';
import {
  getAvatarUrl,
  getTumblrAuthDataFromKV,
  getUserInfo,
} from '~/utils/tumblr/tumblrApi';

export const getLikesFeed: JSONFeedGetter = async (context) => {
  invariant(context.params.uuid, 'Missing UUID');
  const authData = await getTumblrAuthDataFromKV(
    context.params.uuid,
    context.locals
  );
  const userInfo = await getUserInfo(authData);

  return {
    version: 'https://jsonfeed.org/version/1.1',
    title: 'Tumblr likes for ' + userInfo.user.name,
    home_page_url: 'https://www.tumblr.com/likes',
    icon: getAvatarUrl('tumblr', 512),
    favicon: getAvatarUrl('tumblr', 128),
    description: 'wow, look at all these posts you liked',
    authors: [{ name: userInfo.user.name, url: userInfo.user.blogs[0]?.url }],
    items: [],
  };
};
