import { invariant } from '@workers-utils/common';
import type { APIRoute } from 'astro';
import {
  getAuthorizeUrl,
  getRequestToken,
  verifyRequestToken,
} from '~/utils/flickr/flickrApi';

export const GET: APIRoute = async (context) => {
  const requestToken = context.url.searchParams.get('oauth_token');
  const oauthVerifier = context.url.searchParams.get('oauth_verifier');

  if (!requestToken || !oauthVerifier) {
    try {
      const { requestToken, requestTokenSecret } = await getRequestToken(
        context.locals,
        context.url.toString()
      );

      await context.locals.runtime.env.AUTH.put(
        `flickr-token:${requestToken}`,
        requestTokenSecret
      );
      return context.redirect(getAuthorizeUrl(requestToken, 'read'), 302);
    } catch (err) {
      console.error(err);
      return new Response(err + '', { status: 500 });
    }
  }

  const requestTokenSecret = await context.locals.runtime.env.AUTH.get(
    'flickr-token:' + requestToken,
    'text'
  );
  invariant(requestTokenSecret, 'Missing request token secret');

  const oauthResult = await verifyRequestToken(
    context.locals,
    oauthVerifier,
    requestToken,
    requestTokenSecret
  );

  const uuid = crypto.randomUUID();

  await context.locals.runtime.env.AUTH.delete(`flickr-token:${requestToken}`);

  invariant(
    oauthResult.nsid === context.locals.runtime.env.FLICKR_NSID,
    'Expected %s, received %s',
    context.locals.runtime.env.FLICKR_NSID,
    oauthResult.nsid
  );

  await context.locals.runtime.env.AUTH.put(
    `flickr:${uuid}`,
    JSON.stringify(oauthResult)
  );

  return context.redirect('/flickr/' + uuid, 302);
};
