import { makeJsonFeedRoute } from '~/utils/makeJsonFeedRoute';
import { getUserFeed } from '~/utils/tumblr/getUserFeed';

export const GET = makeJsonFeedRoute(getUserFeed);
