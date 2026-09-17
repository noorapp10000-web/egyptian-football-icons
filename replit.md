# Egyptian Football Icons

منصة متابعة المصري البورسعيدي: المباريات والأحداث لحظة بلحظة، الأخبار، اللاعبين،
الإحصائيات، الترتيب، التشكيلات، وتاريخ النادي، مع تطبيق Flutter وواجهة ويب مساندة.

## Run & Operate

- `pnpm --filter @workspace/api-server run dev` — run the API server (port 5000)
- `pnpm run typecheck` — full typecheck across all packages
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regenerate API hooks and Zod schemas from the OpenAPI spec
- `pnpm --filter @workspace/db run push` — push DB schema changes (dev only)
- Required env: `DATABASE_URL` — Postgres connection string

## Stack

- pnpm workspaces, Node.js 24, TypeScript 5.9
- API: Express 5
- DB: PostgreSQL + Drizzle ORM
- Validation: Zod (`zod/v4`), `drizzle-zod`
- API codegen: Orval (from OpenAPI spec)
- Build: esbuild (CJS bundle)

## Where things live

- `flutter_app/` — تطبيق Flutter الأساسي وواجهاته العربية.
- `artifacts/api-server/` — API عام تحت `/api` يقرأ البيانات من في الجول ويخزنها مؤقتًا.
- `artifacts/egyptian-football-hub/` — واجهة ويب مساندة بنفس البيانات والهوية.
- `artifacts/egyptian-football-hub/src/lib/filgoal.server.ts` — النماذج، القراءة، الكاش،
  وتوحيد الأحداث والدقائق.
- `artifacts/egyptian-football-hub/src/lib/match-events.ts` — أنواع الأحداث وتطبيع الدقيقة.
- `flutter_app/lib/screens/app_shell.dart` — الشاشات والتنقل وتفاصيل المباراة.

## Architecture decisions

- كل البيانات الخارجية تمر من خلال API السيرفر، ولا يتصل تطبيق Flutter بالمصادر الخارجية مباشرة.
- الأحداث الرسمية تستخدم الدقيقة المطلقة، بينما التعليق الحي قد يعيد عداد الشوط الثاني من 1؛
  يتم توحيد ذلك قبل إرساله للعميل.
- الأحداث في تفاصيل المباراة تُعرض داخل عمود الفريق صاحب الحدث، مع عمود منفصل للأحداث العامة.
- صور الفرق واللاعبين تمر عبر كاش الصور والبيانات تُعاد من الكاش عند فشل المصدر مؤقتًا.

## Product

التطبيق يعرض الرئيسية، المباريات والنتائج، تفاصيل الحدث والتعليق، الإحصائيات،
التشكيلات على ملعب، قائمة الفريق واللاعبين، الأخبار، جدول الدوري، وتاريخ النادي.

## User preferences

- الحفاظ على ألوان المصري الحالية مع تحسين الوضوح والحركة والأيقونات، والواجهة عربية RTL.
- عدم خلط أحداث الفريقين في قائمة واحدة، وعدم عرض الدقيقة النسبية للشوط الثاني كما لو كانت مطلقة.

## Gotchas

- يجب تشغيل `pnpm install --frozen-lockfile` بعد جلب ملفات الفرع قبل فحص TypeScript.
- توحيد أي مصدر بيانات جديد عبر `normalizeMatchMinute` و`normalizeCommentaryMinute` قبل عرضه.

## Pointers

- See the `pnpm-workspace` skill for workspace structure, TypeScript setup, and package details
