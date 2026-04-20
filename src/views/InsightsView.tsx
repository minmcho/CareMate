/**
 * Insights view — AI-generated weekly insights, sleep analytics,
 * mood patterns, and social challenges in one dashboard.
 */

import { useMemo, useState } from "react";
import { motion } from "motion/react";
import {
  Moon,
  Brain,
  TrendingUp,
  Trophy,
  Sparkles,
  Clock,
  Zap,
  Plus,
  ChevronRight,
  Users,
} from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type {
  Challenge,
  Language,
  MoodEntry,
  SleepLog,
  WeeklyInsight,
  WellnessProfile,
} from "../lib/types";
import { MOOD_TAGS } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { newId } from "../lib/storage";

interface InsightsViewProps {
  lang: Language;
  profile: WellnessProfile;
  sleepLogs: SleepLog[];
  moodEntries: MoodEntry[];
  insights: WeeklyInsight[];
  challenges: Challenge[];
  onSleepLogsChange: (logs: SleepLog[]) => void;
  onMoodEntriesChange: (entries: MoodEntry[]) => void;
  onChallengesChange: (challenges: Challenge[]) => void;
}

type Tab = "overview" | "sleep" | "mood" | "challenges";

export default function InsightsView({
  lang,
  profile,
  sleepLogs,
  moodEntries,
  insights,
  challenges,
  onSleepLogsChange,
  onMoodEntriesChange,
  onChallengesChange,
}: InsightsViewProps) {
  const t = useTranslation(lang);
  const [activeTab, setActiveTab] = useState<Tab>("overview");
  const [showSleepForm, setShowSleepForm] = useState(false);
  const [showMoodForm, setShowMoodForm] = useState(false);

  const [sleepDuration, setSleepDuration] = useState("7");
  const [sleepDeep, setSleepDeep] = useState("1.5");
  const [sleepRem, setSleepRem] = useState("2");

  const [moodScore, setMoodScore] = useState(3);
  const [moodEnergy, setMoodEnergy] = useState(3);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);

  const sleepAvg = useMemo(() => {
    if (sleepLogs.length === 0) return 0;
    return Math.round(sleepLogs.reduce((a, b) => a + b.durationMin, 0) / sleepLogs.length);
  }, [sleepLogs]);

  const sleepQualityAvg = useMemo(() => {
    if (sleepLogs.length === 0) return 0;
    return Math.round(sleepLogs.reduce((a, b) => a + b.qualityScore, 0) / sleepLogs.length);
  }, [sleepLogs]);

  const moodAvg = useMemo(() => {
    if (moodEntries.length === 0) return 0;
    return +(moodEntries.reduce((a, b) => a + b.score, 0) / moodEntries.length).toFixed(1);
  }, [moodEntries]);

  function logSleep() {
    const dur = Math.round(parseFloat(sleepDuration) * 60);
    const deep = Math.round(parseFloat(sleepDeep) * 60);
    const rem = Math.round(parseFloat(sleepRem) * 60);
    const light = Math.max(0, dur - deep - rem);
    const quality = computeQuality(dur, deep, rem, 0);
    const log: SleepLog = {
      id: newId(),
      dateISO: new Date().toISOString().slice(0, 10),
      durationMin: dur,
      qualityScore: quality,
      deepMin: deep,
      remMin: rem,
      lightMin: light,
      awakeMin: 0,
      source: "manual",
      notes: "",
      createdAtISO: new Date().toISOString(),
    };
    onSleepLogsChange([log, ...sleepLogs].slice(0, 90));
    setShowSleepForm(false);
  }

  function logMood() {
    const entry: MoodEntry = {
      id: newId(),
      score: moodScore,
      energy: moodEnergy,
      tags: selectedTags,
      note: "",
      createdAtISO: new Date().toISOString(),
    };
    onMoodEntriesChange([entry, ...moodEntries].slice(0, 200));
    setShowMoodForm(false);
    setSelectedTags([]);
  }

  function toggleChallenge(id: string) {
    onChallengesChange(
      challenges.map((c) =>
        c.id === id ? { ...c, joined: !c.joined } : c,
      ),
    );
  }

  const latestInsight = insights[0] ?? null;
  const moodEmojis = ["😔", "😕", "🙂", "😊", "😄"];

  return (
    <div className="px-5 pb-36 space-y-5">
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4 }}
      >
        <p className="text-[12px] uppercase tracking-widest text-slate-500 font-semibold">
          {t("insights")}
        </p>
        <h2 className="text-[26px] font-bold tracking-tight text-slate-900">
          {t("weeklyInsights")}
        </h2>
      </motion.div>

      {/* Tab switch */}
      <div className="grid grid-cols-4 gap-1 p-1 rounded-2xl bg-white/60 border border-white/70 backdrop-blur-xl">
        {(
          [
            { key: "overview" as Tab, label: "Overview", icon: <Sparkles className="w-3.5 h-3.5" /> },
            { key: "sleep" as Tab, label: t("sleep"), icon: <Moon className="w-3.5 h-3.5" /> },
            { key: "mood" as Tab, label: t("mood"), icon: <Brain className="w-3.5 h-3.5" /> },
            { key: "challenges" as Tab, label: t("challengesTitle"), icon: <Trophy className="w-3.5 h-3.5" /> },
          ]
        ).map((o) => (
          <button
            key={o.key}
            onClick={() => setActiveTab(o.key)}
            className={`py-2 rounded-xl text-[11px] font-bold transition-all flex items-center justify-center gap-1 ${
              activeTab === o.key
                ? "bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-md"
                : "text-slate-600"
            }`}
          >
            {o.icon}
            {o.label}
          </button>
        ))}
      </div>

      {/* Overview */}
      {activeTab === "overview" && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
          {/* Quick stats */}
          <div className="grid grid-cols-3 gap-3">
            <GlassCard tone="lilac">
              <div className="text-center">
                <Moon className="w-5 h-5 mx-auto text-indigo-500 mb-1" />
                <div className="text-[20px] font-bold text-slate-900">{sleepAvg ? `${Math.floor(sleepAvg / 60)}h${sleepAvg % 60 > 0 ? ` ${sleepAvg % 60}m` : ""}` : "—"}</div>
                <div className="text-[10px] text-slate-500">{t("sleepDuration")}</div>
              </div>
            </GlassCard>
            <GlassCard tone="mint">
              <div className="text-center">
                <Brain className="w-5 h-5 mx-auto text-emerald-500 mb-1" />
                <div className="text-[20px] font-bold text-slate-900">{moodAvg || "—"}</div>
                <div className="text-[10px] text-slate-500">{t("mood")}</div>
              </div>
            </GlassCard>
            <GlassCard tone="amber">
              <div className="text-center">
                <TrendingUp className="w-5 h-5 mx-auto text-amber-500 mb-1" />
                <div className="text-[20px] font-bold text-slate-900">{sleepQualityAvg || "—"}%</div>
                <div className="text-[10px] text-slate-500">{t("sleepQuality")}</div>
              </div>
            </GlassCard>
          </div>

          {/* AI Insight */}
          {latestInsight && (
            <GlassCard tone="sky">
              <div className="flex items-start gap-3">
                <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-indigo-400 to-violet-500 grid place-items-center">
                  <Sparkles className="w-4 h-4 text-white" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <span className="text-[13px] font-bold text-slate-900">{t("aiPowered")}</span>
                    <span className="text-[9px] font-bold text-indigo-600 bg-indigo-50 rounded-full px-2 py-0.5">
                      {latestInsight.agent}
                    </span>
                  </div>
                  <p className="text-[12px] text-slate-600 mt-1">{latestInsight.summary}</p>
                  {latestInsight.suggestions.length > 0 && (
                    <div className="flex flex-wrap gap-1 mt-2">
                      {latestInsight.suggestions.map((s, i) => (
                        <span key={i} className="text-[10px] font-semibold text-slate-600 bg-white/70 border border-white/80 rounded-full px-2 py-0.5">
                          {s}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
              </div>
            </GlassCard>
          )}

          {/* Quick actions */}
          <div className="grid grid-cols-2 gap-3">
            <GlassButton variant="primary" size="sm" onClick={() => { setActiveTab("sleep"); setShowSleepForm(true); }} icon={<Moon className="w-4 h-4" />}>
              {t("logSleep")}
            </GlassButton>
            <GlassButton variant="primary" size="sm" onClick={() => { setActiveTab("mood"); setShowMoodForm(true); }} icon={<Brain className="w-4 h-4" />}>
              {t("logMood")}
            </GlassButton>
          </div>
        </motion.div>
      )}

      {/* Sleep tab */}
      {activeTab === "sleep" && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-[16px] font-bold text-slate-900">{t("sleepLog")}</h3>
            <GlassButton variant="primary" size="sm" onClick={() => setShowSleepForm(!showSleepForm)} icon={<Plus className="w-3.5 h-3.5" />}>
              {t("logSleep")}
            </GlassButton>
          </div>

          {showSleepForm && (
            <GlassCard tone="lilac">
              <div className="space-y-3">
                <div>
                  <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">{t("sleepDuration")} (hours)</label>
                  <input type="number" step="0.5" min="0" max="16" value={sleepDuration} onChange={(e) => setSleepDuration(e.target.value)}
                    className="w-full mt-1 px-3 py-2 rounded-xl bg-white/70 border border-white/80 text-[14px] text-slate-900"
                  />
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">{t("deepSleep")} (h)</label>
                    <input type="number" step="0.5" min="0" max="8" value={sleepDeep} onChange={(e) => setSleepDeep(e.target.value)}
                      className="w-full mt-1 px-3 py-2 rounded-xl bg-white/70 border border-white/80 text-[14px] text-slate-900"
                    />
                  </div>
                  <div>
                    <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">{t("remSleep")} (h)</label>
                    <input type="number" step="0.5" min="0" max="8" value={sleepRem} onChange={(e) => setSleepRem(e.target.value)}
                      className="w-full mt-1 px-3 py-2 rounded-xl bg-white/70 border border-white/80 text-[14px] text-slate-900"
                    />
                  </div>
                </div>
                <GlassButton variant="primary" size="sm" onClick={logSleep} icon={<Moon className="w-4 h-4" />}>
                  {t("save")}
                </GlassButton>
              </div>
            </GlassCard>
          )}

          {sleepLogs.length === 0 ? (
            <p className="text-[13px] text-slate-400 text-center py-6">{t("sleepEmpty")}</p>
          ) : (
            <div className="space-y-3">
              {sleepLogs.slice(0, 14).map((log) => (
                <GlassCard key={log.id} tone="neutral">
                  <div className="flex items-center gap-3">
                    <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-indigo-400 to-violet-500 grid place-items-center">
                      <Moon className="w-5 h-5 text-white" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="text-[14px] font-bold text-slate-900">{log.dateISO}</div>
                      <div className="flex items-center gap-3 mt-0.5">
                        <span className="flex items-center gap-1 text-[11px] text-slate-500">
                          <Clock className="w-3 h-3" /> {Math.floor(log.durationMin / 60)}h {log.durationMin % 60}m
                        </span>
                        {log.deepMin > 0 && (
                          <span className="text-[10px] text-indigo-600 bg-indigo-50 rounded-full px-2 py-0.5">
                            Deep: {Math.floor(log.deepMin / 60)}h{log.deepMin % 60 > 0 ? ` ${log.deepMin % 60}m` : ""}
                          </span>
                        )}
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-[18px] font-bold text-slate-900">{log.qualityScore}%</div>
                      <div className="text-[10px] text-slate-500">{t("sleepQuality")}</div>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          )}
        </motion.div>
      )}

      {/* Mood tab */}
      {activeTab === "mood" && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-[16px] font-bold text-slate-900">{t("moodCheckIn")}</h3>
            <GlassButton variant="primary" size="sm" onClick={() => setShowMoodForm(!showMoodForm)} icon={<Plus className="w-3.5 h-3.5" />}>
              {t("logMood")}
            </GlassButton>
          </div>

          {showMoodForm && (
            <GlassCard tone="mint">
              <div className="space-y-4">
                <div>
                  <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">{t("mood")}</label>
                  <div className="flex justify-between mt-2">
                    {moodEmojis.map((emoji, i) => (
                      <button key={i} onClick={() => setMoodScore(i + 1)}
                        className={`text-[28px] p-2 rounded-xl transition-all ${moodScore === i + 1 ? "bg-indigo-100 scale-110" : ""}`}>
                        {emoji}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">{t("energy")}</label>
                  <div className="flex justify-between mt-2">
                    {["⚡", "⚡⚡", "⚡⚡⚡"].map((e, i) => (
                      <button key={i} onClick={() => setMoodEnergy(i + 2)}
                        className={`text-[16px] px-3 py-1.5 rounded-xl transition-all ${moodEnergy === i + 2 ? "bg-amber-100 font-bold" : "text-slate-400"}`}>
                        {e}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <label className="text-[11px] font-semibold text-slate-500 uppercase tracking-wider">Tags</label>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {MOOD_TAGS.map((tag) => (
                      <button key={tag} onClick={() => setSelectedTags((prev) => prev.includes(tag) ? prev.filter((t) => t !== tag) : [...prev, tag])}
                        className={`text-[10px] font-semibold rounded-full px-2.5 py-1 transition-all ${selectedTags.includes(tag) ? "bg-indigo-500 text-white" : "bg-white/70 text-slate-600 border border-white/80"}`}>
                        {tag}
                      </button>
                    ))}
                  </div>
                </div>
                <GlassButton variant="primary" size="sm" onClick={logMood} icon={<Brain className="w-4 h-4" />}>
                  {t("save")}
                </GlassButton>
              </div>
            </GlassCard>
          )}

          {moodEntries.length === 0 ? (
            <p className="text-[13px] text-slate-400 text-center py-6">{t("moodEmpty")}</p>
          ) : (
            <div className="space-y-3">
              {moodEntries.slice(0, 20).map((entry) => (
                <GlassCard key={entry.id} tone="neutral">
                  <div className="flex items-center gap-3">
                    <span className="text-[28px]">{moodEmojis[entry.score - 1] ?? "🙂"}</span>
                    <div className="flex-1 min-w-0">
                      <div className="text-[13px] font-bold text-slate-900">
                        {new Date(entry.createdAtISO).toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                      </div>
                      {entry.tags.length > 0 && (
                        <div className="flex flex-wrap gap-1 mt-1">
                          {entry.tags.map((tag) => (
                            <span key={tag} className="text-[9px] font-semibold text-slate-600 bg-white/70 border border-white/80 rounded-full px-2 py-0.5">{tag}</span>
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="flex items-center gap-1">
                      <Zap className="w-3 h-3 text-amber-500" />
                      <span className="text-[12px] font-bold text-slate-700">{entry.energy}</span>
                    </div>
                  </div>
                </GlassCard>
              ))}
            </div>
          )}
        </motion.div>
      )}

      {/* Challenges tab */}
      {activeTab === "challenges" && (
        <motion.div initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="space-y-4">
          <h3 className="text-[16px] font-bold text-slate-900">{t("challengesTitle")}</h3>
          {challenges.length === 0 ? (
            <p className="text-[13px] text-slate-400 text-center py-6">No active challenges.</p>
          ) : (
            <div className="space-y-3">
              {challenges.map((ch) => (
                <GlassCard key={ch.id} tone={ch.joined ? "mint" : "neutral"}>
                  <div className="flex items-start gap-3">
                    <div className="w-11 h-11 rounded-2xl bg-gradient-to-br from-amber-400 to-orange-500 grid place-items-center text-[20px] shadow-md">
                      {ch.icon}
                    </div>
                    <div className="flex-1 min-w-0">
                      <h4 className="text-[15px] font-bold text-slate-900">{ch.title}</h4>
                      <p className="text-[12px] text-slate-500 mt-0.5">{ch.description}</p>
                      <div className="flex items-center gap-3 mt-2">
                        <span className="flex items-center gap-1 text-[10px] text-slate-500">
                          <Users className="w-3 h-3" /> {ch.participantCount} {t("participants")}
                        </span>
                        <span className="text-[10px] text-slate-500">{ch.targetDays} days</span>
                      </div>
                      {ch.joined && (
                        <div className="mt-2">
                          <div className="w-full h-1.5 rounded-full bg-slate-200 overflow-hidden">
                            <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-500"
                              style={{ width: `${Math.min((ch.progressDays / ch.targetDays) * 100, 100)}%` }} />
                          </div>
                          <div className="text-[10px] text-slate-500 mt-1">{ch.progressDays}/{ch.targetDays} {t("daysCompleted")}</div>
                        </div>
                      )}
                    </div>
                    <GlassButton
                      variant={ch.joined ? "tinted" : "primary"}
                      size="sm"
                      onClick={() => toggleChallenge(ch.id)}
                      icon={<ChevronRight className="w-4 h-4" />}
                    >
                      {ch.joined ? "Joined" : t("joinChallenge")}
                    </GlassButton>
                  </div>
                </GlassCard>
              ))}
            </div>
          )}
        </motion.div>
      )}
    </div>
  );
}

function computeQuality(dur: number, deep: number, rem: number, awake: number): number {
  let score = 0;
  if (dur >= 420 && dur <= 540) score += 40;
  else if (dur >= 360 || dur <= 600) score += 25;
  else if (dur > 0) score += 10;
  if (dur > 0 && deep > 0) {
    const p = deep / dur;
    score += p >= 0.15 ? 20 : p >= 0.10 ? 12 : 5;
  }
  if (dur > 0 && rem > 0) {
    const p = rem / dur;
    score += p >= 0.20 ? 20 : p >= 0.12 ? 12 : 5;
  }
  if (awake <= 15) score += 20;
  else if (awake <= 30) score += 10;
  else score += 3;
  return Math.min(score, 100);
}
