/** تسميات وألوان كل أنواع أحداث المباراة القادمة من "في الجول" أو المستنتجة من التعليق. */

export const EVENT_LABEL: Record<string, string> = {
  goal: "هدف",
  "own-goal": "هدف عكسي",
  penalty: "هدف من ضربة جزاء",
  "penalty-goal": "هدف من ضربة جزاء",
  "missed-penalty": "ضربة جزاء ضائعة",
  "penalty-awarded": "ركلة جزاء",
  "penalty-saved": "تصدي لركلة جزاء",
  "yellow-card": "بطاقة صفراء",
  "second-yellow": "صفراء ثانية",
  "red-card": "بطاقة حمراء",
  substitution: "تبديل",
  injury: "إصابة",
  corner: "ركلة ركنية",
  offside: "تسلل",
  freekick: "ركلة حرة",
  shot: "تسديدة",
  save: "تصدي",
  woodwork: "القائم / العارضة",
  var: "تقنية الفيديو",
  chance: "فرصة خطيرة",
  "kick-off": "بداية المباراة",
  "half-time": "نهاية الشوط الأول",
  "full-time": "نهاية المباراة",
  lineup: "التشكيل الرسمي",
  assist: "صناعة هدف",
};

/** يحوّل أرقام الدقائق القادمة من HTML أو JSON إلى قيمة واحدة ثابتة. */
export function normalizeMatchMinute(raw: unknown): number | null {
  if (typeof raw === "number" && Number.isFinite(raw)) return Math.max(0, Math.round(raw));
  if (typeof raw !== "string") return null;

  const western = raw
    .replace(/[٠-٩]/g, (digit) => String("٠١٢٣٤٥٦٧٨٩".indexOf(digit)))
    .replace(/[٫،]/g, ".")
    .trim();
  const match = western.match(/\d{1,3}/);
  if (!match) return null;
  const minute = Number(match[0]);
  return Number.isFinite(minute) ? Math.max(0, minute) : null;
}

/** يحافظ على ترتيب المصدر عند تساوي الدقائق، ويضع الأحداث غير المؤرخة في النهاية. */
export function sortMatchEvents<T extends { minute: number | null; id: number }>(
  events: T[],
): T[] {
  return events
    .map((event, index) => ({ event, index }))
    .sort((a, b) => {
      const aMinute = a.event.minute;
      const bMinute = b.event.minute;
      if (aMinute == null && bMinute == null) return a.index - b.index;
      if (aMinute == null) return 1;
      if (bMinute == null) return -1;
      if (aMinute !== bMinute) return aMinute - bMinute;
      return a.index - b.index || a.event.id - b.event.id;
    })
    .map(({ event }) => event);
}

/** أسماء الأحداث كما تكتبها "في الجول" بالعربي → المفاتيح الداخلية. */
const ARABIC_TYPES: { key: string; test: RegExp }[] = [
  { key: "own-goal", test: /هدف عكس/ },
  { key: "penalty", test: /هدف من ركلة جزاء|هدف من ضربة جزاء/ },
  { key: "missed-penalty", test: /(ضائعة|إهدار|أهدر).{0,12}(ركلة|ضربة) جزاء/ },
  { key: "penalty-saved", test: /تصدي.{0,12}(ركلة|ضربة) جزاء/ },
  { key: "penalty-awarded", test: /إحراز (ركلة|ضربة) جزاء/ },
  { key: "penalty", test: /^(ركلة|ضربة) جزاء$/ },
  { key: "assist", test: /مساعدة|صناعة/ },
  { key: "goal", test: /هدف/ },
  { key: "second-yellow", test: /صفراء ثانية/ },
  { key: "yellow-card", test: /صفراء/ },
  { key: "red-card", test: /حمراء|طرد/ },
  { key: "substitution", test: /تبديل|خروج|نزول/ },
  { key: "injury", test: /إصاب/ },
  { key: "corner", test: /ركنية|كورنر/ },
  { key: "offside", test: /تسلل/ },
  { key: "freekick", test: /ركلة حرة|مخالفة/ },
  { key: "save", test: /تصدي|إنقاذ/ },
  { key: "var", test: /تقنية الفيديو|الفيديو/ },
  { key: "woodwork", test: /القائم|العارضة/ },
  { key: "shot", test: /تسديد|رأسية/ },
  { key: "kick-off", test: /بداية|انطلاق/ },
  { key: "half-time", test: /نهاية الشوط الأول/ },
  { key: "full-time", test: /نهاية المباراة|انتهت/ },
  { key: "lineup", test: /التشكيل/ },
];

/** يوحّد نوع الحدث: يقبل المفاتيح الإنجليزية أو الاسم العربي القادم من المصدر. */
export function normalizeEventType(raw: string): string {
  const value = (raw ?? "").trim();
  if (!value) return "";
  if (EVENT_LABEL[value]) return value;
  const found = ARABIC_TYPES.find((t) => t.test.test(value));
  return found ? found.key : value;
}

export const eventLabel = (type: string) => EVENT_LABEL[normalizeEventType(type)] ?? type;


export function eventEmoji(raw: string): string {
  const type = normalizeEventType(raw);
  if (/own-goal/.test(type)) return "🥅";
  if (/goal|^penalty$/.test(type)) return "⚽";
  if (/missed-penalty|penalty-saved/.test(type)) return "❌";
  if (/penalty-awarded/.test(type)) return "🎯";
  if (/red/.test(type)) return "🟥";
  if (/yellow/.test(type)) return "🟨";
  if (/substitution/.test(type)) return "🔁";
  if (/injury/.test(type)) return "🚑";
  if (/corner/.test(type)) return "🚩";
  if (/offside/.test(type)) return "🚫";
  if (/save/.test(type)) return "🧤";
  if (/woodwork/.test(type)) return "🪵";
  if (/var/.test(type)) return "📺";
  if (/freekick/.test(type)) return "🦶";
  if (/shot|chance/.test(type)) return "💥";
  if (/assist/.test(type)) return "🅰️";
  if (/lineup/.test(type)) return "📋";
  return "•";
}

export function eventTone(raw: string): string {
  const type = normalizeEventType(raw);
  if (/own-goal/.test(type)) return "border-destructive/40 bg-destructive/10 text-destructive";
  if (/goal|^penalty$/.test(type)) return "border-primary/40 bg-primary/10 text-primary";
  if (/red/.test(type)) return "border-live/40 bg-live/10 text-live";
  if (/yellow/.test(type)) return "border-gold/40 bg-gold/10 text-gold";
  if (/penalty-awarded|var/.test(type)) return "border-gold/40 bg-gold/10 text-gold";
  return "border-border/70 bg-secondary/50 text-muted-foreground";
}
