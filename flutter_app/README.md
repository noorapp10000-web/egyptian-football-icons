# Masrawy Fan — Flutter

تطبيق Android أصلي للنادي المصري البورسعيدي، بنفس هوية الموقع في فرع
`replit-agent/firebase-capacitor`: خلفية داكنة خضراء، لمسات ذهبية، اتجاه RTL،
المباريات، الترتيب، قائمة الفريق، الأخبار، التاريخ، تفاصيل المباراة، وتفضيلات
إشعارات FCM.

## السلوك الحالي

- يفتح التطبيق مباشرة بدون شاشة تسجيل دخول أو إنشاء حساب.
- يستخدم Firebase Anonymous Auth داخليًا فقط إذا كانت إعدادات Firebase الجديدة
  متاحة، حتى يمكن ربط جهاز الإشعارات بالسيرفر بدون حساب ظاهر للمستخدم.
- Firebase الخاص بالتطبيق منفصل عن Firebase الخاص بالموقع. لا تستخدم ملف
  `google-services.json` أو قيم Firebase الموجودة في مشروع الويب.

## التشغيل المحلي

```bash
flutter pub get
flutter run \
  --dart-define=API_BASE_URL=https://YOUR_SERVER/api \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

كل قيم Firebase السابقة تخص مشروع Flutter الجديد وتُمرر وقت البناء فقط.

## GitHub Actions

الملف `.github/workflows/flutter-android.yml` يبني APK عند الدفع إلى فرع
`replit-agent/flutter-app` أو عند تشغيله يدويًا. أضف هذه **Repository Secrets**
في GitHub:

- `FLUTTER_API_BASE_URL`
- `FLUTTER_FIREBASE_API_KEY`
- `FLUTTER_FIREBASE_APP_ID`
- `FLUTTER_FIREBASE_MESSAGING_SENDER_ID`
- `FLUTTER_FIREBASE_PROJECT_ID`
- `FLUTTER_FIREBASE_STORAGE_BUCKET`

فعّل في Firebase الجديد:

1. Anonymous Authentication.
2. Cloud Messaging.
3. صلاحية الإشعارات في Android 13 أو أحدث.

## ربط Firebase الجديد بالسيرفر

بما أن Firebase التطبيق منفصل عن Firebase الموقع، يجب إضافة ملف حساب الخدمة
للمشروع الجديد إلى Secrets الخاصة بتشغيل API باسم:

`FLUTTER_FIREBASE_SERVICE_ACCOUNT_JSON`

يجب أن تكون قيمة السر هي محتوى ملف Service Account JSON كاملًا، ولا تُحفظ داخل
Git أو داخل التطبيق. السيرفر يقبل توكنات Firebase الموقع القديمة وتوكنات
Firebase Flutter الجديدة معًا.