/** مزامنة الاسم وتفضيلات الإشعارات مع حساب المستخدم على السيرفر. */
import { useEffect } from "react";

import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import type { Prefs } from "@/lib/prefs";

/* أنواع الجداول المولّدة بتتحدث بعد أول نشر، فبنستخدم واجهة مرنة لحد ساعتها. */
type LooseRow = Record<string, unknown> | null;
type LooseTable = {
  select: (cols: string) => {
    eq: (col: string, val: string) => { maybeSingle: () => Promise<{ data: LooseRow }> };
  };
  upsert: (values: Record<string, unknown>) => Promise<unknown>;
};
const db = supabase as unknown as { from: (table: string) => LooseTable };

export function usePrefsSync(
  prefs: Prefs,
  ready: boolean,
  apply: (patch: Partial<Prefs>) => void,
) {
  const { user } = useAuth();
  const userId = user?.id;

  // أول ما يسجّل الدخول: نجيب القيم المحفوظة على السيرفر.
  useEffect(() => {
    if (!userId || !ready) return;
    let cancelled = false;
    (async () => {
      const [{ data: profile }, { data: row }] = await Promise.all([
        db.from("profiles").select("username").eq("id", userId).maybeSingle(),
        db
          .from("notification_prefs")
          .select("enabled, types")
          .eq("user_id", userId)
          .maybeSingle(),
      ]);
      if (cancelled) return;
      const patch: Partial<Prefs> = {};
      const username = profile?.["username"];
      if (typeof username === "string" && username) patch.username = username;
      if (row) {
        if (typeof row["enabled"] === "boolean") patch.notificationsEnabled = row["enabled"];
        const types = (row["types"] ?? {}) as Record<string, boolean>;

        if (Object.keys(types).length > 0) {
          patch.notifications = { ...prefs.notifications, ...types };
        }
      }
      if (Object.keys(patch).length > 0) apply(patch);
    })();
    return () => {
      cancelled = true;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId, ready]);

  return {
    saveUsername: async (username: string) => {
      if (!userId) return;
      await db.from("profiles").upsert({ id: userId, username, updated_at: new Date().toISOString() });
    },
    saveNotifications: async (enabled: boolean, types: Record<string, boolean>) => {
      if (!userId) return;
      await db
        .from("notification_prefs")
        .upsert({ user_id: userId, enabled, types, updated_at: new Date().toISOString() });
    },
    signedIn: !!userId,
  };
}
