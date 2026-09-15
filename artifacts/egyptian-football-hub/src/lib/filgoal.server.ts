/**
 * طبقة قراءة البيانات من المصادر (FilGoal + Yallakora).
 * كل القراءات تحدث على السيرفر مع كاش مشترك، فلا يتصل المستخدم بالمصادر مباشرة.
 */

import { normalizeEventType } from "./match-events";

export const TEAM_ID = 8;
export const LEAGUE_ID = 1667;
export const SEASON = "2026-2027";

const UA =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36";
const TIMEOUT_MS = 12_000;

const FG = "https://www.filgoal.com";

export type Source = {
  name: string;
  url: string;
  fetchedAt: string;
  status: "live" | "cached";
};

export type Team = { id: number | null; name: string; crestUrl: string | null };

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
  sourceName: string;
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
  /** حدث مستنتج من التعليق الحي (ركنية، تسلل، إصابة...) وليس من قائمة الأحداث الرسمية. */
  derived?: boolean;
  /** نص التعليق المرتبط بالحدث المستنتج. */
  text?: string | null;
};

export type StatRow = {
  key: string;
  label: string;
  home: number;
  away: number;
  unit: "percent" | "count";
};

export type MatchStats = {
  possession: { home: number; away: number } | null;
  rows: StatRow[];
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
  /** كل أحداث المباراة: الرسمية + المستنتجة من التعليق، مرتبة بالدقيقة. */
  timeline: MatchEvent[];
  stats: MatchStats;
  lineups: {
    home: LineupPlayer[];
    away: LineupPlayer[];
    homeBench: LineupPlayer[];
    awayBench: LineupPlayer[];
  };
  commentary: { id: number; minute: number | null; text: string; half: string | null }[];
};


/* ---------------------------------- utils --------------------------------- */

const nowIso = () => new Date().toISOString();

const decode = (value: string) =>
  value
    .replace(/<[^>]+>/g, " ")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&amp;/g, "&")
    .replace(/&nbsp;/g, " ")
    .replace(/\s+/g, " ")
    .trim();

const absolute = (url: string | null | undefined) => {
  if (!url) return null;
  if (url.startsWith("//")) return `https:${url}`;
  if (url.startsWith("http://")) return url.replace("http://", "https://");
  if (url.startsWith("/")) return `${FG}${url}`;
  return url;
};

const num = (value: string | null | undefined) => {
  if (value == null) return null;
  const cleaned = value.replace(/[^\d.-]/g, "");
  if (!cleaned) return null;
  const parsed = Number(cleaned);
  return Number.isFinite(parsed) ? parsed : null;
};

async function fetchHtml(url: string) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const response = await fetch(url, {
      headers: {
        "User-Agent": UA,
        Accept: "text/html,application/xhtml+xml",
        "Accept-Language": "ar,en;q=0.8",
      },
      signal: controller.signal,
    });
    if (!response.ok) throw new Error(`${response.status} من ${url}`);
    return await response.text();
  } finally {
    clearTimeout(timer);
  }
}

/** كاش بسيط داخل الذاكرة لكل قيمة، مع الاحتفاظ بآخر بيانات ناجحة عند فشل المصدر. */
type CacheEntry<T> = { value: T; at: number; live: boolean };
const cache = new Map<string, CacheEntry<unknown>>();

function matchesCacheTtl(matches: Match[] | undefined) {
  if (!matches || matches.length === 0) return 60 * 60_000;
  if (matches.some((match) => match.status === "live")) return 20_000;

  const now = Date.now();
  const soon = matches.some((match) => {
    if (match.status !== "upcoming" || !match.kickoff) return false;
    const kickoff = new Date(match.kickoff).getTime();
    if (!Number.isFinite(kickoff)) return false;
    const diff = kickoff - now;
    return diff <= 90 * 60_000 && diff > -3 * 60 * 60_000;
  });
  return soon ? 60_000 : 60 * 60_000;
}

async function cached<T>(key: string, ttlMs: number, loader: () => Promise<T>) {
  const hit = cache.get(key) as CacheEntry<T> | undefined;
  if (hit && Date.now() - hit.at < ttlMs) return hit;
  try {
    const value = await loader();
    const entry: CacheEntry<T> = { value, at: Date.now(), live: true };
    cache.set(key, entry);
    return entry;
  } catch (error) {
    console.error(`فشل تحديث ${key}:`, error);
    if (hit) return { ...hit, live: false };
    throw error;
  }
}

const sourceOf = (name: string, url: string, live: boolean, at: number): Source => ({
  name,
  url,
  fetchedAt: new Date(at).toISOString(),
  status: live ? "live" : "cached",
});

/* -------------------------------- parsers --------------------------------- */

const statusFromText = (text: string): Match["status"] => {
  if (text.includes("انته")) return "finished";
  if (text.includes("تأجل") || text.includes("ألغيت")) return "postponed";
  if (text.includes("مباشر") || text.includes("الشوط") || text.includes("استراحة"))
    return "live";
  return "upcoming";
};

const kickoffIso = (text: string) => {
  const m = text.match(/(\d{2})-(\d{2})-(\d{4})\s*-\s*(\d{1,2}):(\d{2})/);
  if (!m) return null;
  const [, d, mo, y, h = "", mi = ""] = m;
  return `${y}-${mo}-${d}T${h.padStart(2, "0")}:${mi}:00+03:00`;
};

