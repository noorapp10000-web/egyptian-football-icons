const FILGOAL = "https://www.filgoal.com";
const TEAM_ID = 8;
const TEAM_NAME = "المصري البورسعيدي";
const LEAGUE_ID = 1667;
const USER_AGENT =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0 Safari/537.36";
const REQUEST_TIMEOUT_MS = 12_000;

export type Team = {
  id: number | null;
  name: string;
  crestUrl: string | null;
};

export type Match = {
  id: string;
  matchId: number;
  slug: string;
  competition: string;
  competitionId: number | null;
  round: string | null;
  kickoff: string | null;
  kickoffText: string | null;
  venue: string | null;
  statusText: string;
  status: "upcoming" | "live" | "finished" | "postponed";
  homeTeam: Team;
  awayTeam: Team;
  homeScore: number | null;
  awayScore: number | null;
  url: string;
};

export type LineupPlayer = {
  id: number;
  name: string;
  number: number | null;
  position: string;
  photoUrl: string | null;
  minutesPlayed: number | null;
  isCaptain: boolean;
  isSpare: boolean;
};

export type MatchEvent = {
  id: number;
  minute: number | null;
  addedTime: number | null;
  type: string;
  half: string | null;
  teamId: number | null;
  teamName: string | null;
  player: string | null;
  playerPhotoUrl: string | null;
  relatedPlayer: string | null;
};

export type MatchDetail = Match & {
  referee: string | null;
  stadium: string | null;
  homeCoach: string | null;
  awayCoach: string | null;
  homeFormation: string | null;
  awayFormation: string | null;
  tvChannels: string[];
  events: MatchEvent[];
  timeline: MatchEvent[];
  stats: { possession: { home: number; away: number } | null; rows: StatRow[] };
  lineups: {
    home: LineupPlayer[];
    away: LineupPlayer[];
    homeBench: LineupPlayer[];
    awayBench: LineupPlayer[];
  };
};

export type StatRow = {
  key: string;
  label: string;
  home: number;
  away: number;
  unit: "percent" | "count";
};

export type SquadPlayer = {
  id: number;
  name: string;
  number: number | null;
  position: string;
  nationality: string;
  photoUrl: string | null;
  url: string;
  goals: number | null;
  appearances: number | null;
  scoringRate: number | null;
};

export type StandingRow = {
  rank: number;
  team: Team;
  played: number;
  won: number;
  drawn: number;
  lost: number;
  goalsFor: number;
  goalsAgainst: number;
  points: number;
  isMasry: boolean;
};

export type NewsItem = {
  id: string;
  title: string;
  url: string;
  imageUrl: string | null;
  publishedText: string | null;
  publishedAt: string | null;
  sourceName: string;
};

export type Source = {
  name: string;
  url: string;
  fetchedAt: string;
  status: "live" | "cached";
};

type CacheEntry<T> = { value: T; expiresAt: number; staleUntil: number; fetchedAt: number };
const cache = new Map<string, CacheEntry<unknown>>();

const decode = (value: string) =>
  value
    .replace(/<[^>]+>/g, " ")
    .replace(/&quot;|&#34;/gi, '"')
    .replace(/&#39;|&#x27;/gi, "'")
    .replace(/&amp;/gi, "&")
    .replace(/&nbsp;/gi, " ")
    .replace(/&#x2F;/gi, "/")
    .replace(/\s+/g, " ")
    .trim();

const absolute = (url: string | null | undefined) => {
  if (!url) return null;
  if (url.startsWith("//")) return `https:${url}`;
  if (url.startsWith("http://")) return url.replace("http://", "https://");
  if (url.startsWith("/")) return `${FILGOAL}${url}`;
  return url;
};

const num = (value: string | null | undefined) => {
  if (value == null) return null;
  const cleaned = value.replace(/[^\d.-]/g, "");
  if (!cleaned) return null;
  const parsed = Number(cleaned);
  return Number.isFinite(parsed) ? parsed : null;
};

async function fetchText(url: string) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": USER_AGENT,
        Accept: "text/html,application/xhtml+xml,application/xml",
        "Accept-Language": "ar,en;q=0.8",
      },
      signal: controller.signal,
    });
    if (!response.ok) throw new Error(`Upstream ${response.status}: ${url}`);
    return await response.text();
  } finally {
    clearTimeout(timer);
  }
}

