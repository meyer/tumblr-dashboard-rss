import type { MiddlewareHandler } from 'astro';

export const onRequest: MiddlewareHandler = async (_context, next) => {
  try {
    return await next();
  } catch (error) {
    console.error(error);
    return new Response(error + '', { status: 500 });
  }
};
