/** تفضيلات المستخدم (الاسم + الإشعارات) محفوظة على الجهاز. */
import { useCallback, useEffect, useState } from "react";

export const NOTIFICATION_TYPES = [
  { key: "matchday", label: "يوم المباراة", hint: "تذكير قبل انطلاق المباراة" },
  { key: "lineup", label: "نزول التشكيل", hint: "أول ما تُعلن تشكيلة الفريق" },
  { key: "kickoff", label: "بداية المباراة", hint: "صافرة البداية" },
  { key: "goal", label: "الأهداف", hint: "هدف لنا أو علينا" },
  { key: "penalty", label: "ركلات الجزاء", hint: "احتساب أو تصدي ركلة جزاء" },
  { key: "card", label: "البطاقات", hint: "صفراء وحمراء" },
  { key: "substitution", label: "التبديلات", hint: "كل تبديل في المباراة" },
  { key: "injury", label: "الإصابات", hint: "إصابة لاعب داخل الملعب" },
  { key: "fulltime", label: "نهاية المباراة", hint: "النتيجة النهائية" },
  { key: "news", label: "الأخبار", hint: "أخبار جديدة عن النادي" },
  { key: "standings", label: "تحديث جدول الدوري", hint: "تغيّر ترتيب الفريق" },
] as const;

export type NotificationKey = (typeof NOTIFICATION_TYPES)[number]["key"];

export type Prefs = {
  username: string;
  notificationsEnabled: boolean;
  notifications: Record<string, boolean>;
};

const STORAGE_KEY = "masrawy-fan-prefs";

export const DEFAULT_PREFS: Prefs = {
  username: "",
  notificationsEnabled: true,
  notifications: Object.fromEntries(NOTIFICATION_TYPES.map((t) => [t.key, true])),
};

export function readPrefs(): Prefs {
  if (typeof window === "undefined") return DEFAULT_PREFS;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return DEFAULT_PREFS;
    const parsed = JSON.parse(raw) as Partial<Prefs>;
    return {
      ...DEFAULT_PREFS,
      ...parsed,
      notifications: { ...DEFAULT_PREFS.notifications, ...(parsed.notifications ?? {}) },
    };
  } catch {
    return DEFAULT_PREFS;
  }
}

export function usePrefs() {
  const [prefs, setPrefs] = useState<Prefs>(DEFAULT_PREFS);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    setPrefs(readPrefs());
    setReady(true);
  }, []);

  const update = useCallback((patch: Partial<Prefs>) => {
    setPrefs((current) => {
      const next = { ...current, ...patch };
      try {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      } catch {
        /* التخزين غير متاح */
      }
      return next;
    });
  }, []);

  const toggleNotification = useCallback((key: string, value: boolean) => {
    setPrefs((current) => {
      const next = { ...current, notifications: { ...current.notifications, [key]: value } };
      try {
        window.localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
      } catch {
        /* التخزين غير متاح */
      }
      return next;
    });
  }, []);

  return { prefs, ready, update, toggleNotification };
}
