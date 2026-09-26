export type CacheEntry<T> = {
  value: T;
  at: number;
  live: boolean;
};

type CacheOptions = {
  staleMaxMs: number;
  onError?: (error: unknown) => void;
};

/**
 * Small process-local cache used behind the edge cache.
 *
 * The in-flight map is deliberately separate from the value cache: an expired
 * value can still be served as stale while exactly one refresh is running.
 */
export class SingleFlightCache {
  private readonly values = new Map<string, CacheEntry<unknown>>();
  private readonly inFlight = new Map<string, Promise<CacheEntry<unknown>>>();

  peek<T>(key: string): CacheEntry<T> | undefined {
    return this.values.get(key) as CacheEntry<T> | undefined;
  }

  async get<T>(
    key: string,
    ttlMs: number,
    loader: () => Promise<T>,
    options: CacheOptions,
  ): Promise<CacheEntry<T>> {
    const hit = this.peek<T>(key);
    if (hit && Date.now() - hit.at < ttlMs) return hit;

    const current = this.inFlight.get(key);
    if (current) return current as Promise<CacheEntry<T>>;

    const pending = this.refresh(key, hit, loader, options);
    this.inFlight.set(key, pending as Promise<CacheEntry<unknown>>);

    try {
      return await pending;
    } finally {
      // A failed or successful refresh must never leave a rejected/resolved
      // promise attached to this key forever.
      if (this.inFlight.get(key) === pending) this.inFlight.delete(key);
    }
  }

  private async refresh<T>(
    key: string,
    hit: CacheEntry<T> | undefined,
    loader: () => Promise<T>,
    options: CacheOptions,
  ): Promise<CacheEntry<T>> {
    try {
      const value = await loader();
      const entry: CacheEntry<T> = { value, at: Date.now(), live: true };
      this.values.set(key, entry as CacheEntry<unknown>);
      return entry;
    } catch (error) {
      options.onError?.(error);
      if (hit && Date.now() - hit.at <= options.staleMaxMs) {
        return { ...hit, live: false };
      }
      throw error;
    }
  }
}