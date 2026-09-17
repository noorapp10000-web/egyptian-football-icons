import { useQueryClient } from "@tanstack/react-query";
import { RefreshCw } from "lucide-react";
import { useState } from "react";

/** زر تحديث يدوي: يتصل بالسيرفر ويجيب آخر بيانات للقسم. */
export function RefreshButton({
  queryKeys,
  label = "تحديث",
}: {
  queryKeys: unknown[][];
  label?: string;
}) {
  const queryClient = useQueryClient();
  const [busy, setBusy] = useState(false);

  const run = async () => {
    if (busy) return;
    setBusy(true);
    try {
      await Promise.all(
        queryKeys.map((queryKey) => queryClient.refetchQueries({ queryKey, type: "active" })),
      );
    } finally {
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      onClick={run}
      disabled={busy}
      aria-label={label}
      className="inline-flex shrink-0 items-center gap-1.5 rounded-full border border-border/70 bg-card px-3 py-1.5 text-[11px] font-bold text-muted-foreground transition-colors hover:border-primary/40 hover:text-primary disabled:opacity-60"
    >
      <RefreshCw className={`size-3.5 ${busy ? "animate-spin" : ""}`} />
      {busy ? "جارٍ التحديث" : label}
    </button>
  );
}
