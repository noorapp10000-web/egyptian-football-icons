/** تنسيق مواعيد المباريات بنظام ١٢ ساعة (ص/م) بتوقيت القاهرة. */

const CAIRO = "Africa/Cairo";

/** "12-09-2026 - 19:00" → Date */
export function parseFilGoalDate(text: string | null | undefined): Date | null {
  if (!text) return null;
  const m = text.match(/(\d{2})-(\d{2})-(\d{4})(?:\s*-\s*(\d{1,2}):(\d{2}))?/);
  if (!m) return null;
  const [, d, mo, y, h = "00", mi = "00"] = m;
  const iso = `${y}-${mo}-${d}T${h.padStart(2, "0")}:${mi}:00+03:00`;
  const date = new Date(iso);
  return Number.isNaN(date.getTime()) ? null : date;
}

export function toDate(iso: string | null | undefined, fallbackText?: string | null): Date | null {
  if (iso) {
    const d = new Date(iso);
    if (!Number.isNaN(d.getTime())) return d;
  }
  return parseFilGoalDate(fallbackText);
}

/** "7:30 م" */
export function formatTime12(date: Date | null): string | null {
  if (!date) return null;
  return new Intl.DateTimeFormat("ar-EG", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: CAIRO,
  }).format(date);
}

/** "الجمعة ١٢ سبتمبر" */
export function formatDay(date: Date | null): string | null {
  if (!date) return null;
  return new Intl.DateTimeFormat("ar-EG", {
    weekday: "long",
    day: "numeric",
    month: "long",
    timeZone: CAIRO,
  }).format(date);
}

/** "الجمعة ١٢ سبتمبر · ٧:٣٠ م" */
export function formatKickoff(
  iso: string | null | undefined,
  fallbackText?: string | null,
): string | null {
  const date = toDate(iso, fallbackText);
  if (!date) return fallbackText ?? null;
  const day = formatDay(date);
  const time = formatTime12(date);
  return time ? `${day} · ${time}` : day;
}

export function formatDateTimeShort(iso: string | null | undefined): string | null {
  const date = toDate(iso);
  if (!date) return null;
  return `${formatDay(date)} · ${formatTime12(date)}`;
}
