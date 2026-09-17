import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import {
  CalendarDays,
  ExternalLink,
  Goal,
  ListOrdered,
  MapPin,
  Newspaper,
  Trophy,
} from "lucide-react";

import { getMatches, getNews, getSquad, getStandings } from "@/lib/hub.functions";
import {
  ErrorNote,
  MatchCard,
  SectionHeading,
  SectionSkeleton,
  SourceNote,
  StatusBadge,
  TeamMark,
} from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { TEAM_CREST } from "@/lib/hub-types";
import { useScheduledRefresh } from "@/lib/scheduled-refresh";
import { RefreshButton } from "@/components/hub/refresh-button";

export const Route = createFileRoute("/_authenticated/")({
  head: () => ({
    meta: [
      { title: "المصري بورسعيد | مباريات وأخبار وترتيب لحظة بلحظة" },
      {
        name: "description",
        content:
          "مركز النادي المصري البورسعيدي: المباراة القادمة وآخر النتائج، جدول ترتيب الدوري، الهدافون وقائمة الفريق، وآخر الأخبار لحظة بلحظة.",
      },
      { property: "og:title", content: "المصري بورسعيد | Egyptian Football Hub" },
      {
        property: "og:description",
        content: "نتائج ومباريات المصري، ترتيب الدوري، اللاعبون والأخبار — بيانات حية.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: HomePage,
});

function Hero() {
  const { data, isLoading } = useQuery({
    queryKey: ["matches"],
    queryFn: () => getMatches(),
    refetchInterval: (query) =>
      query.state.data?.matches.some((m) => m.status === "live") ? 20_000 : false,
  });

  const next = data?.matches.find((m) => m.status === "live" || m.status === "upcoming");

  return (
    <section className="relative overflow-hidden rounded-3xl border border-border/70 bg-gradient-to-b from-primary/20 via-card to-card p-5">
      <div className="pointer-events-none absolute -top-16 -start-10 size-48 rounded-full bg-primary/20 blur-3xl" />
      <div className="relative flex items-center gap-3">
        <img src={TEAM_CREST} alt="شعار النادي المصري" className="size-14 object-contain" />
        <div className="min-w-0 flex-1">
          <h1 className="text-xl font-black leading-tight">النادي المصري البورسعيدي</h1>
          <p className="text-[11px] text-muted-foreground">مباريات · ترتيب · لاعبون · أخبار</p>
        </div>
        <RefreshButton
          queryKeys={[["matches"], ["standings"], ["squad"], ["news"]]}
          label="تحديث الكل"
        />
      </div>

      <div className="relative mt-5">
        {isLoading && <Skeleton className="h-28 w-full rounded-2xl" />}
        {!isLoading && !next && (
          <p className="rounded-2xl bg-background/60 p-4 text-sm text-muted-foreground">
            لا توجد مباراة قادمة معلنة حاليًا.
          </p>
        )}
        {next && (
          <Link
            to="/matches/$matchId"
            params={{ matchId: String(next.matchId) }}
            className="block rounded-2xl bg-background/60 p-4 backdrop-blur-sm transition-colors hover:bg-background/80"
          >
            <div className="flex items-center justify-between gap-2 text-[11px] text-muted-foreground">
              <span className="flex min-w-0 items-center gap-1.5">
                <Trophy className="size-3.5 shrink-0 text-gold" />
                <span className="truncate">{next.competition}</span>
              </span>
              <StatusBadge match={next} />
            </div>
            <div className="mt-3 grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3">
              <TeamMark {...next.homeTeam} />
              <p className="text-2xl font-black tabular-nums">
                {next.homeScore != null ? `${next.homeScore} - ${next.awayScore}` : "VS"}
              </p>
              <TeamMark {...next.awayTeam} />
            </div>
            <div className="mt-3 flex flex-wrap justify-center gap-x-4 gap-y-1 text-[11px] text-muted-foreground">
              {next.kickoffText && (
                <span className="flex items-center gap-1">
                  <CalendarDays className="size-3.5" />
                  {next.kickoffText}
                </span>
              )}
              {next.venue && (
                <span className="flex min-w-0 items-center gap-1">
                  <MapPin className="size-3.5 shrink-0" />
                  <span className="truncate">{next.venue}</span>
                </span>
              )}
            </div>
          </Link>
        )}
      </div>
      <SourceNote source={data?.source} />
    </section>
  );
}

function LatestResults() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["matches"],
    queryFn: () => getMatches(),
  });

  if (isLoading) return <SectionSkeleton cards={2} />;
  if (isError || !data) return <ErrorNote>تعذر تحميل النتائج الآن.</ErrorNote>;

  const results = data.matches.filter((m) => m.status === "finished").slice(0, 4);
  if (results.length === 0) return null;

  return (
    <section className="space-y-3">
      <SectionHeading
        icon={<CalendarDays className="size-4" />}
        title="آخر النتائج"
        action={
          <Link to="/matches" className="text-xs font-bold text-primary">
            كل المباريات
          </Link>
        }
      />
      <div className="grid gap-3 sm:grid-cols-2">
        {results.map((m) => (
          <MatchCard key={m.id} match={m} />
        ))}
      </div>
    </section>
  );
}

function MiniTable() {
  useScheduledRefresh(["standings"], [20, 22, 0, 3]);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["standings"],
    queryFn: () => getStandings(),
  });

  if (isLoading) return <Skeleton className="h-56 w-full rounded-2xl" />;
  if (isError || !data || data.standings.length === 0) return null;

  const masryIndex = data.standings.findIndex((r) => r.isMasry);
  const start = Math.max(0, Math.min(masryIndex - 2, data.standings.length - 5));
  const rows = data.standings.slice(start, start + 5);

  return (
    <section className="space-y-3">
      <SectionHeading
        icon={<ListOrdered className="size-4" />}
        title="الترتيب"
        action={
          <Link to="/table" className="text-xs font-bold text-primary">
            الجدول كامل
          </Link>
        }
      />
      <div className="overflow-hidden rounded-2xl border border-border/70 bg-card">
        {rows.map((row) => (
          <div
            key={row.rank}
            className={`flex items-center gap-3 border-b border-border/60 px-3 py-2.5 last:border-0 ${
              row.isMasry ? "bg-primary/10 font-black" : ""
            }`}
          >
            <span className="w-5 text-xs tabular-nums text-muted-foreground">{row.rank}</span>
            {row.team.crestUrl && (
              <img src={row.team.crestUrl} alt="" className="size-6 object-contain" loading="lazy" />
            )}
            <span className="min-w-0 flex-1 truncate text-sm">{row.team.name}</span>
            <span className="text-[11px] tabular-nums text-muted-foreground">{row.played} لعب</span>
            <span className="w-8 text-center text-sm font-black tabular-nums text-primary">
              {row.points}
            </span>
          </div>
        ))}
      </div>
    </section>
  );
}

