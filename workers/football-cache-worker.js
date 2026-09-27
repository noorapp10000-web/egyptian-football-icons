const ORIGIN = "https://egyptian-football-api-fixes--horohas599.replit.app";

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (!ORIGIN) {
      return new Response("ORIGIN is not configured", {
        status: 500,
        headers: {
          "content-type": "text/plain; charset=utf-8",
        },
      });
    }

    // لا نكاش POST / PUT / PATCH / DELETE
    if (request.method !== "GET" && request.method !== "HEAD") {
      return proxy(request, url);
    }

    // APIs الخاصة بالمستخدمين ممنوع الكاش
    if (path === "/api/me" || path.startsWith("/api/me/")) {
      return proxy(request, url);
    }

    // نكاش فقط Football API
    if (!path.startsWith("/api/football/")) {
      return proxy(request, url);
    }

    // لو فيه Authorization نتجنب الكاش
    if (request.headers.has("Authorization")) {
      return proxy(request, url);
    }

    const ttl = getTTL(path);
    const upstream = new Request(ORIGIN + path + url.search, request);
    const response = await fetch(upstream, {
      cf: {
        cacheEverything: true,
        cacheTtl: ttl,
        cacheTtlByStatus: {
          "200-299": ttl,
          "300-399": ttl,
          "400-499": 0,
          "500-599": 0,
        },
      },
    });

    const headers = new Headers(response.headers);
    const cacheStatus = response.headers.get("CF-Cache-Status") || "UNKNOWN";
    headers.set("X-Masrawy-Edge", "Cloudflare");
    headers.set("X-Masrawy-Cache", cacheStatus);
    headers.set("X-Masrawy-TTL", String(ttl));
    headers.delete("set-cookie");

    if (response.status >= 200 && response.status < 400) {
      headers.set(
        "Cache-Control",
        `public, max-age=0, s-maxage=${ttl}, stale-while-revalidate=${Math.max(30, Math.min(ttl, 300))}`,
      );
      headers.set(
        "CDN-Cache-Control",
        `public, max-age=0, s-maxage=${ttl}, stale-while-revalidate=${Math.max(30, Math.min(ttl, 300))}`,
      );
    } else {
      headers.set("Cache-Control", "no-store");
      headers.delete("CDN-Cache-Control");
    }

    console.log(
      JSON.stringify({
        type: "cache_check",
        method: request.method,
        path,
        status: response.status,
        cacheStatus,
        ttl,
        timestamp: new Date().toISOString(),
      }),
    );

    return new Response(response.body, {
      status: response.status,
      statusText: response.statusText,
      headers,
    });
  },
};

function getTTL(path) {
  // Existing durations intentionally remain unchanged.
  if (
    path === "/api/football/matches" ||
    path.startsWith("/api/football/matches/")
  ) {
    // Keep live scores fresh; the API itself selects a longer TTL when no match is live.
    return 20;
  }

  if (path === "/api/football/standings") {
    return 7200;
  }

  if (path === "/api/football/news") {
    return 3600;
  }

  if (path.startsWith("/api/football/players/")) {
    return 7200;
  }

  if (
    path === "/api/football/squad" ||
    path === "/api/football/team"
  ) {
    return 86400;
  }

  if (path === "/api/football/head-to-head") {
    return 172800;
  }

  if (path === "/api/football/image") {
    return 86400;
  }

  return 60;
}

async function proxy(request, url) {
  return fetch(new Request(ORIGIN + url.pathname + url.search, request));
}