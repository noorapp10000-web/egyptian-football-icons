/** حفظ كل البيانات على الجهاز ليعمل التطبيق بدون إنترنت على آخر نسخة. */
import { useEffect } from "react";
import type { QueryClient } from "@tanstack/react-query";

const CACHE_KEY = "masrawy-fan-cache";
const MAX_AGE = 7 * 24 * 60 * 60_000;

export function useOfflinePersistence(queryClient: QueryClient) {
  useEffect(() => {
    let dispose: (() => void) | undefined;
    let cancelled = false;

    void (async () => {
      try {
        const [{ persistQueryClient }, { createSyncStoragePersister }] = await Promise.all([
          import("@tanstack/react-query-persist-client"),
          import("@tanstack/query-sync-storage-persister"),
        ]);
        if (cancelled) return;
        const persister = createSyncStoragePersister({
          storage: window.localStorage,
          key: CACHE_KEY,
        });
        const [unsubscribe] = persistQueryClient({
          queryClient,
          persister,
          maxAge: MAX_AGE,
        });
        dispose = unsubscribe;
      } catch {
        /* التخزين غير متاح — نكمل بدون كاش دائم */
      }
    })();

    return () => {
      cancelled = true;
      dispose?.();
    };
  }, [queryClient]);
}
