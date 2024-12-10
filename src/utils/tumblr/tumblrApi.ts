import { invariant } from '@workers-utils/common';
import * as s from 'superstruct';
import type { ObjectSchema } from 'superstruct/dist/utils';

const base = 'https://api.tumblr.com/v2';

const getQueryString = <T extends Record<string, any>>(params?: T) => {
  const queryParams =
    params &&
    new URLSearchParams(
      Object.entries(params).map(([k, v]) => [k, v.toString()])
    ).toString();
  return queryParams ? '?' + queryParams : '';
};

const baseResponseSchema = s.type({
  meta: s.object({
    status: s.number(),
    msg: s.string(),
  }),
  response: s.unknown(),
});

export const authCodeSchema = s.type({
  /** The OAuth2 access token */
  access_token: s.string(),
  /** The access token TTL in seconds */
  expires_in: s.integer(),
  /** The type of the access token */
  token_type: s.string(),
  /** The OAuth2 access token scopes */
  scope: s.string(),
  /** An OAuth2 refresh token (if offline_access scope was requested) */
  refresh_token: s.string(),
});

export type KvTokenData = s.Infer<typeof kvTokenSchema>;

const kvTokenSchema = s.assign(
  authCodeSchema,
  s.object({
    expires_at: s.integer(),
  })
);

const imageSizeSchema = s.type({
  /** Width of the image, in pixels */
  width: s.number(),
  /** Height of the image, in pixels */
  height: s.number(),
  /** Location of the image file (either a JPG, GIF, or PNG) */
  url: s.string(),
});

const legacyBasePostSchema = s.type({
  /** The short name used to uniquely identify a blog */
  blog_name: s.string(),

  /** The post's unique ID */
  id: s.number(),

  /** The post's unique ID as a String, for clients that don't support 64-bit integers */
  id_string: s.string(),

  /**
   * The post's unique "genesis" ID as a String
   * Only available to the post owner in certain circumstances
   */
  genesis_post_id: s.optional(s.string()),

  /** The location of the post */
  post_url: s.string(),

  /**
   * The URL of the parent post, if this is a reblog
   * Only available if the post is a reblog
   */
  parent_post_url: s.optional(s.string()),

  /** The type of postSee the type request parameter */
  type: s.string(),

  /** The time of the post, in seconds since the epoch */
  timestamp: s.number(),

  /** The GMT date and time of the post, as a string */
  date: s.string(),

  /** The post format: html or markdown */
  format: s.string(),

  /** The key used to reblog this postSee the /post/reblog method */
  reblog_key: s.string(),

  /** Tags applied to the post */
  tags: s.array(s.string()),

  /**
   * Indicates whether the post was created via the Tumblr bookmarklet
   * Exists only if true
   */
  bookmarklet: s.optional(s.boolean()),

  /**
   * Indicates whether the post was created via mobile/email publishing
   * Exists only if true
   */
  mobile: s.optional(s.boolean()),

  /**
   * The URL for the source of the content (for quotes, reblogs, etc.)
   * Exists only if there's a content source
   */
  source_url: s.optional(s.string()),

  /**
   * The title of the source site
   * Exists only if there's a content source
   */
  source_title: s.optional(s.string()),

  /**
   * Indicates if a user has already liked a post or not
   * Exists only if the request is fully authenticated with OAuth.
   */
  liked: s.optional(s.boolean()),

  /** Indicates the current state of the postStates are published, queued, draft and private */
  state: s.string(),

  /** Indicates whether the post is stored in the Neue Post Format */
  is_blocks_post_format: s.boolean(),

  /**
   * Indicates whether push notifications and activity items are muted for this post by its author.
   * Only available to the post owner in certain circumstances
   */
  muted: s.optional(s.boolean()),

  /** See note below. Only available to the post owner in certain circumstances */
  mute_end_timestamp: s.optional(s.number()),

  /** The total number of post available for this request, useful for paginating through results */
  total_posts: s.optional(s.number()),

  /** Number of notes on a post */
  note_count: s.number(),
});

const makeLegacyPostSchema = <T extends ObjectSchema>(schema: T) =>
  s.assign(legacyBasePostSchema, s.type(schema));

const legacyTextPostSchema = makeLegacyPostSchema({
  type: s.literal('text'),
  title: s.optional(s.nullable(s.string())),
  body: s.string(),
});

const exifDataSchema = s.type({
  /** Camera model */
  Camera: s.string(),

  /** ISO */
  ISO: s.number(),

  /** Aperture */
  Aperture: s.string(),

  /** Exposure time */
  Exposure: s.string(),

  /** Focal length */
  FocalLength: s.string(),
});

