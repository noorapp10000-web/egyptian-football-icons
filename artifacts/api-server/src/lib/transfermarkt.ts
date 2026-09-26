import { loadSquad } from "../../../egyptian-football-hub/src/lib/filgoal.server";
import { transfermarktSnapshot } from "../data/transfermarkt-3963";

const EL_MASRY_ID = 9094;
const EL_MASRY_NAME = "El Masry SC";
const TRANSFERMARKT = "https://www.transfermarkt.com";
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36";
const TIMEOUT_MS = 15_000;

export type HeadToHeadMeeting = {
  id: string;
  season: string | null;
  competition: string;
  date: string | null;
  homeTeam: string;
  awayTeam: string;
  homeTeamId: number | null;
  awayTeamId: number | null;
  homeCrestUrl: string | null;
  awayCrestUrl: string | null;
  homeScore: number | null;
  awayScore: number | null;
  result: "win" | "draw" | "loss" | "unknown";
  matchReportUrl: string | null;
};

export type HeadToHeadData = {
  opponent: { id: number; name: string };
  source: { name: string; url: string; fetchedAt: string };
  summary: {
    total: number;
    wins: number;
    draws: number;
    losses: number;
    goalsFor: number;
    goalsAgainst: number;
    seasons: number;
    competitions: number;
  };
  topScorer: {
    name: string;
    photoUrl: string | null;
    goals: number | null;
    appearances: number | null;
  } | null;
  meetings: HeadToHeadMeeting[];
};

const cache = new Map<number, { expiresAt: number; data: HeadToHeadData }>();
const opponentCache = new Map<string, { expiresAt: number; id: number }>();
const HISTORICAL_TOP_SCORER: NonNullable<HeadToHeadData["topScorer"]> = {
  name: "أحمد جمعة",
  photoUrl: "https://img.a.transfermarkt.technology/portrait/big/340006-1504786004.jpg",
  goals: 54,
  appearances: 177,
};

function decode(value: string) {
  return value
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&#x27;/gi, "'")
    .replace(/&#x2F;/gi, "/")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function absolute(value: string | null | undefined) {
  if (!value) return null;
  if (value.startsWith("//")) return `https:${value}`;
  if (value.startsWith("/")) return `${TRANSFERMARKT}${value}`;
  return value;
}

function attr(html: string, name: string) {
  const match = html.match(new RegExp(`\\b${name}=["']([^"']+)["']`, "i"));
  return match?.[1] ?? null;
}

function plainCell(cell: string) {
  return decode(
    cell
      .replace(/<br\s*\/?>/gi, " ")
      .replace(/<script[\s\S]*?<\/script>/gi, " ")
      .replace(/<style[\s\S]*?<\/style>/gi, " "),
  );
}

function numberFromScore(value: string) {
  const match = value.match(/(\d+)\s*:\s*(\d+)/);
  if (!match) return [null, null] as const;
  return [Number(match[1]), Number(match[2])] as const;
}

function teamFromAnchor(anchor: string, id: number) {
  const image = anchor.match(/<img\b[\s\S]*?>/i)?.[0] ?? "";
  const name =
    attr(image, "alt") ??
    attr(image, "title") ??
    decode(anchor.replace(/<[^>]+>/g, " "));
  const crest = attr(image, "src") ?? attr(image, "data-src");
  return {
    id,
    name: decode(name) || (id === EL_MASRY_ID ? EL_MASRY_NAME : "—"),
    crestUrl: absolute(crest),
  };
}

function parseMeetingRow(row: string, opponentId: number): HeadToHeadMeeting | null {
  const report = row.match(
    /<a\b[^>]*href=["']([^"']*\/spielbericht\/index\/spielbericht\/\d+[^"']*)["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  if (!report) return null;

  const teamAnchors = [...row.matchAll(
    /<a\b[^>]*href=["']([^"']*\/(?:startseite\/)?verein\/(\d+)[^"']*)["'][^>]*>([\s\S]*?)<\/a>/gi,
  )];
  if (teamAnchors.length < 2) return null;
  const first = teamAnchors[0]!;
  const second = teamAnchors[1]!;
  const homeId = Number(first[2]);
  const awayId = Number(second[2]);
  if (
    ![homeId, awayId].includes(EL_MASRY_ID) ||
    ![homeId, awayId].includes(opponentId)
  ) {
    return null;
  }
  const home = teamFromAnchor(first[3]!, homeId);
  const away = teamFromAnchor(second[3]!, awayId);

  const seasonLink = row.match(
    /<a\b[^>]*href=["'][^"']*saison_id\/\d+[^"']*["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  const competitionLink = row.match(
    /<a\b[^>]*href=["'][^"']*(?:wettbewerb|pokalwettbewerb)\/[^"']*["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  const rowText = plainCell(row);
  const date = rowText.match(/\b\d{2}\/\d{2}\/\d{4}\b/)?.[0] ?? null;
  const [homeScore, awayScore] = numberFromScore(plainCell(report[2]!));
  const isMasryHome = homeId === EL_MASRY_ID;
  const masryScore = isMasryHome ? homeScore : awayScore;
  const opponentScore = isMasryHome ? awayScore : homeScore;
  const result =
    masryScore == null || opponentScore == null
      ? "unknown"
      : masryScore > opponentScore
        ? "win"
        : masryScore < opponentScore
          ? "loss"
          : "draw";

  return {
    id: report[1]!.match(/spielbericht\/(\d+)/)?.[1] ?? report[1]!,
    season: seasonLink ? plainCell(seasonLink[1]!) : null,
    competition: competitionLink ? plainCell(competitionLink[1]!) : "مباراة",
    date,
    homeTeam: home.name,
    awayTeam: away.name,
    homeTeamId: home.id,
    awayTeamId: away.id,
    homeCrestUrl: home.crestUrl,
    awayCrestUrl: away.crestUrl,
    homeScore,
    awayScore,
    result,
    matchReportUrl: absolute(report[1]),
  };
}

export function parseTransfermarktMeetings(
  html: string,
  opponentId: number,
): HeadToHeadMeeting[] {
  const rows = [...html.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)]
    .map((match) => parseMeetingRow(match[1]!, opponentId))
    .filter((meeting): meeting is HeadToHeadMeeting => meeting !== null);
  return [...new Map(rows.map((meeting) => [meeting.id, meeting])).values()];
}

async function fetchHtml(url: string) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        Accept: "text/html,application/xhtml+xml",
        "Accept-Language": "en-US,en;q=0.8",
      },
      signal: controller.signal,
    });
    if (!response.ok) throw new Error(`Transfermarkt ${response.status}`);
    return await response.text();
  } finally {
    clearTimeout(timer);
  }
}

