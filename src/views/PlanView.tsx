/**
 * Plan view — daily focus schedule, weekly calendar, and breathwork library.
 *
 * Plans are regenerated from the profile's wellness goals. Items mark as
 * complete inline and a progress ring surfaces today's momentum.
 */

import { useMemo, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Check, RefreshCw, Wind, Clock, ChevronRight } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type {
  BreathworkTechnique,
  DailyPlan,
  Language,
  PlanItem,
  WeeklyPlan,
  WellnessProfile,
} from "../lib/types";
import { useTranslation } from "../lib/i18n";
import {
  BREATHWORK_CATALOG,
  buildDailyPlan,
  buildWeeklyPlan,
  emojiForKind,
  labelForKind,
  labelForTime,
  planCompletion,
} from "../lib/plans";

interface PlanViewProps {
  lang: Language;
  profile: WellnessProfile;
  dailyPlan: DailyPlan | null;
  weeklyPlan: WeeklyPlan | null;
  onDailyPlanChange: (plan: DailyPlan) => void;
  onWeeklyPlanChange: (plan: WeeklyPlan) => void;
  onStartBreathwork: (technique: BreathworkTechnique) => void;
  onSessionLogged: (durationSec: number) => void;
}

type Mode = "daily" | "weekly" | "breathwork";

