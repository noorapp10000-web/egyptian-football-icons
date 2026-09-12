import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { ListOrdered, Shield } from "lucide-react";

import { getStandings } from "@/lib/hub.functions";
import { useScheduledRefresh } from "@/lib/scheduled-refresh";

// تحديث تلقائي ٤ مرات يوميًا بتوقيت القاهرة: ٨م، ١٠م، ١٢م، ٣م
const STANDINGS_REFRESH_HOURS = [20, 22, 0, 3];
import { ErrorNote, SectionHeading, SectionSkeleton, SourceNote } from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";

export const Route = createFileRoute("/table")({
  head: () => ({
    meta: [
      { title: "جدول ترتيب الدوري المصري | ترتيب المصري البورسعيدي" },
      {
        name: "description",
        content:
          "جدول ترتيب الدوري المصري الممتاز: النقاط والمباريات والأهداف لكل فريق مع تمييز مركز النادي المصري البورسعيدي.",
      },
      { property: "og:title", content: "جدول ترتيب الدوري المصري" },
      {
        property: "og:description",
        content: "ترتيب فرق الدوري المصري ونقاط المصري البورسعيدي محدثة تلقائيًا.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: TablePage,
});

function TablePage() {
  useScheduledRefresh(["standings"], STANDINGS_REFRESH_HOURS);

  const { data, isLoading, isError } = useQuery({
    queryKey: ["standings"],
    queryFn: () => getStandings(),
  });

  if (isLoading) return <SectionSkeleton cards={4} />;
  if (isError || !data) return <ErrorNote>تعذر تحميل جدول الترتيب الآن.</ErrorNote>;

  return (
    <div className="space-y-4">
      <SectionHeading icon={<ListOrdered className="size-4" />} title="جدول الدوري" />

      <div className="overflow-hidden rounded-2xl border border-border/70 bg-card">
        <div className="grid grid-cols-[2rem_minmax(0,1fr)_2rem_2rem_2.6rem_2.4rem] items-center gap-2 border-b border-border/70 bg-secondary/50 px-3 py-2.5 text-[10px] font-bold text-muted-foreground">
          <span>#</span>
          <span>الفريق</span>
          <span className="text-center">لعب</span>
          <span className="text-center">فرق</span>
          <span className="text-center">له/عليه</span>
          <span className="text-center">نقاط</span>
        </div>
        <ul>
          {data.standings.map((row) => (
            <li
              key={row.rank}
              className={`grid grid-cols-[2rem_minmax(0,1fr)_2rem_2rem_2.6rem_2.4rem] items-center gap-2 border-b border-border/50 px-3 py-2.5 text-xs last:border-0 ${
                row.isMasry ? "bg-primary/10 font-black" : ""
              }`}
            >
              <span
                className={`flex size-6 items-center justify-center rounded-lg text-[11px] font-bold tabular-nums ${
                  row.rank <= 3
                    ? "bg-gold/20 text-gold"
                    : row.rank >= data.standings.length - 2
                      ? "bg-destructive/15 text-destructive"
                      : "bg-secondary text-muted-foreground"
                }`}
              >
                {row.rank}
              </span>
              <span className="flex min-w-0 items-center gap-2">
                {row.team.crestUrl ? (
                  <img
                    src={row.team.crestUrl}
                    alt={row.team.name}
                    className="size-6 shrink-0 object-contain"
                    loading="lazy"
                  />
                ) : (
                  <Shield className="size-4 shrink-0 text-muted-foreground" />
                )}
                <span className="truncate">{row.team.name}</span>
                {row.isMasry && (
                  <Badge className="shrink-0 bg-primary text-[9px] text-primary-foreground">
                    فريقنا
                  </Badge>
                )}
              </span>
              <span className="text-center tabular-nums">{row.played}</span>
              <span className="text-center tabular-nums text-muted-foreground">
                {row.goalsFor - row.goalsAgainst > 0 ? "+" : ""}
                {row.goalsFor - row.goalsAgainst}
              </span>
              <span className="text-center tabular-nums text-muted-foreground">
                {row.goalsFor}/{row.goalsAgainst}
              </span>
              <span className="text-center font-black tabular-nums text-primary">
                {row.points}
              </span>
            </li>
          ))}
        </ul>
      </div>

      <p className="text-[11px] text-muted-foreground">
        فاز {""}
        {data.standings.find((r) => r.isMasry)?.won ?? 0} · تعادل{" "}
        {data.standings.find((r) => r.isMasry)?.drawn ?? 0} · خسر{" "}
        {data.standings.find((r) => r.isMasry)?.lost ?? 0}
      </p>
      <SourceNote source={data.source} />
    </div>
  );
}
