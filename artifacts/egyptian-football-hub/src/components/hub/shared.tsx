import { Link } from "@tanstack/react-router";
import { CalendarDays, MapPin, Radio, RefreshCw, Shield, Trophy } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import type { Match, Source } from "@/lib/hub-types";
import { MASRY_ID } from "@/lib/hub-types";
import { formatKickoff, formatTime12 } from "@/lib/time";

const imageProxyHosts = [
  "filgoal.com",
  "yallakora.com",
  "elwatannews.com",
  "youm7.com",
  "masrawy.com",
  "kooora.com",
  "kingfut.com",
  "cairo24.com",
  "btolat.com",
  "almasryalyoum.com",
  "wataninet.com",
  "akhbarelyom.com",
  "elbalad.news",
  "sadaelbalad.com",
  "shbabbek.com",
  "newturkpost.com",
  "elghad.news",
];

export function proxiedImageUrl(url: string | null | undefined) {
  if (!url) return null;
  try {
    const parsed = new URL(url);
    const host = parsed.hostname.toLowerCase();
    const allowed = imageProxyHosts.some(
      (item) => host === item || host.endsWith(`.${item}`),
    );
    return parsed.protocol === "https:" && allowed
      ? `/api/football/image?url=${encodeURIComponent(url)}`
      : url;
  } catch {
    return url;
  }
}

export function SourceNote({ source }: { source?: Source | undefined }) {
  if (!source) return null;
  return (
    <p className="flex items-center gap-1.5 text-[11px] text-muted-foreground">
      {source.status === "live" ? (
        <Radio className="size-3.5 text-primary" />
      ) : (
        <RefreshCw className="size-3.5" />
      )}
      المصدر: {source.name} · آخر مزامنة {formatTime12(new Date(source.fetchedAt))}
      {source.status === "cached" && " (نسخة محفوظة)"}

    </p>
  );
}

export function TeamMark({
  name,
  crestUrl,
  size = "md",
}: {
  name: string;
  crestUrl: string | null;
  size?: "sm" | "md" | "lg";
}) {
  const crest = size === "lg" ? "size-16" : size === "sm" ? "size-8" : "size-11";
  const text = size === "lg" ? "text-sm" : "text-xs";
  return (
    <span className="flex min-w-0 flex-col items-center gap-2">
      {crestUrl ? (
        <img
          src={crestUrl}
          alt={name}
          className={`${crest} shrink-0 object-contain drop-shadow-[0_4px_14px_rgba(0,0,0,0.45)]`}
          loading="lazy"
        />
      ) : (
        <Shield className={`${crest} text-muted-foreground`} />
      )}
      <span className={`${text} text-center font-bold leading-tight`}>{name}</span>
    </span>
  );
}

export function StatusBadge({ match }: { match: Pick<Match, "status" | "statusText"> }) {
  if (match.status === "live")
    return (
      <Badge className="gap-1.5 border-0 bg-live/15 text-live">
        <span className="size-1.5 animate-pulse rounded-full bg-live" />
        مباشر
      </Badge>
    );
  if (match.status === "finished")
    return <Badge variant="secondary" className="border-0">انتهت</Badge>;
  if (match.status === "postponed")
    return <Badge variant="outline">مؤجلة</Badge>;
  return <Badge className="border-primary/30 bg-primary/15 text-primary">قادمة</Badge>;
}

export function MatchCard({ match }: { match: Match }) {
  const played = match.homeScore != null && match.awayScore != null;
  const masryHome = match.homeTeam.id === MASRY_ID;
  const masryScore = masryHome ? match.homeScore : match.awayScore;
  const rivalScore = masryHome ? match.awayScore : match.homeScore;
  const result =
    played && masryScore != null && rivalScore != null
      ? masryScore > rivalScore
        ? "فوز"
        : masryScore < rivalScore
          ? "خسارة"
          : "تعادل"
      : null;

  return (
    <Link
      to="/matches/$matchId"
      params={{ matchId: String(match.matchId) }}
      className="group block rounded-2xl border border-border/70 bg-card card-sheen p-4 transition-all hover:border-primary/40 hover:bg-accent/40"
    >
      <div className="flex items-center justify-between gap-2 text-[11px] text-muted-foreground">
        <span className="flex min-w-0 items-center gap-1.5">
          <Trophy className="size-3.5 shrink-0 text-gold" />
          <span className="truncate">{match.competition}</span>
        </span>
        <StatusBadge match={match} />
      </div>

      <div className="mt-4 grid grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] items-center gap-3">
        <TeamMark {...match.homeTeam} />
        <div className="text-center">
          {played ? (
            <p className="text-3xl font-black tabular-nums tracking-tighter">
              {match.homeScore}
              <span className="mx-1 text-muted-foreground">-</span>
              {match.awayScore}
            </p>
          ) : (
            <p className="text-base font-extrabold text-muted-foreground">VS</p>
          )}
          <p className="mt-1 text-[10px] font-semibold text-muted-foreground">
            {result ?? match.statusText}
          </p>
        </div>
        <TeamMark {...match.awayTeam} />
      </div>

      <div className="mt-4 flex flex-wrap items-center justify-center gap-x-4 gap-y-1 text-[11px] text-muted-foreground">
        {formatKickoff(match.kickoff, match.kickoffText) && (
          <span className="flex items-center gap-1">
            <CalendarDays className="size-3.5" />
            {formatKickoff(match.kickoff, match.kickoffText)}
          </span>
        )}

        {match.venue && (
          <span className="flex min-w-0 items-center gap-1">
            <MapPin className="size-3.5 shrink-0" />
            <span className="truncate">{match.venue}</span>
          </span>
        )}
      </div>
    </Link>
  );
}

export function SectionSkeleton({ cards = 4 }: { cards?: number }) {
  return (
    <div className="grid gap-3 sm:grid-cols-2">
      {Array.from({ length: cards }).map((_, i) => (
        <Skeleton key={i} className="h-32 w-full rounded-2xl" />
      ))}
    </div>
  );
}

export function SectionHeading({
  icon,
  title,
  action,
}: {
  icon: React.ReactNode;
  title: string;
  action?: React.ReactNode;
}) {
  return (
    <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-3">
      <h2 className="flex min-w-0 items-center gap-2 text-lg font-black tracking-tight">
        <span className="flex size-8 shrink-0 items-center justify-center rounded-xl bg-primary/15 text-primary">
          {icon}
        </span>
        <span className="truncate">{title}</span>
      </h2>
      {action}
    </div>
  );
}

export function ErrorNote({ children }: { children: React.ReactNode }) {
  return (
    <p className="rounded-2xl border border-border/70 bg-card p-4 text-sm text-muted-foreground">
      {children}
    </p>
  );
}
