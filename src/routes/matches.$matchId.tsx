import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import {
  ArrowRight,
  BarChart3,
  Flag,
  Goal,
  MapPin,
  MessageSquareText,
  Shirt,
  Trophy,
  Tv,
} from "lucide-react";

import { getMatchDetail } from "@/lib/hub.functions";
import { LineupPitch } from "@/components/lineup-pitch";
import {
  ErrorNote,
  SectionSkeleton,
  SourceNote,
  StatusBadge,
  TeamMark,
} from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";

export const Route = createFileRoute("/matches/$matchId")({
  head: () => ({
    meta: [
      { title: "تفاصيل المباراة | المصري بورسعيد" },
      {
        name: "description",
        content:
          "أحداث المباراة دقيقة بدقيقة، إحصائيات الاستحواذ والتسديدات، التشكيل الأساسي والبدلاء، والتعليق الحي لمباريات المصري البورسعيدي.",
      },
      { property: "og:title", content: "تفاصيل المباراة | المصري بورسعيد" },
      {
        property: "og:description",
        content: "الأحداث والإحصائيات والتشكيل والتعليق الحي للمباراة.",
      },
      { property: "og:type", content: "article" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: MatchDetailPage,
});

const EVENT_LABEL: Record<string, string> = {
  goal: "هدف",
  "own-goal": "هدف عكسي",
  penalty: "ضربة جزاء",
  "missed-penalty": "ضربة جزاء ضائعة",
  "yellow-card": "بطاقة صفراء",
  "red-card": "بطاقة حمراء",
  substitution: "تبديل",
};

const EVENT_TONE = (type: string) =>
  /goal|penalty/.test(type) && !/missed/.test(type)
    ? "border-primary/40 bg-primary/10 text-primary"
    : /red-card/.test(type)
      ? "border-live/40 bg-live/10 text-live"
      : /yellow/.test(type)
        ? "border-gold/40 bg-gold/10 text-gold"
        : "border-border/70 bg-secondary/50 text-muted-foreground";

function StatBar({
  label,
  home,
  away,
  unit,
}: {
  label: string;
  home: number;
  away: number;
  unit: "percent" | "count";
}) {
  const total = home + away || 1;
  const homePct = unit === "percent" ? home : Math.round((home / total) * 100);
  const suffix = unit === "percent" ? "%" : "";
  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between text-xs font-bold tabular-nums">
        <span>
          {home}
          {suffix}
        </span>
        <span className="text-muted-foreground">{label}</span>
        <span>
          {away}
          {suffix}
        </span>
      </div>
      <div className="flex h-2 overflow-hidden rounded-full bg-secondary">
        <span className="bg-primary" style={{ width: `${homePct}%` }} />
        <span className="flex-1 bg-gold/70" />
      </div>
    </div>
  );
}

function MatchDetailPage() {
  const { matchId } = Route.useParams();
  const id = Number(matchId);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["match-detail", id],
    queryFn: () => getMatchDetail({ data: { matchId: id } }),
    enabled: Number.isFinite(id),
    refetchInterval: (query) => (query.state.data?.match.status === "live" ? 20_000 : false),
  });

  if (isLoading) return <SectionSkeleton cards={3} />;
  if (isError || !data?.match)
    return (
      <div className="space-y-3">
        <ErrorNote>تعذر تحميل تفاصيل هذه المباراة الآن، حاول لاحقًا.</ErrorNote>
        <Link to="/matches" className="text-sm font-bold text-primary">
          العودة لكل المباريات
        </Link>
      </div>
    );

  const m = data.match;
  const played = m.homeScore != null && m.awayScore != null;
  const hasLineups = m.lineups.home.length > 0 || m.lineups.away.length > 0;
  const hasStats = m.stats.possession != null || m.stats.rows.length > 0;

  return (
    <div className="space-y-4">
      <Link
        to="/matches"
        className="inline-flex items-center gap-1.5 text-xs font-bold text-muted-foreground transition-colors hover:text-primary"
      >
        <ArrowRight className="size-4" />
        كل المباريات
      </Link>

      <div className="rounded-2xl border border-border/70 bg-card card-sheen p-4">
        <div className="flex items-center justify-between gap-2 text-[11px] text-muted-foreground">
          <span className="flex min-w-0 items-center gap-1.5">
            <Trophy className="size-3.5 shrink-0 text-gold" />
            <span className="truncate">
              {m.competition}
              {m.round ? ` · ${m.round}` : ""}
            </span>
          </span>
          <StatusBadge match={m} />
        </div>

        <div className="mt-4 grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3">
          <TeamMark {...m.homeTeam} size="lg" />
          <div className="text-center">
            <p className="text-4xl font-black tabular-nums tracking-tighter">
              {played ? `${m.homeScore} - ${m.awayScore}` : "VS"}
            </p>
            <p className="mt-1 text-[11px] font-semibold text-muted-foreground">
              {m.statusText}
            </p>
          </div>
          <TeamMark {...m.awayTeam} size="lg" />
        </div>

        <div className="mt-4 flex flex-wrap justify-center gap-x-4 gap-y-1 text-[11px] text-muted-foreground">
          {m.stadium && (
            <span className="flex items-center gap-1">
              <MapPin className="size-3.5" /> {m.stadium}
            </span>
          )}
          {m.referee && (
            <span className="flex items-center gap-1">
              <Flag className="size-3.5" /> الحكم: {m.referee}
            </span>
          )}
          {m.tvChannels.length > 0 && (
            <span className="flex items-center gap-1">
              <Tv className="size-3.5" /> {m.tvChannels.join("، ")}
            </span>
          )}
        </div>
      </div>

      <Tabs defaultValue={m.events.length > 0 ? "events" : hasLineups ? "lineups" : "stats"} dir="rtl">
        <TabsList className="grid w-full grid-cols-4 rounded-2xl">
          <TabsTrigger value="events" className="rounded-xl text-xs">
            الأحداث
          </TabsTrigger>
          <TabsTrigger value="stats" className="rounded-xl text-xs">
            الإحصائيات
          </TabsTrigger>
          <TabsTrigger value="lineups" className="rounded-xl text-xs">
            التشكيل
          </TabsTrigger>
          <TabsTrigger value="commentary" className="rounded-xl text-xs">
            التعليق
          </TabsTrigger>
        </TabsList>

        <TabsContent value="events" className="mt-4 space-y-2">
          {m.events.length === 0 && <ErrorNote>لا توجد أحداث مسجلة لهذه المباراة بعد.</ErrorNote>}
          {m.events.map((e) => (
            <div
              key={e.id}
              className="flex items-center justify-between gap-3 rounded-2xl border border-border/70 bg-card px-3 py-2.5"
            >
              <span className="flex min-w-0 items-center gap-2">
                <Badge variant="outline" className={`shrink-0 text-[10px] ${EVENT_TONE(e.type)}`}>
                  {EVENT_LABEL[e.type] ?? e.type}
                </Badge>
                <span className="min-w-0">
                  <span className="block truncate text-sm font-bold">{e.player ?? "—"}</span>
                  {(e.relatedPlayer || e.teamName) && (
                    <span className="block truncate text-[11px] text-muted-foreground">
                      {e.relatedPlayer ? `${e.relatedPlayer} · ` : ""}
                      {e.teamName ?? ""}
                    </span>
                  )}
                </span>
              </span>
              <span className="shrink-0 text-xs font-black tabular-nums text-muted-foreground">
                {e.minute != null ? `${e.minute}${e.addedTime ? `+${e.addedTime}` : ""}’` : ""}
              </span>
            </div>
          ))}
        </TabsContent>

        <TabsContent value="stats" className="mt-4">
          {!hasStats && <ErrorNote>الإحصائيات غير متاحة لهذه المباراة.</ErrorNote>}
          {hasStats && (
            <div className="space-y-4 rounded-2xl border border-border/70 bg-card p-4">
              <div className="flex items-center gap-2 text-sm font-black">
                <BarChart3 className="size-4 text-primary" /> إحصائيات المباراة
              </div>
              {m.stats.possession && (
                <StatBar
                  label="الاستحواذ"
                  home={m.stats.possession.home}
                  away={m.stats.possession.away}
                  unit="percent"
                />
              )}
              {m.stats.rows.map((r) => (
                <StatBar key={r.key} label={r.label} home={r.home} away={r.away} unit={r.unit} />
              ))}
              <p className="text-[11px] text-muted-foreground">
                إحصائيات مستنتجة من أحداث المباراة والتعليق الحي.
              </p>
            </div>
          )}
        </TabsContent>

        <TabsContent value="lineups" className="mt-4">
          {!hasLineups && <ErrorNote>لم تُعلن التشكيلة بعد.</ErrorNote>}
          {hasLineups && (
            <div className="grid gap-3 sm:grid-cols-2">
              <LineupPitch
                teamName={m.homeTeam.name}
                crestUrl={m.homeTeam.crestUrl}
                formation={m.homeFormation}
                coach={m.homeCoach}
                players={m.lineups.home}
                bench={m.lineups.homeBench}
              />
              <LineupPitch
                teamName={m.awayTeam.name}
                crestUrl={m.awayTeam.crestUrl}
                formation={m.awayFormation}
                coach={m.awayCoach}
                players={m.lineups.away}
                bench={m.lineups.awayBench}
              />
            </div>
          )}
        </TabsContent>

        <TabsContent value="commentary" className="mt-4 space-y-2">
          {m.commentary.length === 0 && <ErrorNote>لا يوجد تعليق متاح لهذه المباراة.</ErrorNote>}
          {m.commentary.map((c) => (
            <div
              key={c.id}
              className="flex gap-3 rounded-2xl border border-border/70 bg-card px-3 py-2.5 text-sm"
            >
              <span className="shrink-0 rounded-lg bg-secondary px-1.5 py-0.5 text-[11px] font-black tabular-nums text-muted-foreground">
                {c.minute != null ? `${c.minute}’` : "—"}
              </span>
              <p className="leading-relaxed">{c.text}</p>
            </div>
          ))}
        </TabsContent>
      </Tabs>

      <div className="flex flex-wrap items-center justify-between gap-2">
        <SourceNote source={data.source} />
        <span className="flex items-center gap-3 text-[11px] text-muted-foreground">
          <span className="flex items-center gap-1">
            <Goal className="size-3.5" /> {m.events.length} حدث
          </span>
          <span className="flex items-center gap-1">
            <Shirt className="size-3.5" /> {m.lineups.home.length + m.lineups.away.length} لاعب
          </span>
          <span className="flex items-center gap-1">
            <MessageSquareText className="size-3.5" /> {m.commentary.length} تعليق
          </span>
        </span>
      </div>
    </div>
  );
}