const teamFromBlock = (block: string): Team => {
  const id = num(block.match(/\/teams\/(\d+)\//i)?.[1] ?? null);
  const name = decode(block.match(/<strong>([\s\S]*?)<\/strong>/i)?.[1] ?? "");
  const crest = block.match(/data-src="([^"]*Photos\/Team\/[^"]+)"/i)?.[1];
  return { id, name: name || "غير معروف", crestUrl: absolute(crest) };
};

export function parseTeamMatches(html: string): Match[] {
  const blocks = html.split('<div class="cin_cntnr">').slice(1);
  return blocks
    .map((raw): Match | null => {
      const block = raw.split('<div class="cin_cntnr">')[0]!;
      const matchLink = block.match(/href="(\/matches\/(\d+)\/[^"]*)"/i);
      if (!matchLink) return null;
      const competitionBlock = block.match(/<p>\s*<a href="\/championships\/(\d+)\/[^"]*">([\s\S]*?)<\/a>/i);
      const homeBlock = block.match(/<div class="f">([\s\S]*?)<div class="m">/i)?.[1] ?? "";
      const awayBlock = block.match(/<div class="s">([\s\S]*?)<\/div>\s*<\/div>/i)?.[1] ?? "";
      const statusText = decode(block.match(/<span class="status[^"]*">([\s\S]*?)<\/span>/i)?.[1] ?? "");
      const aux = block.match(/<div class="match-aux">([\s\S]*?)<\/div>\s*<\/a>/i)?.[1] ?? "";
      const auxParts = [...aux.matchAll(/<span>([\s\S]*?)<\/span>/gi)]
        .map((m) => decode(m[1]!))
        .filter(Boolean);
      const dateText = auxParts.find((v) => /\d{2}-\d{2}-\d{4}/.test(v)) ?? null;
      const venue = auxParts.find((v) => v && !/\d{2}-\d{2}-\d{4}/.test(v)) ?? null;
      const home = teamFromBlock(homeBlock);
      const away = teamFromBlock(awayBlock);
      const scores = [...block.matchAll(/<b>(?:<text>[\s\S]*?<\/text>)?\s*(\d+)\s*<\/b>/gi)].map(
        (m) => Number(m[1]),
      );
      const matchId = Number(matchLink[2]);

      return {
        id: `filgoal-${matchId}`,
        matchId,
        slug: decodeURIComponent(matchLink[1]!.split("/")[3] ?? ""),
        competition: decode(competitionBlock?.[2] ?? "مباراة"),
        competitionId: num(competitionBlock?.[1] ?? null),
        round: null,
        kickoff: dateText ? kickoffIso(dateText) : null,
        kickoffText: dateText,
        venue,
        statusText: statusText || "لم تبدأ",
        status: statusFromText(statusText),
        homeTeam: home,
        awayTeam: away,
        homeScore: scores.length >= 2 ? scores[0]! : null,
        awayScore: scores.length >= 2 ? scores[1]! : null,
        url: `${FG}${matchLink[1]}`,
      } satisfies Match;
    })
    .filter((m): m is Match => m !== null);
}

export function parseSquad(html: string): SquadPlayer[] {
  const body = html.match(/قائمة اللاعبين[\s\S]*?<tbody[^>]*>([\s\S]*?)<\/tbody>/i)?.[1] ?? "";
  const rows = [...body.matchAll(/<tr>([\s\S]*?)<\/tr>/gi)].map((m) => m[1]!);
  const players = rows
    .map((row): SquadPlayer | null => {
      const cells = [...row.matchAll(/<td>([\s\S]*?)<\/td>/gi)].map((m) => m[1]!);
      if (cells.length < 4) return null;
      const link = cells[1]!.match(/href="(\/players\/(\d+)\/[^"]*)"/i);
      if (!link) return null;
      const photo = cells[1]!.match(/data-src="([^"]+)"/i)?.[1];
      return {
        id: Number(link[2]),
        name: decode(cells[1]!.match(/<span>([\s\S]*?)<\/span>/i)?.[1] ?? ""),
        number: num(decode(cells[0]!)),
        position: decode(cells[2]!) || "—",
        nationality: decode(cells[3]!) || "—",
        photoUrl: absolute(photo),
        url: `${FG}${link[1]}`,
        goals: null,
        appearances: null,
        scoringRate: null,
      } satisfies SquadPlayer;
    })
    .filter((p): p is SquadPlayer => p !== null && Boolean(p.name));
  return [...new Map(players.map((p) => [p.id, p])).values()];
}

export function parseCoach(html: string) {
  const head = html.match(/<div id="hd"[\s\S]*?<div class="s">([\s\S]*?)<ul>/i)?.[1] ?? "";
  const photo = head.match(/data-src="([^"]*Photos\/Person\/[^"]+)"/i)?.[1];
  const name = decode(head.match(/<span>\s*([^<]+?)\s*<b/i)?.[1] ?? "");
  const founded = num(html.match(/<span>\s*(\d{4})\s*<\/span>\s*<\/li>\s*<li>\s*<b>\s*التأسيس/i)?.[1] ?? null);
  return {
    name: name || null,
    role: "المدير الفني",
    photoUrl: absolute(photo),
    founded: founded ?? 1920,
    crestUrl: `https://semedia.filgoal.com/Photos/Team/Medium/${TEAM_ID}.png`,
  };
}

