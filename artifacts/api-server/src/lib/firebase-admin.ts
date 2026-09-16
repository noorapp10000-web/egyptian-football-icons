import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

let firebaseApp: App | undefined;
let flutterFirebaseApp: App | undefined;

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function parseServiceAccount(raw: string, variableName: string): ServiceAccount {
  try {
    return JSON.parse(raw) as ServiceAccount;
  } catch {
    throw new Error(`${variableName} must contain valid service account JSON.`);
  }
}

function initializeFromServiceAccount(
  raw: string,
  variableName: string,
  name: string,
): App {
  const serviceAccount = parseServiceAccount(raw, variableName);
  const existing = getApps().find((app) => app.name === name);
  if (existing) return existing;

  return initializeApp(
    {
      credential: cert({
        projectId: serviceAccount.project_id,
        clientEmail: serviceAccount.client_email,
        privateKey: serviceAccount.private_key.replace(/\\n/g, "\n"),
      }),
    },
    name,
  );
}

function getFirebaseApp(): App {
  if (firebaseApp) return firebaseApp;
  const raw = process.env["FIREBASE_SERVICE_ACCOUNT_JSON"];
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is required for Firebase-backed API routes.");
  }
  firebaseApp = initializeFromServiceAccount(raw, "FIREBASE_SERVICE_ACCOUNT_JSON", "[DEFAULT]");
  return firebaseApp;
}

function getFlutterFirebaseApp(): App {
  if (flutterFirebaseApp) return flutterFirebaseApp;
  const raw = process.env["FLUTTER_FIREBASE_SERVICE_ACCOUNT_JSON"];
  if (!raw) {
    throw new Error(
      "FLUTTER_FIREBASE_SERVICE_ACCOUNT_JSON is required for Flutter device authentication.",
    );
  }
  flutterFirebaseApp = initializeFromServiceAccount(
    raw,
    "FLUTTER_FIREBASE_SERVICE_ACCOUNT_JSON",
    "flutter-firebase",
  );
  return flutterFirebaseApp;
}

export async function verifyFirebaseIdToken(token: string) {
  const auths: Auth[] = [];
  const errors: unknown[] = [];

  try {
    auths.push(firebaseAuth());
  } catch (error) {
    errors.push(error);
  }
  if (process.env["FLUTTER_FIREBASE_SERVICE_ACCOUNT_JSON"]) {
    try {
      auths.push(getAuth(getFlutterFirebaseApp()));
    } catch (error) {
      errors.push(error);
    }
  }

  for (const auth of auths) {
    try {
      return await auth.verifyIdToken(token);
    } catch (error) {
      errors.push(error);
    }
  }

  throw errors.at(-1) ?? new Error("No Firebase Admin app is configured.");
}

export function firebaseAuth(): Auth {
  return getAuth(getFirebaseApp());
}

export function firebaseMessaging(): Messaging {
  return getMessaging(getFirebaseApp());
}