async function cached<T>(
  key: string,
  ttlMs: number,
  staleMs: number,
  loader: () => Promise<T>,
): Promise<{ value: T; live: boolean; fetchedAt: number }> {
  const existing = cache.get(key) as CacheEntry<T> | undefined;
  const now = Date.now();
  if (existing && existing.expiresAt > now) {
    return { value: existing.value, live: false, fetchedAt: existing.fetchedAt };
  }
  try {
    const value = await loader();
    const fetchedAt = Date.now();
    cache.set(key, { value, expiresAt: fetchedAt + ttlMs, staleUntil: fetchedAt + staleMs, fetchedAt });
    return { value, live: true, fetchedAt };
  } catch (error) {
    if (existing && existing.staleUntil > now) {
      return { value: existing.value, live: false, fetchedAt: existing.fetchedAt };
    }
    throw error;
  }
}

const sourceOf = (name: string, url: string, live: boolean, fetchedAt: number): Source => ({
  name,
  url,
  fetchedAt: new Date(fetchedAt).toISOString(),
  status: live ? "live" : "cached",
});

const statusFromText = (text: string): Match["status"] => {
  if (text.includes("انته")) return "finished";
  if (text.includes("تأجل") || text.includes("ألغ")) return "postponed";
  if (text.includes("مباشر") || text.includes("الشوط") || text.includes("استراحة")) return "live";
  return "upcoming";
};

const kickoffIso = (text: string) => {
  const match = text.match(/(\d{2})-(\d{2})-(\d{4})\s*-\s*(\d{1,2}):(\d{2})/);
  if (!match) return null;
  const [, day, month, year, hour, minute] = match;
  return `${year}-${month}-${day}T${hour!.padStart(2, "0")}:${minute}:00+03:00`;
};

