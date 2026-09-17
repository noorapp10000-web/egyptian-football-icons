import type {
  getMatches,
  getSquad,
  getStandings,
  getNews,
  getMatchDetail,
} from "./hub.functions";

export type MatchesData = Awaited<ReturnType<typeof getMatches>>;
export type Match = MatchesData["matches"][number];
export type SquadData = Awaited<ReturnType<typeof getSquad>>;
export type SquadPlayer = SquadData["players"][number];
export type StandingsData = Awaited<ReturnType<typeof getStandings>>;
export type StandingRow = StandingsData["standings"][number];
export type NewsData = Awaited<ReturnType<typeof getNews>>;
export type NewsItem = NewsData["news"][number];
export type DetailData = Awaited<ReturnType<typeof getMatchDetail>>;
export type MatchDetail = DetailData["match"];
export type Source = MatchesData["source"];

export const TEAM_CREST = "https://semedia.filgoal.com/Photos/Team/Medium/8.png";
export const MASRY_ID = 8;
