/** مزامنة الاسم وتفضيلات الإشعارات مع حساب Firebase على API Server. */
import { useEffect } from "react";

import { useAuth } from "@/hooks/useAuth";
import { firebaseAuth } from "@/lib/firebase";
import type { Prefs } from "@/lib/prefs";

async function apiRequest(path: string, init?: RequestInit) {
  const token = await firebaseAuth.currentUser?.getIdToken();
  const response = await fetch(`/api${path}`, {
    ...init,
    headers: {
      "content-type": "application/json",
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(init?.headers ?? {}),
    },
  });
  if (!response.ok) throw new Error(`API request failed: ${response.status}`);
  return (await response.json()) as {
    preferences: {
      username: string;
      notificationsEnabled: boolean;
      notifications: Record<string, boolean>;
    };
  };
}

export function usePrefsSync(
  prefs: Prefs,
  ready: boolean,
  apply: (patch: Partial<Prefs>) => void,
) {
  const { user } = useAuth();
  const userId = user?.uid;

  // أول ما يسجّل الدخول: نجيب القيم المحفوظة على السيرفر.
  useEffect(() => {
    if (!userId || !ready) return;
    let cancelled = false;
    (async () => {
      let result: Awaited<ReturnType<typeof apiRequest>>;
      try {
        result = await apiRequest("/me/preferences");
      } catch {
        return;
      }
      if (cancelled) return;
      const patch: Partial<Prefs> = {};
      if (result.preferences.username) patch.username = result.preferences.username;
      if (typeof result.preferences.notificationsEnabled === "boolean") {
        patch.notificationsEnabled = result.preferences.notificationsEnabled;
      }
      if (Object.keys(result.preferences.notifications).length > 0) {
        patch.notifications = { ...prefs.notifications, ...result.preferences.notifications };
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
      await apiRequest("/me/preferences", {
        method: "PUT",
        body: JSON.stringify({ username }),
      });
    },
    saveNotifications: async (enabled: boolean, types: Record<string, boolean>) => {
      if (!userId) return;
      await apiRequest("/me/preferences", {
        method: "PUT",
        body: JSON.stringify({ notificationsEnabled: enabled, notifications: types }),
      });
    },
    signedIn: !!userId,
  };
}