const teamFromBlock = (block: string): Team => ({
  id: num(block.match(/\/teams\/(\d+)\//i)?.[1] ?? null),
  name: decode(block.match(/<strong>([\s\S]*?)<\/strong>/i)?.[1] ?? "") || "غير معروف",
  crestUrl: absolute(block.match(/data-src="([^"]*Photos\/Team\/[^"]+)"/i)?.[1]),
});

export function parseTeamMatches(html: string): Match[] {
  return html
    .split('<div class="cin_cntnr">')
    .slice(1)
    .map((raw): Match | null => {
      const block = raw.split('<div class="cin_cntnr">')[0]!;
      const link = block.match(/href="(\/matches\/(\d+)\/[^"]*)"/i);
      if (!link) return null;
      const competition = block.match(
        /<p>\s*<a href="\/championships\/(\d+)\/[^"]*">([\s\S]*?)<\/a>/i,
      );
      const home = teamFromBlock(block.match(/<div class="f">([\s\S]*?)<div class="m">/i)?.[1] ?? "");
      const away = teamFromBlock(block.match(/<div class="s">([\s\S]*?)<\/div>\s*<\/div>/i)?.[1] ?? "");
      const statusText = decode(block.match(/<span class="status[^"]*">([\s\S]*?)<\/span>/i)?.[1] ?? "");
      const auxiliary = block.match(/<div class="match-aux">([\s\S]*?)<\/div>\s*<\/a>/i)?.[1] ?? "";
      const aux = [...auxiliary.matchAll(/<span>([\s\S]*?)<\/span>/gi)].map((m) => decode(m[1]!));
      const date = aux.find((value) => /\d{2}-\d{2}-\d{4}/.test(value)) ?? null;
      const venue = aux.find((value) => value && !/\d{2}-\d{2}-\d{4}/.test(value)) ?? null;
      const scores = [...block.matchAll(/<b>(?:<text>[\s\S]*?<\/text>)?\s*(\d+)\s*<\/b>/gi)].map((m) => Number(m[1]));
      const matchId = Number(link[2]);
      return {
        id: `filgoal-${matchId}`,
        matchId,
        slug: decodeURIComponent(link[1]!.split("/")[3] ?? ""),
        competition: decode(competition?.[2] ?? "مباراة"),
        competitionId: num(competition?.[1] ?? null),
        round: null,
        kickoff: date ? kickoffIso(date) : null,
        kickoffText: date,
        venue,
        statusText: statusText || "لم تبدأ",
        status: statusFromText(statusText),
        homeTeam: home,
        awayTeam: away,
        homeScore: scores.length >= 2 ? scores[0]! : null,
        awayScore: scores.length >= 2 ? scores[1]! : null,
        url: `${FILGOAL}${link[1]}`,
      };
    })
    .filter((match): match is Match => match !== null);
}

function sortMatches(matches: Match[]) {
  const upcoming = (match: Match) => match.status === "upcoming" || match.status === "postponed";
  return matches.sort((a, b) => {
    const group = (m: Match) => (m.status === "live" ? 0 : upcoming(m) ? 1 : 2);
    if (group(a) !== group(b)) return group(a) - group(b);
    return upcoming(a)
      ? (a.kickoff ?? "9999").localeCompare(b.kickoff ?? "9999")
      : (b.kickoff ?? "").localeCompare(a.kickoff ?? "");
  });
}

export async function loadMatches() {
  const resultsUrl = `${FILGOAL}/teams/${TEAM_ID}/matches-results/x`;
  const fixturesUrl = `${FILGOAL}/teams/${TEAM_ID}/matches-fixtures`;
  const entry = await cached("matches", 60 * 60_000, 24 * 60 * 60_000, async () => {
    const [results, fixtures] = await Promise.all([
      fetchText(resultsUrl).then(parseTeamMatches).catch(() => []),
      fetchText(fixturesUrl).then(parseTeamMatches).catch(() => []),
    ]);
    const matches = [...new Map([...results, ...fixtures].map((m) => [m.id, m])).values()];
    if (!matches.length) throw new Error("No matches returned by FilGoal");
    return sortMatches(matches);
  });
  return { matches: entry.value, source: sourceOf("FilGoal", resultsUrl, entry.live, entry.fetchedAt) };
}

const balancedJson = (input: string) => {
  let depth = 0;
  for (let index = 0; index < input.length; index += 1) {
    if (input[index] === "{" || input[index] === "[") depth += 1;
    if (input[index] === "}" || input[index] === "]") {
      depth -= 1;
      if (depth === 0) return input.slice(0, index + 1);
    }
  }
  return null;
};

const dateFromDotNet = (value: string | null | undefined) => {
  const milliseconds = value?.match(/\/Date\((-?\d+)\)\//)?.[1];
  return milliseconds ? new Date(Number(milliseconds)).toISOString() : null;
};

function mapLineup(raw: unknown, isSpare = false): LineupPlayer {
  const player = raw as Record<string, unknown>;
  return {
    id: Number(player.PersonId ?? 0),
    name: String(player.PersonName ?? ""),
    number: player.ShirtNumber == null ? null : Number(player.ShirtNumber),
    position: String(player.PlayerPositionName ?? "—"),
    photoUrl: absolute(String(player.PersonLogoUrl ?? "")),
    minutesPlayed: player.MinutesPlayed == null ? null : Number(player.MinutesPlayed),
    isCaptain: Boolean(player.IsCaptin),
    isSpare,
  };
}

function eventType(value: string) {
  const normalized = value.toLowerCase();
  if (normalized.includes("هدف") || normalized.includes("goal")) return "goal";
  if (normalized.includes("صفراء") || normalized.includes("yellow")) return "yellow";
  if (normalized.includes("حمراء") || normalized.includes("red")) return "red";
  if (normalized.includes("تبديل") || normalized.includes("sub")) return "substitution";
  return value || "event";
}

function parseMatchModel(html: string): MatchDetail | null {
  const start = html.indexOf("viewModelData");
  if (start === -1) return null;
  const jsonStart = html.indexOf("=", start);
  const json = balancedJson(html.slice(jsonStart + 1).trimStart());
  if (!json) return null;
  let model: Record<string, unknown>;
  try {
    model = JSON.parse(json) as Record<string, unknown>;
  } catch {
    return null;
  }
  const get = <T>(key: string) => model[key] as T;
  const homeId = Number(get<number>("HomeTeamId"));
  const awayId = Number(get<number>("AwayTeamId"));
  const squads = (get<unknown[]>("MatchTeamsSquads") ?? []) as unknown[];
  const filterSquad = (teamId: number, spare: boolean) =>
    squads
      .filter((raw) => {
        const item = raw as Record<string, unknown>;
        return Number(item.TeamId) === teamId && Boolean(item.IsSpare) === spare;
      })
      .map((raw) => mapLineup(raw, spare));
  const homePlayers = squads.length
    ? filterSquad(homeId, false)
    : ((get<unknown[]>("HomeTeamSquad") ?? []) as unknown[]).map((raw) => mapLineup(raw));
  const awayPlayers = squads.length
    ? filterSquad(awayId, false)
    : ((get<unknown[]>("AwayTeamSquad") ?? []) as unknown[]).map((raw) => mapLineup(raw));
  const homeBench = squads.length
    ? filterSquad(homeId, true)
    : ((get<unknown[]>("HomeTeamSpareSquad") ?? []) as unknown[]).map((raw) => mapLineup(raw, true));
  const awayBench = squads.length
    ? filterSquad(awayId, true)
    : ((get<unknown[]>("AwayTeamSpareSquad") ?? []) as unknown[]).map((raw) => mapLineup(raw, true));
  const events = ((get<unknown[]>("Events") ?? []) as unknown[]).map((raw, index) => {
    const item = raw as Record<string, unknown>;
    return {
      id: Number(item.Id ?? index),
      minute: num(String(item.CalculatedTime ?? "")),
      addedTime: num(String(item.CalculatedAdditionalTime ?? "")),
      type: eventType(String(item.MatchEventTypeName ?? "")),
      half: item.MatchStatusName == null ? null : String(item.MatchStatusName),
      teamId: item.TeamId == null ? null : Number(item.TeamId),
      teamName: item.TeamName == null ? null : String(item.TeamName),
      player: item.PlayerAName == null ? null : String(item.PlayerAName),
      playerPhotoUrl: absolute(String(item.PlayerALogoUrl ?? "")),
      relatedPlayer: item.PlayerBName == null ? null : String(item.PlayerBName),
    } satisfies MatchEvent;
  });
  events.sort((a, b) => (a.minute ?? 999) - (b.minute ?? 999));
  const statusText = String((get<Record<string, unknown>>("CurrentMatchStatus")?.MatchStatusName as string) ?? "");
  const id = Number(get<number>("Id"));
  const slug = String(get<string>("Slug") ?? "");
  return {
    id: `filgoal-${id}`,
    matchId: id,
    slug,
    competition: String(get<string>("ChampionshipName") ?? ""),
    competitionId: get<number>("ChampionshipId") ?? null,
    round: String(get<string>("WeekOrRound") ?? "").trim() || null,
    kickoff: dateFromDotNet(get<string>("Date")),
    kickoffText: null,
    venue: get<string>("StadiumName") ?? null,
    statusText: statusText || "لم تبدأ",
    status: statusFromText(statusText),
    homeTeam: { id: homeId, name: String(get<string>("HomeTeamName") ?? ""), crestUrl: absolute(get<string>("HomeTeamLogoUrl")) },
    awayTeam: { id: awayId, name: String(get<string>("AwayTeamName") ?? ""), crestUrl: absolute(get<string>("AwayTeamLogoUrl")) },
    homeScore: get<number>("HomeScore") ?? null,
    awayScore: get<number>("AwayScore") ?? null,
    url: `${FILGOAL}/matches/${id}/${slug}`,
    referee: get<string>("RefereeName") ?? null,
    stadium: get<string>("StadiumName") ?? null,
    homeCoach: get<string>("HomeTeamCoachName") ?? null,
    awayCoach: get<string>("AwayTeamCoachName") ?? null,
    homeFormation: get<string>("HomeTeamFormationName") ?? null,
    awayFormation: get<string>("AwayTeamFormationName") ?? null,
    tvChannels: ((get<unknown[]>("TvCoverage") ?? []) as unknown[]).map((item) =>
      String((item as Record<string, unknown>).TvChannelName ?? ""),
    ),
    events,
    timeline: events,
    stats: { possession: null, rows: [] },
    lineups: { home: homePlayers, away: awayPlayers, homeBench, awayBench },
  };
}

export async function loadMatchDetail(matchId: number) {
  const { matches } = await loadMatches();
  const known = matches.find((match) => match.matchId === matchId);
  const url = `${FILGOAL}/matches/${matchId}/coverage/${known?.slug ?? "x"}`;
  const entry = await cached(`match-${matchId}`, 60 * 60_000, 7 * 24 * 60 * 60_000, async () => {
    const html = await fetchText(url);
    const detail = parseMatchModel(html) ?? parseMatchModel(await fetchText(known?.url ?? `${FILGOAL}/matches/${matchId}/x`));
    if (!detail) throw new Error("Match detail is unavailable");
    return detail;
  });
  return { match: entry.value, source: sourceOf("FilGoal", entry.value.url, entry.live, entry.fetchedAt) };
}

export function parseSquad(html: string): SquadPlayer[] {
  const body = html.match(/قائمة اللاعبين[\s\S]*?<tbody[^>]*>([\s\S]*?)<\/tbody>/i)?.[1] ?? "";
  const players = [...body.matchAll(/<tr>([\s\S]*?)<\/tr>/gi)]
    .map((match): SquadPlayer | null => {
      const cells = [...match[1]!.matchAll(/<td>([\s\S]*?)<\/td>/gi)].map((cell) => cell[1]!);
      const link = cells[1]?.match(/href="(\/(?:players|persons)\/(\d+)\/[^"]*)"/i);
      if (!link) return null;
      return {
        id: Number(link[2]),
        name: decode(cells[1]!.match(/<span>([\s\S]*?)<\/span>/i)?.[1] ?? ""),
        number: num(decode(cells[0]!)),
        position: decode(cells[2] ?? "") || "—",
        nationality: decode(cells[3] ?? "") || "—",
        photoUrl: absolute(cells[1]!.match(/data-src="([^"]+)"/i)?.[1]),
        url: `${FILGOAL}${link[1]}`,
        goals: null,
        appearances: null,
        scoringRate: null,
      };
    })
    .filter((player): player is SquadPlayer => player !== null && Boolean(player.name));
  return [...new Map(players.map((player) => [player.id, player])).values()];
}

function parseScorers(html: string) {
  return [...html.matchAll(/<div class="fg_rw">([\s\S]*?)(?=<div class="fg_rw">|$)/gi)]
    .map((match) => {
      const row = match[1]!;
      const id = row.match(/href="\/[Pp]layers\/(\d+)\//i)?.[1];
      if (!id) return null;
      const cells = [...row.matchAll(/<div class="fg_cl t2">([\s\S]*?)<\/div>/gi)].map((cell) => num(decode(cell[1]!)));
      return { id: Number(id), goals: cells[0] ?? null, appearances: cells[1] ?? null, scoringRate: num(row.match(/data-value="(\d+)"/i)?.[1] ?? null) };
    })
    .filter((value): value is { id: number; goals: number | null; appearances: number | null; scoringRate: number | null } => value !== null);
}

function parseCoach(html: string) {
  const head = html.match(/<div id="hd"[\s\S]*?<div class="s">([\s\S]*?)<ul>/i)?.[1] ?? "";
  return {
    name: decode(head.match(/<span>\s*([^<]+?)\s*<b/i)?.[1] ?? "") || null,
    role: "المدير الفني",
    photoUrl: absolute(head.match(/data-src="([^"]*Photos\/Person\/[^"]+)"/i)?.[1]),
    crestUrl: `https://semedia.filgoal.com/Photos/Team/Medium/${TEAM_ID}.png`,
  };
}

export async function loadSquad() {
  const playersUrl = `${FILGOAL}/teams/${TEAM_ID}/players/${encodeURIComponent("المصري")}`;
  const entry = await cached("squad", 24 * 60 * 60_000, 7 * 24 * 60 * 60_000, async () => {
    const [playersHtml, scorersHtml] = await Promise.all([
      fetchText(playersUrl),
      fetchText(`${FILGOAL}/teams/${TEAM_ID}/scorers/x`).catch(() => ""),
    ]);
    const players = parseSquad(playersHtml);
    if (!players.length) throw new Error("Squad is unavailable");
    const byId = new Map(parseScorers(scorersHtml).map((scorer) => [scorer.id, scorer]));
    return {
      players: players.map((player) => ({ ...player, ...(byId.get(player.id) ?? {}) })),
      coach: parseCoach(playersHtml),
      scorers: parseScorers(scorersHtml),
    };
  });
  return { ...entry.value, source: sourceOf("FilGoal", playersUrl, entry.live, entry.fetchedAt) };
}

export async function loadTeam() {
  const squad = await loadSquad();
  return {
    team: { id: TEAM_ID, name: TEAM_NAME, crestUrl: `https://semedia.filgoal.com/Photos/Team/Medium/${TEAM_ID}.png` },
    ...squad,
  };
}

export function parseStandings(html: string): StandingRow[] {
  const table = html.split('<div class="fg_tbl a arg expandable">')[1] ?? html;
  return [...table.matchAll(/<div class="fg_rw active">([\s\S]*?)(?=<div class="fg_rw|$)/gi)]
    .map((match): StandingRow | null => {
      const row = match[1]!;
      const rank = num(decode(row.match(/<div class="fg_cl t1">([\s\S]*?)<\/div>/i)?.[1] ?? ""));
      const teamCell = row.match(/<div class="fg_cl t2[^"]*">([\s\S]*?)<\/div>/i)?.[1] ?? "";
      const teamId = num(teamCell.match(/data-tmid="(\d+)"/i)?.[1] ?? null);
      const teamName = decode(teamCell.replace(/<img[^>]*>/gi, ""));
      const crestUrl = absolute(teamCell.match(/data-src="([^"]+)"/i)?.[1]);
      const values = [...row.matchAll(/<div class="fg_cl t3(?: ex)?">([\s\S]*?)<\/div>/gi)].map((m) => num(decode(m[1]!)) ?? 0);
      if (rank == null || !teamName) return null;
      return {
        rank,
        team: { id: teamId, name: teamName, crestUrl },
        played: values[0] ?? 0,
        won: values[1] ?? 0,
        drawn: values[3] ?? 0,
        lost: values[2] ?? 0,
        goalsFor: values[4] ?? 0,
        goalsAgainst: values[5] ?? 0,
        points: values.at(-1) ?? 0,
        isMasry: teamId === TEAM_ID,
      };
    })
    .filter((row): row is StandingRow => row !== null);
}

export async function loadStandings() {
  const url = `${FILGOAL}/championships/${LEAGUE_ID}/standings/x`;
  const entry = await cached("standings", 2 * 60 * 60_000, 24 * 60 * 60_000, async () => {
    const rows = parseStandings(await fetchText(url));
    if (!rows.length) throw new Error("Standings are unavailable");
    return rows;
  });
  return { standings: entry.value, source: sourceOf("FilGoal", url, entry.live, entry.fetchedAt) };
}

const publishedAt = (value: string | null) => {
  if (!value) return null;
  const date = new Date(decode(value));
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
};

export function parseFilGoalNews(html: string): NewsItem[] {
  return [...html.matchAll(/<li>\s*<a href="(\/articles\/(\d+)\/[^"]*)"([\s\S]*?)<\/a>\s*<\/li>/gi)]
    .map((match): NewsItem | null => {
      const chunk = match[0]!;
      const title = decode(chunk.match(/<h6>([\s\S]*?)<\/h6>/i)?.[1] ?? chunk.match(/<a[^>]*>([\s\S]*?)<\/a>/i)?.[1] ?? "");
      if (!title) return null;
      const dateText = chunk.match(/<span[^>]*>([\s\S]*?(?:\d{4}|[٠-٩]{4})[\s\S]*?)<\/span>/i)?.[1] ?? null;
      return {
        id: `filgoal-${match[2]}`,
        title,
        url: `${FILGOAL}${match[1]}`,
        imageUrl: absolute(chunk.match(/(?:data-src|data-original|src)="([^"]+)"/i)?.[1]),
        publishedText: dateText ? decode(dateText) : null,
        publishedAt: publishedAt(dateText),
        sourceName: "FilGoal",
      };
    })
    .filter((item): item is NewsItem => item !== null);
}

function parseRssNews(xml: string): NewsItem[] {
  return [...xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)]
    .map((match): NewsItem | null => {
      const item = match[1]!;
      const title = decode(item.match(/<title>([\s\S]*?)<\/title>/i)?.[1] ?? "");
      const url = decode(item.match(/<link>([\s\S]*?)<\/link>/i)?.[1] ?? "");
      if (!title || !url) return null;
      const date = decode(item.match(/<pubDate>([\s\S]*?)<\/pubDate>/i)?.[1] ?? "");
      return {
        id: `rss-${Buffer.from(url).toString("base64url").slice(-32)}`,
        title,
        url,
        imageUrl: absolute(item.match(/<media:(?:content|thumbnail)[^>]+url=["']([^"']+)/i)?.[1]),
        publishedText: date || null,
        publishedAt: publishedAt(date),
        sourceName: decode(item.match(/<source[^>]*>([\s\S]*?)<\/source>/i)?.[1] ?? "أخبار"),
      };
    })
    .filter((item): item is NewsItem => item !== null);
}

export async function loadNews() {
  const teamUrl = `${FILGOAL}/teams/${TEAM_ID}/articles/${encodeURIComponent("المصري")}`;
  const rssUrl = `https://news.google.com/rss/search?q=${encodeURIComponent('"المصري البورسعيدي" OR "النادي المصري"')}&hl=ar&gl=EG&ceid=EG:ar`;
  const entry = await cached("news", 60 * 60_000, 6 * 60 * 60_000, async () => {
    const [filgoal, rss] = await Promise.all([
      fetchText(teamUrl).then(parseFilGoalNews).catch(() => []),
      fetchText(rssUrl).then(parseRssNews).catch(() => []),
    ]);
    const items = [...new Map([...filgoal, ...rss].map((item) => [item.url, item])).values()]
      .filter((item) => !/الألومنيوم|مصري المقاصة/.test(item.title))
      .sort((a, b) => Date.parse(b.publishedAt ?? "") - Date.parse(a.publishedAt ?? ""))
      .slice(0, 40);
    if (!items.length) throw new Error("News is unavailable");
    return items;
  });
  return { news: entry.value, source: sourceOf("FilGoal + Google News", teamUrl, entry.live, entry.fetchedAt) };
}

export async function loadPlayerDetail(playerId: number) {
  const url = `${FILGOAL}/players/${playerId}/x`;
  const entry = await cached(`player-${playerId}`, 2 * 60 * 60_000, 24 * 60 * 60_000, async () => {
    const html = await fetchText(url);
    const head = html.match(/<div id="dhd">([\s\S]*?)<div class="bd">/i)?.[1] ?? html;
    const name = decode(head.match(/<h1>([\s\S]*?)<\/h1>/i)?.[1] ?? "");
    if (!name) throw new Error("Player is unavailable");
    return {
      id: playerId,
      name,
      role: decode(head.match(/data-player-position="([^"]*)"/i)?.[1] ?? "") || null,
      photoUrl: absolute(head.match(/data-src="([^"]*Photos\/Person\/[^"]+)"/i)?.[1]),
      url,
    };
  });
  return { player: entry.value, source: sourceOf("FilGoal", url, entry.live, entry.fetchedAt) };
}