import { makeJsonFeedRoute } from '~/utils/makeJsonFeedRoute';
import { getDashboardFeed } from '~/utils/tumblr/getDashboardFeed';

export const GET = makeJsonFeedRoute(getDashboardFeed);