export function parseScorers(html: string) {
  const block = html.match(/قائمة الهدافين[\s\S]*?<div class="fg_tbl[^"]*"[^>]*>([\s\S]*)/i)?.[1] ?? "";
  const rows = [...block.matchAll(/<div class="fg_rw">([\s\S]*?)(?=<div class="fg_rw">|$)/gi)].map(
    (m) => m[1]!,
  );
  return rows
    .map((row) => {
      const link = row.match(/href="\/[Pp]layers\/(\d+)\//i);
      if (!link) return null;
      const name = decode(row.match(/<b>([\s\S]*?)<\/b>/i)?.[1] ?? "");
      const cells = [...row.matchAll(/<div class="fg_cl t2">([\s\S]*?)<\/div>/gi)].map((m) =>
        num(decode(m[1]!)),
      );
      const rate = num(row.match(/data-value="(\d+)"/i)?.[1] ?? null);
      return {
        id: Number(link[1]),
        name,
        goals: cells[0] ?? null,
        appearances: cells[1] ?? null,
        scoringRate: rate,
      };
    })
    .filter((r): r is NonNullable<typeof r> => r !== null && Boolean(r.name));
}

export function parseStandings(html: string): StandingRow[] {
  const table = html.match(/<div class="fg_tbl a arg expandable">([\s\S]*?)<\/div>\s*<\/div>\s*<\/div>\s*<\/div>/i)?.[1]
    ?? html.split('<div class="fg_tbl a arg expandable">')[1] ?? "";
  const rows = [...table.matchAll(/<div class="fg_rw active">([\s\S]*?)(?=<div class="fg_rw|$)/gi)].map(
    (m) => m[1]!,
  );
  return rows
    .map((row) => {
      const rank = num(decode(row.match(/<div class="fg_cl t1">([\s\S]*?)<\/div>/i)?.[1] ?? ""));
      const teamCell = row.match(/<div class="fg_cl t2[^"]*">([\s\S]*?)<\/div>/i)?.[1] ?? "";
      const teamId = num(teamCell.match(/data-tmid="(\d+)"/i)?.[1] ?? null);
      const teamName = decode(teamCell.replace(/<img[^>]*>/gi, ""));
      const crest = teamCell.match(/data-src="([^"]+)"/i)?.[1];
      const played = num(decode(row.match(/<div class="fg_cl t3">([\s\S]*?)<\/div>/i)?.[1] ?? ""));
      const ex = [...row.matchAll(/<div class="fg_cl t3 ex">([\s\S]*?)<\/div>/gi)].map((m) =>
        num(decode(m[1]!)) ?? 0,
      );
      const t3 = [...row.matchAll(/<div class="fg_cl t3">([\s\S]*?)<\/div>/gi)].map((m) =>
        num(decode(m[1]!)) ?? 0,
      );
      if (rank == null || !teamName) return null;
      return {
        rank,
        team: { id: teamId, name: teamName, crestUrl: absolute(crest) },
        played: played ?? 0,
        won: ex[2] ?? 0,
        lost: ex[3] ?? 0,
        drawn: ex[4] ?? 0,
        goalsFor: ex[5] ?? 0,
        goalsAgainst: ex[6] ?? 0,
        points: t3[t3.length - 1] ?? 0,
        isMasry: teamId === TEAM_ID,
      } satisfies StandingRow;
    })
    .filter((r): r is StandingRow => r !== null);
}

const balancedJson = (input: string) => {
  let depth = 0;
  for (let i = 0; i < input.length; i += 1) {
    const c = input[i];
    if (c === "{" || c === "[") depth += 1;
    else if (c === "}" || c === "]") {
      depth -= 1;
      if (depth === 0) return input.slice(0, i + 1);
    }
  }
  return null;
};

const dotNetDate = (value: string | null | undefined) => {
  const ms = value?.match(/\/Date\((-?\d+)\)\//)?.[1];
  return ms ? new Date(Number(ms)).toISOString() : null;
};

const mapSquad = (list: unknown[]): LineupPlayer[] =>
  (list as Record<string, never>[]).map((p) => ({
    id: Number(p["PersonId"] ?? 0),
    name: String(p["PersonName"] ?? ""),
    number: p["ShirtNumber"] == null ? null : Number(p["ShirtNumber"]),
    position: String(p["PlayerPositionName"] ?? "—"),
    photoUrl: absolute(p["PersonLogoUrl"] as unknown as string),
    minutesPlayed: p["MinutesPlayed"] == null ? null : Number(p["MinutesPlayed"]),
    isCaptain: Boolean(p["IsCaptin"]),
    isSpare: Boolean(p["IsSpare"]),
  }));

export function parseMatchDetail(html: string): MatchDetail | null {
  const start = html.indexOf("viewModelData");
  if (start === -1) return null;
  const eq = html.indexOf("=", start);
  const json = balancedJson(html.slice(eq + 1).trimStart());
  if (!json) return null;
  let d: Record<string, never>;
  try {
    d = JSON.parse(json);
  } catch {
    return null;
  }
  const get = <T,>(key: string) => d[key] as unknown as T;
  const statusText = String(
    (get<Record<string, unknown>>("CurrentMatchStatus")?.["MatchStatusName"] as string) ?? "",
  );
  const matchId = Number(get<number>("Id"));
  const slug = String(get<string>("Slug") ?? "");

  const events: MatchEvent[] = (get<unknown[]>("Events") ?? []).map((raw) => {
    const e = raw as Record<string, never>;
    return {
      id: Number(e["Id"]),
      minute: e["CalculatedTime"] == null ? null : Number(e["CalculatedTime"]),
      addedTime: e["CalculatedAdditionalTime"] ? Number(e["CalculatedAdditionalTime"]) : null,
      type: normalizeEventType(String(e["MatchEventTypeName"] ?? "")),
      half: (e["MatchStatusName"] as unknown as string) ?? null,
      teamId: e["TeamId"] == null ? null : Number(e["TeamId"]),
      teamName: (e["TeamName"] as unknown as string) ?? null,
      player: (e["PlayerAName"] as unknown as string) ?? null,
      playerPhotoUrl: absolute(e["PlayerALogoUrl"] as unknown as string),
      relatedPlayer: (e["PlayerBName"] as unknown as string) ?? null,
    };
  });
  events.sort((a, b) => (a.minute ?? 0) - (b.minute ?? 0));

  const commentary = (get<unknown[]>("Comments") ?? [])
    .map((raw) => {
      const c = raw as Record<string, never>;
      return {
        id: Number(c["Id"]),
        minute: c["Time"] == null ? null : Number(c["Time"]),
        text: decode(String(c["Content"] ?? "")),
        half: (c["MatchStatusName"] as unknown as string) ?? null,
      };
    })
    .filter((c) => c.text);

  return {
    id: `filgoal-${matchId}`,
    matchId,
    slug,
    competition: String(get<string>("ChampionshipName") ?? ""),
    competitionId: get<number>("ChampionshipId") ?? null,
    round: (get<string>("WeekOrRound") ?? "").trim() || null,
    kickoff: dotNetDate(get<string>("Date")),
    kickoffText: null,
    venue: get<string>("StadiumName") ?? null,
    statusText: statusText || "لم تبدأ",
    status: statusFromText(statusText),
    homeTeam: {
      id: Number(get<number>("HomeTeamId")),
      name: String(get<string>("HomeTeamName") ?? ""),
      crestUrl: absolute(get<string>("HomeTeamLogoUrl")),
    },
    awayTeam: {
      id: Number(get<number>("AwayTeamId")),
      name: String(get<string>("AwayTeamName") ?? ""),
      crestUrl: absolute(get<string>("AwayTeamLogoUrl")),
    },
    homeScore: get<number>("HomeScore") ?? null,
    awayScore: get<number>("AwayScore") ?? null,
    url: `${FG}/matches/${matchId}/${slug}`,
    referee: get<string>("RefereeName") ?? null,
    stadium: get<string>("StadiumName") ?? null,
    homeCoach: get<string>("HomeTeamCoachName") ?? null,
    awayCoach: get<string>("AwayTeamCoachName") ?? null,
    homeFormation: get<string>("HomeTeamFormationName") ?? null,
    awayFormation: get<string>("AwayTeamFormationName") ?? null,
    tvChannels: (get<unknown[]>("TvCoverage") ?? []).map((raw) =>
      String((raw as Record<string, never>)["TvChannelName"] ?? ""),
    ),
    events,
    timeline: buildTimeline(
      events,
      commentary,
      String(get<string>("HomeTeamName") ?? ""),
      String(get<string>("AwayTeamName") ?? ""),
      Number(get<number>("HomeTeamId")),
      Number(get<number>("AwayTeamId")),
    ),
    stats: deriveStats(
      commentary,
      events,
      String(get<string>("HomeTeamName") ?? ""),
      String(get<string>("AwayTeamName") ?? ""),
    ),

    lineups: {
      home: mapSquad(get<unknown[]>("HomeTeamSquad") ?? []),
      away: mapSquad(get<unknown[]>("AwayTeamSquad") ?? []),
      homeBench: mapSquad(get<unknown[]>("HomeTeamSpareSquad") ?? []),
      awayBench: mapSquad(get<unknown[]>("AwayTeamSpareSquad") ?? []),
    },
    commentary,
  };
}

/* ---------------- كل أحداث المباراة من صفحة "أحداث المباراة" في الجول ---------------- */

/**
 * صفحة /matches/{id}/coverage/{slug} فيها قائمة الأحداث الكاملة (تبديلات، إنذارات،
 * ركنيات، إصابات، أهداف...) وهي أكثر من قائمة Events المختصرة في بيانات الصفحة الرئيسية.
 */
export function parseCoverageEvents(
  html: string,
  homeTeam: { id: number; name: string },
  awayTeam: { id: number; name: string },
): MatchEvent[] {
  const start = html.indexOf("match-events-container");
  if (start === -1) return [];
  const end = html.indexOf("</ul>", start);
  if (end === -1) return [];
  const block = html.slice(start, end);

  const events: MatchEvent[] = [];
  let half: string | null = null;
  let autoId = -1;

  for (const item of block.split(/<li\b/i).slice(1)) {
    const heading = item.match(/<h3[^>]*>([\s\S]*?)<\/h3>/i);
    if (heading) {
      half = decode(heading[1]!).trim() || half;
      continue;
    }
    const timeBlock = item.match(/<span[^>]*>([\s\S]*?)<\/span>/i)?.[1] ?? "";
    const addedTime = num(timeBlock.match(/<b[^>]*>\s*\+?(\d+)/i)?.[1] ?? null);
    const minute = num(timeBlock.replace(/<b[\s\S]*?<\/b>/gi, ""));

    for (const p of item.matchAll(/<p class="([rl])"[^>]*>([\s\S]*?)<\/p>/gi)) {
      const side = p[1] === "r" ? homeTeam : awayTeam;
      const body = p[2]!;
      const type = normalizeEventType(decode(body.match(/alt="([^"]*)"/i)?.[1] ?? "").trim());
      const anchor = body.match(/<a[^>]*href="\/players\/(\d+)[^"]*"[^>]*>([\s\S]*?)<\/a>/i);
      const player = anchor ? decode(anchor[2]!).trim() : null;
      if (!type && !player) continue;
      events.push({
        id: anchor ? Number(anchor[1]) * 1000 + events.length : autoId--,
        minute,
        addedTime,
        type,
        half,
        teamId: side.id,
        teamName: side.name,
        player,
        playerPhotoUrl: null,
        relatedPlayer: null,
      });
    }
  }

  // الصفحة بتعرض الأحدث أولاً — نرجّعها بالترتيب الزمني الطبيعي.
  return events.reverse();
}

/* ------------------- كل أحداث المباراة (رسمية + مستنتجة من التعليق) ------------------ */

/** أنماط الأحداث اللي "في الجول" بيذكرها في التعليق الحي فقط. */
const DERIVED_PATTERNS: { type: string; test: RegExp }[] = [
  { type: "var", test: /تقنية الفيديو|حكم الفيديو|\bVAR\b|الـ ?var/i },
  { type: "missed-penalty", test: /(يضيع|أضاع|أهدر|يهدر|ضائعة).{0,25}(ركلة|ضربة) جزاء/ },
  { type: "penalty-saved", test: /(يتصدى|تصدى|أنقذ).{0,25}(ركلة|ضربة) جزاء/ },
  { type: "penalty-awarded", test: /(ركلة|ضربة) جزاء/ },
  { type: "injury", test: /إصاب|الطاقم الطبي|يتلقى العلاج|نقالة|الجهاز الطبي/ },
  { type: "woodwork", test: /القائم|العارضة/ },
  { type: "corner", test: /ركنية|كورنر/ },
  { type: "offside", test: /تسلل/ },
  { type: "save", test: /يتصدى|تصدى|ينقذ|أنقذ|تصدي الحارس/ },
  { type: "freekick", test: /ركلة حرة|مخالفة/ },
  { type: "shot", test: /تسديدة|يسدد|تصويبة|رأسية/ },
  { type: "kick-off", test: /انطلاق|بداية الشوط|صافرة البداية/ },
  { type: "half-time", test: /نهاية الشوط الأول/ },
  { type: "full-time", test: /نهاية المباراة|صافرة النهاية/ },
];

function buildTimeline(
  events: MatchEvent[],
  commentary: { id: number; minute: number | null; text: string; half: string | null }[],
  homeName: string,
  awayName: string,
  homeId: number,
  awayId: number,
): MatchEvent[] {
  const isHome = teamMatcher(homeName);
  const isAway = teamMatcher(awayName);
  const derived: MatchEvent[] = [];

  for (const c of commentary) {
    // الأهداف والبطاقات والتبديلات موجودة أصلاً في الأحداث الرسمية.
    if (/هدف|بطاقة|تبديل|يسجل|سجل/.test(c.text)) continue;
    const match = DERIVED_PATTERNS.find((p) => p.test.test(c.text));
    if (!match) continue;

    const home = isHome(c.text);
    const away = isAway(c.text);
    derived.push({
      id: -c.id,
      minute: c.minute,
      addedTime: null,
      type: match.type,
      half: c.half,
      teamId: home && !away ? homeId : away && !home ? awayId : null,
      teamName: home && !away ? homeName : away && !home ? awayName : null,
      player: null,
      playerPhotoUrl: null,
      relatedPlayer: null,
      derived: true,
      text: c.text,
    });
  }

  return [...events, ...derived].sort((a, b) => (a.minute ?? 0) - (b.minute ?? 0));
}


/* ------------------------- إحصائيات المباراة (استنتاج) ------------------------ */

/** يطابق اسم فريق داخل نص التعليق (بالاسم الكامل أو أطول كلمة مميزة فيه). */
const teamMatcher = (name: string) => {
  const clean = name.replace(/منتخب|نادي/g, "").trim();
  const tokens = clean.split(/\s+/).filter((t) => t.length >= 4);
  return (text: string) =>
    (clean.length > 2 && text.includes(clean)) || tokens.some((t) => text.includes(t));
};

/**
 * "في الجول" ما بيوفرش جدول إحصائيات جاهز، فبنستنتجه من التعليق الحي
 * (الاستحواذ بيتنشر كنص) ومن أحداث المباراة (البطاقات والتبديلات).
 */
export function deriveStats(
  commentary: { minute: number | null; text: string }[],
  events: MatchEvent[],
  homeName: string,
  awayName: string,
): MatchStats {
  const isHome = teamMatcher(homeName);
  const isAway = teamMatcher(awayName);

  // آخر سطر استحواذ في التعليق: "الاستحواذ : 42% فريق أ مقابل 58% فريق ب."
  let possession: MatchStats["possession"] = null;
  for (const c of commentary) {
    if (!c.text.includes("الاستحواذ")) continue;
    const parts = [...c.text.matchAll(/(\d{1,3})\s*%\s*([^%]*?)(?:مقابل|\.|$)/g)].map((m) => ({
      value: Number(m[1]),
      who: m[2] ?? "",
    }));
    if (parts.length < 2) continue;
    const homePart = parts.find((p) => isHome(p.who));
    const awayPart = parts.find((p) => isAway(p.who));
    const next =
      homePart && awayPart
        ? { home: homePart.value, away: awayPart.value }
        : { home: parts[0]!.value, away: parts[1]!.value };
    if (next.home + next.away >= 95 && next.home + next.away <= 105) {
      possession = next;
      break; // التعليق مرتب من الأحدث للأقدم
    }
  }

  const counters: Record<string, [number, number]> = {
    shots: [0, 0],
    onTarget: [0, 0],
    corners: [0, 0],
    fouls: [0, 0],
    offsides: [0, 0],
    saves: [0, 0],
  };

  const bump = (key: string, side: 0 | 1) => {
    const row = counters[key];
    if (row) row[side] += 1;
  };

  for (const c of commentary) {
    const t = c.text;
    const home = isHome(t);
    const away = isAway(t);
    const side: 0 | 1 | null = home && !away ? 0 : away && !home ? 1 : null;
    if (side == null) continue;

    if (/تسديدة|تسدد|كرة رأسية|رأسية من/.test(t)) {
      bump("shots", side);
      if (/تصدى|أنقذ|أمسك|القائم|العارضة|داخل الشباك|في الشباك|هدف/.test(t))
        bump("onTarget", side);
    }
    if (/ركنية/.test(t)) bump("corners", side);
    if (/تسلل/.test(t)) bump("offsides", side);
    if (/خطأ/.test(t)) bump("fouls", side === 0 ? 1 : 0);
    if (/تصدى|أنقذ|أمسك الحارس|تصدي/.test(t)) bump("saves", side === 0 ? 1 : 0);
  }

  const homeId = events.find((e) => e.teamName && isHome(e.teamName))?.teamId ?? null;
  const eventSide = (e: MatchEvent): 0 | 1 | null => {
    if (e.teamName) {
      if (isHome(e.teamName)) return 0;
      if (isAway(e.teamName)) return 1;
    }
    if (e.teamId != null && homeId != null) return e.teamId === homeId ? 0 : 1;
    return null;
  };

  const eventCounts: Record<string, [number, number]> = {
    corners: [0, 0],
    offsides: [0, 0],
    injuries: [0, 0],
  };

  const cards: Record<string, [number, number]> = {
    yellow: [0, 0],
    red: [0, 0],
    subs: [0, 0],
  };
  for (const e of events) {
    const side = eventSide(e);
    if (side == null) continue;
    if (/yellow/i.test(e.type)) cards["yellow"]![side] += 1;
    else if (/red/i.test(e.type)) cards["red"]![side] += 1;
    else if (/substitution/i.test(e.type)) cards["subs"]![side] += 1;
    else if (/corner/i.test(e.type)) eventCounts["corners"]![side] += 1;
    else if (/offside/i.test(e.type)) eventCounts["offsides"]![side] += 1;
    else if (/injury/i.test(e.type)) eventCounts["injuries"]![side] += 1;
  }

  // الأحداث الرسمية أدق من الاستنتاج من التعليق، فتحل مكانه لما تكون متاحة.
  for (const key of ["corners", "offsides"] as const) {
    const official = eventCounts[key]!;
    if (official[0] + official[1] > 0) counters[key] = official;
  }

  const labels: { key: string; label: string; from: Record<string, [number, number]> }[] = [
    { key: "shots", label: "التسديدات", from: counters },
    { key: "onTarget", label: "تسديدات على الهدف", from: counters },
    { key: "corners", label: "الركنيات", from: counters },
    { key: "saves", label: "تصديات الحارس", from: counters },
    { key: "fouls", label: "الأخطاء", from: counters },
    { key: "offsides", label: "التسلل", from: counters },
    { key: "yellow", label: "بطاقات صفراء", from: cards },
    { key: "red", label: "بطاقات حمراء", from: cards },
    { key: "subs", label: "التبديلات", from: cards },
    { key: "injuries", label: "الإصابات", from: eventCounts },
  ];

  const rows: StatRow[] = labels
    .map(({ key, label, from }) => {
      const pair = from[key] ?? [0, 0];
      return {
        key,
        label,
        home: pair[0] ?? 0,
        away: pair[1] ?? 0,
        unit: "count" as const,
      };
    })
    .filter((r) => r.home > 0 || r.away > 0);

  return { possession, rows };
}


/** أخبار النادي من صفحة أخبار الفريق في "في الجول" (قائمة <li> داخل main). */
export function parseFilGoalNews(html: string): NewsItem[] {
  const blocks = [
    ...html.matchAll(
      /<li>\s*<a href="(\/articles\/(\d+)\/[^"]*)"([\s\S]*?)<\/a>\s*<\/li>/gi,
    ),
    // النسخة المختصرة على صفحة النادي (mcitem)
    ...html.matchAll(
      /<div class="mcitem">([\s\S]*?)<\/div>\s*<\/div>/gi,
    ),
  ];

  const items: NewsItem[] = [];
  for (const m of blocks) {
    const chunk = m[0]!;
    const link = chunk.match(/href="(\/articles\/(\d+)\/[^"]*)"/i);
    if (!link) continue;
    const id = `filgoal-${link[2]}`;
    // العنوان: من h6 لو موجود، وإلا نص الرابط، وإلا من الـ slug
    let title = decode(
      (chunk.match(/<h6>([\s\S]*?)<\/h6>/i)?.[1] ?? "").replace(/<[^>]+>/g, " "),
    );
    if (!title) {
      const anchor = chunk.match(
        /<a href="\/articles\/\d+\/[^"]*"[^>]*>([\s\S]*?)<\/a>/i,
      )?.[1];
      title = decode((anchor ?? "").replace(/<[^>]+>/g, " "));
    }
    if (!title) {
      try {
        title = decodeURIComponent(link[1]!.split("/")[3] ?? "").replace(/-/g, " ");
      } catch {
        title = "";
      }
    }
    if (!title) continue;
    const image = chunk.match(/data-src="([^"]+)"/i)?.[1];
    const date = chunk.match(/<span>[\s\S]*?([^<>]*\d{4}[^<>]*)<\/span>/i)?.[1];
    items.push({
      id,
      title,
      url: `${FG}${link[1]}`,
      imageUrl: absolute(image),
      publishedText: date ? decode(date) : null,
      sourceName: "FilGoal",
    });
  }
  return [...new Map(items.map((n) => [n.id, n])).values()];
}

