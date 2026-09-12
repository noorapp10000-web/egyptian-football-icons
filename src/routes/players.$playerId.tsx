import { createFileRoute, Link } from "@tanstack/react-router";
import { useQuery } from "@tanstack/react-query";
import { ArrowRight, Radio, RefreshCw, Shirt } from "lucide-react";

import { getPlayerDetail } from "@/lib/hub.functions";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export const Route = createFileRoute("/players/$playerId")({
  head: () => ({
    meta: [
      { title: "بيانات اللاعب | المصري بورسعيد" },
      {
        name: "description",
        content:
          "صفحة اللاعب: المركز، رقم القميص، الجنسية، تاريخ الميلاد، الأهداف والمشاركات وتاريخ الانتقالات.",
      },
      { property: "og:title", content: "بيانات اللاعب | المصري بورسعيد" },
      {
        property: "og:description",
        content: "كل بيانات وإحصائيات اللاعب داخل التطبيق، بدون الخروج لموقع خارجي.",
      },
      { property: "og:type", content: "profile" },
      { name: "twitter:card", content: "summary_large_image" },
    ],
  }),
  component: PlayerPage,
});

function InfoRow({ label, value }: { label: string; value: string | null }) {
  if (!value) return null;
  return (
    <div className="flex items-center justify-between gap-3 border-b py-2 text-sm last:border-0">
      <span className="text-muted-foreground">{label}</span>
      <span className="font-semibold">{value}</span>
    </div>
  );
}

function PlayerPage() {
  const { playerId } = Route.useParams();
  const id = Number(playerId);
  const { data, isLoading, isError } = useQuery({
    queryKey: ["player", id],
    queryFn: () => getPlayerDetail({ data: { playerId: id } }),
    enabled: Number.isFinite(id),
  });

  return (
    <div dir="rtl" className="mx-auto w-full max-w-3xl space-y-4 p-4">
      <Link
        to="/"
        className="inline-flex items-center gap-1.5 text-sm font-semibold text-muted-foreground hover:text-primary"
      >
        <ArrowRight className="size-4" /> رجوع
      </Link>

      {isLoading && (
        <div className="space-y-3">
          <Skeleton className="h-32 w-full rounded-xl" />
          <Skeleton className="h-48 w-full rounded-xl" />
        </div>
      )}

      {isError && (
        <Card>
          <CardContent className="p-6 text-center text-sm text-muted-foreground">
            تعذر تحميل بيانات اللاعب حاليًا، حاول مرة أخرى بعد قليل.
          </CardContent>
        </Card>
      )}

      {data && (
        <>
          <Card>
            <CardContent className="flex flex-wrap items-center gap-4 p-4">
              {data.player.photoUrl ? (
                <img
                  src={data.player.photoUrl}
                  alt={data.player.name}
                  className="size-24 rounded-full border object-cover"
                />
              ) : (
                <span className="flex size-24 items-center justify-center rounded-full border bg-secondary">
                  <Shirt className="size-8 text-muted-foreground" />
                </span>
              )}
              <div className="min-w-0 flex-1">
                <h1 className="text-xl font-black leading-tight">{data.player.name}</h1>
                <p className="mt-1 text-sm text-muted-foreground">
                  {[data.player.position, data.player.club].filter(Boolean).join(" · ") ||
                    data.player.role}
                </p>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {data.player.shirtNumber && (
                    <Badge variant="outline">#{data.player.shirtNumber}</Badge>
                  )}
                  {data.player.nationality && (
                    <Badge variant="outline">{data.player.nationality}</Badge>
                  )}
                  {data.player.availability && (
                    <Badge variant="secondary">{data.player.availability}</Badge>
                  )}
                </div>
              </div>
            </CardContent>
          </Card>

          {data.player.totals.length > 0 && (
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
              {data.player.totals.map((t) => (
                <Card key={t.label}>
                  <CardContent className="p-3 text-center">
                    <p className="text-2xl font-black tabular-nums">{t.value ?? "—"}</p>
                    <p className="mt-0.5 text-[11px] text-muted-foreground">{t.label}</p>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}

          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">بيانات اللاعب</CardTitle>
            </CardHeader>
            <CardContent className="pt-0">
              <InfoRow label="النادي" value={data.player.club} />
              <InfoRow label="المركز" value={data.player.position} />
              <InfoRow label="رقم القميص" value={data.player.shirtNumber} />
              <InfoRow label="الجنسية" value={data.player.nationality} />
              <InfoRow label="تاريخ الميلاد" value={data.player.birthDate} />
              <InfoRow label="مكان الميلاد" value={data.player.birthPlace} />
              <InfoRow label="الحالة" value={data.player.availability} />
            </CardContent>
          </Card>

          {data.player.competitions.length > 0 && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">إحصائيات البطولات الحالية</CardTitle>
              </CardHeader>
              <CardContent className="px-2 pt-0">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead className="text-right">البطولة</TableHead>
                      <TableHead className="text-center">مشاركات</TableHead>
                      <TableHead className="text-center">أهداف</TableHead>
                      <TableHead className="text-center">صفراء</TableHead>
                      <TableHead className="text-center">حمراء</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {data.player.competitions.map((c) => (
                      <TableRow key={`${c.competitionId}-${c.competition}`}>
                        <TableCell className="text-right font-semibold">
                          {c.competition}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {c.appearances ?? "—"}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {c.goals ?? "—"}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {c.yellowCards ?? "—"}
                        </TableCell>
                        <TableCell className="text-center tabular-nums">
                          {c.redCards ?? "—"}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </CardContent>
            </Card>
          )}

          {data.player.career.length > 0 && (
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">تاريخ الانتقالات</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2 pt-0">
                {data.player.career.map((c, i) => (
                  <div
                    key={`${c.toTeam}-${c.from}-${i}`}
                    className="flex items-center gap-3 rounded-lg border p-2.5 text-sm"
                  >
                    {c.toTeamCrestUrl && (
                      <img src={c.toTeamCrestUrl} alt="" className="size-8 object-contain" />
                    )}
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold">{c.toTeam ?? "—"}</p>
                      <p className="text-[11px] text-muted-foreground">
                        {[c.from, c.until].filter(Boolean).join(" → ")}
                        {c.contract ? ` · ${c.contract}` : ""}
                      </p>
                    </div>
                    {c.position && (
                      <Badge variant="outline" className="text-[10px]">
                        {c.position}
                      </Badge>
                    )}
                  </div>
                ))}
              </CardContent>
            </Card>
          )}

          <p className="flex items-center gap-1.5 text-xs text-muted-foreground">
            {data.source.status === "live" ? (
              <Radio className="size-3.5 text-primary" />
            ) : (
              <RefreshCw className="size-3.5" />
            )}
            المصدر: {data.source.name}
            {data.source.status === "cached" && " (نسخة محفوظة)"}
          </p>
        </>
      )}
    </div>
  );
}
