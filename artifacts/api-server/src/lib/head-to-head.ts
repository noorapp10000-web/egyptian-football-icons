const TRANSFERMARKT = "https://www.transfermarkt.com";
const EL_MASRY_ID = 9094;
const EL_MASRY_NAME = "El Masry SC";
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36";

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
  source: { name: string; url: string; fetchedAt: string; status: "live" | "cached" };
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
  topScorer: null;
  meetings: HeadToHeadMeeting[];
};

const cache = new Map<number, { expiresAt: number; data: HeadToHeadData }>();
const HEAD_TO_HEAD_CACHE_MS = 2 * 24 * 60 * 60_000;
const opponentIds: Record<string, number> = {
  "ittihad alexandria": 3963,
  "ittihad alexandria sc": 3963,
  "الاتحاد السكندري": 3963,
  "الاتحاد السكندرى": 3963,
};

const fallbackIttihadMeetings: HeadToHeadMeeting[] = [
  ["5008960", "26/27", "Premier League", "15/09/2026", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 0, 2, "loss"],
  ["4752851", "25/26", "Egyptian League Cup", "11/12/2025", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 0, 0, "draw"],
  ["4693059", "25/26", "Premier League", "08/08/2025", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 3, 1, "win"],
  ["4481540", "24/25", "Premier League", "08/02/2025", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 1, 2, "win"],
  ["4430216", "23/24", "Premier League", "18/08/2024", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 0, 2, "win"],
  ["4187344", "23/24", "Premier League", "04/04/2024", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 2, 3, "loss"],
  ["3946960", "22/23", "Premier League", "22/05/2023", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 1, 2, "win"],
  ["3947113", "22/23", "Premier League", "07/01/2023", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 2, 1, "win"],
  ["3872042", "21/22", "Premier League", "18/07/2022", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 0, 0, "draw"],
  ["4176054", "21/22", "Egyptian League Cup", "16/01/2022", "Ittihad Alexandria SC", "El Masry SC", 3963, 9094, 2, 2, "draw"],
  ["3683711", "21/22", "Premier League", "24/12/2021", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 0, 1, "loss"],
  ["3565528", "20/21", "Premier League", "20/05/2021", "El Masry SC", "Ittihad Alexandria SC", 9094, 3963, 1, 0, "win"],
].map(([id, season, competition, date, homeTeam, awayTeam, homeTeamId, awayTeamId, homeScore, awayScore, result]) => ({
  id: String(id),
  season: String(season),
  competition: String(competition),
  date: String(date),
  homeTeam: String(homeTeam),
  awayTeam: String(awayTeam),
  homeTeamId: Number(homeTeamId),
  awayTeamId: Number(awayTeamId),
  homeCrestUrl: `https://img.a.transfermarkt.technology/wappen/big/${homeTeamId}.png`,
  awayCrestUrl: `https://img.a.transfermarkt.technology/wappen/big/${awayTeamId}.png`,
  homeScore: Number(homeScore),
  awayScore: Number(awayScore),
  result: result as HeadToHeadMeeting["result"],
  matchReportUrl: `https://www.transfermarkt.com/spielbericht/index/spielbericht/${id}`,
}));

const decode = (value: string) =>
  value
    .replace(/<[^>]+>/g, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&nbsp;/gi, " ")
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&#x27;/gi, "'")
    .replace(/\s+/g, " ")
    .trim();

const absolute = (value: string | null | undefined) => {
  if (!value) return null;
  if (value.startsWith("//")) return `https:${value}`;
  if (value.startsWith("/")) return `${TRANSFERMARKT}${value}`;
  return value.replace(/^http:\/\//, "https://");
};

function highQualityCrest(value: string | null) {
  if (!value) return null;
  return value.replace(
    /\/wappen\/(?:tiny|small|medium|big)\//i,
    "/wappen/big/",
  );
}

const attr = (html: string, name: string) =>
  html.match(new RegExp(`\\b${name}=["']([^"']+)["']`, "i"))?.[1] ?? null;

async function fetchHtml(url: string) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 15_000);
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

