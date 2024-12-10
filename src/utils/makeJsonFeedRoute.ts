import type { APIContext, APIRoute } from 'astro';
import type { JSONFeed } from '~/jsonfeed';
import { JSONFeedResponse } from '~/utils/JSONFeedResponse';

export type JSONFeedGetter = (context: APIContext) => Promise<JSONFeed>;

export const makeJsonFeedRoute = (
  getFeed: (context: APIContext) => Promise<JSONFeed>
): APIRoute => {
  return async (context) => {
    try {
      return new JSONFeedResponse(await getFeed(context));
    } catch (error) {
      console.error(error);
      return new Response(
        'Something went wrong while generating this JSON feed',
        { status: 500 }
      );
    }
  };
};