export default function PlanView({
  lang,
  profile,
  dailyPlan,
  weeklyPlan,
  onDailyPlanChange,
  onWeeklyPlanChange,
  onStartBreathwork,
  onSessionLogged,
}: PlanViewProps) {
  const t = useTranslation(lang);
  const [mode, setMode] = useState<Mode>("daily");

  const today = useMemo(() => {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }, []);

  const todayISO = toDateISO(today);

  // Lazy-generate if the stored plan is stale or missing.
  const effectiveDaily: DailyPlan = useMemo(() => {
    if (dailyPlan && dailyPlan.dateISO === todayISO) return dailyPlan;
    const fresh = buildDailyPlan(today, profile);
    onDailyPlanChange(fresh);
    return fresh;
  }, [dailyPlan, today, todayISO, profile, onDailyPlanChange]);

  const effectiveWeekly: WeeklyPlan = useMemo(() => {
    const monday = toDateISO(mondayOf(today));
    if (weeklyPlan && weeklyPlan.weekStartISO === monday) return weeklyPlan;
    const fresh = buildWeeklyPlan(today, profile);
    onWeeklyPlanChange(fresh);
    return fresh;
  }, [weeklyPlan, today, profile, onWeeklyPlanChange]);

  function toggleItem(item: PlanItem) {
    const updatedItems = effectiveDaily.items.map((i) =>
      i.id === item.id ? { ...i, completed: !i.completed } : i,
    );
    const next: DailyPlan = { ...effectiveDaily, items: updatedItems };
    onDailyPlanChange(next);
    if (!item.completed) {
      onSessionLogged(item.durationMin * 60);
    }
  }

  function regenerate() {
    if (mode === "weekly") {
      onWeeklyPlanChange(buildWeeklyPlan(today, profile));
    } else {
      onDailyPlanChange(buildDailyPlan(today, profile));
    }
  }

  const daily = effectiveDaily;
  const weekly = effectiveWeekly;
  const progress = planCompletion(daily);

  return (
    <div className="px-5 pb-36 space-y-5">
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
        className="flex items-end justify-between"
      >
        <div>
          <p className="text-[12px] uppercase tracking-widest text-slate-500 font-semibold">
            {t("plan")}
          </p>
          <h2 className="text-[26px] font-bold tracking-tight text-slate-900">
            {mode === "breathwork"
              ? t("breathwork")
              : mode === "weekly"
                ? t("weeklyPlan")
                : t("dailyPlan")}
          </h2>
        </div>
        {mode !== "breathwork" && (
          <button
            onClick={regenerate}
            className="flex items-center gap-1 text-[12px] font-semibold text-indigo-600 bg-white/70 border border-white/80 rounded-full px-3 py-1.5 shadow-sm"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            {t("regeneratePlan")}
          </button>
        )}
      </motion.div>

      {/* Mode switch */}
      <div className="grid grid-cols-3 gap-2 p-1 rounded-2xl bg-white/60 border border-white/70 backdrop-blur-xl">
        {(
          [
            { key: "daily", label: t("today") },
            { key: "weekly", label: t("week") },
            { key: "breathwork", label: t("breathwork") },
          ] as const
        ).map((o) => (
          <button
            key={o.key}
            onClick={() => setMode(o.key)}
            className={`py-2 rounded-xl text-[12px] font-bold transition-all ${
              mode === o.key
                ? "bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-md"
                : "text-slate-600"
            }`}
          >
            {o.label}
          </button>
        ))}
      </div>

      <AnimatePresence mode="wait">
        {mode === "daily" && (
          <motion.div
            key="daily"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="space-y-4"
          >
            {/* Progress ring */}
            <GlassCard tone="neutral">
              <div className="flex items-center gap-4">
                <ProgressRing pct={progress.pct} />
                <div className="flex-1">
                  <div className="text-[12px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("today")}
                  </div>
                  <div className="text-[18px] font-bold text-slate-900">
                    {progress.done}/{progress.total} complete
                  </div>
                  <p className="text-[12px] text-slate-500 mt-1">
                    {t("planFocus")}: {weekly.focus.map((g) => t(`${g}Tag` as never)).join(" · ")}
                  </p>
                </div>
              </div>
            </GlassCard>

            {/* Items */}
            {daily.items.length === 0 && (
              <p className="text-[13px] text-slate-400 text-center py-6">{t("planEmpty")}</p>
            )}
            <div className="space-y-3">
              {daily.items.map((item) => (
                <PlanItemRow
                  key={item.id}
                  item={item}
                  onToggle={() => toggleItem(item)}
                  onStartBreath={
                    item.techniqueId
                      ? () => {
                          const technique = BREATHWORK_CATALOG.find(
                            (tt) => tt.id === item.techniqueId,
                          );
                          if (technique) onStartBreathwork(technique);
                        }
                      : undefined
                  }
                  lang={lang}
                />
              ))}
            </div>
          </motion.div>
        )}

        {mode === "weekly" && (
          <motion.div
            key="weekly"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="space-y-3"
          >
            {weekly.days.map((day) => {
              const c = planCompletion(day);
              const isToday = day.dateISO === todayISO;
              return (
                <GlassCard key={day.id} tone={isToday ? "lilac" : "neutral"}>
                  <div className="flex items-center gap-3">
                    <DayBadge iso={day.dateISO} isToday={isToday} />
                    <div className="flex-1 min-w-0">
                      <div className="text-[14px] font-bold text-slate-900">
                        {formatWeekday(day.dateISO)}
                      </div>
                      <div className="text-[11px] text-slate-500">
                        {day.items.map((i) => emojiForKind(i.kind)).join("  ")}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-[11px] text-slate-500">{c.done}/{c.total}</div>
                      <div className="w-16 h-1.5 mt-1 rounded-full bg-slate-200 overflow-hidden">
                        <div
                          className="h-full bg-gradient-to-r from-indigo-500 to-violet-500"
                          style={{ width: `${c.pct}%` }}
                        />
                      </div>
                    </div>
                  </div>
                </GlassCard>
              );
            })}
          </motion.div>
        )}

        {mode === "breathwork" && (
          <motion.div
            key="breath"
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -8 }}
            className="space-y-3"
          >
            <p className="text-[12px] text-slate-500 px-1">{t("choosePattern")}</p>
            {BREATHWORK_CATALOG.map((tech) => (
              <GlassCard key={tech.id} tone="neutral">
                <div className="flex items-start gap-3">
                  <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-indigo-400 to-violet-500 grid place-items-center shadow-md">
                    <Wind className="w-5 h-5 text-white" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <h4 className="text-[15px] font-bold text-slate-900">{tech.name}</h4>
                      <span className="text-[10px] font-semibold text-indigo-600 bg-indigo-50 rounded-full px-2 py-0.5">
                        {tech.pattern.join("·")}
                      </span>
                    </div>
                    <p className="text-[12px] text-slate-500 mt-0.5">{tech.summary}</p>
                    <div className="flex flex-wrap gap-1 mt-2">
                      {tech.benefits.map((b) => (
                        <span
                          key={b}
                          className="text-[10px] font-semibold text-slate-600 bg-white/70 border border-white/80 rounded-full px-2 py-0.5"
                        >
                          {b}
                        </span>
                      ))}
                    </div>
                  </div>
                  <GlassButton
                    variant="primary"
                    size="sm"
                    onClick={() => onStartBreathwork(tech)}
                    icon={<ChevronRight className="w-4 h-4" />}
                  >
                    {t("startSession")}
                  </GlassButton>
                </div>
              </GlassCard>
            ))}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ----- subcomponents -------------------------------------------------------

function PlanItemRow({
  item,
  onToggle,
  onStartBreath,
  lang,
}: {
  key?: string | number;
  item: PlanItem;
  onToggle: () => void;
  onStartBreath?: () => void;
  lang: Language;
}) {
  const t = useTranslation(lang);
  return (
    <GlassCard tone={item.completed ? "mint" : "neutral"}>
      <div className="flex items-start gap-3">
        <button
          onClick={onToggle}
          aria-label={item.completed ? t("markIncomplete") : t("markComplete")}
          className={`w-9 h-9 shrink-0 rounded-full grid place-items-center border-2 transition-all ${
            item.completed
              ? "bg-emerald-500 border-emerald-500 text-white"
              : "bg-white border-slate-300 text-transparent"
          }`}
        >
          <Check className="w-4 h-4" />
        </button>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5">
            <span className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">
              {labelForTime(item.time)}
            </span>
            <span className="text-[10px] text-slate-400">·</span>
            <span className="text-[11px] font-semibold text-indigo-600">
              {emojiForKind(item.kind)} {labelForKind(item.kind)}
            </span>
          </div>
          <div
            className={`text-[15px] font-bold mt-0.5 ${
              item.completed ? "text-slate-400 line-through" : "text-slate-900"
            }`}
          >
            {item.title}
          </div>
          <p className="text-[12px] text-slate-500 mt-0.5">{item.summary}</p>
          <div className="flex items-center gap-3 mt-2">
            <span className="flex items-center gap-1 text-[11px] text-slate-400">
              <Clock className="w-3 h-3" /> {item.durationMin} min
            </span>
            {onStartBreath && (
              <button
                onClick={onStartBreath}
                className="text-[11px] font-bold text-indigo-600 flex items-center gap-0.5"
              >
                <Wind className="w-3 h-3" /> {t("startBreathwork")}
              </button>
            )}
          </div>
        </div>
      </div>
    </GlassCard>
  );
}

function ProgressRing({ pct }: { pct: number }) {
  const radius = 28;
  const circ = 2 * Math.PI * radius;
  const offset = circ * (1 - pct / 100);
  return (
    <div className="relative w-20 h-20 shrink-0">
      <svg viewBox="0 0 72 72" className="w-full h-full -rotate-90">
        <circle cx="36" cy="36" r={radius} className="stroke-slate-200" strokeWidth="6" fill="none" />
        <motion.circle
          cx="36"
          cy="36"
          r={radius}
          strokeWidth="6"
          fill="none"
          strokeLinecap="round"
          className="stroke-indigo-500"
          strokeDasharray={circ}
          animate={{ strokeDashoffset: offset }}
          transition={{ duration: 0.6, ease: "easeOut" }}
        />
      </svg>
      <div className="absolute inset-0 grid place-items-center text-[15px] font-bold text-slate-900">
        {pct}%
      </div>
    </div>
  );
}

function DayBadge({ iso, isToday }: { iso: string; isToday: boolean }) {
  const date = new Date(`${iso}T00:00:00`);
  const day = date.getDate();
  return (
    <div
      className={`w-12 h-12 rounded-2xl grid place-items-center font-bold shrink-0 border ${
        isToday
          ? "bg-gradient-to-b from-indigo-500 to-violet-600 text-white border-transparent shadow-md"
          : "bg-white/70 text-slate-700 border-white/80"
      }`}
    >
      <span className="text-[18px] leading-none">{day}</span>
    </div>
  );
}

// ----- helpers -------------------------------------------------------------

function toDateISO(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function mondayOf(date: Date): Date {
  const copy = new Date(date);
  const day = copy.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  copy.setDate(copy.getDate() + diff);
  copy.setHours(0, 0, 0, 0);
  return copy;
}

function formatWeekday(iso: string): string {
  const date = new Date(`${iso}T00:00:00`);
  return date.toLocaleDateString(undefined, { weekday: "long", month: "short", day: "numeric" });
}
