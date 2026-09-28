import { transfermarktSnapshot } from "../data/transfermarkt-3963";
import transfermarktSnapshots from "../data/transfermarkt-snapshots.json";

const EL_MASRY_ID = 9094;
const EL_MASRY_NAME = "El Masry SC";
const TRANSFERMARKT = "https://www.transfermarkt.com";
const READER_PREFIX = "https://r.jina.ai/http://";
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36";
const TIMEOUT_MS = 15_000;
const MAX_PAGES = 20;

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

export type HeadToHeadScorer = {
  name: string;
  photoUrl: string | null;
  goals: number | null;
  appearances: number | null;
};

export type HeadToHeadData = {
  opponent: { id: number; name: string };
  source: {
    name: string;
    url: string;
    fetchedAt: string;
    status?: "live" | "reader" | "cached";
  };
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
  topScorer: HeadToHeadScorer | null;
  topScorers: HeadToHeadScorer[];
  meetings: HeadToHeadMeeting[];
};

const cache = new Map<number, { expiresAt: number; data: HeadToHeadData }>();
const opponentCache = new Map<string, { expiresAt: number; id: number }>();
const inFlight = new Map<number, Promise<HeadToHeadData>>();
let transfermarktQueue = Promise.resolve();

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
  return value.replace(/^http:\/\//, "https://");
}

function highQualityCrest(value: string | null) {
  if (!value) return null;
  return value
    .replace(/\/wappen\/(?:tiny|small|medium|big)\//i, "/wappen/big/")
    .replace(/\/wappen\/[^/]+\//i, "/wappen/big/");
}

function highQualityPortrait(value: string | null) {
  if (!value) return null;
  return value
    .replace(/\/portrait\/(?:tiny|small|medium|big)\//i, "/portrait/big/")
    .replace(/\/portrait\/[^/]+\//i, "/portrait/big/");
}

function attr(html: string, name: string) {
  return html.match(new RegExp(`\\b${name}=["']([^"']+)["']`, "i"))?.[1] ?? null;
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
    crestUrl: highQualityCrest(absolute(crest)),
  };
}

function resultFor(homeId: number, homeScore: number | null, awayScore: number | null) {
  const masryScore = homeId === EL_MASRY_ID ? homeScore : awayScore;
  const opponentScore = homeId === EL_MASRY_ID ? awayScore : homeScore;
  return masryScore == null || opponentScore == null
    ? "unknown"
    : masryScore > opponentScore
      ? "win"
      : masryScore < opponentScore
        ? "loss"
        : "draw";
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
  const homeId = Number(teamAnchors[0]![2]);
  const awayId = Number(teamAnchors[1]![2]);
  if (
    ![homeId, awayId].includes(EL_MASRY_ID) ||
    ![homeId, awayId].includes(opponentId)
  ) {
    return null;
  }

  const home = teamFromAnchor(teamAnchors[0]![3]!, homeId);
  const away = teamFromAnchor(teamAnchors[1]![3]!, awayId);
  const seasonLink = row.match(
    /<a\b[^>]*href=["'][^"']*saison_id\/\d+[^"']*["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  const competitionLink = row.match(
    /<a\b[^>]*href=["'][^"']*(?:wettbewerb|pokalwettbewerb)\/[^"']*["'][^>]*>([\s\S]*?)<\/a>/i,
  );
  const rowText = plainCell(row);
  const date = rowText.match(/\b\d{2}\/\d{2}\/\d{4}\b/)?.[0] ?? null;
  const [homeScore, awayScore] = numberFromScore(plainCell(report[2]!));

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
    result: resultFor(homeId, homeScore, awayScore),
    matchReportUrl: absolute(report[1]),
  };
}

function markdownTeamLinks(row: string) {
  return [...row.matchAll(
    /\]\((https?:\/\/www\.transfermarkt\.com\/[^)]*\/(?:startseite\/)?verein\/(\d+)[^)]*)\s+"([^"]*)"\)/gi,
  )].map((match) => ({
    id: Number(match[2]),
    name: decode(match[3]!),
  }));
}

