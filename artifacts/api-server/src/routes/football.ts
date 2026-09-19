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
  "yallakora.com",
  "www.yallakora.com",
  "elwatannews.com",
  "www.elwatannews.com",
  "youm7.com",
  "www.youm7.com",
  "masrawy.com",
  "www.masrawy.com",
  "kooora.com",
  "www.kooora.com",
  "kingfut.com",
  "www.kingfut.com",
  "cairo24.com",
  "www.cairo24.com",
  "btolat.com",
  "www.btolat.com",
  "almasryalyoum.com",
  "www.almasryalyoum.com",
  "wataninet.com",
  "www.wataninet.com",
  "akhbarelyom.com",
  "www.akhbarelyom.com",
  "elbalad.news",
  "www.elbalad.news",
  "sadaelbalad.com",
  "www.sadaelbalad.com",
  "shbabbek.com",
  "www.shbabbek.com",
  "newturkpost.com",
  "www.newturkpost.com",
  "elghad.news",
  "www.elghad.news",
]);

const isAllowedImageHost = (hostname: string) => {
  const normalized = hostname.toLowerCase();
  return [...IMAGE_HOSTS].some(
    (host) => normalized === host || normalized.endsWith(`.${host}`),
  );
};

router.get("/football/image", async (req, res) => {
  const rawUrl = typeof req.query.url === "string" ? req.query.url : "";
  let target: URL;
  try {
    target = new URL(rawUrl);
  } catch {
    res.status(400).json({ error: "invalid_image_url" });
    return;
  }

  if (target.protocol !== "https:" || !isAllowedImageHost(target.hostname)) {
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