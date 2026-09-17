import { createFileRoute } from "@tanstack/react-router";
import { useQueryClient } from "@tanstack/react-query";
import { BellRing, Check, Settings as SettingsIcon, Trash2, UserRound } from "lucide-react";
import { useEffect, useState } from "react";
import { toast } from "sonner";

import { AccountCard } from "@/components/hub/account-card";
import { SectionHeading } from "@/components/hub/shared";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Switch } from "@/components/ui/switch";
import { NOTIFICATION_TYPES, usePrefs } from "@/lib/prefs";
import { usePrefsSync } from "@/lib/prefs-sync";

export const Route = createFileRoute("/_authenticated/settings")({
  head: () => ({
    meta: [
      { title: "الإعدادات | Masrawy Fan" },
      {
        name: "description",
        content:
          "اضبط اسمك داخل تطبيق Masrawy Fan واختر الإشعارات التي تريد وصولها: التشكيل، الأهداف، التبديلات، الأخبار وغيرها.",
      },
      { property: "og:title", content: "إعدادات تطبيق Masrawy Fan" },
      {
        property: "og:description",
        content: "اسم المستخدم وتفضيلات الإشعارات وإدارة البيانات المحفوظة.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: SettingsPage,
});

function SettingsPage() {
  const { prefs, ready, update, toggleNotification } = usePrefs();
  const [name, setName] = useState("");
  const queryClient = useQueryClient();

  useEffect(() => {
    if (ready) setName(prefs.username);
  }, [ready, prefs.username]);

  const { saveUsername, saveNotifications, signedIn } = usePrefsSync(prefs, ready, update);

  const saveName = async () => {
    const value = name.trim();
    update({ username: value });
    await saveUsername(value);
    toast.success(signedIn ? "تم حفظ الاسم على حسابك" : "تم حفظ الاسم");
  };

  const setNotificationsEnabled = (v: boolean) => {
    update({ notificationsEnabled: v });
    void saveNotifications(v, prefs.notifications);
  };

  const setNotificationType = (key: string, v: boolean) => {
    toggleNotification(key, v);
    void saveNotifications(prefs.notificationsEnabled, { ...prefs.notifications, [key]: v });
  };

  const clearCache = async () => {
    queryClient.clear();
    try {
      window.localStorage.removeItem("masrawy-fan-cache");
    } catch {
      /* لا شيء */
    }
    await queryClient.refetchQueries();
    toast.success("تم مسح البيانات المحفوظة وإعادة التحميل");
  };

  return (
    <div className="space-y-6">
      <SectionHeading icon={<SettingsIcon className="size-4" />} title="الإعدادات" />

      <AccountCard />


      <section className="space-y-3 rounded-2xl border border-border/70 bg-card p-4">
        <h3 className="flex items-center gap-2 text-sm font-black">
          <UserRound className="size-4 text-primary" /> اسم المستخدم
        </h3>
        <p className="text-[11px] text-muted-foreground">الاسم الذي يظهر لك داخل التطبيق.</p>
        <div className="flex gap-2">
          <Input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="اكتب اسمك"
            maxLength={30}
            className="rounded-xl"
          />
          <Button onClick={saveName} className="shrink-0 rounded-xl font-bold">
            <Check className="size-4" /> حفظ
          </Button>
        </div>
      </section>

      <section className="space-y-3 rounded-2xl border border-border/70 bg-card p-4">
        <div className="flex items-center justify-between gap-3">
          <h3 className="flex items-center gap-2 text-sm font-black">
            <BellRing className="size-4 text-gold" /> الإشعارات
          </h3>
          <Switch
            checked={prefs.notificationsEnabled}
            onCheckedChange={setNotificationsEnabled}
            aria-label="تفعيل كل الإشعارات"
          />
        </div>
        <p className="text-[11px] text-muted-foreground">
          اختر الإشعارات التي تريد وصولها. الإيقاف العام يوقف كل الأنواع.
        </p>

        <ul className={prefs.notificationsEnabled ? "" : "pointer-events-none opacity-50"}>
          {NOTIFICATION_TYPES.map((t) => (
            <li
              key={t.key}
              className="flex items-center justify-between gap-3 border-b border-border/50 py-3 last:border-0"
            >
              <span className="min-w-0">
                <span className="block text-sm font-bold">{t.label}</span>
                <span className="block text-[11px] text-muted-foreground">{t.hint}</span>
              </span>
              <Switch
                checked={prefs.notifications[t.key] ?? true}
                onCheckedChange={(v) => setNotificationType(t.key, v)}
                aria-label={t.label}
              />
            </li>
          ))}
        </ul>
      </section>

      <section className="space-y-3 rounded-2xl border border-border/70 bg-card p-4">
        <h3 className="text-sm font-black">البيانات المحفوظة</h3>
        <p className="text-[11px] text-muted-foreground">
          يحتفظ التطبيق بآخر نسخة من المباريات والترتيب والأخبار والتاريخ ليعمل بدون إنترنت.
        </p>
        <Button variant="outline" onClick={clearCache} className="rounded-xl">
          <Trash2 className="size-4" /> مسح البيانات وإعادة التحميل
        </Button>
      </section>
    </div>
  );
}
