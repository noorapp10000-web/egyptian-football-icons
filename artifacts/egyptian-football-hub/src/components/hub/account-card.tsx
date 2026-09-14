import { Link, useNavigate } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { LogIn, LogOut, UserRound } from "lucide-react";

import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/useAuth";
import { Button } from "@/components/ui/button";

/** بطاقة الحساب داخل الإعدادات: دخول جوجل/البريد أو تسجيل الخروج. */
export function AccountCard() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const signOut = async () => {
    await queryClient.cancelQueries();
    queryClient.clear();
    await supabase.auth.signOut();
    navigate({ to: "/auth", replace: true });
  };

  if (loading) return null;

  return (
    <section className="space-y-3 rounded-2xl border border-border/70 bg-card p-4">
      <h3 className="flex items-center gap-2 text-sm font-black">
        <UserRound className="size-4 text-primary" /> الحساب
      </h3>
      {user ? (
        <>
          <p className="truncate text-[11px] text-muted-foreground" dir="ltr">
            {user.email}
          </p>
          <Button variant="outline" onClick={signOut} className="rounded-xl">
            <LogOut className="size-4" /> تسجيل الخروج
          </Button>
        </>
      ) : (
        <>
          <p className="text-[11px] text-muted-foreground">
            سجّل دخولك لحفظ اسمك وتفضيلات الإشعارات على كل أجهزتك.
          </p>
          <Button asChild className="rounded-xl font-bold">
            <Link to="/auth">
              <LogIn className="size-4" /> تسجيل الدخول
            </Link>
          </Button>
        </>
      )}
    </section>
  );
}
