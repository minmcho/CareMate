import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Plus, Check, Flame, Snowflake, Trash2 } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { Habit, Language, WellnessGoal, WellnessProfile } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { newId } from "../lib/storage";

interface HabitsViewProps {
  lang: Language;
  profile: WellnessProfile;
  habits: Habit[];
  onHabitsChange: (habits: Habit[]) => void;
  onProfileChange: (profile: WellnessProfile) => void;
  onSessionLogged: (durationSec: number) => void;
}

const GOALS: { key: WellnessGoal; label: string; emoji: string }[] = [
  { key: "mindfulness", label: "Mindfulness", emoji: "🧘" },
  { key: "movement", label: "Movement", emoji: "🏃" },
  { key: "nutrition", label: "Nutrition", emoji: "🥗" },
  { key: "sleep", label: "Sleep", emoji: "🌙" },
  { key: "stress", label: "Stress", emoji: "🌿" },
  { key: "hydration", label: "Hydration", emoji: "💧" },
];

export default function HabitsView({
  lang,
  profile,
  habits,
  onHabitsChange,
  onProfileChange,
  onSessionLogged,
}: HabitsViewProps) {
  const t = useTranslation(lang);
  const [adding, setAdding] = useState(false);
  const [draftTitle, setDraftTitle] = useState("");
  const [draftGoal, setDraftGoal] = useState<WellnessGoal>("mindfulness");
  const [draftTarget, setDraftTarget] = useState(3);

  function toggleToday(habit: Habit) {
    const today = new Date().toISOString().slice(0, 10);
    const already = habit.history.includes(today);
    const updated: Habit = {
      ...habit,
      completedThisWeek: already ? Math.max(0, habit.completedThisWeek - 1) : habit.completedThisWeek + 1,
      history: already ? habit.history.filter((d) => d !== today) : [...habit.history, today],
    };
    onHabitsChange(habits.map((h) => (h.id === habit.id ? updated : h)));

    if (!already) {
      onSessionLogged(60);
      // bump streak if last check-in was yesterday or earlier today
      const last = profile.lastCheckInISO ? new Date(profile.lastCheckInISO) : null;
      const now = new Date();
      const isSameDay =
        last &&
        last.getFullYear() === now.getFullYear() &&
        last.getMonth() === now.getMonth() &&
        last.getDate() === now.getDate();
      const nextStreak = isSameDay ? profile.streakDays : profile.streakDays + 1;
      onProfileChange({
        ...profile,
        streakDays: nextStreak,
        lastCheckInISO: now.toISOString(),
      });
    }
  }

  function addHabit() {
    if (!draftTitle.trim()) return;
    const goalMeta = GOALS.find((g) => g.key === draftGoal)!;
    const habit: Habit = {
      id: newId(),
      title: draftTitle.trim(),
      emoji: goalMeta.emoji,
      goal: draftGoal,
      targetPerWeek: draftTarget,
      completedThisWeek: 0,
      history: [],
    };
    onHabitsChange([habit, ...habits]);
    setAdding(false);
    setDraftTitle("");
    setDraftGoal("mindfulness");
    setDraftTarget(3);
  }

  function removeHabit(id: string) {
    onHabitsChange(habits.filter((h) => h.id !== id));
  }

  function useFreezeStreak() {
    if (!profile.streakFreezeAvailable) return;
    onProfileChange({ ...profile, streakFreezeAvailable: false });
  }

  const today = new Date().toISOString().slice(0, 10);

  return (
    <div className="px-5 pb-36 space-y-5">
      {/* Streak summary */}
      <GlassCard
        tone="amber"
        initial={{ opacity: 0, y: 12 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="flex items-center justify-between gap-4">
          <div>
            <div className="text-[11px] uppercase tracking-wider font-semibold text-amber-700">
              {t("streak")}
            </div>
            <div className="flex items-center gap-2 mt-1">
              <Flame className="w-6 h-6 text-amber-500" />
              <span className="text-[28px] font-bold text-slate-900">
                {profile.streakDays}
              </span>
              <span className="text-[12px] text-slate-500 font-semibold">{t("days")}</span>
            </div>
          </div>
          <GlassButton
            variant={profile.streakFreezeAvailable ? "tinted" : "ghost"}
            size="sm"
            onClick={useFreezeStreak}
            disabled={!profile.streakFreezeAvailable}
            icon={<Snowflake className="w-3.5 h-3.5" />}
          >
            {profile.streakFreezeAvailable ? t("freezeStreak") : t("freezeUsed") || "Used"}
          </GlassButton>
        </div>
      </GlassCard>

      {/* My habits */}
      <div>
        <div className="flex items-center justify-between px-1 mb-3">
          <h3 className="text-[13px] uppercase tracking-wider font-semibold text-slate-500">
            {t("myHabits")}
          </h3>
          <GlassButton
            variant="tinted"
            size="sm"
            icon={<Plus className="w-3.5 h-3.5" />}
            onClick={() => setAdding(true)}
          >
            {t("newHabit")}
          </GlassButton>
        </div>

        <AnimatePresence>
          {adding && (
            <motion.div
              initial={{ opacity: 0, y: -8, height: 0 }}
              animate={{ opacity: 1, y: 0, height: "auto" }}
              exit={{ opacity: 0, y: -8, height: 0 }}
              transition={{ duration: 0.3 }}
              className="mb-3 overflow-hidden"
            >
              <GlassCard tone="lilac">
                <input
                  value={draftTitle}
                  onChange={(e) => setDraftTitle(e.target.value)}
                  placeholder={t("habitTitle")}
                  className="w-full bg-white/70 border border-white/80 rounded-2xl px-4 py-3 text-[14px] text-slate-800 placeholder:text-slate-400 outline-none backdrop-blur-xl"
                />
                <div className="mt-3 text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                  {t("habitGoal")}
                </div>
                <div className="mt-2 flex flex-wrap gap-1.5">
                  {GOALS.map((g) => (
                    <button
                      key={g.key}
                      onClick={() => setDraftGoal(g.key)}
                      className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border transition-all ${
                        draftGoal === g.key
                          ? "bg-indigo-500 text-white border-transparent"
                          : "bg-white/70 text-slate-600 border-white/80"
                      }`}
                    >
                      {g.emoji} {g.label}
                    </button>
                  ))}
                </div>
                <div className="mt-3 flex items-center justify-between">
                  <label className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("habitTarget")}
                  </label>
                  <div className="flex items-center gap-2">
                    {[1, 3, 5, 7].map((n) => (
                      <button
                        key={n}
                        onClick={() => setDraftTarget(n)}
                        className={`w-8 h-8 rounded-full text-[12px] font-bold border ${
                          draftTarget === n
                            ? "bg-indigo-500 text-white border-transparent"
                            : "bg-white/70 text-slate-600 border-white/80"
                        }`}
                      >
                        {n}
                      </button>
                    ))}
                  </div>
                </div>
                <div className="mt-4 flex gap-2">
                  <GlassButton variant="ghost" size="md" fullWidth onClick={() => setAdding(false)}>
                    {t("close")}
                  </GlassButton>
                  <GlassButton variant="primary" size="md" fullWidth onClick={addHabit}>
                    {t("addHabit")}
                  </GlassButton>
                </div>
              </GlassCard>
            </motion.div>
          )}
        </AnimatePresence>

        <div className="space-y-3">
          <AnimatePresence initial={false}>
            {habits.map((h, i) => {
              const done = h.history.includes(today);
              const pct = Math.min(1, h.completedThisWeek / h.targetPerWeek);
              return (
                <motion.div
                  key={h.id}
                  layout
                  initial={{ opacity: 0, y: 14 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, x: -40 }}
                  transition={{ duration: 0.35, delay: i * 0.03 }}
                >
                  <GlassCard tone="neutral" padded={false}>
                    <div className="flex items-center gap-3 p-4">
                      <motion.button
                        whileTap={{ scale: 0.9 }}
                        onClick={() => toggleToday(h)}
                        className={`shrink-0 w-12 h-12 rounded-2xl grid place-items-center text-xl transition-all ${
                          done
                            ? "bg-gradient-to-b from-emerald-500 to-teal-600 text-white shadow-[0_10px_20px_-8px_rgba(16,185,129,0.55)]"
                            : "bg-white/70 border border-white/80 text-slate-600"
                        }`}
                      >
                        {done ? <Check className="w-5 h-5" /> : <span>{h.emoji}</span>}
                      </motion.button>
                      <div className="flex-1 min-w-0">
                        <div className="text-[15px] font-bold text-slate-900 truncate">{h.title}</div>
                        <div className="text-[11px] text-slate-500 font-semibold uppercase tracking-wider">
                          {h.goal}
                        </div>
                        <div className="mt-2 h-1.5 rounded-full bg-white/60 overflow-hidden">
                          <motion.div
                            initial={{ width: 0 }}
                            animate={{ width: `${pct * 100}%` }}
                            transition={{ duration: 0.6 }}
                            className="h-full bg-gradient-to-r from-indigo-400 via-violet-500 to-fuchsia-500"
                          />
                        </div>
                        <div className="mt-1 text-[10px] text-slate-500">
                          {h.completedThisWeek}/{h.targetPerWeek} {t("days")}
                        </div>
                      </div>
                      <button
                        onClick={() => removeHabit(h.id)}
                        aria-label="Remove"
                        className="shrink-0 w-8 h-8 rounded-full bg-white/60 border border-white/70 grid place-items-center text-slate-400 hover:text-rose-500 hover:bg-white"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </GlassCard>
                </motion.div>
              );
            })}
          </AnimatePresence>
          {habits.length === 0 && !adding && (
            <p className="text-center text-[12px] text-slate-500 py-6">{t("startChatting")}</p>
          )}
        </div>
      </div>
    </div>
  );
}