function TopScorers() {
  const { data, isLoading } = useQuery({ queryKey: ["squad"], queryFn: () => getSquad() });
  if (isLoading) return <Skeleton className="h-32 w-full rounded-2xl" />;
  if (!data) return null;

  const scorers = data.players
    .filter((p) => (p.goals ?? 0) > 0)
    .sort((a, b) => (b.goals ?? 0) - (a.goals ?? 0))
    .slice(0, 5);
  if (scorers.length === 0) return null;

  return (
    <section className="space-y-3">
      <SectionHeading
        icon={<Goal className="size-4" />}
        title="الهدافون"
        action={
          <Link to="/squad" className="text-xs font-bold text-primary">
            الفريق
          </Link>
        }
      />
      <div className="grid gap-2 sm:grid-cols-2">
        {scorers.map((p) => (
          <Link
            key={p.id}
            to="/players/$playerId"
            params={{ playerId: String(p.id) }}
            className="flex items-center gap-3 rounded-2xl border border-border/70 bg-card p-3 transition-colors hover:border-primary/40"
          >
            {p.photoUrl ? (
              <img src={p.photoUrl} alt="" className="size-10 rounded-full object-cover" loading="lazy" />
            ) : (
              <span className="size-10 rounded-full bg-secondary" />
            )}
            <span className="min-w-0 flex-1">
              <span className="block truncate text-sm font-bold">{p.name}</span>
              <span className="block text-[11px] text-muted-foreground">{p.position ?? "—"}</span>
            </span>
            <Badge className="border-0 bg-gold/15 font-black tabular-nums text-gold">
              {p.goals} ⚽
            </Badge>
          </Link>
        ))}
      </div>
    </section>
  );
}

function NewsPreview() {
  const { data, isLoading } = useQuery({ queryKey: ["news"], queryFn: () => getNews() });
  if (isLoading) return <Skeleton className="h-32 w-full rounded-2xl" />;
  if (!data || data.news.length === 0) return null;

  return (
    <section className="space-y-3">
      <SectionHeading
        icon={<Newspaper className="size-4" />}
        title="آخر الأخبار"
        action={
          <Link to="/news" className="text-xs font-bold text-primary">
            كل الأخبار
          </Link>
        }
      />
      <div className="grid gap-3 sm:grid-cols-2">
        {data.news.slice(0, 4).map((item) => (
          <a
            key={item.id}
            href={item.url}
            target="_blank"
            rel="noreferrer"
            className="group flex gap-3 rounded-2xl border border-border/70 bg-card p-3 transition-colors hover:border-primary/40"
          >
            {item.imageUrl && (
              <img
                src={item.imageUrl}
                alt=""
                className="size-16 shrink-0 rounded-xl object-cover"
                loading="lazy"
              />
            )}
            <span className="min-w-0">
              <span className="line-clamp-2 text-sm font-bold leading-snug group-hover:text-primary">
                {item.title}
              </span>
              <span className="mt-1 flex items-center gap-1.5 text-[11px] text-muted-foreground">
                {item.sourceName}
                <ExternalLink className="size-3" />
              </span>
            </span>
          </a>
        ))}
      </div>
    </section>
  );
}

function HomePage() {
  return (
    <div className="space-y-7">
      <Hero />
      <LatestResults />
      <MiniTable />
      <TopScorers />
      <NewsPreview />
    </div>
  );
}
