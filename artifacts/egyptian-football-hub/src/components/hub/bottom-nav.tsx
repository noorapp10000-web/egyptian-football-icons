import { Link } from "@tanstack/react-router";
import {
  CalendarDays,
  Home,
  Landmark,
  ListOrdered,
  Newspaper,
  Settings,
  Users,
} from "lucide-react";

const ITEMS = [
  { to: "/", label: "الرئيسية", icon: Home },
  { to: "/matches", label: "المباريات", icon: CalendarDays },
  { to: "/table", label: "الترتيب", icon: ListOrdered },
  { to: "/squad", label: "الفريق", icon: Users },
  { to: "/news", label: "الأخبار", icon: Newspaper },
  { to: "/history", label: "التاريخ", icon: Landmark },
  { to: "/settings", label: "الإعدادات", icon: Settings },
] as const;

export function BottomNav() {
  return (
    <nav className="fixed inset-x-0 bottom-0 z-40 border-t border-border/70 bg-background/85 backdrop-blur-xl">
      <ul className="mx-auto grid max-w-3xl grid-cols-7">
        {ITEMS.map(({ to, label, icon: Icon }) => (
          <li key={to}>
            <Link
              to={to}
              activeOptions={{ exact: to === "/" }}
              className="group flex flex-col items-center gap-1 py-2.5 text-[10px] font-bold text-muted-foreground transition-colors"
              activeProps={{ className: "!text-primary" }}
            >
              {({ isActive }) => (
                <>
                  <span
                    className={`flex h-7 w-10 items-center justify-center rounded-full transition-all ${
                      isActive ? "bg-primary/15 shadow-[0_0_20px_-6px_var(--primary)]" : ""
                    }`}
                  >
                    <Icon className="size-[18px]" />
                  </span>
                  <span className="truncate">{label}</span>
                </>
              )}
            </Link>
          </li>
        ))}
      </ul>
      <div className="h-[env(safe-area-inset-bottom)]" />
    </nav>
  );
}
