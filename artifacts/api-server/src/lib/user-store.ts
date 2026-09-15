import { mkdirSync, readFileSync, renameSync, writeFileSync } from "node:fs";
import { dirname } from "node:path";

export type UserPreferences = {
  username: string;
  notificationsEnabled: boolean;
  notifications: Record<string, boolean>;
  devices: string[];
  updatedAt: string;
};

type Store = { users: Record<string, UserPreferences> };

const filePath = process.env["HUB_USER_STORE_FILE"] ?? "data/firebase-users.json";

function readStore(): Store {
  try {
    const parsed = JSON.parse(readFileSync(filePath, "utf8")) as Partial<Store>;
    return { users: parsed.users ?? {} };
  } catch {
    return { users: {} };
  }
}

function writeStore(store: Store) {
  mkdirSync(dirname(filePath), { recursive: true });
  const tempPath = `${filePath}.tmp`;
  writeFileSync(tempPath, JSON.stringify(store, null, 2));
  renameSync(tempPath, filePath);
}

function defaults(): UserPreferences {
  return {
    username: "",
    notificationsEnabled: true,
    notifications: {
      matchday: true,
      lineup: true,
      kickoff: true,
      goal: true,
      penalty: true,
      card: true,
      substitution: true,
      injury: true,
      fulltime: true,
      news: true,
      standings: true,
    },
    devices: [],
    updatedAt: new Date(0).toISOString(),
  };
}

export function getPreferences(userId: string): UserPreferences {
  const store = readStore();
  return store.users[userId] ?? defaults();
}

export function savePreferences(
  userId: string,
  patch: Partial<Pick<UserPreferences, "username" | "notificationsEnabled" | "notifications">>,
): UserPreferences {
  const store = readStore();
  const current = store.users[userId] ?? defaults();
  const next = {
    ...current,
    ...patch,
    notifications: { ...current.notifications, ...(patch.notifications ?? {}) },
    updatedAt: new Date().toISOString(),
  };
  store.users[userId] = next;
  writeStore(store);
  return next;
}

export function addDevice(userId: string, token: string): UserPreferences {
  const store = readStore();
  const current = store.users[userId] ?? defaults();
  const devices = [...new Set([...current.devices, token])].slice(-20);
  const next = { ...current, devices, updatedAt: new Date().toISOString() };
  store.users[userId] = next;
  writeStore(store);
  return next;
}