function parseMarkdownMeetingRow(row: string, opponentId: number) {
  const report = row.match(
    /\[(\d+\s*:\s*\d+|[-–]\s*:\s*[-–])\]\((https?:\/\/www\.transfermarkt\.com\/[^)]*spielbericht\/index\/spielbericht\/(\d+)[^)]*)/i,
  );
  if (!report) return null;

  const teams = markdownTeamLinks(row);
  if (teams.length < 2) return null;
  const homeId = teams[0]!.id;
  const awayId = teams[1]!.id;
  if (
    ![homeId, awayId].includes(EL_MASRY_ID) ||
    ![homeId, awayId].includes(opponentId)
  ) {
    return null;
  }

  const crestUrls = [...row.matchAll(
    /!\[[^\]]*\]\((https?:\/\/img\.a\.transfermarkt\.technology\/wappen\/[^)]+)\)/gi,
  )].map((match) => highQualityCrest(match[1]!));
  const score = numberFromScore(report[1]!);
  const season = row.match(/\|\s*\[([^|\]]+)\]\(https?:\/\/www\.transfermarkt\.com\/[^)]*saison_id\/\d+[^)]*\)/i)?.[1];
  const competitionMatches = [...row.matchAll(
    /\]\(https?:\/\/www\.transfermarkt\.com\/[^)]*\/(?:wettbewerb|pokalwettbewerb)\/[^)]*\s+"([^"]+)"\)/gi,
  )];
  const competition = competitionMatches[1]?.[1] ?? competitionMatches[0]?.[1] ?? "مباراة";
  const date = row.match(/\|\s*(\d{2}\/\d{2}\/\d{4})\s*\|/)?.[1] ?? null;

  return {
    id: report[3]!,
    season: season ? decode(season) : null,
    competition: decode(competition),
    date,
    homeTeam: teams[0]!.name,
    awayTeam: teams[1]!.name,
    homeTeamId: homeId,
    awayTeamId: awayId,
    homeCrestUrl: crestUrls[0] ?? highQualityCrest(`https://img.a.transfermarkt.technology/wappen/big/${homeId}.png`),
    awayCrestUrl: crestUrls[1] ?? highQualityCrest(`https://img.a.transfermarkt.technology/wappen/big/${awayId}.png`),
    homeScore: score[0],
    awayScore: score[1],
    result: resultFor(homeId, score[0], score[1]),
    matchReportUrl: report[2]!,
  } satisfies HeadToHeadMeeting;
}

export function parseTransfermarktMeetings(
  source: string,
  opponentId: number,
): HeadToHeadMeeting[] {
  const meetings = source.includes("<tr")
    ? [...source.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)]
        .map((match) => parseMeetingRow(match[1]!, opponentId))
    : source
        .split(/\r?\n/)
        .map((line) => parseMarkdownMeetingRow(line, opponentId));
  return [...new Map(
    meetings
      .filter((meeting): meeting is HeadToHeadMeeting => meeting !== null)
      .map((meeting) => [meeting.id, meeting]),
  ).values()];
}

function parseTopScorers(source: string): HeadToHeadScorer[] {
  const heading = source.search(/top fixture-goal scorers/i);
  if (heading < 0) return [];
  const section = source.slice(heading).split(/\n#{1,3}\s+/)[0]!;
  const scorers: HeadToHeadScorer[] = [];
  const players = [...section.matchAll(
    /!\[[^\]]*\]\((https?:\/\/img\.a\.transfermarkt\.technology\/portrait\/[^)]+)\)[\s\S]*?\[([^\]]+)\]\(https?:\/\/www\.transfermarkt\.com\/[^)]*\/spieler\/(\d+)[^)]*\)/gi,
  )];
  for (let index = 0; index < players.length; index += 1) {
    const player = players[index]!;
    const nextPlayerOffset = players[index + 1]?.index ?? section.length;
    const tail = section.slice((player.index ?? 0) + player[0].length, nextPlayerOffset);
    const goalsMatch = tail.match(
      /\[(\d+)\]\(https?:\/\/www\.transfermarkt\.com\/jumplist\/bilanz\/spieler\/\d+/i,
    );
    scorers.push({
      name: decode(player[2]!),
      photoUrl: highQualityPortrait(player[1]!),
      goals: goalsMatch ? Number(goalsMatch[1]) : null,
      appearances: null,
    });
  }
  return [...new Map(scorers.map((scorer) => [scorer.name, scorer])).values()];
}

async function fetchText(url: string, headers: Record<string, string> = {}) {
  let lastError: unknown;
  for (let attempt = 0; attempt < 3; attempt += 1) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    let release: (() => void) | undefined;
    try {
      const previous = transfermarktQueue;
      transfermarktQueue = new Promise<void>((resolve) => {
        release = resolve;
      });
      await previous;
      await new Promise((resolve) => setTimeout(resolve, 150));
      const response = await fetch(url, {
        headers: {
          "User-Agent": USER_AGENT,
          ...headers,
        },
        signal: controller.signal,
      });
      if (response.ok) return await response.text();
      lastError = new Error(`Transfermarkt ${response.status}`);
      const retryable = response.status === 408 || response.status === 429 || response.status >= 500;
      if (!retryable) throw lastError;
    } catch (error) {
      lastError = error;
      if (attempt === 2) throw error;
    } finally {
      // Release the next request even when the upstream or parser fails.
      release?.();
      clearTimeout(timer);
    }
    await new Promise((resolve) => setTimeout(resolve, 300 * 2 ** attempt));
  }
  throw lastError instanceof Error ? lastError : new Error("Transfermarkt unavailable");
}

