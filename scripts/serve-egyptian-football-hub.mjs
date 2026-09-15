import { createServer } from "node:http";
import { Readable } from "node:stream";
import { readFile, stat } from "node:fs/promises";
import { extname, normalize, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const artifactDir = fileURLToPath(
  new URL("../artifacts/egyptian-football-hub/", import.meta.url),
);
const publicDir = resolve(artifactDir, ".output/public");
const { default: app } = await import(
  new URL("./.output/server/index.mjs", `file://${artifactDir}/`).href
);

const mimeTypes = {
  ".css": "text/css; charset=utf-8",
  ".gif": "image/gif",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".jpeg": "image/jpeg",
  ".jpg": "image/jpeg",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".txt": "text/plain; charset=utf-8",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
};

function publicFilePath(pathname) {
  let decodedPath;
  try {
    decodedPath = decodeURIComponent(pathname);
  } catch {
    return null;
  }

  const candidate = resolve(publicDir, `.${decodedPath}`);
  const relative = normalize(candidate).slice(publicDir.length);
  return relative.startsWith("..") ? null : candidate;
}

async function servePublicFile(request, response) {
  if (request.method !== "GET" && request.method !== "HEAD") return false;

  const filePath = publicFilePath(
    new URL(request.url, "http://localhost").pathname,
  );
  if (!filePath) return false;

  try {
    const fileInfo = await stat(filePath);
    if (!fileInfo.isFile()) return false;
    response.statusCode = 200;
    response.setHeader(
      "content-type",
      mimeTypes[extname(filePath).toLowerCase()] ?? "application/octet-stream",
    );
    response.setHeader("content-length", fileInfo.size);
    response.end(
      request.method === "HEAD" ? undefined : await readFile(filePath),
    );
    return true;
  } catch {
    return false;
  }
}

const server = createServer(async (request, response) => {
  try {
    if (await servePublicFile(request, response)) return;

    const headers = new Headers();
    for (const [key, value] of Object.entries(request.headers)) {
      if (value !== undefined) {
        headers.set(key, Array.isArray(value) ? value.join(", ") : value);
      }
    }

    const method = request.method ?? "GET";
    const init = { method, headers };
    if (method !== "GET" && method !== "HEAD") {
      init.body = Readable.toWeb(request);
      init.duplex = "half";
    }

    const upstream = await app.fetch(
      new Request(
        `http://${request.headers.host ?? "localhost"}${request.url ?? "/"}`,
        init,
      ),
      {},
      { waitUntil() {} },
    );

    response.statusCode = upstream.status;
    upstream.headers.forEach((value, key) => response.setHeader(key, value));
    response.end(Buffer.from(await upstream.arrayBuffer()));
  } catch (error) {
    console.error(error);
    if (!response.headersSent) response.statusCode = 500;
    response.end("Internal Server Error");
  }
});

const port = Number(process.env.PORT ?? 3000);
const host = process.env.HOST ?? "0.0.0.0";
server.listen(port, host, () => {
  console.error(`Egyptian Football Hub server listening on ${host}:${port}`);
});
