import assert from "node:assert/strict";
import test from "node:test";

import { SingleFlightCache } from "./single-flight-cache.ts";

test("deduplicates concurrent cache misses and clears the flight after success", async () => {
  const cache = new SingleFlightCache();
  let calls = 0;

  const loader = async () => {
    calls += 1;
    await new Promise((resolve) => setTimeout(resolve, 5));
    return { matches: ["one"] };
  };

  const results = await Promise.all(
    Array.from({ length: 1_000 }, () =>
      cache.get("matches", 0, loader, { staleMaxMs: 60_000 }),
    ),
  );

  assert.equal(calls, 1);
  assert.equal(results.length, 1_000);
  assert.deepEqual(results[0]?.value, { matches: ["one"] });

  await cache.get("matches", 60_000, loader, { staleMaxMs: 60_000 });
  assert.equal(calls, 1);
});

test("clears the flight after an exception and serves bounded stale data", async () => {
  const cache = new SingleFlightCache();
  let calls = 0;
  const first = () => Promise.resolve("valid");
  const firstEntry = await cache.get("value", 60_000, first, { staleMaxMs: 60_000 });
  assert.equal(firstEntry.value, "valid");

  const failing = async () => {
    calls += 1;
    throw new Error("source unavailable");
  };

  const stale = await cache.get("value", 0, failing, {
    staleMaxMs: 60_000,
  });
  assert.equal(stale.value, "valid");
  assert.equal(stale.live, false);
  assert.equal(calls, 1);

  await assert.rejects(
    cache.get("value", 0, failing, { staleMaxMs: -1 }),
    /source unavailable/,
  );
  assert.equal(calls, 2);
});