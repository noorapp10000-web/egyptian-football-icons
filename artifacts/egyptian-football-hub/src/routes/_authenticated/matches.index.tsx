import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { CalendarDays } from "lucide-react";

import { getMatches } from "@/lib/hub.functions";
import {
  ErrorNote,
  MatchCard,
  SectionHeading,
  SectionSkeleton,
  SourceNote,
} from "@/components/hub/shared";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { RefreshButton } from "@/components/hub/refresh-button";

export const Route = createFileRoute("/_authenticated/matches/")({
  head: () => ({
    meta: [
      { title: "مباريات المصري | النتائج والمواعيد القادمة" },
      {
        name: "description",
        content:
          "كل مباريات النادي المصري البورسعيدي: النتائج بالتفصيل والمواعيد القادمة مع الملعب والبطولة، محدثة من في الجول.",
      },
      { property: "og:title", content: "مباريات المصري | النتائج والمواعيد" },
      {
        property: "og:description",
        content: "نتائج ومواعيد مباريات المصري البورسعيدي لحظة بلحظة.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: MatchesPage,
});

function MatchesPage() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["matches"],
    queryFn: () => getMatches(),
    refetchInterval: (query) =>
      query.state.data?.matches.some((m) => m.status === "live") ? 20_000 : false,
  });

  if (isLoading) return <SectionSkeleton cards={6} />;
  if (isError || !data) return <ErrorNote>تعذر تحميل المباريات الآن، حاول لاحقًا.</ErrorNote>;

  const upcoming = data.matches.filter(
    (m) => m.status === "upcoming" || m.status === "postponed",
  );
  const played = data.matches.filter((m) => m.status === "finished" || m.status === "live");

  return (
    <div className="space-y-4">
      <SectionHeading
        icon={<CalendarDays className="size-4" />}
        title="المباريات"
        action={<RefreshButton queryKeys={[["matches"]]} />}
      />
      <Tabs defaultValue={upcoming.length > 0 ? "upcoming" : "results"} dir="rtl">
        <TabsList className="grid w-full grid-cols-2 rounded-2xl">
          <TabsTrigger value="upcoming" className="rounded-xl">
            قادمة ({upcoming.length})
          </TabsTrigger>
          <TabsTrigger value="results" className="rounded-xl">
            النتائج ({played.length})
          </TabsTrigger>
        </TabsList>
        <TabsContent value="upcoming" className="mt-4 grid gap-3 sm:grid-cols-2">
          {upcoming.length === 0 && (
            <ErrorNote>لا توجد مباريات قادمة معلنة حاليًا.</ErrorNote>
          )}
          {upcoming.map((m) => (
            <MatchCard key={m.id} match={m} />
          ))}
        </TabsContent>
        <TabsContent value="results" className="mt-4 grid gap-3 sm:grid-cols-2">
          {played.map((m) => (
            <MatchCard key={m.id} match={m} />
          ))}
        </TabsContent>
      </Tabs>
      <SourceNote source={data.source} />
    </div>
  );
}
