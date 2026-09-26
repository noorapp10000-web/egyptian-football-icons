# Egyptian Football API

REST API for the Egyptian Football Icons Flutter app. It serves El Masry matches, match details and lineups, squad/team data, standings, news, player profiles, and historical head-to-head meetings.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- No runtime secret is required for the public football data routes. Optional Firebase variables from the source mobile app are not needed by this API.

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

- `artifacts/api-server/src/routes/football.ts` — public football endpoints, caching headers, and image redirect allowlist.
- `artifacts/api-server/src/lib/football-source.ts` — FilGoal parsers, upstream fetch timeout, and in-memory stale cache.
- `artifacts/api-server/src/lib/head-to-head.ts` — Transfermarkt historical meetings with a cached fallback for the known El Masry–Ittihad matchup.
- `lib/api-spec/openapi.yaml` — source of truth for all public API contracts.

## Architecture decisions

- Upstream data is fetched server-side so the Flutter client never scrapes FilGoal or Transfermarkt directly.
- Responses use public CDN-friendly cache headers, while the API also keeps stale in-memory data for short upstream outages.
- The head-to-head endpoint falls back to a checked-in recent snapshot for Ittihad Alexandria when Transfermarkt blocks the server.
- Image URLs are redirected only for explicitly approved HTTPS hosts; arbitrary proxying is rejected.

## Product

The API powers a native football hub focused on El Masry SC, with live/upcoming/results views, detailed match center data, team information, league context, news, and historical rivalries.

## User preferences

_Populate as you build — explicit user instructions worth remembering across sessions._

## Gotchas

- Run `pnpm --filter @workspace/api-spec run codegen` after changing `lib/api-spec/openapi.yaml`.
- Use the shared proxy path `/api/...` when checking routes locally; the service itself listens on the workflow-provided `PORT`.
- A match before kickoff may correctly return empty events and lineups; confirmed lineups are supplied by the upstream match model when available.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
