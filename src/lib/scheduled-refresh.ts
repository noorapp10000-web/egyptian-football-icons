import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

const CAIRO_OFFSET_MIN = 3 * 60; // UTC+3

/** Milliseconds until the next scheduled refresh time (Cairo clock hours). */
function msUntilNextSlot(hours: number[]): number {
  const now = Date.now();
  let best = Number.POSITIVE_INFINITY;
  for (const h of hours) {
    // Build the next occurrence of hour h on the Cairo wall clock.
    const nowUtc = new Date(now);
    const cairoNow = new Date(now + CAIRO_OFFSET_MIN * 60_000);
    const target = new Date(
      Date.UTC(
        cairoNow.getUTCFullYear(),
        cairoNow.getUTCMonth(),
        cairoNow.getUTCDate(),
        h - 3, // convert Cairo hour back to UTC hour
        0,
        0,
      ),
    );
    let t = target.getTime();
    if (t <= now) t += 24 * 60 * 60_000; // next day
    if (t - now < best) best = t - now;
    void nowUtc;
  }
  return best;
}

/**
 * Invalidates a query at fixed Cairo-time slots every day
 * (e.g. league table refresh at 8pm, 10pm, 12am, 3am).
 */
export function useScheduledRefresh(queryKey: unknown[], hours: number[]) {
  const queryClient = useQueryClient();

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const tick = async () => {
      await queryClient.invalidateQueries({ queryKey });
      timer = setTimeout(tick, msUntilNextSlot(hours));
    };
    timer = setTimeout(tick, msUntilNextSlot(hours));
    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [queryClient, queryKey.join("|"), hours.join("|")]);
}
