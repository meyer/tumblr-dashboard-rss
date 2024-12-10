export class JSONResponse extends Response {
  constructor(data: unknown, init?: ResponseInit) {
    super(JSON.stringify(data), {
      ...init,
      headers: {
        ...init?.headers,
        'Content-Type': 'application/json; charset=utf-8',
      },
    });
  }
}
