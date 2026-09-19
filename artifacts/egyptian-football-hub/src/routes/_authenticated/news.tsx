import { createFileRoute } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { ExternalLink, Newspaper } from "lucide-react";

import { getNews } from "@/lib/hub.functions";
import {
  ErrorNote,
  proxiedImageUrl,
  SectionHeading,
  SectionSkeleton,
  SourceNote,
} from "@/components/hub/shared";
import { Badge } from "@/components/ui/badge";
import { RefreshButton } from "@/components/hub/refresh-button";

export const Route = createFileRoute("/_authenticated/news")({
  head: () => ({
    meta: [
      { title: "أخبار النادي المصري البورسعيدي | آخر المستجدات" },
      {
        name: "description",
        content:
          "آخر أخبار النادي المصري البورسعيدي: الانتقالات، الإصابات، تصريحات الجهاز الفني وتقارير المباريات من في الجول ومصادر أخرى.",
      },
      { property: "og:title", content: "أخبار النادي المصري البورسعيدي" },
      {
        property: "og:description",
        content: "أخبار المصري البورسعيدي مجمعة ومحدثة من أكثر من مصدر.",
      },
      { property: "og:type", content: "website" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: NewsPage,
});

function NewsPage() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ["news"],
    queryFn: () => getNews(),
  });

  if (isLoading) return <SectionSkeleton cards={6} />;
  if (isError || !data) return <ErrorNote>تعذر تحميل الأخبار الآن.</ErrorNote>;
  if (data.news.length === 0)
    return <ErrorNote>لا توجد أخبار جديدة عن النادي المصري حاليًا.</ErrorNote>;

  const [lead, ...rest] = data.news;

  return (
    <div className="space-y-4">
      <SectionHeading
        icon={<Newspaper className="size-4" />}
        title="آخر الأخبار"
        action={<RefreshButton queryKeys={[["news"]]} />}
      />

      {lead && (
        <a
          href={lead.url}
          target="_blank"
          rel="noreferrer"
          className="group block overflow-hidden rounded-2xl border border-border/70 bg-card"
        >
          {lead.imageUrl && (
            <img
              src={proxiedImageUrl(lead.imageUrl) ?? undefined}
              alt=""
              className="h-44 w-full object-cover"
              loading="lazy"
            />
          )}
          <div className="p-4">
            <Badge className="border-0 bg-gold/15 text-[10px] text-gold">{lead.sourceName}</Badge>
            <p className="mt-2 text-base font-black leading-snug group-hover:text-primary">
              {lead.title}
            </p>
            <p className="mt-1.5 flex items-center gap-1.5 text-[11px] text-muted-foreground">
              {lead.publishedText}
              <ExternalLink className="size-3" />
            </p>
          </div>
        </a>
      )}

      <div className="grid gap-3 sm:grid-cols-2">
        {rest.map((item) => (
          <a
            key={item.id}
            href={item.url}
            target="_blank"
            rel="noreferrer"
            className="group flex gap-3 rounded-2xl border border-border/70 bg-card p-3 transition-colors hover:border-primary/40 hover:bg-accent/40"
          >
            {item.imageUrl && (
              <img
                src={proxiedImageUrl(item.imageUrl) ?? undefined}
                alt=""
                className="size-20 shrink-0 rounded-xl object-cover"
                loading="lazy"
              />
            )}
            <div className="min-w-0">
              <p className="line-clamp-3 text-sm font-bold leading-snug group-hover:text-primary">
                {item.title}
              </p>
              <div className="mt-1.5 flex flex-wrap items-center gap-2 text-[11px] text-muted-foreground">
                <Badge variant="secondary" className="border-0 text-[10px]">
                  {item.sourceName}
                </Badge>
                {item.publishedText}
              </div>
            </div>
          </a>
        ))}
      </div>
      <SourceNote source={data.source} />
    </div>
  );
}
