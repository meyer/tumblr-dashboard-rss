import { getPhotostreamFeed } from '~/utils/flickr/getPhotostreamFeed';
import { makeJsonFeedRoute } from '~/utils/makeJsonFeedRoute';

export const GET = makeJsonFeedRoute(getPhotostreamFeed);