async function fetchTransfermarktPage(url: string) {
  const readerUrl = `${READER_PREFIX}${url.replace(/^https?:\/\//i, "")}`;
  try {
    // The reader is intentionally tried first. A direct 202 response from
    // Transfermarkt can poison the same outbound session for the reader.
    const reader = await fetchText(readerUrl, {
      "X-Return-Format": "markdown",
      "User-Agent": "curl/8.0",
    });
    if (
      reader.trim().length > 500 &&
      /spielbericht|record vs|bilanz|\/verein\//i.test(reader)
    ) {
      return { content: reader, status: "reader" as const };
    }
  } catch {
    // Fall through to the direct origin if the reader is unavailable.
  }

  try {
    const direct = await fetchText(url);
    if (
      direct.trim().length > 500 &&
      /spielbericht|\/verein\/|record vs|top fixture-goal/i.test(direct)
    ) {
      return { content: direct, status: "live" as const };
    }
  } catch {
    // The direct origin often returns a bot-protection response in cloud runtimes.
  }

  throw new Error("Transfermarkt page is empty");
}

function pageUrl(baseUrl: string, page: number) {
  const withoutPage = baseUrl.replace(/\/page\/\d+(?=\/|$)/i, "");
  return page === 1 ? withoutPage : `${withoutPage}/page/${page}`;
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
  "ceramica cleopatra": 57439,
  "ceramica": 57439,
  "cleopatra fc": 57439,
  "سيراميكا كليوباترا": 57439,
  "سيراميكا": 57439,
  "al ahly": 7,
  "al ahly sc": 7,
  "al ahly fc": 7,
  "الأهلي": 7,
  "الاهلي": 7,
  "zamalek": 664,
  "zamalek sc": 664,
  "الزمالك": 664,
  "pyramids fc": 44664,
  "pyramids": 44664,
  "بيراميدز": 44664,
  "enppi": 9218,
  "enppi club": 9218,
  "enppi sc": 9218,
  "انبي": 9218,
  "إنبي": 9218,
  "القناة": 24297,
  "qanah": 24297,
  "qanah fc": 24297,
  "أبو قير للأسمدة": 39575,
  "abo qir fertilizers": 39575,
  "abu qir fertilizers": 39575,
  "البنك الأهلي": 62448,
  "bank el ahly": 62448,
  "national bank of egypt": 62448,
  "بترول أسيوط": 16216,
  "petrol asyut": 16216,
  "asyut petrol": 16216,
  "م.السـويس بتروجت": 10957,
  "م.السويس بتروجت": 10957,
  "بتروجت": 10957,
  "suez petrojet fc": 10957,
  "petrojet": 10957,
  "المقاولون العرب": 3369,
  "el mokawloon sc": 3369,
  "arab contractors": 3369,
  "سموحة": 23387,
  "smouha": 23387,
  "smouha sc": 23387,
  "مودرن سبورت": 68770,
  "modern sport club": 68770,
  "modern future": 68770,
  "طلائع الجيش": 9219,
  "tala'ea el gaish": 9219,
  "talaea el gaish": 9219,
  "زد": 47010,
  "زد اف سي": 47010,
  "zed fc": 47010,
  "وادي دجلة": 18234,
  "wadi degla": 18234,
  "wadi degla fc": 18234,
  "الشرقية إنبي": 9218,
  "el sharkia enppi fc": 9218,
  "الجونة": 20572,
  "el gouna": 20572,
  "el gouna fc": 20572,
  "غزل المحلة": 13446,
  "ghazl el mahalla": 13446,
  "ghazl mahalla": 13446,
};
const normalizedOpponentIds = new Map(
  Object.entries(knownOpponentIds).map(([name, id]) => [normalizeName(name), id]),
);
const persistedSnapshots = Object.values(transfermarktSnapshots as Record<string, HeadToHeadData>);