/** خلاصة أخبار Google (تجمع يلاكورة واليوم السابع وغيرها) عن النادي المصري. */
export function parseAggregatorNews(xml: string): NewsItem[] {
  const items = [...xml.matchAll(/<item>([\s\S]*?)<\/item>/gi)]
    .map((m): NewsItem | null => {
      const block = m[1]!;
      const rawTitle = decode(block.match(/<title>([\s\S]*?)<\/title>/i)?.[1] ?? "");
      const url = decode(block.match(/<link>([\s\S]*?)<\/link>/i)?.[1] ?? "");
      if (!rawTitle || !url) return null;
      const source = decode(
        block.match(/<source[^>]*>([\s\S]*?)<\/source>/i)?.[1] ?? "أخبار",
      );
      const title = rawTitle.replace(new RegExp(`\\s*-\\s*${source}\\s*$`), "").trim();
      const pubDate = block.match(/<pubDate>([\s\S]*?)<\/pubDate>/i)?.[1];
      const guid = decode(block.match(/<guid[^>]*>([\s\S]*?)<\/guid>/i)?.[1] ?? url);
      let publishedText: string | null = null;
      if (pubDate) {
        const d = new Date(pubDate);
        if (!Number.isNaN(d.getTime())) {
          publishedText = d.toLocaleDateString("ar-EG", {
            day: "numeric",
            month: "long",
            year: "numeric",
          });
        }
      }
      return {
        id: `news-${guid.slice(-40)}`,
        title,
        url,
        imageUrl: null,
        publishedText,
        sourceName: source,
      } satisfies NewsItem;
    })
    .filter((n): n is NewsItem => n !== null);
  return [...new Map(items.map((n) => [n.id, n])).values()];
}

