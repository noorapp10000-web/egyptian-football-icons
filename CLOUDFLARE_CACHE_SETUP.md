# إعداد Cloudflare Cache لـ Egyptian Football API

## المعمارية

المسار المقصود هو:

```text
Flutter Offline Cache
        ↓
Cloudflare CDN Cache
        ↓ عند Cache MISS فقط
Replit API
        ↓ عند انتهاء كاش RAM فقط
FilGoal / Google News
```

الـAPI يرسل `Cache-Control` مختلفًا حسب نوع البيانات. Cloudflare هو طبقة
التوزيع الأساسية، وكاش RAM داخل Replit هو طبقة تقليل إضافية لحالات الـMISS
والـrevalidation. لا يعتمد النظام على ذاكرة Replit وحدها.

## إعداد Dashboard

1. أضف النطاق المستخدم أمام رابط نشر Replit إلى Cloudflare، واضبط DNS إلى
   رابط النشر حسب طريقة Cloudflare الحالية. استخدم HTTPS وFull (strict) إذا
   كان النطاق يمر عبر Cloudflare.
2. من **Caching → Cache Rules** أنشئ قاعدة للطلبات التالية:
   - الشرط: `http.request.method in {"GET" "HEAD"} and starts_with(http.request.uri.path, "/api/football/")`
   - Cache eligibility: **Eligible for cache**.
   - احترم `Cache-Control` من الأصل، ولا تضع Edge TTL ثابتًا يتغلب على header
     الأصل. لو كانت واجهة Cloudflare تعرض اختيارًا اسمه **Respect origin
     headers**, استخدمه.
   - لا تغيّر query string: يجب أن يبقى `url` جزءًا من مفتاح `/football/image`
     القديم إذا استُخدم endpoint التوافق.
3. أنشئ قاعدة أعلى أولوية لمنع البيانات الشخصية:
   - الشرط: `http.request.uri.path starts_with "/api/me/"`
   - Cache eligibility: **Do not cache**.
   - لا تستخدم أي Edge TTL أو Cache Everything لهذه المسارات.
4. أنشئ قاعدة صريحة للطرق غير GET/HEAD:
   - الشرط: `http.request.method in {"POST" "PUT" "PATCH" "DELETE"}`
   - **Do not cache**.
5. لا تضف Worker. لا تحتاج هذه المعمارية Worker لأن الـAPI يرسل headers
   صحيحة وCloudflare CDN يستطيع تنفيذ الـcache rules مباشرة.
6. امسح الكاش القديم بعد إنشاء القواعد، ثم اختبر من خلال النطاق العام لا من
   عنوان `localhost`:

```bash
curl -sSI https://YOUR_DOMAIN/api/football/news
curl -sSI https://YOUR_DOMAIN/api/me/preferences
```

توقّع `CF-Cache-Status: MISS` في أول طلب ثم `HIT` في الطلبات التالية للـGET
العامة، وتوقّع `private, no-store` وغياب التخزين العام لطلبات `/api/me/*`.

## مدد الكاش

| Endpoint | Source refresh | HTTP Cloudflare TTL |
|---|---:|---:|
| `GET /api/football/matches` | 20 ثانية عند LIVE؛ 60 ثانية قبل مباراة قريبة؛ ساعة في الحالة العادية | 20 ثانية عند LIVE؛ 60 ثانية قبل مباراة قريبة؛ ساعة عاديًا |
| `GET /api/football/matches/:matchId` | 20 ثانية عند LIVE؛ ساعة لغير LIVE | 20 ثانية عند LIVE؛ ساعة لغير LIVE |
| `GET /api/football/standings` | ساعتان | ساعتان |
| `GET /api/football/news` | ساعة | ساعة |
| `GET /api/football/players/:playerId` | ساعتان | ساعتان |
| `GET /api/football/squad` | 24 ساعة | 24 ساعة |
| `GET /api/football/image` | لا يوجد تحميل من Replit؛ endpoint توافق يعيد redirect فقط | 24 ساعة للـredirect |
| `/api/me/*` | حسب العملية | `private, no-store` |

الـresponses العامة تستخدم `public`, `max-age`, `s-maxage` و
`stale-while-revalidate`. مدة الـSWR قصيرة أثناء LIVE حتى لا تُعرض نتيجة
مباراة قديمة لفترة غير منطقية.

## Authentication والخصوصية

مسارات football العامة لا تعتمد على Firebase Authorization header، لذلك يمكن
لـCloudflare مشاركة نفس JSON بين المستخدمين. لا تُزل authentication من
المسارات الشخصية: `/api/me/preferences` و`/api/me/devices` ما زالت تتطلب
Bearer Firebase token.

يجب عدم إنشاء قاعدة `Cache Everything` عامة على كل `/api`. طبّق الكاش فقط على
GET/HEAD تحت `/api/football/*`، واترك `/api/me/*` وPOST/PUT/PATCH/DELETE بلا
كاش حتى لا يتسرب userId أو preferences أو device token.

## الصور

تم إيقاف تحميل صور الأخبار من Replit. parser الأخبار يحتفظ فقط بعنوان الصورة
الموجود أصلًا في HTML/RSS؛ لا يفتح السيرفر صفحة كل مقال لاستخراج `og:image`.
وإذا استُدعي `/api/football/image` من عميل قديم، فالخادم يتحقق من host ثم
يعيد HTTP redirect إلى المصدر، ولا يقرأ أو يخزن أو يرسل bytes الصورة. Flutter
الحالي يطلب رابط الصورة الأصلي مباشرة مع استمرار كاش الصور المحلي في Flutter.