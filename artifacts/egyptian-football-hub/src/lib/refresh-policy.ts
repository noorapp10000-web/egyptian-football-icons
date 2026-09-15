/**
 * سياسة التحديث التلقائي:
 * - الترتيب والأخبار: كل ساعة.
 * - يوم المباراة: من ساعة ونصف قبل البداية → كل دقيقة (لالتقاط التشكيل فور نزوله).
 * - أثناء المباراة: كل ٢٠ ثانية.
 * - بعد المباراة: العودة للتحديث كل ساعة.
 */
import type { Match } from "./hub-types";
import { toDate } from "./time";

export const HOUR = 60 * 60_000;
export const LIVE_MS = 20_000;
export const MATCHDAY_MS = 60_000;
export const PRE_MATCH_WINDOW_MS = 90 * 60_000;

type MatchLike = Pick<Match, "status" | "kickoff" | "kickoffText">;

export function intervalForMatches(matches: MatchLike[] | undefined): number {
  if (!matches || matches.length === 0) return HOUR;
  if (matches.some((m) => m.status === "live")) return LIVE_MS;

  const now = Date.now();
  const soon = matches.some((m) => {
    if (m.status !== "upcoming") return false;
    const date = toDate(m.kickoff, m.kickoffText);
    if (!date) return false;
    const diff = date.getTime() - now;
    // من ساعة ونصف قبل الموعد وحتى ٣ ساعات بعده (لو الحالة لسه ما اتحدثتش)
    return diff <= PRE_MATCH_WINDOW_MS && diff > -3 * HOUR;
  });

  return soon ? MATCHDAY_MS : HOUR;
}

export function intervalForMatchDetail(match: MatchLike | undefined): number {
  if (!match) return HOUR;
  return intervalForMatches([match]);
}
