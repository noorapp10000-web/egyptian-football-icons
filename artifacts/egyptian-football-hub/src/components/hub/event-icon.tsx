import {
  AlertTriangle,
  ArrowLeftRight,
  Ban,
  BellRing,
  ClipboardList,
  Circle,
  CircleDot,
  Crosshair,
  Flag,
  Footprints,
  Goal,
  Hand,
  Handshake,
  HeartPulse,
  MonitorPlay,
  ShieldX,
  Square,
  Target,
  Timer,
  Volleyball,
  XCircle,
  Zap,
  type LucideIcon,
} from "lucide-react";

import { normalizeEventType } from "@/lib/match-events";

const ICONS: Record<string, LucideIcon> = {
  goal: Volleyball,
  "own-goal": ShieldX,
  penalty: Target,
  "penalty-goal": Target,
  "missed-penalty": XCircle,
  "penalty-awarded": Crosshair,
  "penalty-saved": Hand,
  "yellow-card": Square,
  "second-yellow": Square,
  "red-card": Square,
  substitution: ArrowLeftRight,
  injury: HeartPulse,
  corner: Flag,
  offside: Ban,
  freekick: Footprints,
  shot: Zap,
  save: Hand,
  woodwork: Goal,
  var: MonitorPlay,
  chance: Zap,
  "kick-off": Timer,
  "half-time": Timer,
  "full-time": BellRing,
  lineup: ClipboardList,
  assist: Handshake,
};

/** أيقونة حقيقية لكل نوع حدث بدل الإيموجي. */
export function EventIcon({
  type,
  className = "size-3.5",
}: {
  type: string;
  className?: string;
}) {
  const key = normalizeEventType(type);
  const Icon = ICONS[key] ?? (key ? CircleDot : Circle);

  if (key === "yellow-card" || key === "second-yellow")
    return <Square className={`${className} fill-gold text-gold`} aria-hidden />;
  if (key === "red-card")
    return <Square className={`${className} fill-live text-live`} aria-hidden />;
  if (key === "injury")
    return <HeartPulse className={className} aria-hidden />;
  if (key === "chance") return <AlertTriangle className={className} aria-hidden />;

  return <Icon className={className} aria-hidden />;
}
