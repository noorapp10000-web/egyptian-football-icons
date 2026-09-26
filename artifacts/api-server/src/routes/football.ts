import { Router, type Response } from "express";

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

  // Backwards-compatible endpoint: redirect the client to the source. Replit
  // never downloads, stores, or streams the image bytes.
  res
    .setHeader("Cache-Control", "public, max-age=86400, s-maxage=86400")
    .redirect(302, target.toString());
});

function setPublicCache(
  res: Response,
  maxAgeSeconds: number,
  staleWhileRevalidateSeconds: number,
) {
  res.setHeader(
    "Cache-Control",
    `public, max-age=${maxAgeSeconds}, s-maxage=${maxAgeSeconds}, stale-while-revalidate=${staleWhileRevalidateSeconds}`,
  );
}

function matchesHttpTtl(matches: Awaited<ReturnType<typeof loadMatches>>["matches"]) {
  if (matches.some((match) => match.status === "live")) {
    return { maxAge: 20, swr: 5 };
  }
  const now = Date.now();
  const soon = matches.some((match) => {
    if (match.status !== "upcoming" || !match.kickoff) return false;
    const kickoff = Date.parse(match.kickoff);
    return Number.isFinite(kickoff) && kickoff - now <= 90 * 60_000 && kickoff - now > -3 * 60 * 60_000;
  });
  return soon ? { maxAge: 60, swr: 15 } : { maxAge: 3600, swr: 300 };
}

router.get("/football/matches", async (_req, res) => {
  const data = await loadMatches();
  const ttl = matchesHttpTtl(data.matches);
  setPublicCache(res, ttl.maxAge, ttl.swr);
  res.json(data);
});

router.get("/football/matches/:matchId", async (req, res) => {
  const matchId = Number(req.params.matchId);
  if (!Number.isInteger(matchId)) {
    res.status(400).json({ error: "invalid_match_id" });
    return;
  }
  const data = await loadMatchDetail(matchId);
  const ttl = data.match.status === "live" ? { maxAge: 20, swr: 5 } : { maxAge: 3600, swr: 300 };
  setPublicCache(res, ttl.maxAge, ttl.swr);
  res.json(data);
});

router.get("/football/players/:playerId", async (req, res) => {
  const playerId = Number(req.params.playerId);
  if (!Number.isInteger(playerId)) {
    res.status(400).json({ error: "invalid_player_id" });
    return;
  }
  const data = await loadPlayerDetail(playerId);
  setPublicCache(res, 7200, 900);
  res.json(data);
});

router.get("/football/squad", async (_req, res) => {
  const data = await loadSquad();
  setPublicCache(res, 86400, 3600);
  res.json(data);
});

router.get("/football/standings", async (_req, res) => {
  const data = await loadStandings();
  setPublicCache(res, 7200, 900);
  res.json(data);
});

router.get("/football/news", async (_req, res) => {
  const data = await loadNews();
  setPublicCache(res, 3600, 300);
  res.json(data);
});

export default router;