/* ------------------------------ data loaders ------------------------------ */

const MATCHES_URL = `${FG}/teams/${TEAM_ID}/matches-results/x`;
const FIXTURES_URL = `${FG}/teams/${TEAM_ID}/matches-fixtures`;
const PLAYERS_URL = `${FG}/teams/${TEAM_ID}/players/x`;
const SCORERS_URL = `${FG}/teams/${TEAM_ID}/scorers/x`;
const STANDINGS_URL = `${FG}/championships/${LEAGUE_ID}/standings/x`;
// صفحة أخبار نادي المصري نفسها على "في الجول" + صفحة النادي كمصدر إضافي
const FG_NEWS_URL = `${FG}/teams/${TEAM_ID}/articles/${encodeURIComponent("المصري")}`;
const FG_TEAM_URL = `${FG}/teams/${TEAM_ID}`;
// خلاصة أخبار تجمع يلاكورة ومصادر مصرية أخرى عن النادي
const AGG_NEWS_URL = `https://news.google.com/rss/search?q=${encodeURIComponent(
  '"المصري البورسعيدي" OR "النادي المصري"',
)}&hl=ar&gl=EG&ceid=EG:ar`;

export async function loadMatches() {
  const existing = cache.get("matches") as CacheEntry<Match[]> | undefined;
  const entry = await cached("matches", matchesCacheTtl(existing?.value), async () => {
    const [results, fixtures] = await Promise.all([
      fetchHtml(MATCHES_URL).then(parseTeamMatches).catch(() => [] as Match[]),
      fetchHtml(FIXTURES_URL).then(parseTeamMatches).catch(() => [] as Match[]),
    ]);
    const all = [...results, ...fixtures];
    if (all.length === 0) throw new Error("لا توجد مباريات في الصفحة");
    const unique = [...new Map(all.map((m) => [m.id, m])).values()];
    const isUpcoming = (m: Match) => m.status === "upcoming" || m.status === "postponed";
    const group = (m: Match) => (m.status === "live" ? 0 : isUpcoming(m) ? 1 : 2);
    return unique.sort((a, b) => {
      const g = group(a) - group(b);
      if (g !== 0) return g;
      // القادمة: الأقرب أولًا — المنتهية: الأحدث أولًا
      return isUpcoming(a)
        ? (a.kickoff ?? "9999").localeCompare(b.kickoff ?? "9999")
        : (b.kickoff ?? "").localeCompare(a.kickoff ?? "");
    });
  });
  return {
    matches: entry.value,
    source: sourceOf("FilGoal", MATCHES_URL, entry.live, entry.at),
  };
}