function normalize(value: string) {
  return value
    .toLowerCase()
    .replace(/[إأآ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}

function teamFromAnchor(anchor: string, id: number) {
  const image = anchor.match(/<img\b[\s\S]*?>/i)?.[0] ?? "";
  const name =
    attr(image, "alt") ??
    attr(image, "title") ??
    decode(anchor.replace(/<[^>]+>/g, " "));
  return {
    id,
    name: decode(name) || (id === EL_MASRY_ID ? EL_MASRY_NAME : "—"),
    crestUrl: highQualityCrest(absolute(attr(image, "src") ?? attr(image, "data-src"))),
  };
}

function parseRow(row: string, opponentId: number): HeadToHeadMeeting | null {
  const report = row.match(
    /<a\b[^>]*href=["']([^"']*\/spielbericht\/index\/spielbericht\/\d+[^"']*)["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  if (!report) return null;
  const teams = [...row.matchAll(
    /<a\b[^>]*href=["'][^"']*\/(?:startseite\/)?verein\/(\d+)[^"']*["'][^>]*>([\s\S]*?)<\/a>/gi,
  )];
  if (teams.length < 2) return null;
  const homeId = Number(teams[0]![1]);
  const awayId = Number(teams[1]![1]);
  if (![homeId, awayId].includes(EL_MASRY_ID) || ![homeId, awayId].includes(opponentId)) return null;
  const home = teamFromAnchor(teams[0]![2]!, homeId);
  const away = teamFromAnchor(teams[1]![2]!, awayId);
  const text = decode(row);
  const score = decode(report[2]!).match(/(\d+)\s*:\s*(\d+)/);
  const homeScore = score ? Number(score[1]) : null;
  const awayScore = score ? Number(score[2]) : null;
  const masryScore = homeId === EL_MASRY_ID ? homeScore : awayScore;
  const opponentScore = homeId === EL_MASRY_ID ? awayScore : homeScore;
  return {
    id: report[1]!.match(/spielbericht\/(\d+)/)?.[1] ?? report[1]!,
    season: decode(row.match(/saison_id\/\d+[^"']*["'][^>]*>([\s\S]*?)<\/a>/i)?.[1] ?? "") || null,
    competition: decode(row.match(/(?:wettbewerb|pokalwettbewerb)\/[^"']*["'][^>]*>([\s\S]*?)<\/a>/i)?.[1] ?? "مباراة"),
    date: text.match(/\b\d{2}\/\d{2}\/\d{4}\b/)?.[0] ?? null,
    homeTeam: home.name,
    awayTeam: away.name,
    homeTeamId: home.id,
    awayTeamId: away.id,
    homeCrestUrl: home.crestUrl,
    awayCrestUrl: away.crestUrl,
    homeScore,
    awayScore,
    result: masryScore == null || opponentScore == null
      ? "unknown"
      : masryScore > opponentScore
        ? "win"
        : masryScore < opponentScore
          ? "loss"
          : "draw",
    matchReportUrl: absolute(report[1]),
  };
}

export function parseTransfermarktMeetings(html: string, opponentId: number) {
  const meetings = [...html.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)]
    .map((match) => parseRow(match[1]!, opponentId))
    .filter((meeting): meeting is HeadToHeadMeeting => meeting !== null);
  return [...new Map(meetings.map((meeting) => [meeting.id, meeting])).values()];
}

async function resolveOpponentId(name: string) {
  const known = opponentIds[normalize(name)];
  if (known) return known;
  const html = await fetchHtml(
    `${TRANSFERMARKT}/schnellsuche/ergebnis/schnellsuche?query=${encodeURIComponent(name)}`,
  );
  const matches = [...html.matchAll(
    /<a\b[^>]*href=["'][^"']*\/(?:startseite\/)?verein\/(\d+)[^"']*["'][^>]*>([\s\S]*?)<\/a>/gi,
  )];
  const wanted = normalize(name);
  const exact = matches.find((match) => normalize(decode(match[2]!)).includes(wanted));
  const id = Number((exact ?? matches[0])?.[1]);
  if (!Number.isInteger(id) || id <= 0) throw new Error("Transfermarkt opponent not found");
  return id;
}

export async function loadHeadToHead(name: string): Promise<HeadToHeadData> {
  const opponentId = await resolveOpponentId(name);
  const existing = cache.get(opponentId);
  if (existing && existing.expiresAt > Date.now()) return existing.data;
  const url =
    `${TRANSFERMARKT}/el-masry-sc/bilanzdetail/verein/${EL_MASRY_ID}` +
    `/wettbewerb_id//gegner_id/${opponentId}/saison_id//heim_gast//datum_von//datum_bis//day/0/land_id/0`;
  let meetings: HeadToHeadMeeting[];
  let sourceUrl = url;
  let sourceStatus: "live" | "cached" = "live";
  try {
    meetings = parseTransfermarktMeetings(await fetchHtml(url), opponentId);
    if (!meetings.length) throw new Error("Transfermarkt head-to-head is empty");
  } catch (error) {
    if (opponentId !== 3963) throw error;
    meetings = fallbackIttihadMeetings;
    sourceUrl = `${url}#cached-snapshot`;
    sourceStatus = "cached";
  }
  const played = meetings.filter((meeting) => meeting.homeScore != null && meeting.awayScore != null);
  const data: HeadToHeadData = {
    opponent: {
      id: opponentId,
      name: meetings[0]!.homeTeamId === opponentId ? meetings[0]!.homeTeam : meetings[0]!.awayTeam,
    },
    source: { name: "Transfermarkt", url: sourceUrl, fetchedAt: new Date().toISOString(), status: sourceStatus },
    summary: {
      total: played.length,
      wins: played.filter((meeting) => meeting.result === "win").length,
      draws: played.filter((meeting) => meeting.result === "draw").length,
      losses: played.filter((meeting) => meeting.result === "loss").length,
      goalsFor: played.reduce((total, meeting) => total + (meeting.homeTeamId === EL_MASRY_ID ? meeting.homeScore! : meeting.awayScore!), 0),
      goalsAgainst: played.reduce((total, meeting) => total + (meeting.homeTeamId === EL_MASRY_ID ? meeting.awayScore! : meeting.homeScore!), 0),
      seasons: new Set(meetings.map((meeting) => meeting.season).filter(Boolean)).size,
      competitions: new Set(meetings.map((meeting) => meeting.competition).filter(Boolean)).size,
    },
    topScorer: null,
    meetings,
  };
  cache.set(opponentId, { data, expiresAt: Date.now() + HEAD_TO_HEAD_CACHE_MS });
  return data;
}