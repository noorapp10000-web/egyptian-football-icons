import { Outlet, createFileRoute, redirect } from "@tanstack/react-router";
import { useEffect, useState } from "react";

import { BottomNav } from "@/components/hub/bottom-nav";
import { TEAM_CREST } from "@/lib/hub-types";
import { firebaseAuth } from "@/lib/firebase";

export const Route = createFileRoute("/_authenticated")({
  ssr: false,
  beforeLoad: async () => {
    const user = firebaseAuth.currentUser;
    if (!user) throw redirect({ to: "/auth" });
    return { user };
  },
  component: AuthenticatedLayout,
});

function AuthenticatedLayout() {
  return (
    <div className="min-h-screen bg-background pb-24 font-[Cairo,system-ui,sans-serif]">
      <header className="sticky top-0 z-30 border-b border-border/70 bg-background/85 backdrop-blur-xl">
        <div className="mx-auto flex max-w-3xl items-center justify-between gap-2.5 px-4 py-3">
          <a href="/" className="flex items-center gap-2.5">
            <img src={TEAM_CREST} alt="شعار النادي المصري" className="size-8 object-contain" />
            <span className="text-sm font-black">MASRAWY FAN</span>
          </a>
          <OfflineBadge />
        </div>
      </header>
      <main className="mx-auto max-w-3xl px-4 py-5">
        <Outlet />
      </main>
      <BottomNav />
    </div>
  );
}

function OfflineBadge() {
  const [offline, setOffline] = useState(false);

  useEffect(() => {
    const sync = () => setOffline(!navigator.onLine);
    sync();
    window.addEventListener("online", sync);
    window.addEventListener("offline", sync);
    return () => {
      window.removeEventListener("online", sync);
      window.removeEventListener("offline", sync);
    };
  }, []);

  if (!offline) return null;
  return (
    <span className="rounded-full bg-gold/15 px-2.5 py-1 text-[10px] font-bold text-gold">
      بدون إنترنت · نسخة محفوظة
    </span>
  );
}