let schedulerStarted = false;

/** جدولة مركزية تعمل مرة واحدة مع سيرفر Replit، بدل أن يجلب كل مستخدم من المصدر. */
export function startHubScheduler() {
  // start.ts is evaluated by both SSR and the browser bundle. The scheduler
  // must never run in a user's browser or it would bypass the server cache.
  if (schedulerStarted || typeof window !== "undefined") return;
  schedulerStarted = true;

  const refreshMatches = () => {
    void loadMatches().catch((error) => console.error("جدولة المباريات فشلت:", error));
  };
  const refreshNews = () => {
    void loadNews().catch((error) => console.error("جدولة الأخبار فشلت:", error));
  };
  const refreshStandings = () => {
    void loadStandings().catch((error) => console.error("جدولة الترتيب فشلت:", error));
  };

  refreshMatches();
  refreshNews();
  refreshStandings();
  setInterval(refreshMatches, 20_000);
  setInterval(refreshNews, 30 * 60_000);
  setInterval(refreshStandings, 60 * 60_000);
}

export async function loadSquad() {
  const entry = await cached("squad", 10 * 60_000, async () => {
    const [playersHtml, scorersHtml] = await Promise.all([
      fetchHtml(PLAYERS_URL),
      fetchHtml(SCORERS_URL).catch(() => ""),
    ]);
    const players = parseSquad(playersHtml);
    if (players.length === 0) throw new Error("قائمة اللاعبين فارغة");
    const scorers = scorersHtml ? parseScorers(scorersHtml) : [];
    const byId = new Map(scorers.map((s) => [s.id, s]));
    const enriched = players.map((p) => {
      const stat = byId.get(p.id);
      return stat
        ? {
            ...p,
            goals: stat.goals,
            appearances: stat.appearances,
            scoringRate: stat.scoringRate,
          }
        : p;
    });
    return { players: enriched, coach: parseCoach(playersHtml), scorers };
  });
  return {
    ...entry.value,
    source: sourceOf("FilGoal", PLAYERS_URL, entry.live, entry.at),
  };
}

