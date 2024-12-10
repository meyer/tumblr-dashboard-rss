import { createHmac, randomBytes } from 'node:crypto';
import { invariant } from '@workers-utils/common';
import * as s from 'superstruct';

type KvTokenData = s.Infer<typeof kvTokenSchema>;

const kvTokenSchema = s.type({
  nsid: s.string(),
  oauthToken: s.string(),
  oauthTokenSecret: s.string(),
});

const chars: Record<string, string> = {
  '!': '%21',
  "'": '%27',
  '(': '%28',
  ')': '%29',
  '*': '%2A',
};

const regex = new RegExp('[' + Object.keys(chars).join('') + ']', 'g');

const encodeRFC3986 = (str: string) =>
  encodeURIComponent(str).replace(regex, (c) => chars[c] || c);

const join = (arr: string[]) => arr.map(encodeRFC3986).join('&');

const hmac = (text: string, key: string) =>
  createHmac('sha1', key).update(text).digest('base64');

const getSigningKey = (consumerSecret: string, tokenSecret?: string) =>
  join([consumerSecret, tokenSecret || '']);

const sortAndCleanParams = (params: Record<string, any>) => {
  return Object.entries(params)
    .filter(([, v]) => typeof v !== 'undefined')
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([k, v]) => k + '=' + encodeRFC3986(v.toString()))
    .join('&');
};

const getBaseString = (
  method: string,
  url: string,
  params: Record<string, any>
) => join([method, url, sortAndCleanParams(params)]);

const getSignature = (
  method: 'GET' | 'POST',
  url: string,
  params: Record<string, any>,
  consumerSecret: string,
  tokenSecret?: string
) =>
  hmac(
    getBaseString(method, url, params),
    getSigningKey(consumerSecret, tokenSecret)
  );

export const getFlickrAuthDataFromKV = async (
  uuid: string,
  locals: App.Locals
): Promise<KvTokenData> => {
  const kvResult = await locals.runtime.env.AUTH.get('flickr:' + uuid, 'json');
  invariant(kvResult, 'No auth data for the requested key');
  s.assert(
    kvResult,
    kvTokenSchema,
    'kvResult does not match the kvTokenSchema'
  );
  return kvResult;
};

const requestTokenSchema = s.type({
  oauth_token: s.string(),
  oauth_token_secret: s.string(),
});

const getSignedUrl = (
  method: 'GET' | 'POST',
  apiUrl: string,
  locals: App.Locals,
  extraParams: Record<string, string> | null = null,
  oauthToken?: string,
  oauthTokenSecret?: string
): URL => {
  const consumerSecret = locals.runtime.env.FLICKR_API_SECRET;

  const requestParams = {
    ...extraParams,
    oauth_nonce: randomBytes(32).toString('base64'),
    oauth_timestamp: Math.floor(Date.now() / 1000).toString(),
    oauth_consumer_key: locals.runtime.env.FLICKR_API_KEY,
    oauth_signature_method: 'HMAC-SHA1',
    oauth_version: '1.0',
    ...(oauthToken ? { oauth_token: oauthToken } : null),
  };

  const oauthSignature = getSignature(
    method,
    apiUrl,
    requestParams,
    consumerSecret,
    oauthTokenSecret
  );

  const urlObj = new URL(apiUrl);
  for (const [key, value] of Object.entries(requestParams)) {
    urlObj.searchParams.set(key, value);
  }
  urlObj.searchParams.set('oauth_signature', oauthSignature);

  return urlObj;
};

export const getRequestToken = async (
  locals: App.Locals,
  callbackUrl: string
) => {
  const url = getSignedUrl(
    'GET',
    'https://www.flickr.com/services/oauth/request_token',
    locals,
    { oauth_callback: callbackUrl }
  );

  const result = await fetch(url);
  const body = await result.text();
  const responseValue = Object.fromEntries(new URLSearchParams(body).entries());

  s.assert(responseValue, requestTokenSchema);
  return {
    requestToken: responseValue.oauth_token,
    requestTokenSecret: responseValue.oauth_token_secret,
  };
};

const accessTokenSchema = s.type({
  oauth_token: s.string(),
  oauth_token_secret: s.string(),
  user_nsid: s.string(),
});

export const verifyRequestToken = async (
  locals: App.Locals,
  oauthVerifier: string,
  requestToken: string,
  requestTokenSecret: string
) => {
  const url = getSignedUrl(
    'GET',
    'https://www.flickr.com/services/oauth/access_token',
    locals,
    { oauth_verifier: oauthVerifier },
    requestToken,
    requestTokenSecret
  );

  const result = await fetch(url);
  const body = await result.text();
  const responseValue = Object.fromEntries(new URLSearchParams(body).entries());

  s.assert(responseValue, accessTokenSchema);
  return {
    nsid: responseValue.user_nsid,
    oauthToken: responseValue.oauth_token,
    oauthTokenSecret: responseValue.oauth_token_secret,
  };
};

export const getAuthorizeUrl = (
  requestToken: string,
  perms: 'read' | 'write' | 'delete' = 'read'
) => {
  const url = new URL('https://www.flickr.com/services/oauth/authorize');
  url.searchParams.set('perms', perms);
  url.searchParams.set('oauth_token', requestToken);
  return url.href;
};

const baseUrl = 'https://www.flickr.com/services/rest/';

export const queryFlickrApi = async (
  locals: App.Locals,
  authData: KvTokenData,
  apiMethod: string,
  params: Record<string, string> | null = null
): Promise<unknown> => {
  const signedUrl = getSignedUrl(
    'GET',
    baseUrl,
    locals,
    {
      ...params,
      method: apiMethod,
      format: 'json',
      nojsoncallback: '1',
    },
    authData.oauthToken,
    authData.oauthTokenSecret
  );
  const result = await fetch(signedUrl, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
    },
  });
  const textResult = await result.text();
  try {
    return JSON.parse(textResult);
  } catch (error) {
    console.error('Error parsing JSON', textResult);
    throw error;
  }
};

export const getContactsPhotos = async () => {};
