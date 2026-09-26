import { Router, type Response } from "express";
import {
  loadMatchDetail,
  loadMatches,
  loadNews,
  loadPlayerDetail,
  loadSquad,
  loadStandings,
  loadTeam,
} from "../lib/football-source";
import { loadHeadToHead } from "../lib/head-to-head";

const router = Router();

const IMAGE_HOSTS = new Set([
  "filgoal.com",
  "www.filgoal.com",
  "media.filgoal.com",
  "semedia.filgoal.com",
  "yallakora.com",
  "www.yallakora.com",
  "transfermarkt.com",
  "www.transfermarkt.com",
  "img.a.transfermarkt.technology",
  "kingfut.com",
  "www.kingfut.com",
  "news.google.com",
]);

function setPublicCache(res: Response, maxAge: number, staleWhileRevalidate: number) {
  const value = `public, max-age=${maxAge}, s-maxage=${maxAge}, stale-while-revalidate=${staleWhileRevalidate}`;
  res.setHeader("Cache-Control", value);
  res.setHeader("CDN-Cache-Control", value);
}

router.get("/football/image", (req, res) => {
  const rawUrl = typeof req.query.url === "string" ? req.query.url : "";
  let target: URL;
  try {
    target = new URL(rawUrl);
  } catch {
    res.status(400).json({ error: "invalid_image_url" });
    return;
  }
  const hostname = target.hostname.toLowerCase();
  const allowed = [...IMAGE_HOSTS].some((host) => hostname === host || hostname.endsWith(`.${host}`));
  if (target.protocol !== "https:" || !allowed) {
    res.status(403).json({ error: "image_host_not_allowed" });
    return;
  }
  setPublicCache(res, 86_400, 86_400);
  res.redirect(302, target.toString());
});

router.get("/football/matches", async (_req, res) => {
  const data = await loadMatches();
  const live = data.matches.some((match) => match.status === "live");
  setPublicCache(res, live ? 20 : 3_600, live ? 5 : 300);
  res.json(data);
});

router.get("/football/matches/:matchId", async (req, res) => {
  const matchId = Number(req.params.matchId);
  if (!Number.isInteger(matchId) || matchId <= 0) {
    res.status(400).json({ error: "invalid_match_id" });
    return;
  }
  const data = await loadMatchDetail(matchId);
  setPublicCache(res, data.match.status === "live" ? 20 : 3_600, data.match.status === "live" ? 5 : 300);
  res.json(data);
});

router.get("/football/head-to-head", async (req, res) => {
  const opponent = typeof req.query.opponent === "string" ? req.query.opponent.trim() : "";
  if (!opponent) {
    res.status(400).json({ error: "missing_opponent" });
    return;
  }
  try {
    const data = await loadHeadToHead(opponent);
    setPublicCache(res, 172_800, 3_600);
    res.json(data);
  } catch (error) {
    req.log?.warn({ err: error, opponent }, "Head-to-head source unavailable");
    res.status(502).json({ error: "head_to_head_unavailable" });
  }
});

router.get("/football/players/:playerId", async (req, res) => {
  const playerId = Number(req.params.playerId);
  if (!Number.isInteger(playerId) || playerId <= 0) {
    res.status(400).json({ error: "invalid_player_id" });
    return;
  }
  const data = await loadPlayerDetail(playerId);
  setPublicCache(res, 7_200, 900);
  res.json(data);
});

router.get("/football/squad", async (_req, res) => {
  const data = await loadSquad();
  setPublicCache(res, 86_400, 3_600);
  res.json(data);
});

router.get("/football/team", async (_req, res) => {
  const data = await loadTeam();
  setPublicCache(res, 86_400, 3_600);
  res.json(data);
});

router.get("/football/standings", async (_req, res) => {
  const data = await loadStandings();
  setPublicCache(res, 7_200, 900);
  res.json(data);
});

router.get("/football/news", async (_req, res) => {
  const data = await loadNews();
  setPublicCache(res, 3_600, 300);
  res.json(data);
});

export default router;