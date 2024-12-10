import type { JSONFeed } from '~/jsonfeed';

export class JSONFeedResponse extends Response {
  constructor(data: JSONFeed, init?: ResponseInit) {
    super(JSON.stringify(data), {
      ...init,
      headers: {
        ...init?.headers,
        'Content-Type': 'application/feed+json; charset=utf-8',
      },
    });
  }
}
