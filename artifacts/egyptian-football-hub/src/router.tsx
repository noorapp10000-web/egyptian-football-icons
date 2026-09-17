import { QueryClient } from "@tanstack/react-query";
import { createRouter } from "@tanstack/react-router";
import { routeTree } from "./routeTree.gen";

export const getRouter = () => {
  const queryClient = new QueryClient({
    defaultOptions: {
      queries: {
        // نعرض آخر نسخة محفوظة فورًا حتى بدون إنترنت، والتحديث يحصل في الخلفية.
        staleTime: 60_000,
        gcTime: 7 * 24 * 60 * 60_000,
        networkMode: "offlineFirst",
        retry: 1,
        refetchOnWindowFocus: true,
      },
    },
  });

  const router = createRouter({
    routeTree,
    context: { queryClient },
    scrollRestoration: true,
    defaultPreloadStaleTime: 0,
  });

  return router;
};
