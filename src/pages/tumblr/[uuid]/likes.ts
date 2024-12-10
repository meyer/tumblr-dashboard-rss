import { makeJsonFeedRoute } from '~/utils/makeJsonFeedRoute';
import { getLikesFeed } from '~/utils/tumblr/getLikesFeed';

export const GET = makeJsonFeedRoute(getLikesFeed);
