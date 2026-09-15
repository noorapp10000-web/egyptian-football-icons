import { useEffect, useState } from "react";

import { firebaseAuth, onAuthStateChanged, type User } from "@/lib/firebase";

/** حالة تسجيل الدخول الحالية للمستخدم. */
export function useAuth() {
  const [user, setUser] = useState<User | null>(firebaseAuth.currentUser);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(firebaseAuth, (next) => {
      setUser(next);
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  return { user, loading, isAuthenticated: !!user };
}
