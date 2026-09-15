import { getApp, getApps, initializeApp } from "firebase/app";
import {
  GoogleAuthProvider,
  getAuth,
  onAuthStateChanged,
  signInWithPopup,
  signInWithRedirect,
  getRedirectResult,
  signOut,
  type User,
} from "firebase/auth";

const projectId = import.meta.env["VITE_FIREBASE_PROJECT_ID"] ?? "almasry-sc-fed4e";
const messagingSenderId =
  import.meta.env["VITE_FIREBASE_MESSAGING_SENDER_ID"] ?? "1081052661025";

export const firebaseConfig = {
  apiKey:
    import.meta.env["VITE_FIREBASE_API_KEY"] ??
    "AIzaSyDHa_KoKF6TOxeAMH9L_kAiGIYoQDdt1T8",
  authDomain: import.meta.env["VITE_FIREBASE_AUTH_DOMAIN"] ?? `${projectId}.firebaseapp.com`,
  projectId,
  storageBucket:
    import.meta.env["VITE_FIREBASE_STORAGE_BUCKET"] ?? `${projectId}.firebasestorage.app`,
  messagingSenderId,
  // This fallback keeps the Android Firebase project usable in local builds.
  // Production web builds should set the Web app ID from Firebase Console.
  appId:
    import.meta.env["VITE_FIREBASE_APP_ID"] ??
    "1:1081052661025:android:1ace9d4ffce052f65bea60",
};

export const firebaseApp = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const firebaseAuth = getAuth(firebaseApp);
export const googleProvider = new GoogleAuthProvider();

export {
  getRedirectResult,
  onAuthStateChanged,
  signInWithPopup,
  signInWithRedirect,
  signOut,
};
export type { User };