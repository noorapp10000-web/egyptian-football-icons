import { Link } from "@tanstack/react-router";
import { Star } from "lucide-react";

export type PitchPlayer = {
  id: number;
  name: string;
  number: number | null;
  position: string;
  photoUrl: string | null;
  isCaptain: boolean;
};

const isKeeper = (p: PitchPlayer) =>
  /حارس|goal ?keeper|gk/i.test(p.position ?? "");

/** يحوّل نص الخطة "4-3-3" إلى صفوف أعداد اللاعبين أمام الحارس. */
function formationRows(formation: string | null, outfieldCount: number) {
  const parsed = (formation ?? "")
    .replace(/[٠-٩]/g, (d) => String("٠١٢٣٤٥٦٧٨٩".indexOf(d)))
    .split(/[^0-9]+/)
    .map((n) => Number(n))
    .filter((n) => n > 0 && n < 7);

  const sum = parsed.reduce((a, b) => a + b, 0);
  if (parsed.length >= 2 && sum === outfieldCount) return parsed;

  // خطط بديلة حسب عدد اللاعبين المتاح
  if (outfieldCount === 10) return [4, 3, 3];
  const rows: number[] = [];
  let left = outfieldCount;
  while (left > 0) {
    const take = Math.min(4, left);
    rows.push(take);
    left -= take;
  }
  return rows;
}

/** يوزّع التشكيل على صفوف الملعب: الحارس ثم خطوط الخطة. */
function buildRows(players: PitchPlayer[], formation: string | null) {
  const keeper = players.find(isKeeper) ?? players[0];
  const outfield = players.filter((p) => p.id !== keeper?.id);
  const rows = formationRows(formation, outfield.length);

  const lines: PitchPlayer[][] = keeper ? [[keeper]] : [];
  let index = 0;
  for (const count of rows) {
    const line = outfield.slice(index, index + count);
    if (line.length > 0) lines.push(line);
    index += count;
  }
  if (index < outfield.length) lines.push(outfield.slice(index));
  return lines;
}

function PlayerChip({ player }: { player: PitchPlayer }) {
  const shortName = player.name.split(" ").slice(0, 2).join(" ");
  return (
    <Link
      to="/players/$playerId"
      params={{ playerId: String(player.id) }}
      className="flex w-16 flex-col items-center gap-1 text-center transition-transform hover:scale-105"
    >
      <span className="relative">
        <span className="block size-11 overflow-hidden rounded-full border-2 border-primary-foreground/70 bg-secondary shadow-lg">
          {player.photoUrl ? (
            <img
              src={player.photoUrl}
              alt={player.name}
              loading="lazy"
              className="size-full object-cover"
            />
          ) : (
            <span className="flex size-full items-center justify-center text-xs font-bold text-muted-foreground">
              {player.number ?? "—"}
            </span>
          )}
        </span>
        <span className="absolute -bottom-1 -end-1 flex size-5 items-center justify-center rounded-full bg-gold text-[10px] font-extrabold tabular-nums text-gold-foreground shadow">
          {player.number ?? "—"}
        </span>
        {player.isCaptain && (
          <Star className="absolute -top-1 -start-1 size-3.5 fill-gold text-gold drop-shadow" />
        )}
      </span>
      <span className="line-clamp-2 rounded bg-background/55 px-1 text-[10px] font-semibold leading-tight text-foreground backdrop-blur-sm">
        {shortName}
      </span>
    </Link>
  );
}

export function LineupPitch({
  teamName,
  formation,
  crestUrl,
  coach,
  players,
  bench,
}: {
  teamName: string;
  formation: string | null;
  crestUrl?: string | null;
  coach?: string | null;
  players: PitchPlayer[];
  bench?: PitchPlayer[];
}) {
  const lines = buildRows(players, formation);

  return (
    <div className="overflow-hidden rounded-xl border bg-card">
      <div className="flex items-center justify-between gap-2 border-b px-3 py-2">
        <span className="flex items-center gap-2 text-xs font-bold">
          {crestUrl && <img src={crestUrl} alt="" className="size-5 object-contain" />}
          {teamName}
        </span>
        {formation && (
          <span className="rounded bg-primary/15 px-2 py-0.5 text-[11px] font-extrabold tabular-nums text-primary">
            {formation}
          </span>
        )}
      </div>

      <div
        className="relative flex flex-col justify-between gap-3 px-2 py-4"
        style={{
          background:
            "repeating-linear-gradient(to bottom, var(--pitch) 0 32px, var(--pitch-alt) 32px 64px)",
        }}
      >
        {/* خطوط الملعب */}
        <div className="pointer-events-none absolute inset-2 rounded-md border-2 border-[var(--pitch-line)]" />
        <div className="pointer-events-none absolute inset-x-2 top-1/2 h-0 border-t-2 border-[var(--pitch-line)]" />
        <div className="pointer-events-none absolute start-1/2 top-1/2 size-16 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-[var(--pitch-line)]" />
        <div className="pointer-events-none absolute bottom-2 start-1/2 h-10 w-32 -translate-x-1/2 rounded-t-sm border-2 border-b-0 border-[var(--pitch-line)]" />
        <div className="pointer-events-none absolute top-2 start-1/2 h-10 w-32 -translate-x-1/2 rounded-b-sm border-2 border-t-0 border-[var(--pitch-line)]" />

        {lines.map((line, i) => (
          <div
            key={i}
            className="relative flex flex-wrap items-center justify-center gap-x-2 gap-y-3"
          >
            {line.map((p) => (
              <PlayerChip key={p.id} player={p} />
            ))}
          </div>
        ))}
      </div>

      {coach && (
        <p className="border-t px-3 py-2 text-[11px] text-muted-foreground">
          المدير الفني: <span className="font-semibold text-foreground">{coach}</span>
        </p>
      )}

      {bench && bench.length > 0 && (
        <div className="border-t px-3 py-2">
          <p className="mb-1.5 text-[11px] font-bold text-muted-foreground">البدلاء</p>
          <div className="flex flex-wrap gap-x-3 gap-y-1 text-[11px]">
            {bench.map((p) => (
              <Link
                key={p.id}
                to="/players/$playerId"
                params={{ playerId: String(p.id) }}
                className="flex items-center gap-1 rounded px-1 transition-colors hover:bg-accent/60"
              >
                <span className="tabular-nums text-muted-foreground">{p.number ?? "—"}</span>
                <span>{p.name}</span>
              </Link>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
