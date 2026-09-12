import { useEffect } from "react";
import { useQueryClient } from "@tanstack/react-query";

const CAIRO_OFFSET_MS = 3 * 60 * 60_000; // UTC+3

/** Milliseconds until the next scheduled refresh time (Cairo wall-clock hours). */
function msUntilNextSlot(hours: number[]): number {
  const now = Date.now();
  const cairo = new Date(now + CAIRO_OFFSET_MS);
  let best = Number.POSITIVE_INFINITY;

  for (const h of hours) {
    // Today's slot on the Cairo clock, expressed back in UTC ms.
    const slotUtcMs =
      Date.UTC(cairo.getUTCFullYear(), cairo.getUTCMonth(), cairo.getUTCDate(), h) -
      CAIRO_OFFSET_MS;
    const t = slotUtcMs > now ? slotUtcMs : slotUtcMs + 24 * 60 * 60_000; // else tomorrow
    best = Math.min(best, t - now);
  }
  return best;
}

/**
 * Invalidates a query at fixed Cairo-time slots every day
 * (e.g. league table refresh at 8pm, 10pm, 12am, 3am Cairo time).
 */
export function useScheduledRefresh(queryKey: unknown[], hours: number[]) {
  const queryClient = useQueryClient();
  const key = queryKey.join("|");
  const slotKey = hours.join("|");

  useEffect(() => {
    let timer: ReturnType<typeof setTimeout>;
    const tick = async () => {
      await queryClient.invalidateQueries({ queryKey });
      timer = setTimeout(tick, msUntilNextSlot(hours));
    };
    timer = setTimeout(tick, msUntilNextSlot(hours));
    return () => clearTimeout(timer);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [queryClient, key, slotKey]);
}