const legacyPhotoSchema = s.type({
  /** User supplied caption for the individual photo (Photosets only) */
  caption: s.optional(s.string()),

  /** The photo at its original size */
  original_size: imageSizeSchema,

  /** alternate photo sizes, each with: */
  alt_sizes: s.array(imageSizeSchema),

  /** EXIF data */
  exif: s.optional(exifDataSchema),
});

const legacyPhotoPostSchema = makeLegacyPostSchema({
  type: s.literal('photo'),
  /** The user-supplied caption */
  caption: s.string(),
  /** The width of the photo or photoset */
  width: s.optional(s.number()),
  /** The height of the photo or photoset */
  height: s.optional(s.number()),
  /** Photo objects */
  photos: s.array(legacyPhotoSchema),
});

const legacyQuotePostSchema = makeLegacyPostSchema({
  type: s.literal('quote'),
  /** The text of the quote (can be modified by the user when posting) */
  text: s.string(),
  /** Full HTML for the source of the quote Example: <a href="...">Steve Jobs</a> */
  source: s.string(),
});

const legacyLinkPostSchema = makeLegacyPostSchema({
  type: s.literal('link'),
  /** The title of the page the link points to */
  title: s.string(),
  /** A user-supplied description */
  description: s.string(),
  /** The link! */
  url: s.string(),
  /** The author of the article the link points to */
  link_author: s.string(),
  /** An excerpt from the article the link points to */
  excerpt: s.string(),
  /** The publisher of the article the link points to */
  publisher: s.string(),
  /** Photo objects */
  photos: s.array(legacyPhotoSchema),
});

const legacyChatPostSchema = makeLegacyPostSchema({
  type: s.literal('chat'),
  /** The optional title of the post */
  title: s.optional(s.string()),
  /** The full chat body */
  body: s.string(),
  /** Array of objects */
  dialogue: s.array(
    s.type({
      /** Name of the speaker */
      name: s.string(),
      /** Label of the speaker */
      label: s.string(),
      /** Text. */
      phrase: s.string(),
    })
  ),
});

const legacyAudioPostSchema = makeLegacyPostSchema({
  type: s.literal('audio'),
  /** The user-supplied caption */
  caption: s.string(),
  /** HTML for embedding the audio player */
  player: s.string(),
  /** Number of times the audio post has been played */
  plays: s.number(),
  /** Location of the audio file's ID3 album art image */
  album_art: s.string(),
  /** The audio file's ID3 artist value */
  artist: s.string(),
  /** The audio file's ID3 album value */
  album: s.string(),
  /** The audio file's ID3 title value */
  track_name: s.string(),
  /** The audio file's ID3 track value */
  track_number: s.number(),
  /** The audio file's ID3 year value */
  year: s.number(),
});

const legacyVideoPostSchema = makeLegacyPostSchema({
  type: s.literal('video'),

  /** The user-supplied caption	 */
  caption: s.string(),
  /** of embed objects	Object fields within the array:	Values vary by video source */
  player: s.array(
    s.type({
      /** Width of video player, in pixels	 */
      width: s.number(),
      /** HTML for embedding the video player */
      embed_code: s.string(),
    })
  ),
});

const legacyAnswerPostSchema = makeLegacyPostSchema({
  type: s.literal('answer'),
  /** The blog that sent this ask, or answered it if it was privately answered */
  asking_name: s.string(),
  /** The blog URL that sent this ask, or answered it if it was privately answered */
  asking_url: s.string(),
  /** The question being asked */
  question: s.string(),
  /** The answer given */
  answer: s.string(),
});

export type LegacyPost = s.Infer<typeof legacyPostSchema>;

const legacyPostSchema = s.union([
  legacyTextPostSchema,
  legacyPhotoPostSchema,
  legacyQuotePostSchema,
  legacyLinkPostSchema,
  legacyChatPostSchema,
  legacyAudioPostSchema,
  legacyVideoPostSchema,
  legacyAnswerPostSchema,
]);

export const getRefreshToken = async (
  env: WorkerEnv,
  refresh_token: string
): Promise<KvTokenData> => {
  const result = await fetch(`${base}/oauth2/token`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      grant_type: 'refresh_token',
      client_id: env.TUMBLR_OAUTH_CONSUMER_KEY,
      client_secret: env.TUMBLR_OAUTH_CONSUMER_SECRET,
      refresh_token,
    }),
  });
  const body = await result.text();
  invariant(
    result.status === 200,
    `getRefreshToken error: ${result.status} ${result.statusText} -- ${body}`
  );
  const jsonBody = JSON.parse(body);
  s.assert(jsonBody, authCodeSchema);

  return {
    ...jsonBody,
    // expire two minutes early, just in case
    expires_at: Date.now() + (jsonBody.expires_in - 2) * 1000,
  };
};