export async function loadStandings() {
  const entry = await cached("standings", 60 * 60_000, async () => {
    const rows = parseStandings(await fetchHtml(STANDINGS_URL));
    if (rows.length === 0) throw new Error("جدول الترتيب فارغ");
    return rows;
  });
  return {
    standings: entry.value,
    source: sourceOf("FilGoal", STANDINGS_URL, entry.live, entry.at),
  };
}

export async function loadNews() {
  const entry = await cached("news", 30 * 60_000, async () => {
    const [fgHtml, teamHtml, aggXml] = await Promise.all([
      fetchHtml(FG_NEWS_URL).catch(() => ""),
      fetchHtml(FG_TEAM_URL).catch(() => ""),
      fetchHtml(AGG_NEWS_URL).catch(() => ""),
    ]);
    const fgItems = [
      ...(fgHtml ? parseFilGoalNews(fgHtml) : []),
      ...(teamHtml ? parseFilGoalNews(teamHtml) : []),
    ].filter((n) => {
      const t = n.title;
      if (t.includes("المصري للألومنيوم") || t.includes("مصري المقاصة")) return false;
      // صفحات "في الجول" بتحتوي كمان أخبار عامة، فنسيب اللي يخص النادي بس
      return t.includes("المصري") || t.includes("بورسعيد");
    });
    const aggItems = (aggXml ? parseAggregatorNews(aggXml) : []).filter((n) => {
      const t = n.title;
      if (t.includes("المصري للألومنيوم") || t.includes("مصري المقاصة")) return false;
      if (/الدوري المصري|المنتخب المصري|الاتحاد المصري|السوبر المصري/.test(t)) {
        return t.includes("بورسعيد");
      }
      return t.includes("المصري") || t.includes("بورسعيد");
    });
    const merged = [...fgItems, ...aggItems];
    return [...new Map(merged.map((n) => [n.url, n])).values()].slice(0, 40);
  });
  return {
    news: entry.value,
    source: sourceOf("FilGoal + مصادر أخبار", FG_NEWS_URL, entry.live, entry.at),
  };
}

export async function loadMatchDetail(matchId: number) {
  const entry = await cached(`match-${matchId}`, 20_000, async () => {
    const { matches } = await loadMatches();
    const known = matches.find((m) => m.matchId === matchId);
    const slug = known?.slug || "x";
    // صفحة التغطية (أحداث المباراة) فيها قائمة الأحداث الكاملة: تبديلات، ركنيات،
    // إصابات، ركلات جزاء... بينما الصفحة الرئيسية بتعرض قائمة مختصرة.
    const url = `${FG}/matches/${matchId}/coverage/${slug}`;
    const html = await fetchHtml(url);
    const detail = parseMatchDetail(html);
    if (!detail) {
      const fallback = parseMatchDetail(await fetchHtml(known?.url ?? `${FG}/matches/${matchId}/x`));
      if (!fallback) throw new Error("تفاصيل المباراة غير متاحة");
      return fallback;
    }
    if (detail.events.length === 0) {
      const scraped = parseCoverageEvents(html, detail.homeTeam as { id: number; name: string }, detail.awayTeam as { id: number; name: string });
      if (scraped.length > 0) detail.events = scraped;
    }
    return detail;
  });
  return {
    match: entry.value,
    source: sourceOf("FilGoal", entry.value.url, entry.live, entry.at),
  };
}

