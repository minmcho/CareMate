import { motion } from "motion/react";
import { Droplets, Heart, Leaf, Moon, Wind } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import StreakRing from "../components/StreakRing";
import type { Habit, Language, WellnessProfile, WellnessSession } from "../lib/types";
import { useTranslation } from "../lib/i18n";

interface HomeViewProps {
  lang: Language;
  profile: WellnessProfile;
  habits: Habit[];
  sessions: WellnessSession[];
  onStartBreathing: () => void;
  onOpenChat: () => void;
  onMoodLogged: (score: number) => void;
}

const moodEmojis: { score: number; label: keyof ReturnType<typeof useTranslation> extends never ? never : string }[] = [];

function greetingKey(): "greetingMorning" | "greetingAfternoon" | "greetingEvening" {
  const h = new Date().getHours();
  if (h < 12) return "greetingMorning";
  if (h < 18) return "greetingAfternoon";
  return "greetingEvening";
}

export default function HomeView({
  lang,
  profile,
  habits,
  sessions,
  onStartBreathing,
  onOpenChat,
  onMoodLogged,
}: HomeViewProps) {
  const t = useTranslation(lang);
  void moodEmojis;

  const weeklyDone = habits.reduce((acc, h) => acc + h.completedThisWeek, 0);
  const weeklyGoal = Math.max(
    1,
    habits.reduce((acc, h) => acc + h.targetPerWeek, 0),
  );

  const sessionsToday = sessions.filter((s) => isToday(s.createdAtISO));

  const moods = [
    { score: 5, emoji: "😊", label: t("moodCalm"), tone: "emerald" },
    { score: 4, emoji: "🙂", label: t("moodOk"), tone: "sky" },
    { score: 3, emoji: "😐", label: t("moodTired"), tone: "amber" },
    { score: 2, emoji: "😟", label: t("moodStressed"), tone: "rose" },
    { score: 1, emoji: "😢", label: t("moodLow"), tone: "violet" },
  ];

  const focusCards = [
    {
      key: "mindfulness",
      title: t("mindfulnessTag"),
      subtitle: "5-min body scan",
      icon: <Wind className="w-5 h-5 text-violet-600" />,
      tone: "lilac" as const,
    },
    {
      key: "movement",
      title: t("movementTag"),
      subtitle: "Light stretch flow",
      icon: <Heart className="w-5 h-5 text-rose-500" />,
      tone: "rose" as const,
    },
    {
      key: "nutrition",
      title: t("nutritionTag"),
      subtitle: "Plate method tips",
      icon: <Leaf className="w-5 h-5 text-emerald-600" />,
      tone: "mint" as const,
    },
    {
      key: "sleep",
      title: t("sleepTag"),
      subtitle: "Wind-down ritual",
      icon: <Moon className="w-5 h-5 text-indigo-500" />,
      tone: "sky" as const,
    },
    {
      key: "hydration",
      title: t("hydrationTag"),
      subtitle: "Mindful sip",
      icon: <Droplets className="w-5 h-5 text-cyan-600" />,
      tone: "sky" as const,
    },
  ];

  return (
    <div className="px-5 pb-36 space-y-5">
      {/* Greeting */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <p className="text-[14px] text-slate-500 font-medium">{t(greetingKey())}</p>
        <h2 className="text-[28px] font-bold tracking-tight text-slate-900 leading-tight">
          {profile.displayName}
        </h2>
      </motion.div>

      {/* Streak + breathing */}
      <GlassCard
        tone="neutral"
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.05 }}
      >
        <div className="flex items-center gap-5">
          <StreakRing days={profile.streakDays} weeklyGoal={weeklyGoal} weeklyDone={weeklyDone} />
          <div className="flex-1 min-w-0">
            <div className="text-[12px] uppercase tracking-wider text-slate-500 font-semibold">
              {t("streak")}
            </div>
            <div className="text-[18px] font-bold text-slate-900">
              {profile.streakDays} {t("days")}
            </div>
            <p className="text-[12px] text-slate-500 mt-1 line-clamp-2">
              {t("weeklyProgress")}: {weeklyDone}/{weeklyGoal}
            </p>
            <GlassButton
              variant="primary"
              size="sm"
              className="mt-3"
              onClick={onStartBreathing}
              icon={<Wind className="w-4 h-4" />}
            >
              {t("startBreathing")}
            </GlassButton>
          </div>
        </div>
      </GlassCard>

      {/* Daily check-in */}
      <GlassCard
        tone="lilac"
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.45, delay: 0.1 }}
      >
        <div className="text-[12px] uppercase tracking-wider text-violet-700/90 font-semibold">
          {t("dailyCheckIn")}
        </div>
        <h3 className="text-[18px] font-bold text-slate-900 mt-1">{t("howAreYouFeeling")}</h3>
        <div className="mt-4 grid grid-cols-5 gap-2">
          {moods.map((m) => (
            <motion.button
              key={m.score}
              whileTap={{ scale: 0.92 }}
              whileHover={{ y: -2 }}
              onClick={() => onMoodLogged(m.score)}
              className="flex flex-col items-center gap-1 p-2 rounded-2xl bg-white/70 border border-white/70 backdrop-blur-xl"
              aria-label={m.label}
            >
              <span className="text-2xl leading-none">{m.emoji}</span>
              <span className="text-[10px] font-semibold text-slate-600 truncate w-full text-center">
                {m.label}
              </span>
            </motion.button>
          ))}
        </div>
        <p className="mt-3 text-[11px] text-violet-700/80">
          {sessionsToday.length > 0
            ? `+${sessionsToday.length} session${sessionsToday.length > 1 ? "s" : ""} logged today`
            : t("startChatting")}
        </p>
      </GlassCard>

      {/* Today's focus */}
      <div>
        <h3 className="text-[13px] uppercase tracking-wider font-semibold text-slate-500 px-1 mb-3">
          {t("todaysFocus")}
        </h3>
        <div className="grid grid-cols-2 gap-3">
          {focusCards.map((c, i) => (
            <GlassCard
              key={c.key}
              tone={c.tone}
              interactive
              padded={false}
              onClick={onOpenChat}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.4, delay: 0.15 + i * 0.05 }}
            >
              <div className="p-4">
                <div className="w-9 h-9 rounded-xl bg-white/70 border border-white/80 grid place-items-center backdrop-blur-xl">
                  {c.icon}
                </div>
                <div className="mt-3 text-[15px] font-bold text-slate-900">{c.title}</div>
                <div className="text-[12px] text-slate-500">{c.subtitle}</div>
              </div>
            </GlassCard>
          ))}
        </div>
      </div>

      {/* Disclaimer */}
      <motion.p
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.4 }}
        className="text-[10px] text-center text-slate-400 px-6 leading-relaxed"
      >
        {t("coachDisclaimer")}
      </motion.p>
    </div>
  );
}

function isToday(iso: string): boolean {
  const d = new Date(iso);
  const now = new Date();
  return (
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  );
}
