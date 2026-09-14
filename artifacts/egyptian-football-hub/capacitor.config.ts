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
  server: {
    url:
      process.env["CAP_SERVER_URL"] ??
      "https://project--fed06797-85e0-46bd-acbd-d420b4b17003.lovable.app",
    cleartext: false,
    androidScheme: "https",
  },
  android: {
    allowMixedContent: false,
    backgroundColor: "#0b0f17",
  },
};

export default config;
