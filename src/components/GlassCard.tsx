import { ReactNode, MouseEventHandler } from "react";
import { motion, MotionProps } from "motion/react";
import { cn } from "../lib/utils";

/**
 * Apple-style "liquid glass" surface.
 *
 * Layers:
 *  1. Blurred translucent base (backdrop-blur + saturated background).
 *  2. 1px inner highlight ring.
 *  3. Soft outer shadow.
 *  4. Subtle gradient sheen at the top for the "glass" feel.
 */
export interface GlassCardProps extends MotionProps {
  className?: string;
  children: ReactNode;
  tone?: "neutral" | "mint" | "lilac" | "rose" | "sky" | "amber";
  padded?: boolean;
  interactive?: boolean;
  onClick?: MouseEventHandler<HTMLDivElement>;
  key?: string | number;
}

const toneMap: Record<NonNullable<GlassCardProps["tone"]>, string> = {
  neutral: "from-white/80 via-white/60 to-white/40",
  mint: "from-emerald-100/80 via-emerald-50/60 to-white/40",
  lilac: "from-violet-100/80 via-violet-50/60 to-white/40",
  rose: "from-rose-100/80 via-rose-50/60 to-white/40",
  sky: "from-sky-100/80 via-sky-50/60 to-white/40",
  amber: "from-amber-100/80 via-amber-50/60 to-white/40",
};

export default function GlassCard({
  className,
  children,
  tone = "neutral",
  padded = true,
  interactive = false,
  ...motionProps
}: GlassCardProps) {
  return (
    <motion.div
      {...motionProps}
      className={cn(
        "relative overflow-hidden rounded-[28px] border border-white/60",
        "bg-gradient-to-b",
        toneMap[tone],
        "backdrop-blur-2xl backdrop-saturate-150",
        "shadow-[0_10px_40px_-12px_rgba(30,30,60,0.15),0_1px_0_rgba(255,255,255,0.9)_inset]",
        padded && "p-5",
        interactive && "cursor-pointer active:scale-[0.98] transition-transform duration-200",
        className,
      )}
    >
      {/* Top sheen */}
      <div
        aria-hidden
        className="pointer-events-none absolute inset-x-0 top-0 h-16 bg-gradient-to-b from-white/70 to-transparent opacity-70"
      />
      {/* Ambient glow */}
      <div
        aria-hidden
        className="pointer-events-none absolute -top-20 -right-20 h-48 w-48 rounded-full bg-white/40 blur-3xl"
      />
      <div className="relative z-[1]">{children}</div>
    </motion.div>
  );
}
