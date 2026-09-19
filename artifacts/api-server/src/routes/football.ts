import { Router } from "express";

import {
  loadMatchDetail,
  loadMatches,
  loadNews,
  loadPlayerDetail,
  loadSquad,
  loadStandings,
} from "../../../egyptian-football-hub/src/lib/filgoal.server";

const router = Router();

const IMAGE_HOSTS = new Set([
  "filgoal.com",
  "www.filgoal.com",
  "media.filgoal.com",
  "semedia.filgoal.com",
]);

router.get("/football/image", async (req, res) => {
  const rawUrl = typeof req.query.url === "string" ? req.query.url : "";
  let target: URL;
  try {
    target = new URL(rawUrl);
  } catch {
    res.status(400).json({ error: "invalid_image_url" });
    return;
  }

  if (target.protocol !== "https:" || !IMAGE_HOSTS.has(target.hostname.toLowerCase())) {
    res.status(403).json({ error: "image_host_not_allowed" });
    return;
  }

  try {
    const response = await fetch(target, {
      headers: {
        Accept: "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8",
        Referer: "https://www.filgoal.com/",
        "User-Agent":
          "Mozilla/5.0 (Android 13; Mobile) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36",
      },
      signal: AbortSignal.timeout(12_000),
    });
    if (!response.ok) {
      res.status(response.status).end();
      return;
    }
    const contentType = response.headers.get("content-type") ?? "image/jpeg";
    if (!contentType.startsWith("image/")) {
      res.status(415).end();
      return;
    }
    const body = Buffer.from(await response.arrayBuffer());
    res
      .setHeader("Content-Type", contentType)
      .setHeader("Cache-Control", "public, max-age=86400, s-maxage=604800")
      .send(body);
  } catch {
    res.status(502).json({ error: "image_fetch_failed" });
  }
});

router.get("/football/matches", async (_req, res) => {
  res.json(await loadMatches());
});

router.get("/football/matches/:matchId", async (req, res) => {
  const matchId = Number(req.params.matchId);
  if (!Number.isInteger(matchId)) {
    res.status(400).json({ error: "invalid_match_id" });
    return;
  }
  res.json(await loadMatchDetail(matchId));
});

router.get("/football/players/:playerId", async (req, res) => {
  const playerId = Number(req.params.playerId);
  if (!Number.isInteger(playerId)) {
    res.status(400).json({ error: "invalid_player_id" });
    return;
  }
  res.json(await loadPlayerDetail(playerId));
});

router.get("/football/squad", async (_req, res) => {
  res.json(await loadSquad());
});

router.get("/football/standings", async (_req, res) => {
  res.json(await loadStandings());
});

router.get("/football/news", async (_req, res) => {
  res.json(await loadNews());
});

export default router;