import { createFileRoute } from "@tanstack/react-router";
import { useState } from "react";
import {
  Building2,
  Check,
  Crown,
  ExternalLink,
  History as HistoryIcon,
  Landmark,
  Medal,
  ShieldCheck,
  Star,
  Target,
  Trophy,
  UserCog,
  Users,
} from "lucide-react";

import { SectionHeading } from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { COACH_HISTORY, RECORD_PLAYERS } from "@/lib/history-data";
import { HONOURS, IDENTITY, LEAGUE_CUP_PATH, PRESIDENTS, SOURCES, TIMELINE } from "@/lib/history-content";
import { HISTORY_PHOTOS } from "@/lib/history-photos";
import { LEGENDS, PRESIDENT_PHOTOS, TOP_SCORERS } from "@/lib/history-people";
import { TEAM_CREST } from "@/lib/hub-types";

const CUP_GALLERY = [
  { src: HISTORY_PHOTOS.gallery[0], caption: "البوستر الرسمي لتتويج المصري بكأس عاصمة مصر 2026" },
  { src: HISTORY_PHOTOS.gallery[1], caption: "لحظة رفع الكأس وسط الاحتفالات على منصة التتويج" },
  { src: HISTORY_PHOTOS.gallery[2], caption: "احتفال اللاعبين باللقب أمام جماهير بورسعيد" },
  { src: HISTORY_PHOTOS.gallery[3], caption: "تيفو جماهير المصري في المدرجات ليلة النهائي" },
];