export const getTumblrAuthDataFromKV = async (
  uuid: string,
  locals: App.Locals
): Promise<KvTokenData> => {
  const kvResult = await locals.runtime.env.AUTH.get('tumblr:' + uuid, 'json');
  invariant(kvResult, 'No auth data for the requested key');
  s.assert(
    kvResult,
    kvTokenSchema,
    'kvResult does not match the kvTokenSchema'
  );
  if (kvResult.expires_at > Date.now()) {
    return kvResult;
  }

  console.log('Token is invalid, refreshing...');
  const newData = await getRefreshToken(
    locals.runtime.env,
    kvResult.refresh_token
  );
  await locals.runtime.env.AUTH.put(`tumblr:${uuid}`, JSON.stringify(newData));
  console.log(
    'New token expires at %s',
    new Date(newData.expires_at).toISOString()
  );
  return newData;
};

const buildApiFunction = <T, S, A extends unknown[]>(
  getUrl: (...args: A) => string,
  schema: s.Struct<T, S> | ((data: unknown) => s.Infer<s.Struct<T, S>>)
): ((
  authData: KvTokenData,
  ...args: A
) => Promise<s.Infer<s.Struct<T, S>>>) => {
  return async (authData: KvTokenData, ...args: A) => {
    const path = getUrl(...args);
    console.log(`GET ${base}${path}`);
    const result = await fetch(`${base}${path}`, {
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'social media RSS 1.0',
        Authorization: `Bearer ${authData.access_token}`,
      },
      method: 'GET',
    });
    const body = await result.json();
    s.assert(body, baseResponseSchema);

    if (body.meta.status !== 200) {
      throw new Error(
        'Received a non-200 status: ' + body.meta.status + ' ' + body.meta.msg
      );
    }

    if (typeof schema === 'function') {
      return schema(body.response);
    }
    s.assert(body.response, schema, 'API response does not match schema');
    return body.response;
  };
};

const userBlogSchema = s.type({
  /** The short name of the blog */
  name: s.string(),
  /** The URL of the blog */
  url: s.string(),
  /** The title of the blog */
  title: s.string(),
  /** Indicates if this is the user's primary blog */
  primary: s.boolean(),
  /** Total count of followers for this blog */
  followers: s.number(),
  /** Indicate if posts are tweeted */
  tweet: s.enums(['auto', 'Y', 'N']),
  /** Indicates whether a blog is public or private */
  type: s.enums(['public', 'private']),
});

export const getUserInfo = buildApiFunction(
  () => '/user/info',
  s.type({
    user: s.type({
      /** The number of blogs the user is following */
      following: s.integer(),
      /** The default posting format - html, markdown, or raw */
      default_post_format: s.enums(['html', 'markdown', 'raw']),
      /** The user's tumblr short name */
      name: s.string(),
      /** The total count of the user's likes */
      likes: s.integer(),
      /**  */
      blogs: s.array(userBlogSchema),
    }),
  })
);

const avatarSchema = s.type({
  width: s.number(),
  height: s.number(),
  url: s.string(),
});

const blogSchema = s.type({
  /** The display title of the blog */
  title: s.string(),
  /** The total number of posts to this blog */
  posts: s.integer(),
  /** The short blog name that appears before tumblr.com in a standard blog hostname */
  name: s.string(),
  /** The time of the most recent post, in seconds since the epoch */
  updated: s.integer(),
  /** You guessed it! The blog's description */
  description: s.string(),
  /** Indicates whether the blog allows questions */
  ask: s.boolean(),
  /** Indicates whether the blog allows anonymous questions; returned only if ask is true */
  ask_anon: s.optional(s.boolean()),
  /** Whether you're following the blog, returned only if this request has an authenticated user */
  followed: s.boolean(),
  /** Number of likes for this user, returned only if this is the user's primary blog and sharing of likes is enabled */
  likes: s.optional(s.integer()),
  /** Indicates whether this blog has been blocked by the calling user's primary blog; returned only if there is an authenticated user making this call */
  is_blocked_from_primary: s.optional(s.boolean()),
  /** An array of avatar objects, each a different size, which should each have a width, height, and URL. */
  avatar: s.array(avatarSchema),
  /** The blog's url */
  url: s.string(),
});