async function resolveOpponentId(name: string) {
  const normalized = normalizeName(name);
  const known = knownOpponentIds[normalized] ?? normalizedOpponentIds.get(normalized);
  if (known) return known;
  const cached = opponentCache.get(normalized);
  if (cached && cached.expiresAt > Date.now()) return cached.id;

  const searchUrl = `${TRANSFERMARKT}/schnellsuche/ergebnis/schnellsuche?query=${encodeURIComponent(name)}`;
  const { content } = await fetchTransfermarktPage(searchUrl);
  const matches = [...content.matchAll(
    /<a\b[^>]*href=["'][^"']*\/(?:startseite\/)?verein\/(\d+)[^"']*["'][^>]*>([\s\S]*?)<\/a>/gi,
  )];
  const markdownMatches = [...content.matchAll(
    /\]\((?:https?:\/\/www\.transfermarkt\.com)?\/?[^)]*\/(?:startseite\/)?verein\/(\d+)[^)]*\s+"([^"]+)"\)/gi,
  )];
  const wanted = normalizeName(name);
  const exact = matches.find((match) => normalizeName(decode(match[2]!)).includes(wanted));
  const fromMarkdown = markdownMatches.find((match) => normalizeName(match[2]!).includes(wanted));
  const id = Number((exact ?? fromMarkdown ?? matches[0] ?? markdownMatches[0])?.[1]);
  if (!Number.isInteger(id) || id <= 0) {
    throw new Error("Transfermarkt opponent not found");
  }
  opponentCache.set(normalized, {
    expiresAt: Date.now() + 7 * 24 * 60 * 60_000,
    id,
  });
  return id;
}

function summaryFor(meetings: HeadToHeadMeeting[]) {
  const played = meetings.filter(
    (meeting) => meeting.homeScore != null && meeting.awayScore != null,
  );
  return {
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
}

export async function loadTransfermarktHeadToHead(opponentName: string) {
  const opponentId = await resolveOpponentId(opponentName);
  const cached = cache.get(opponentId);
  if (cached && cached.expiresAt > Date.now()) return cached.data;
  const pending = inFlight.get(opponentId);
  if (pending) return pending;

  const request = (async () => {
    const baseUrl = `${TRANSFERMARKT}/vergleich/bilanzdetail/verein/${EL_MASRY_ID}/gegner_id/${opponentId}`;
    let meetings: HeadToHeadMeeting[] = [];
    let topScorers: HeadToHeadScorer[] = [];
    let sourceStatus: "live" | "reader" | "cached" = "live";
    let sourceUrl = baseUrl;
    let fetchedAt = new Date().toISOString();

    try {
      for (let page = 1; page <= MAX_PAGES; page += 1) {
        const fetched = await fetchTransfermarktPage(pageUrl(baseUrl, page));
        sourceStatus = fetched.status;
        if (page === 1) {
          topScorers = parseTopScorers(fetched.content);
        }
        const current = parseTransfermarktMeetings(fetched.content, opponentId);
        const before = meetings.length;
        meetings = [...new Map(
          [...meetings, ...current].map((meeting) => [meeting.id, meeting]),
        ).values()];
        if (current.length === 0 || meetings.length === before) break;
      }
      if (meetings.length === 0) throw new Error("Transfermarkt head-to-head is empty");
      // Transfermarkt includes future fixtures on the same page. This API is
      // the historical record, so only return matches with a final score.
      meetings = meetings.filter(
        (meeting) => meeting.homeScore != null && meeting.awayScore != null,
      );
    } catch (error) {
      const snapshot =
        persistedSnapshots.find((item) => item.opponent.id === opponentId) ??
        (opponentId === 3963 ? (transfermarktSnapshot as unknown as HeadToHeadData) : null);
      if (!snapshot) throw error;
      meetings = snapshot.meetings.map((meeting) => ({
        ...meeting,
        homeCrestUrl: highQualityCrest(meeting.homeCrestUrl),
        awayCrestUrl: highQualityCrest(meeting.awayCrestUrl),
      }));
      sourceStatus = "cached";
      sourceUrl = `${snapshot.source.url}#cached-snapshot`;
      fetchedAt = new Date().toISOString();
    }

    const opponentMeeting = meetings.find(
      (meeting) => meeting.homeTeamId === opponentId || meeting.awayTeamId === opponentId,
    );
    const data: HeadToHeadData = {
      opponent: {
        id: opponentId,
        name: opponentMeeting
          ? opponentMeeting.homeTeamId === opponentId
            ? opponentMeeting.homeTeam
            : opponentMeeting.awayTeam
          : opponentName,
      },
      source: {
        name: "Transfermarkt",
        url: sourceUrl,
        fetchedAt,
        status: sourceStatus,
      },
      summary: summaryFor(meetings),
      topScorer: topScorers[0] ?? null,
      topScorers,
      meetings,
    };
    cache.set(opponentId, {
      expiresAt: Date.now() + 6 * 60 * 60_000,
      data,
    });
    return data;
  })();
  inFlight.set(opponentId, request);
  try {
    return await request;
  } finally {
    inFlight.delete(opponentId);
  }
}