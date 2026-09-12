import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { Goal, Shirt, Users } from "lucide-react";

import { getSquad } from "@/lib/hub.functions";
import { ErrorNote, SectionHeading, SectionSkeleton, SourceNote } from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";
import type { SquadPlayer } from "@/lib/hub-types";

export const Route = createFileRoute("/squad")({
  head: () => ({
    meta: [
      { title: "قائمة لاعبي المصري البورسعيدي | الفريق والجهاز الفني" },
      {
        name: "description",
        content:
          "قائمة لاعبي النادي المصري البورسعيدي بالمراكز وأرقام القمصان والجنسيات، مع الهدافين والمدير الفني.",
      },
      { property: "og:title", content: "قائمة لاعبي المصري البورسعيدي" },
      {
        property: "og:description",
        content: "لاعبو المصري بالمراكز والأرقام والهدافين والجهاز الفني.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: SquadPage,
});

const GROUPS: { title: string; test: RegExp }[] = [
  { title: "حراس المرمى", test: /حارس/ },
  { title: "الدفاع", test: /ظهير|قلب دفاع|مدافع/ },
  { title: "الوسط", test: /وسط/ },
  { title: "الهجوم", test: /مهاجم|جناح|رأس حربة/ },
];

function PlayerCard({ player }: { player: SquadPlayer }) {
  return (
    <Link
      to="/players/$playerId"
      params={{ playerId: String(player.id) }}
      className="group relative overflow-hidden rounded-2xl border border-border/70 bg-card card-sheen p-3 text-center transition-all hover:border-primary/40 hover:bg-accent/40"
    >
      {player.number != null && (
        <span className="absolute start-2 top-2 text-lg font-black tabular-nums text-muted-foreground/30">
          {player.number}
        </span>
      )}
      {player.photoUrl ? (
        <img
          src={player.photoUrl}
          alt={player.name}
          className="mx-auto size-16 rounded-full border border-border object-cover"
          loading="lazy"
        />
      ) : (
        <span className="mx-auto flex size-16 items-center justify-center rounded-full border bg-secondary">
          <Shirt className="size-6 text-muted-foreground" />
        </span>
      )}
      <p className="mt-2 text-sm font-bold leading-tight group-hover:text-primary">
        {player.name}
      </p>
      <p className="mt-0.5 text-[11px] text-muted-foreground">{player.position}</p>
      {(player.goals ?? 0) > 0 && (
        <Badge variant="outline" className="mt-1.5 text-[10px]">
          {player.goals} هدف
        </Badge>
      )}
    </Link>
  );
}

function SquadPage() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["squad"],
    queryFn: () => getSquad(),
  });

  if (isLoading) return <SectionSkeleton cards={6} />;
  if (isError || !data) return <ErrorNote>تعذر تحميل قائمة اللاعبين الآن.</ErrorNote>;

  const topScorers = data.players
    .filter((p) => (p.goals ?? 0) > 0)
    .sort((a, b) => (b.goals ?? 0) - (a.goals ?? 0))
    .slice(0, 5);

  const grouped = GROUPS.map((g) => ({
    title: g.title,
    players: data.players.filter((p) => g.test.test(p.position)),
  })).filter((g) => g.players.length > 0);
  const others = data.players.filter((p) => !GROUPS.some((g) => g.test.test(p.position)));

  return (
    <div className="space-y-6">
      <SectionHeading icon={<Users className="size-4" />} title="الفريق" />

      {data.coach?.name && (
        <div className="flex items-center gap-4 rounded-2xl border border-border/70 bg-card card-sheen p-4">
          {data.coach.photoUrl ? (
            <img
              src={data.coach.photoUrl}
              alt={data.coach.name}
              className="size-16 shrink-0 rounded-full border-2 border-gold object-cover"
              loading="lazy"
            />
          ) : (
            <Users className="size-10 shrink-0 text-muted-foreground" />
          )}
          <div className="min-w-0">
            <p className="text-[11px] text-muted-foreground">{data.coach.role}</p>
            <p className="truncate text-lg font-black">{data.coach.name}</p>
          </div>
        </div>
      )}

      {topScorers.length > 0 && (
        <div className="rounded-2xl border border-border/70 bg-card p-4">
          <h3 className="flex items-center gap-2 text-sm font-black">
            <Goal className="size-4 text-gold" /> الهدافون
          </h3>
          <ul className="mt-3 space-y-1">
            {topScorers.map((p, i) => (
              <li key={p.id}>
                <Link
                  to="/players/$playerId"
                  params={{ playerId: String(p.id) }}
                  className="flex items-center justify-between gap-2 rounded-xl px-1 py-1.5 text-sm transition-colors hover:bg-accent/50"
                >
                  <span className="flex min-w-0 items-center gap-2">
                    <span className="w-4 text-center font-black tabular-nums text-gold">
                      {i + 1}
                    </span>
                    {p.photoUrl && (
                      <img
                        src={p.photoUrl}
                        alt={p.name}
                        className="size-8 shrink-0 rounded-full object-cover"
                        loading="lazy"
                      />
                    )}
                    <span className="truncate font-bold">{p.name}</span>
                  </span>
                  <span className="shrink-0 text-[11px] tabular-nums text-muted-foreground">
                    {p.goals} هدف · {p.appearances ?? "—"} مباراة
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        </div>
      )}

      {[...grouped, ...(others.length > 0 ? [{ title: "لاعبون آخرون", players: others }] : [])].map(
        (group) => (
          <section key={group.title} className="space-y-3">
            <h3 className="text-sm font-black text-muted-foreground">{group.title}</h3>
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">
              {group.players.map((p) => (
                <PlayerCard key={p.id} player={p} />
              ))}
            </div>
          </section>
        ),
      )}

      <SourceNote source={data.source} />
    </div>
  );
}
