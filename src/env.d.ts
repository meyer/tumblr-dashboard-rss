/// <reference path="../.astro/types.d.ts" />

type Runtime = import('@astrojs/cloudflare').Runtime<WorkerEnv>;

declare namespace App {
  interface Locals extends Runtime {}
}