export { nowIso };

/* ------------------------------ تفاصيل اللاعب ----------------------------- */

export type PlayerCompetitionStat = {
  competitionId: number | null;
  competition: string;
  teamName: string;
  minutes: number | null;
  appearances: number | null;
  goals: number | null;
  yellowCards: number | null;
  redCards: number | null;
};

export type PlayerCareerStop = {
  fromTeam: string | null;
  toTeam: string | null;
  toTeamCrestUrl: string | null;
  position: string | null;
  number: string | null;
  from: string | null;
  until: string | null;
  duration: string | null;
  contract: string | null;
};

export type PlayerDetail = {
  id: number;
  name: string;
  role: string | null;
  photoUrl: string | null;
  club: string | null;
  clubCrestUrl: string | null;
  nationality: string | null;
  birthDate: string | null;
  birthPlace: string | null;
  shirtNumber: string | null;
  position: string | null;
  availability: string | null;
  totals: { label: string; value: number | null }[];
  competitions: PlayerCompetitionStat[];
  career: PlayerCareerStop[];
  url: string;
};

const infoValue = (items: { label: string; value: string }[], key: string) =>
  items.find((i) => i.label.includes(key))?.value ?? null;

export function parsePlayerDetail(html: string, playerId: number): PlayerDetail | null {
  const head = html.match(/<div id="dhd">([\s\S]*?)<div class="bd">/i)?.[1] ?? html;
  const name = decode(head.match(/<h1>([\s\S]*?)<\/h1>/i)?.[1] ?? "");
  if (!name) return null;

  const photo = head.match(/data-src="([^"]*Photos\/Person\/[^"]+)"/i)?.[1];
  const clubCrest = head.match(/data-src="([^"]*Photos\/Team\/[^"]+)"/i)?.[1];
  const role = decode(head.match(/data-player-position="([^"]*)"/i)?.[1] ?? "") || null;

  const infoBlock = head.match(/<div class="s">\s*<ul>([\s\S]*?)<\/ul>/i)?.[1] ?? "";
  const items = [...infoBlock.matchAll(/<li[^>]*>([\s\S]*?)<\/li>/gi)]
    .map((m) => {
      const raw = m[1]!;
      const label = decode(raw.match(/<b>([\s\S]*?)<\/b>/i)?.[1] ?? "").replace(/[:：]\s*$/, "");
      const value = decode(raw.replace(/<b>[\s\S]*?<\/b>/i, ""));
      return { label, value };
    })
    .filter((i) => i.label && i.value);

  const totals = [...head.matchAll(/<li class="mip_stats"[\s\S]*?<b>([\s\S]*?)<\/b>\s*<span>([\s\S]*?)<\/span>/gi)]
    .map((m) => ({ label: decode(m[2]!), value: num(decode(m[1]!)) }))
    .filter((t) => t.label);

  const competitions = [
    ...html.matchAll(/<div class="fg_rw s" data-champid="(\d+)">([\s\S]*?)<\/div>\s*<\/div>/gi),
  ].map((m) => {
    const row = m[2]!;
    const cells = [...row.matchAll(/<div class="fg_cl t3"[^>]*>([\s\S]*?)<\/div>/gi)].map((c) =>
      num(decode(c[1]!)),
    );
    return {
      competitionId: num(m[1]!),
      competition: decode(row.match(/<div class="fg_cl t1">([\s\S]*?)<\/div>/i)?.[1] ?? ""),
      teamName: decode(row.match(/<div class="fg_cl t2">([\s\S]*?)<\/div>/i)?.[1] ?? ""),
      minutes: cells[0] ?? null,
      appearances: cells[1] ?? null,
      goals: cells[2] ?? null,
      yellowCards: cells[3] ?? null,
      redCards: cells[4] ?? null,
    } satisfies PlayerCompetitionStat;
  });

  const careerBlock = html.match(/<div id="career-viewer">([\s\S]*?)<\/ul>/i)?.[1] ?? "";
  const career = [...careerBlock.matchAll(/<li>([\s\S]*?)<\/li>/gi)].map((m) => {
    const block = m[1]!;
    const teams = [...block.matchAll(/<b>([\s\S]*?)<\/b>/gi)].map((t) => decode(t[1]!));
    const crest = block.match(/<img src="([^"]*Photos\/Team\/[^"]+)"/i)?.[1];
    const fields = [...block.matchAll(/<span>\s*<label>([\s\S]*?)<\/label>([\s\S]*?)<\/span>/gi)].map(
      (f) => ({ label: decode(f[1]!), value: decode(f[2]!) }),
    );
    const field = (key: string) => fields.find((f) => f.label.includes(key))?.value ?? null;
    return {
      fromTeam: teams[1] ?? null,
      toTeam: teams[0] ?? null,
      toTeamCrestUrl: absolute(crest),
      position: field("مركز"),
      number: field("رقم"),
      from: field("من"),
      until: field("حتى"),
      duration: field("مده"),
      contract: field("عقد"),
    } satisfies PlayerCareerStop;
  });

  return {
    id: playerId,
    name,
    role,
    photoUrl: absolute(photo),
    club: infoValue(items, "النادي"),
    clubCrestUrl: absolute(clubCrest),
    nationality: infoValue(items, "الجنسية"),
    birthDate: infoValue(items, "تاريخ الميلاد"),
    birthPlace: infoValue(items, "مكان الميلاد"),
    shirtNumber: infoValue(items, "رقم القميص"),
    position: infoValue(items, "المركز"),
    availability: infoValue(items, "الحالة"),
    totals,
    competitions,
    career,
    url: `${FG}/players/${playerId}/x`,
  } satisfies PlayerDetail;
}

export async function loadPlayerDetail(playerId: number) {
  const entry = await cached(`player-${playerId}`, 10 * 60_000, async () => {
    const detail = parsePlayerDetail(await fetchHtml(`${FG}/players/${playerId}/x`), playerId);
    if (!detail) throw new Error("بيانات اللاعب غير متاحة");
    return detail;
  });
  return {
    player: entry.value,
    source: sourceOf("FilGoal", entry.value.url, entry.live, entry.at),
  };
}