export const getBlogInfo = buildApiFunction(
  (blogIdentifier: string) => `/blog/${blogIdentifier}/info`,
  s.type({ blog: blogSchema })
);

type AvatarSize = 16 | 24 | 30 | 40 | 48 | 64 | 96 | 128 | 512;

export const getAvatarUrl = (blogIdentifier: string, size: AvatarSize) =>
  `${base}/blog/${blogIdentifier}/avatar/${size}`;

interface GetDashboardArgs {
  /** The number of results to return: 1-20, inclusive. Default: 20 */
  limit?: number;

  /** Post number to start at. Default: 0 (first post) */
  offset?: number;

  /**
   * The type of post to return.
   *
   * Default: none (return all types)
   */
  type?:
    | 'text'
    | 'photo'
    | 'quote'
    | 'link'
    | 'chat'
    | 'audio'
    | 'video'
    | 'answer';

  /**
   * Return posts that have appeared after this ID.
   * Use this parameter to page through the results: first get a set of posts,
   * and then get posts since the last ID of the previous set.
   *
   * Default: 0
   */
  since_id?: number;

  /**
   * Indicates whether to return reblog information (specify true or false).
   * Returns the various reblogged_ fields.
   *
   * Default: false
   */
  reblog_info?: boolean;
  /**
   * Indicates whether to return notes information (specify true or false).
   * Returns note count and note metadata.
   *
   * Default: false
   */
  notes_info?: boolean;
  /**
   * Returns posts' content in NPF format instead of the legacy format.
   *
   * Default: false
   */
  npf?: boolean;
}

export const getDashboard = buildApiFunction(
  (args?: GetDashboardArgs) => '/user/dashboard' + getQueryString(args),
  (data) => {
    s.assert(data, s.object({ posts: s.array(s.unknown()) }));
    const posts: s.Infer<typeof legacyPostSchema>[] = [];
    for (const post of data.posts) {
      s.assert(post, legacyPostSchema);
      posts.push(post);
    }
    return posts;
  }
);

interface GetUserLikesArgs {
  /**
   * The number of results to return: 1-20, inclusive.
   *
   * Default: 20
   */
  limit?: number;
  /**
   * Liked post number to start at
   *
   * Default: 0 (first post)
   */
  offset?: number;
  /**
   * Retrieve posts liked before the specified timestamp */
  before?: number;
  /** Retrieve posts liked after the specified timestamp	None */
  after?: number;
}

export const getUserLikes = buildApiFunction(
  (args?: GetUserLikesArgs) => '/user/likes' + getQueryString(args),
  s.type({
    liked_posts: s.array(legacyPostSchema),
    liked_count: s.integer(),
  })
);

interface GetBlogPostsParams {
  /** The type of post to return. Specify one of the following: text, quote, link, answer, video, audio, photo, chat */
  type?: string;

  /** A specific post ID. Returns the single post specified or (if not found) a 404 error. */
  id?: number;

  /** Limits the response to posts with the specified tag(s) */
  tag?: string | string[];

  /**
   * The number of posts to return: 1-20, inclusive.
   *
   * Defaults to 20
   */
  limit?: number;

  /**
   * Post number to start at
   *
   * Defaults to 0 (first post)
   */
  offset?: number;

  /**
   * Indicates whether to return reblog information (specify true or false). Returns the various reblogged_ fields.
   * Defaults to false
   */
  reblog_info?: boolean;

  /**
   * Indicates whether to return notes information (specify true or false). Returns note count and note metadata.
   *
   * Defaults to false
   */
  notes_info?: boolean;

  /**
   * Specifies the post format to return, other than HTML: text – Plain text, no HTML; raw – As entered by the user (no post-processing); if the user writes in Markdown, the Markdown will be returned rather than HTML
   * Defaults to None (HTML)
   */
  filter?: 'text' | 'raw';

  /** Returns posts published before a specified Unix timestamp, in seconds. */
  before?: number;

  /** Returns posts published after a specified Unix timestamp, in seconds. */
  after?: number;

  /**
   * A specific sort order, "desc" for descending, "asc" for ascending.
   *
   * Defaults to "desc"
   */
  sort?: string;

  /** Returns posts' content in NPF format instead of the legacy format. */
  npf?: boolean;
}

export const getBlogPosts = buildApiFunction(
  (blogIdentifier: string, args?: GetBlogPostsParams) =>
    `/blog/${blogIdentifier}/posts` + getQueryString(args),
  s.type({
    blog: blogSchema,
    posts: s.array(legacyPostSchema),
  })
);
