import { motion } from "motion/react";
import { Flame } from "lucide-react";

interface StreakRingProps {
  days: number;
  weeklyGoal?: number;
  weeklyDone?: number;
}

/**
 * Circular gradient progress ring (SVG) showing weekly habit completion plus
 * the current streak count in the center. Animates the dash offset on mount.
 */
export default function StreakRing({ days, weeklyGoal = 7, weeklyDone = 0 }: StreakRingProps) {
  const size = 128;
  const stroke = 12;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const pct = Math.max(0, Math.min(1, weeklyDone / weeklyGoal));
  const offset = circumference * (1 - pct);

  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} className="-rotate-90">
        <defs>
          <linearGradient id="streakGradient" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#f59e0b" />
            <stop offset="50%" stopColor="#ec4899" />
            <stop offset="100%" stopColor="#8b5cf6" />
          </linearGradient>
        </defs>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="rgba(255,255,255,0.6)"
          strokeWidth={stroke}
          fill="none"
        />
        <motion.circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          stroke="url(#streakGradient)"
          strokeWidth={stroke}
          strokeLinecap="round"
          fill="none"
          strokeDasharray={circumference}
          initial={{ strokeDashoffset: circumference }}
          animate={{ strokeDashoffset: offset }}
          transition={{ duration: 1.1, ease: [0.22, 1, 0.36, 1] }}
        />
      </svg>
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ delay: 0.2, type: "spring", stiffness: 260, damping: 20 }}
        className="absolute inset-0 flex flex-col items-center justify-center"
      >
        <Flame className="w-5 h-5 text-amber-500 mb-1" />
        <div className="text-3xl font-bold tracking-tight bg-gradient-to-br from-amber-500 to-rose-500 bg-clip-text text-transparent">
          {days}
        </div>
        <div className="text-[10px] font-semibold text-slate-500 tracking-wider uppercase">
          {weeklyDone}/{weeklyGoal}
        </div>
      </motion.div>
    </div>
  );
}
