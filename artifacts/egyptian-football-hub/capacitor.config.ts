import type { CapacitorConfig } from "@capacitor/cli";

/**
 * تطبيق Masrawy Fan للأندرويد.
 * التطبيق بيفتح نسخة الويب المنشورة (لأن البيانات بتتجاب من السيرفر لحظيًا).
 * لو غيّرت الدومين، عدّل server.url هنا أو حدّد CAP_SERVER_URL وقت البناء.
 */
const config: CapacitorConfig = {
  appId: "app.lovable.masrawyfan",
  appName: "Masrawy Fan",
  webDir: "mobile/www",
  ...(process.env["CAP_SERVER_URL"]
    ? {
        server: {
          url: process.env["CAP_SERVER_URL"],
          cleartext: false,
          androidScheme: "https" as const,
        },
      }
    : {}),
  android: {
    allowMixedContent: false,
    backgroundColor: "#0b0f17",
  },
};

export default config;
