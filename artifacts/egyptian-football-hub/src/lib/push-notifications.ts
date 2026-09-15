import { Capacitor } from "@capacitor/core";
import { PushNotifications } from "@capacitor/push-notifications";
import { useEffect } from "react";

import { useAuth } from "@/hooks/useAuth";
import { firebaseAuth } from "@/lib/firebase";

async function saveDeviceToken(token: string) {
  const idToken = await firebaseAuth.currentUser?.getIdToken();
  if (!idToken) return;
  await fetch("/api/me/devices", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${idToken}`,
    },
    body: JSON.stringify({ token }),
  });
}

/** يسجل جهاز Android في FCM بعد دخول المستخدم، بدون طلب بيانات اعتماد إضافية. */
export function usePushNotifications() {
  const { user } = useAuth();

  useEffect(() => {
    if (!user || !Capacitor.isNativePlatform()) return;
    let cancelled = false;
    let removeRegistration: (() => Promise<void>) | undefined;
    let removeError: (() => Promise<void>) | undefined;

    void (async () => {
      const permissions = await PushNotifications.requestPermissions();
      if (cancelled || permissions.receive !== "granted") return;

      const registration = await PushNotifications.addListener("registration", ({ value }) => {
        void saveDeviceToken(value).catch((error) => console.error("FCM device registration failed", error));
      });
      const errorListener = await PushNotifications.addListener("registrationError", (error) => {
        console.error("FCM registration failed", error);
      });
      removeRegistration = () => registration.remove();
      removeError = () => errorListener.remove();
      await PushNotifications.register();
    })().catch((error) => console.error("FCM setup failed", error));

    return () => {
      cancelled = true;
      void removeRegistration?.();
      void removeError?.();
    };
  }, [user?.uid]);
}