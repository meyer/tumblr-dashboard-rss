import { invariant } from '@workers-utils/common';
import type { APIRoute } from 'astro';
import * as s from 'superstruct';
import { type KvTokenData, authCodeSchema } from '~/utils/tumblr/tumblrApi';

const state = '1234';

export const GET: APIRoute = async (context) => {
  const codeParam = context.url.searchParams.get('code');
  const stateParam = context.url.searchParams.get('state');

  const redirectUrl = new URL(context.url);
  redirectUrl.search = '';

  if (!codeParam || !stateParam) {
    const authUrl = new URL('https://www.tumblr.com/oauth2/authorize');

    authUrl.searchParams.set(
      'client_id',
      context.locals.runtime.env.TUMBLR_OAUTH_CONSUMER_KEY
    );
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('scope', ['basic', 'offline_access'].join(' '));
    authUrl.searchParams.set('state', state);
    authUrl.searchParams.set('redirect_uri', redirectUrl.toString());

    console.log('Redirect to %s', authUrl);

    return context.redirect(authUrl.toString(), 302);
  }

  invariant(stateParam === state, 'Invalid state');

  const result = await fetch('https://api.tumblr.com/v2/oauth2/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      client_id: context.locals.runtime.env.TUMBLR_OAUTH_CONSUMER_KEY,
      client_secret: context.locals.runtime.env.TUMBLR_OAUTH_CONSUMER_SECRET,
      redirect_uri: redirectUrl,
      code: codeParam,
      grant_type: 'authorization_code',
    }),
  });

  const body = await result.json();

  invariant(
    result.status === 200,
    'Something went wrong: ' + result.status + ' ' + result.statusText
  );
  s.assert(body, authCodeSchema);

  const authData: KvTokenData = {
    ...body,
    expires_at: Date.now() + body.expires_in * 1000,
  };

  const uuid = crypto.randomUUID();

  // save auth info to KV
  await context.locals.runtime.env.AUTH.put(
    `tumblr:${uuid}`,
    JSON.stringify(authData)
  );

  return context.redirect(`/tumblr/${uuid}`, 302);
};
