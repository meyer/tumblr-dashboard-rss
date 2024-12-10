import { invariant } from '@workers-utils/common';
import type { JSONFeedGetter } from '~/utils/makeJsonFeedRoute';
import { getFeedItemsForPosts } from '~/utils/tumblr/getFeedItemsForPosts';
import {
  getAvatarUrl,
  getBlogPosts,
  getTumblrAuthDataFromKV,
} from '~/utils/tumblr/tumblrApi';

const userIdRegex = /^[a-z0-9-]+$/g;

export const getUserFeed: JSONFeedGetter = async (context) => {
  invariant(context.params.uuid, 'Missing UUID');
  invariant(context.params.userId, 'Missing userId');

  if (!userIdRegex.test(context.params.userId)) {
    throw new Error('Invalid user ID');
  }

  const authData = await getTumblrAuthDataFromKV(
    context.params.uuid,
    context.locals
  );

  const { blog, posts } = await getBlogPosts(authData, context.params.userId, {
    notes_info: true,
    reblog_info: true,
  });

  const feedUrl = new URL(context.url);
  feedUrl.pathname = '';
  feedUrl.search = '';

  return {
    version: 'https://jsonfeed.org/version/1.1',
    title: `Tumblr \u2027 ${blog.title}`,
    description: blog.description,
    feed_url: feedUrl.toString(),
    home_page_url: blog.url,
    authors: [{ name: blog.name, url: blog.url }],
    icon: getAvatarUrl(blog.name, 512),
    favicon: getAvatarUrl(blog.name, 128),
    items: getFeedItemsForPosts(posts),
  };
};
