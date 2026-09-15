import { Router, type RequestHandler } from "express";
import { firebaseAuth } from "../lib/firebase-admin";
import { addDevice, getPreferences, savePreferences } from "../lib/user-store";

type FirebaseUser = { uid: string; email?: string };

const router = Router();

const requireFirebaseUser: RequestHandler = async (req, res, next) => {
  const authorization = req.header("authorization");
  const token = authorization?.startsWith("Bearer ") ? authorization.slice(7) : "";
  if (!token) {
    res.status(401).json({ error: "missing_bearer_token" });
    return;
  }

  try {
    const decoded = await firebaseAuth().verifyIdToken(token);
    res.locals.firebaseUser = { uid: decoded.uid, email: decoded.email } satisfies FirebaseUser;
    next();
  } catch (error) {
    req.log?.warn({ err: error }, "Firebase token verification failed");
    res.status(401).json({ error: "invalid_bearer_token" });
  }
};

router.get("/me/preferences", requireFirebaseUser, (req, res) => {
  const user = res.locals.firebaseUser as FirebaseUser;
  res.json({ userId: user.uid, preferences: getPreferences(user.uid) });
});

router.put("/me/preferences", requireFirebaseUser, (req, res) => {
  const user = res.locals.firebaseUser as FirebaseUser;
  const body = req.body as {
    username?: unknown;
    notificationsEnabled?: unknown;
    notifications?: unknown;
  };

  const username =
    typeof body.username === "string" ? body.username.trim().slice(0, 30) : undefined;
  const notificationsEnabled =
    typeof body.notificationsEnabled === "boolean" ? body.notificationsEnabled : undefined;
  const notifications =
    body.notifications && typeof body.notifications === "object"
      ? Object.fromEntries(
          Object.entries(body.notifications).filter(([, value]) => typeof value === "boolean"),
        )
      : undefined;

  const preferences = savePreferences(user.uid, {
    ...(username === undefined ? {} : { username }),
    ...(notificationsEnabled === undefined ? {} : { notificationsEnabled }),
    ...(notifications === undefined ? {} : { notifications }),
  });
  res.json({ userId: user.uid, preferences });
});

router.post("/me/devices", requireFirebaseUser, (req, res) => {
  const user = res.locals.firebaseUser as FirebaseUser;
  const token = typeof req.body?.token === "string" ? req.body.token.trim() : "";
  if (!token || token.length > 4096) {
    res.status(400).json({ error: "invalid_device_token" });
    return;
  }
  res.json({ userId: user.uid, preferences: addDevice(user.uid, token) });
});

export default router;