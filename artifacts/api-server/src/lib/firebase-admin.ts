import { cert, getApps, initializeApp, type App } from "firebase-admin/app";
import { getAuth, type Auth } from "firebase-admin/auth";
import { getMessaging, type Messaging } from "firebase-admin/messaging";

let firebaseApp: App | undefined;

function getFirebaseApp(): App {
  if (firebaseApp) return firebaseApp;
  const existing = getApps()[0];
  if (existing) {
    firebaseApp = existing;
    return existing;
  }

  const raw = process.env["FIREBASE_SERVICE_ACCOUNT_JSON"];
  if (!raw) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is required for Firebase-backed API routes.");
  }

  const serviceAccount = JSON.parse(raw) as {
    project_id: string;
    client_email: string;
    private_key: string;
  };

  firebaseApp = initializeApp({
    credential: cert({
      projectId: serviceAccount.project_id,
      clientEmail: serviceAccount.client_email,
      privateKey: serviceAccount.private_key.replace(/\\n/g, "\n"),
    }),
  });
  return firebaseApp;
}

export function firebaseAuth(): Auth {
  return getAuth(getFirebaseApp());
}

export function firebaseMessaging(): Messaging {
  return getMessaging(getFirebaseApp());
}