function normalizeName(value: string) {
  return value
    .toLowerCase()
    .replace(/[إأآ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}

const knownOpponentIds: Record<string, number> = {
  "ittihad alexandria": 3963,
  "ittihad alexandria sc": 3963,
  "الاتحاد السكندري": 3963,
  "الاتحاد السكندرى": 3963,
};

async function resolveOpponentId(name: string) {
  const normalized = normalizeName(name);
  const known = knownOpponentIds[normalized];
  if (known) return known;
  const cached = opponentCache.get(normalized);
  if (cached && cached.expiresAt > Date.now()) return cached.id;

  const searchUrl = `${TRANSFERMARKT}/schnellsuche/ergebnis/schnellsuche?query=${encodeURIComponent(name)}`;
  const html = await fetchHtml(searchUrl);
  const matches = [...html.matchAll(
    /<a\b[^>]*href=["'][^"']*\/(?:startseite\/)?verein\/(\d+)[^"']*["'][^>]*>([\s\S]*?)<\/a>/gi,
  )];
  const wanted = normalizeName(name);
  const exact = matches.find((match) => normalizeName(decode(match[2]!)).includes(wanted));
  const id = Number((exact ?? matches[0])?.[1]);
  if (!Number.isInteger(id) || id <= 0) throw new Error("Transfermarkt opponent not found");
  opponentCache.set(normalized, { expiresAt: Date.now() + 7 * 24 * 60 * 60_000, id });
  return id;
}

export async function loadTransfermarktHeadToHead(opponentName: string) {
  const opponentId = await resolveOpponentId(opponentName);
  const cached = cache.get(opponentId);
  if (cached && cached.expiresAt > Date.now()) return cached.data;

  const url =
    `${TRANSFERMARKT}/el-masry-sc/bilanzdetail/verein/${EL_MASRY_ID}` +
    `/wettbewerb_id//gegner_id/${opponentId}/saison_id//heim_gast//datum_von//datum_bis//day/0/land_id/0`;
  let meetings: HeadToHeadMeeting[] = [];
  let sourceUrl = url;
  let fetchedAt = new Date().toISOString();
  try {
    meetings = parseTransfermarktMeetings(await fetchHtml(url), opponentId);
    if (meetings.length === 0) throw new Error("Transfermarkt head-to-head is empty");
  } catch (error) {
    if (opponentId !== 3963) throw error;
    const snapshot = transfermarktSnapshot as unknown as HeadToHeadData;
    meetings = snapshot.meetings;
    sourceUrl = `${snapshot.source.url}#cached-snapshot`;
    fetchedAt = new Date().toISOString();
  }

  const played = meetings.filter(
    (meeting) => meeting.homeScore != null && meeting.awayScore != null,
  );
  const summary = {
    total: played.length,
    wins: played.filter((meeting) => meeting.result === "win").length,
    draws: played.filter((meeting) => meeting.result === "draw").length,
    losses: played.filter((meeting) => meeting.result === "loss").length,
    goalsFor: played.reduce((total, meeting) => {
      const score = meeting.homeTeamId === EL_MASRY_ID ? meeting.homeScore : meeting.awayScore;
      return total + (score ?? 0);
    }, 0),
    goalsAgainst: played.reduce((total, meeting) => {
      const score =
        meeting.homeTeamId === EL_MASRY_ID ? meeting.awayScore : meeting.homeScore;
      return total + (score ?? 0);
    }, 0),
    seasons: new Set(meetings.map((meeting) => meeting.season).filter(Boolean)).size,
    competitions: new Set(meetings.map((meeting) => meeting.competition).filter(Boolean)).size,
  };

  let topScorer: HeadToHeadData["topScorer"] = HISTORICAL_TOP_SCORER;
  try {
    const squad = await loadSquad();
    const player = squad.players
      .filter((item) => item.goals != null)
      .sort((a, b) => (b.goals ?? 0) - (a.goals ?? 0))[0];
    if (player && (player.goals ?? 0) > 0) {
      topScorer = {
        name: player.name,
        photoUrl: player.photoUrl,
        goals: player.goals,
        appearances: player.appearances,
      };
    }
  } catch {
    // The historical meetings remain useful when the current squad source is unavailable.
  }

  const data: HeadToHeadData = {
    opponent: { id: opponentId, name: meetings[0]?.homeTeamId === opponentId ? meetings[0]!.homeTeam : meetings[0]!.awayTeam },
    source: { name: "Transfermarkt", url: sourceUrl, fetchedAt },
    summary,
    topScorer,
    meetings,
  };
  cache.set(opponentId, { expiresAt: Date.now() + 6 * 60 * 60_000, data });
  return data;
}