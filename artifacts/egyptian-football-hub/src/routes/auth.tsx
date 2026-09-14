import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { LogIn } from "lucide-react";

import { lovable } from "@/integrations/lovable/index";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";
import { TEAM_CREST } from "@/lib/hub-types";

export const Route = createFileRoute("/auth")({
  head: () => ({
    meta: [
      { title: "تسجيل الدخول | Masrawy Fan" },
      {
        name: "description",
        content:
          "سجّل دخولك إلى تطبيق Masrawy Fan بحساب جوجل لمتابعة النادي المصري وحفظ تفضيلاتك.",
      },
      { property: "og:title", content: "تسجيل الدخول | Masrawy Fan" },
      {
        property: "og:description",
        content: "ادخل بحساب جوجل لتتابع النادي المصري البورسعيدي.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: AuthPage,
});

function AuthPage() {
  const navigate = useNavigate();
  const { isAuthenticated, loading } = useAuth();
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && isAuthenticated) navigate({ to: "/", replace: true });
  }, [loading, isAuthenticated, navigate]);

  const google = async () => {
    setBusy(true);
    const result = await lovable.auth.signInWithOAuth("google", {
      redirect_uri: `${window.location.origin}/auth`,
      extraParams: { prompt: "select_account" },
    });
    if (result.error) {
      setBusy(false);
      toast.error("تعذر الدخول بحساب جوجل، حاول مرة أخرى");
      return;
    }
    if (result.redirected) return;
    navigate({ to: "/", replace: true });
  };

  return (
    <main className="flex min-h-screen items-center justify-center bg-background px-5 py-10 font-[Cairo,system-ui,sans-serif]">
      <section className="w-full max-w-sm space-y-7 text-center">
        <img src={TEAM_CREST} alt="شعار النادي المصري" className="mx-auto size-24 object-contain" />
        <div className="space-y-2">
          <h1 className="text-2xl font-black">Masrawy Fan</h1>
          <p className="text-sm leading-7 text-muted-foreground">
            سجّل دخولك لمتابعة مباريات وأخبار النادي المصري وحفظ تفضيلاتك.
          </p>
        </div>
        <Button onClick={google} disabled={busy || loading} className="h-12 w-full rounded-xl font-bold">
          <LogIn className="size-5" /> {busy ? "جارٍ فتح جوجل…" : "المتابعة بحساب جوجل"}
        </Button>
      </section>
    </main>
  );
}