export const Route = createFileRoute("/_authenticated/history")({
  head: () => ({
    meta: [
      { title: "تاريخ النادي المصري البورسعيدي | 1920 حتى اليوم" },
      {
        name: "description",
        content:
          "موسوعة تاريخ النادي المصري البورسعيدي: التأسيس 1920، الألقاب، الخط الزمني، تسلسل كل المدربين وكل رؤساء النادي، وأساطير النسور الخضراء بالصور والمصادر.",
      },
      { property: "og:title", content: "تاريخ النادي المصري البورسعيدي" },
      {
        property: "og:description",
        content: "1920 حتى اليوم: الألقاب، المدربون، الرؤساء، الأساطير والمحطات الكبرى بالصور.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: HistoryPage,
});

function initials(name: string) {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0])
    .join("");
}

function Portrait({
  src,
  name,
  className = "size-14",
}: {
  src: string | null | undefined;
  name: string;
  className?: string;
}) {
  if (!src)
    return (
      <span
        className={`${className} flex shrink-0 items-center justify-center rounded-full border border-primary/25 bg-primary/10 text-sm font-black text-primary`}
      >
        {initials(name)}
      </span>
    );
  return (
    <img
      src={src}
      alt={name}
      loading="lazy"
      className={`${className} shrink-0 rounded-full border border-primary/25 bg-secondary object-cover`}
    />
  );
}

function HistoryPage() {
  const withPhoto = COACH_HISTORY.filter((c) => c.photo).length;

  return (
    <div className="space-y-5 pb-4">
      <HistoryHero />

      <Tabs defaultValue="story" dir="rtl" className="space-y-4">
        <div>
          <TabsList className="grid h-auto w-full grid-cols-3 gap-1 rounded-2xl bg-secondary/60 p-1">
            {[
              { v: "story", t: "الحكاية", i: HistoryIcon },
              { v: "honours", t: "البطولات", i: Trophy },
              { v: "cup-path", t: "مسار الرابطة", i: Medal },
              { v: "coaches", t: "المدربون", i: UserCog },
              { v: "presidents", t: "الرؤساء", i: Crown },
              { v: "scorers", t: "الهدافون", i: Target },
              { v: "legends", t: "الأساطير", i: Star },
              { v: "apps", t: "الأكثر مشاركة", i: Users },
              { v: "identity", t: "الهوية", i: ShieldCheck },
            ].map(({ v, t, i: Icon }) => (
              <TabsTrigger
                key={v}
                value={v}
                className="gap-1.5 rounded-xl px-3 py-2 text-xs font-bold data-[state=active]:bg-primary data-[state=active]:text-primary-foreground"
              >
                <Icon className="size-3.5" />
                {t}
              </TabsTrigger>
            ))}
          </TabsList>
        </div>

        <TabsContent value="story" className="space-y-4">
          <Timeline />
        </TabsContent>

        <TabsContent value="honours" className="space-y-3">
          <Honours />
        </TabsContent>

        <TabsContent value="cup-path" className="space-y-3">
          <LeagueCupPath />
        </TabsContent>

        <TabsContent value="coaches" className="space-y-3">
          <Coaches count={withPhoto} />
        </TabsContent>

        <TabsContent value="presidents" className="space-y-3">
          <Presidents />
        </TabsContent>

        <TabsContent value="scorers" className="space-y-3">
          <TopScorers />
        </TabsContent>

        <TabsContent value="legends" className="space-y-3">
          <Legends />
        </TabsContent>

        <TabsContent value="apps" className="space-y-3">
          <MostApps />
        </TabsContent>

        <TabsContent value="identity" className="space-y-3">
          <Identity />
        </TabsContent>

      </Tabs>

      <Sources />
    </div>
  );
}

function HistoryHero() {
  const stats = [
    { k: "1920", v: "سنة التأسيس" },
    { k: "17", v: "لقب دوري القناة" },
    { k: "1", v: "كأس مصر" },
    { k: "1", v: "كأس الرابطة 2025/26" },
    { k: `${COACH_HISTORY.length}`, v: "فترة تدريبية موثّقة" },
    { k: `${PRESIDENTS.length}`, v: "فترة رئاسة" },
  ];
  return (
    <section className="relative overflow-hidden rounded-3xl border border-primary/25 bg-gradient-to-b from-primary/20 via-card to-card p-5">
      <div className="flex items-center gap-4">
        <img src={TEAM_CREST} alt="شعار النادي المصري" className="size-16 object-contain" />
        <div>
          <p className="text-[11px] font-bold text-primary">موسوعة النسور الخضراء</p>
          <h1 className="text-2xl font-black leading-tight">تاريخ النادي المصري</h1>
          <p className="mt-1 text-xs text-muted-foreground">
            من ثورة 1919 وشوارع بورسعيد إلى اليوم — قرن كامل من الكرة والهوية.
          </p>
        </div>
      </div>
      <div className="mt-4 grid grid-cols-3 gap-2">
        {stats.map((s) => (
          <div key={s.v} className="rounded-2xl border border-border/60 bg-background/40 p-3 text-center">
            <p className="text-lg font-black text-primary">{s.k}</p>
            <p className="text-[10px] font-bold text-muted-foreground">{s.v}</p>
          </div>
        ))}
      </div>
    </section>
  );
}

function Timeline() {
  return (
    <>
      <SectionHeading icon={<HistoryIcon className="size-4" />} title="الخط الزمني" />
      <ol className="relative space-y-4 border-r-2 border-primary/25 pr-4">
        {TIMELINE.map((e) => (
          <li key={e.year + e.title} className="relative">
            <span
              className={`absolute -right-[22px] top-2 size-3 rounded-full ring-4 ring-background ${
                e.tone === "gold" ? "bg-accent" : e.tone === "dark" ? "bg-destructive" : "bg-primary"
              }`}
            />
            <article
              className={`overflow-hidden rounded-2xl border bg-card ${
                e.tone === "gold"
                  ? "border-accent/40"
                  : e.tone === "dark"
                    ? "border-destructive/40"
                    : "border-border/70"
              }`}
            >
              {e.image && (
                <figure className="border-b border-border/60">
                  <img
                    src={e.image.src}
                    alt={e.image.caption}
                    loading="lazy"
                    className="h-44 w-full object-cover"
                  />
                  <figcaption className="px-3 py-1.5 text-[10px] text-muted-foreground">
                    {e.image.caption}
                  </figcaption>
                </figure>
              )}
              <div className="space-y-1.5 p-4">
                <Badge variant="outline" className="border-primary/40 text-[10px] font-black text-primary">
                  {e.year}
                </Badge>
                <h3 className="text-base font-black leading-tight">{e.title}</h3>
                <p className="text-[13px] leading-relaxed text-muted-foreground">{e.body}</p>
              </div>
            </article>
          </li>
        ))}
      </ol>
    </>
  );
}

function Honours() {
  return (
    <>
      <SectionHeading icon={<Trophy className="size-4" />} title="خزانة البطولات" />
      {HONOURS.map((h) => (
        <article key={h.title} className="rounded-2xl border border-border/70 bg-card p-4">
          <div className="flex items-center justify-between gap-2">
            <h3 className="text-sm font-black">{h.title}</h3>
            <Badge className="border-0 bg-accent/20 text-accent">{h.wins.length}× بطل</Badge>
          </div>
          <div className="mt-3 flex flex-wrap gap-1.5">
            {h.wins.map((w) => (
              <span
                key={w}
                className="rounded-lg bg-accent/15 px-2 py-1 text-[11px] font-bold text-accent"
              >
                {w}
              </span>
            ))}
          </div>
          {h.runnersUp && (
            <>
              <p className="mt-3 text-[11px] font-bold text-muted-foreground">
                وصافة ({h.runnersUp.length})
              </p>
              <div className="mt-1.5 flex flex-wrap gap-1.5">
                {h.runnersUp.map((r) => (
                  <span
                    key={r}
                    className="rounded-lg bg-secondary px-2 py-1 text-[11px] text-muted-foreground"
                  >
                    {r}
                  </span>
                ))}
              </div>
            </>
          )}
          {h.note && <p className="mt-3 text-[11px] font-bold text-primary">{h.note}</p>}
        </article>
      ))}
    </>
  );
}

function LeagueCupPath() {
  const matches = LEAGUE_CUP_PATH.flatMap((stage) => stage.matches);
  const goalsFor = matches.reduce((total, match) => total + match.masryScore, 0);
  const goalsAgainst = matches.reduce((total, match) => total + match.opponentScore, 0);

  return (
    <section className="space-y-4">
      <div className="relative overflow-hidden rounded-2xl border border-gold/40 bg-gradient-to-bl from-gold/20 via-card to-primary/10 p-5">
        <div className="absolute -left-5 -top-5 size-28 rounded-full border border-gold/15" />
        <div className="relative flex items-center gap-4">
          <div className="flex size-16 shrink-0 items-center justify-center rounded-full border border-gold/40 bg-gold/15 text-gold shadow-lg shadow-gold/10">
            <Trophy className="size-8" strokeWidth={1.7} />
          </div>
          <div className="min-w-0">
            <Badge className="border-0 bg-gold/20 text-[10px] font-black text-gold">بطل 2025–26</Badge>
            <h2 className="mt-2 text-xl font-black">الطريق إلى الكأس</h2>
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">
              رحلة المصري من أول صافرة في المجموعات إلى ليلة الثلاثية والتتويج.
            </p>
          </div>
        </div>
        <div className="relative mt-5 grid grid-cols-3 divide-x divide-x-reverse divide-border/70 rounded-xl border border-border/60 bg-background/35 py-3 text-center">
          <div>
            <p className="text-lg font-black text-gold">{matches.length}</p>
            <p className="text-[10px] text-muted-foreground">مباراة</p>
          </div>
          <div>
            <p className="text-lg font-black text-primary">{goalsFor}</p>
            <p className="text-[10px] text-muted-foreground">هدف للمصري</p>
          </div>
          <div>
            <p className="text-lg font-black">{goalsAgainst}</p>
            <p className="text-[10px] text-muted-foreground">هدف عليه</p>
          </div>
        </div>
      </div>

      <div className="space-y-2">
        <SectionHeading icon={<Trophy className="size-4" />} title="من ليلة التتويج" />
        <div className="grid grid-cols-2 gap-2">
          {CUP_GALLERY.map((photo) => (
            <figure
              key={photo.src}
              className="overflow-hidden rounded-2xl border border-gold/30 bg-card"
            >
              <img
                src={photo.src}
                alt={photo.caption}
                loading="lazy"
                className="h-32 w-full object-cover"
              />
              <figcaption className="px-2 py-1.5 text-[10px] leading-snug text-muted-foreground">
                {photo.caption}
              </figcaption>
            </figure>
          ))}
        </div>
      </div>

      <div className="relative pr-5">
        <div className="absolute bottom-5 right-[7px] top-5 w-px bg-gradient-to-b from-primary via-primary/60 to-gold" />
        <div className="space-y-4">
          {LEAGUE_CUP_PATH.map((stage, stageIndex) => (
            <article
              key={stage.stage}
              className={`relative overflow-hidden rounded-2xl border bg-card ${
                stageIndex === LEAGUE_CUP_PATH.length - 1 ? "border-gold/50" : "border-border/70"
              }`}
            >
              <span
                className={`absolute -right-[22px] top-6 z-10 flex size-4 items-center justify-center rounded-full ring-4 ring-background ${
                  stageIndex === LEAGUE_CUP_PATH.length - 1 ? "bg-gold text-gold-foreground" : "bg-primary text-primary-foreground"
                }`}
              >
                <Check className="size-2.5" strokeWidth={4} />
              </span>
              <header className="border-b border-border/60 bg-secondary/30 px-4 py-3">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-[10px] font-bold text-primary">المحطة {stageIndex + 1}</p>
                    <h3 className="text-base font-black">{stage.stage}</h3>
                    <p className="mt-0.5 text-[11px] text-muted-foreground">{stage.summary}</p>
                  </div>
                  <Badge
                    variant="outline"
                    className={`shrink-0 text-[9px] font-black ${
                      stageIndex === LEAGUE_CUP_PATH.length - 1
                        ? "border-gold/50 bg-gold/10 text-gold"
                        : "border-primary/30 text-primary"
                    }`}
                  >
                    {stage.outcome}
                  </Badge>
                </div>
              </header>
              <div className="divide-y divide-border/50">
                {stage.matches.map((match) => {
                  const won = match.masryScore > match.opponentScore;
                  const drawn = match.masryScore === match.opponentScore;
                  return (
                    <div key={`${stage.stage}-${match.date}-${match.opponent}`} className="grid grid-cols-[1fr_auto] items-center gap-3 px-4 py-3">
                      <div className="min-w-0">
                        <div className="flex items-center gap-2">
                          <span className={`size-1.5 shrink-0 rounded-full ${won ? "bg-primary" : drawn ? "bg-gold" : "bg-muted-foreground"}`} />
                          <p className="truncate text-sm font-bold">
                            المصري <span className="px-1 text-muted-foreground">×</span> {match.opponent}
                          </p>
                        </div>
                        <p className="mt-1 pr-3.5 text-[10px] text-muted-foreground">
                          {match.date}
                          {match.note ? ` · ${match.note}` : ""}
                        </p>
                      </div>
                      <div className={`min-w-16 rounded-lg px-2 py-1.5 text-center ${won ? "bg-primary/15 text-primary" : drawn ? "bg-gold/15 text-gold" : "bg-secondary text-muted-foreground"}`}>
                        <span className="text-lg font-black tabular-nums">{match.masryScore} — {match.opponentScore}</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </article>
          ))}
        </div>
      </div>

      <a
        href="https://www.filgoal.com/championships/1527"
        target="_blank"
        rel="noreferrer"
        className="flex items-center justify-center gap-2 rounded-xl border border-border/70 bg-secondary/40 px-4 py-3 text-xs font-bold text-muted-foreground transition-colors hover:border-primary/40 hover:text-primary"
      >
        المصدر: FilGoal — كأس عاصمة مصر
        <ExternalLink className="size-3.5" />
      </a>
    </section>
  );
}

function Coaches({ count }: { count: number }) {
  const [onlyPhotos, setOnlyPhotos] = useState(false);
  const list = onlyPhotos ? COACH_HISTORY.filter((c) => c.photo) : COACH_HISTORY;

  return (
    <>
      <SectionHeading icon={<UserCog className="size-4" />} title="تسلسل المدربين" />
      <p className="text-[11px] text-muted-foreground">
        {COACH_HISTORY.length} فترة تدريبية موثّقة من Transfermarkt، من بوشكاش 1979 حتى اليوم — مع
        عدد المباريات ومعدل النقاط لكل مباراة. {count} منهم بصور رسمية.
      </p>
      <button
        onClick={() => setOnlyPhotos((v) => !v)}
        className={`rounded-full border px-3 py-1.5 text-[11px] font-bold transition-colors ${
          onlyPhotos
            ? "border-primary bg-primary/15 text-primary"
            : "border-border/70 text-muted-foreground"
        }`}
      >
        عرض أصحاب الصور فقط
      </button>
      <ul className="space-y-2">
        {list.map((c, i) => (
          <li
            key={`${c.nameEn}-${c.from}-${i}`}
            className="flex items-center gap-3 rounded-2xl border border-border/70 bg-card p-3"
          >
            <Portrait src={c.photo} name={c.nameEn} />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-black">{c.name}</p>
              <p className="text-[11px] text-muted-foreground">
                {c.from} — {c.to || "حتى الآن"}
              </p>
            </div>
            <div className="text-left">
              <p className="text-sm font-black text-primary">{c.matches}</p>
              <p className="text-[10px] text-muted-foreground">مباراة</p>
              {c.ppm !== "-" && (
                <p className="text-[10px] font-bold text-accent">{c.ppm} ن/م</p>
              )}
            </div>
          </li>
        ))}
      </ul>
    </>
  );
}

function Presidents() {
  return (
    <>
      <SectionHeading icon={<Crown className="size-4" />} title="تسلسل رؤساء النادي" />
      <p className="text-[11px] text-muted-foreground">
        من أحمد حسني 1920 إلى كامل أبو علي — {PRESIDENTS.length} فترة رئاسة موثّقة من ويكيبيديا
        والموقع الرسمي للنادي.
      </p>
      <ol className="space-y-2">
        {PRESIDENTS.map((p, i) => (
          <li
            key={`${p.name}-${p.from}`}
            className="flex items-start gap-3 rounded-2xl border border-border/70 bg-card p-3"
          >
            <span className="mt-0.5 flex size-7 shrink-0 items-center justify-center rounded-full bg-secondary text-[11px] font-black text-muted-foreground">
              {i + 1}
            </span>
            <Portrait src={PRESIDENT_PHOTOS[p.name] ?? null} name={p.name} className="size-11" />
            <div className="min-w-0 flex-1">
              <p className="text-sm font-black">{p.name}</p>
              <p className="text-[11px] text-muted-foreground">
                {p.from} — {p.to}
              </p>
              {p.note && <p className="mt-1 text-[11px] leading-relaxed text-primary">{p.note}</p>}
            </div>
          </li>
        ))}
      </ol>
      <p className="text-[10px] text-muted-foreground">
        ملاحظة: الصور المتوفرة من أرشيف النادي لبعض الرؤساء فقط، وباقي الأسماء تُعرض بأحرف الاسم حتى
        تتوفر صورة موثّقة.
      </p>
    </>
  );
}

function TopScorers() {
  return (
    <>
      <SectionHeading icon={<Target className="size-4" />} title="أفضل 10 هدافين في التاريخ" />
      <p className="text-[11px] text-muted-foreground">
        الأكثر تهديفًا للنادي المصري في بطولة الدوري — المصدر ويكيبيديا، آخر تحديث 30 مايو 2019.
      </p>
      <ol className="space-y-2">
        {TOP_SCORERS.map((s) => (
          <li
            key={s.rank}
            className={`flex items-center gap-3 rounded-2xl border bg-card p-3 ${
              s.rank <= 3 ? "border-accent/40" : "border-border/70"
            }`}
          >
            <span
              className={`flex size-7 shrink-0 items-center justify-center rounded-full text-[11px] font-black ${
                s.rank <= 3 ? "bg-accent/20 text-accent" : "bg-secondary text-muted-foreground"
              }`}
            >
              {s.rank}
            </span>
            <Portrait src={s.photo} name={s.name} className="size-12" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-black">{s.name}</p>
              <p className="text-[11px] text-muted-foreground">هداف تاريخي في الدوري</p>
            </div>
            <div className="text-left">
              <p className="text-base font-black text-primary">{s.goals}</p>
              <p className="text-[10px] text-muted-foreground">هدف</p>
            </div>
          </li>
        ))}
      </ol>
    </>
  );
}

function Legends() {
  return (
    <>
      <SectionHeading icon={<Star className="size-4" />} title="أساطير النسور الخضراء" />
      <p className="text-[11px] text-muted-foreground">
        أسماء صنعت وجدان جمهور بورسعيد وحفرت اسمها في تاريخ النادي المصري.
      </p>
      <div className="grid gap-2">
        {LEGENDS.map((l) => (
          <article
            key={l.name}
            className="flex items-start gap-3 rounded-2xl border border-border/70 bg-card p-4"
          >
            <Portrait src={l.photo} name={l.name} className="size-16" />
            <div className="min-w-0 flex-1">
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-sm font-black">{l.name}</h3>
                <Badge variant="outline" className="border-primary/40 text-[10px] font-bold text-primary">
                  {l.role}
                </Badge>
              </div>
              {l.era && <p className="text-[11px] text-muted-foreground">{l.era}</p>}
              <p className="mt-1 text-[12px] leading-relaxed text-muted-foreground">{l.note}</p>
            </div>
          </article>
        ))}
      </div>
    </>
  );
}

function MostApps() {
  return (
    <>
      <SectionHeading icon={<Users className="size-4" />} title="الأكثر مشاركة في تاريخ النادي" />
      <p className="text-[11px] text-muted-foreground">
        ترتيب اللاعبين حسب عدد المباريات مع المصري وفق Transfermarkt (منذ بدء تسجيل الإحصاءات).
      </p>
      <ul className="space-y-2">
        {RECORD_PLAYERS.map((p) => (
          <li
            key={p.rank + p.nameEn}
            className="flex items-center gap-3 rounded-2xl border border-border/70 bg-card p-3"
          >
            <span className="w-5 text-center text-sm font-black text-muted-foreground">{p.rank}</span>
            <Portrait src={p.photo} name={p.nameEn} className="size-12" />
            <div className="min-w-0 flex-1">
              <p className="truncate text-sm font-black">{p.name}</p>
              <p className="text-[11px] text-muted-foreground">
                {p.goals} هدف · {p.assists} صناعة
              </p>
            </div>
            <div className="text-left">
              <p className="text-base font-black text-primary">{p.apps}</p>
              <p className="text-[10px] text-muted-foreground">مباراة</p>
            </div>
          </li>
        ))}
      </ul>
    </>
  );
}


function Identity() {
  return (
    <>
      <SectionHeading icon={<Building2 className="size-4" />} title="الهوية والمنشآت" />
      <div className="grid gap-2">
        {IDENTITY.map((c) => (
          <article key={c.title} className="rounded-2xl border border-border/70 bg-card p-4">
            <h3 className="text-sm font-black text-primary">{c.title}</h3>
            <p className="mt-1.5 text-[13px] leading-relaxed text-muted-foreground">{c.body}</p>
          </article>
        ))}
      </div>
      <figure className="overflow-hidden rounded-2xl border border-border/70">
        <img
          src="https://upload.wikimedia.org/wikipedia/commons/9/94/Port_said_egypt_%286%29.JPG"
          alt="مدينة بورسعيد"
          loading="lazy"
          className="h-44 w-full object-cover"
        />
        <figcaption className="bg-card px-3 py-2 text-[10px] text-muted-foreground">
          بورسعيد — مدينة النادي وجمهوره · ويكيميديا كومنز
        </figcaption>
      </figure>
    </>
  );
}

function Sources() {
  return (
    <section className="rounded-2xl border border-border/70 bg-card p-4">
      <h2 className="flex items-center gap-2 text-sm font-black">
        <Landmark className="size-4 text-primary" />
        المصادر
      </h2>
      <ul className="mt-2 space-y-1.5">
        {SOURCES.map((s) => (
          <li key={s.url}>
            <a
              href={s.url}
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1.5 text-[12px] text-muted-foreground hover:text-primary"
            >
              <ExternalLink className="size-3.5" />
              {s.label}
            </a>
          </li>
        ))}
      </ul>
    </section>
  );
}
