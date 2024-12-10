import { getUserPhotostreamFeed } from '~/utils/flickr/getUserPhotostreamFeed';
import { makeJsonFeedRoute } from '~/utils/makeJsonFeedRoute';

export const GET = makeJsonFeedRoute(getUserPhotostreamFeed);
