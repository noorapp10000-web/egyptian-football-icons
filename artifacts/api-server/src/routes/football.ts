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