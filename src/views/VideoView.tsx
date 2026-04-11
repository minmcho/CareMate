import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Apple, Dumbbell, Loader2, Play, ShieldCheck, Sparkles, Square } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { Language, VideoAnalysis, WellnessProfile } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { analyseVideo } from "../lib/ai";
import { cn } from "../lib/utils";

interface VideoViewProps {
  lang: Language;
  profile: WellnessProfile;
  recent: VideoAnalysis[];
  onNewAnalysis: (analysis: VideoAnalysis) => void;
}

export default function VideoView({ lang, profile, recent, onNewAnalysis }: VideoViewProps) {
  const t = useTranslation(lang);
  const [mode, setMode] = useState<"meal" | "exercise">("meal");
  const [recording, setRecording] = useState(false);
  const [processing, setProcessing] = useState(false);
  const [current, setCurrent] = useState<VideoAnalysis | null>(recent[0] ?? null);

  async function runAnalysis() {
    setRecording(false);
    setProcessing(true);
    try {
      const analysis = await analyseVideo({
        mode,
        durationSec: 12,
        profile,
      });
      setCurrent(analysis);
      onNewAnalysis(analysis);
    } finally {
      setProcessing(false);
    }
  }

  return (
    <div className="px-5 pb-36 space-y-5">
      {/* Mode picker */}
      <div className="grid grid-cols-2 gap-3">
        {([
          { key: "meal", label: t("mealMode"), icon: <Apple className="w-5 h-5" />, tone: "mint" as const },
          { key: "exercise", label: t("exerciseMode"), icon: <Dumbbell className="w-5 h-5" />, tone: "sky" as const },
        ] as const).map((m) => (
          <motion.button
            key={m.key}
            whileTap={{ scale: 0.97 }}
            onClick={() => setMode(m.key)}
            className={cn(
              "relative p-4 rounded-[24px] border backdrop-blur-2xl transition-all text-left",
              mode === m.key
                ? "bg-gradient-to-b from-indigo-500 to-violet-600 text-white border-transparent shadow-[0_15px_30px_-10px_rgba(99,102,241,0.55)]"
                : "bg-white/60 border-white/70 text-slate-700",
            )}
          >
            <div
              className={cn(
                "w-10 h-10 rounded-xl grid place-items-center",
                mode === m.key ? "bg-white/20" : "bg-white/70 border border-white/80",
              )}
            >
              {m.icon}
            </div>
            <div className="mt-3 text-[14px] font-bold tracking-tight">{m.label}</div>
            <div className={cn("text-[11px] mt-0.5", mode === m.key ? "text-white/80" : "text-slate-500")}>
              {m.key === "meal" ? "Qwen 3.5 VL" : "Form coach"}
            </div>
          </motion.button>
        ))}
      </div>

      {/* Camera preview */}
      <GlassCard tone="neutral" padded={false} className="overflow-hidden">
        <div className="relative aspect-[4/5] bg-gradient-to-br from-slate-800 via-slate-900 to-black">
          {/* Simulated camera feed */}
          <motion.div
            initial={{ opacity: 0.2 }}
            animate={{ opacity: [0.2, 0.4, 0.25] }}
            transition={{ duration: 6, repeat: Infinity }}
            className="absolute inset-0 bg-[radial-gradient(circle_at_30%_20%,rgba(139,92,246,0.35),transparent_60%),radial-gradient(circle_at_70%_80%,rgba(236,72,153,0.3),transparent_55%)]"
          />
          <div className="absolute inset-4 rounded-[22px] border border-white/20" />
          <div className="absolute inset-8 rounded-[18px] border border-white/10" />

          {/* Focus reticle */}
          <motion.div
            animate={{ scale: [1, 1.08, 1] }}
            transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-48 h-48 rounded-3xl border-2 border-white/40"
          />

          {/* Recording chip */}
          {recording && (
            <div className="absolute top-4 left-4 flex items-center gap-2 px-3 py-1.5 rounded-full bg-rose-500/90 backdrop-blur-xl text-white text-[11px] font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
              {t("recording")}
            </div>
          )}

          {/* Overlay cards when analysing */}
          <AnimatePresence>
            {processing && (
              <motion.div
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                exit={{ opacity: 0 }}
                className="absolute inset-0 grid place-items-center bg-black/50 backdrop-blur-sm"
              >
                <div className="flex flex-col items-center gap-2 text-white">
                  <Loader2 className="w-6 h-6 animate-spin" />
                  <div className="text-[13px] font-semibold">{t("analyzing")}</div>
                </div>
              </motion.div>
            )}
          </AnimatePresence>

          {/* Simulated hint */}
          <div className="absolute bottom-3 inset-x-3 text-center text-[10px] text-white/60">
            {t("cameraUnavailable")}
          </div>
        </div>

        {/* Controls */}
        <div className="flex items-center justify-center gap-3 p-4">
          {!recording && !processing && (
            <GlassButton variant="primary" size="lg" onClick={() => setRecording(true)} icon={<Play className="w-4 h-4" />}>
              {mode === "meal" ? t("recordMeal") : t("recordExercise")}
            </GlassButton>
          )}
          {recording && (
            <GlassButton variant="danger" size="lg" onClick={runAnalysis} icon={<Square className="w-4 h-4" />}>
              {t("analyze")}
            </GlassButton>
          )}
          {processing && (
            <GlassButton variant="ghost" size="lg" disabled icon={<Loader2 className="w-4 h-4 animate-spin" />}>
              {t("analyzing")}
            </GlassButton>
          )}
        </div>
      </GlassCard>

      {/* Analysis result */}
      <AnimatePresence mode="popLayout">
        {current ? (
          <motion.div
            key={current.id}
            initial={{ opacity: 0, y: 18 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -10 }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
          >
            <GlassCard tone={current.mode === "meal" ? "mint" : "sky"}>
              <div className="flex items-start justify-between">
                <div>
                  <div className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("analysisReady")}
                  </div>
                  <div className="text-[20px] font-bold text-slate-900 tracking-tight mt-0.5">
                    {current.mode === "meal" ? t("mealMode") : t("exerciseMode")}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <div className="text-[10px] font-semibold uppercase text-emerald-700 bg-emerald-50 border border-emerald-100 rounded-full px-2.5 py-1 flex items-center gap-1">
                    <ShieldCheck className="w-3 h-3" /> Wellness-safe
                  </div>
                </div>
              </div>

              {/* Score bar */}
              <div className="mt-4">
                <div className="flex items-center justify-between text-[11px] font-semibold text-slate-500">
                  <span>{t("wellnessScore")}</span>
                  <span>{current.score}/100</span>
                </div>
                <div className="h-2 mt-1.5 rounded-full bg-white/60 overflow-hidden">
                  <motion.div
                    initial={{ width: 0 }}
                    animate={{ width: `${current.score}%` }}
                    transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
                    className="h-full bg-gradient-to-r from-emerald-400 via-teal-400 to-sky-400"
                  />
                </div>
              </div>

              {/* Nutrition or form */}
              {current.mode === "meal" && current.nutritionEstimate && (
                <div className="mt-4">
                  <div className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("nutritionEstimate")}
                  </div>
                  <p className="text-[14px] text-slate-800 mt-1">{current.nutritionEstimate}</p>
                </div>
              )}
              {current.mode === "exercise" && current.formNotes && (
                <div className="mt-4">
                  <div className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("formNotes")}
                  </div>
                  <ul className="mt-1 space-y-1">
                    {current.formNotes.map((n, i) => (
                      <li key={i} className="text-[13px] text-slate-800 flex gap-2">
                        <span className="text-indigo-500">•</span>
                        {n}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Highlights */}
              {current.highlights.length > 0 && (
                <div className="mt-4">
                  <div className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold flex items-center gap-1.5">
                    <Sparkles className="w-3 h-3" /> {t("highlights")}
                  </div>
                  <ul className="mt-1 space-y-1">
                    {current.highlights.map((h, i) => (
                      <li key={i} className="text-[13px] text-slate-800 flex gap-2">
                        <span className="text-emerald-500">✓</span>
                        {h}
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {/* Cautions */}
              {current.cautions.length > 0 && (
                <div className="mt-4">
                  <div className="text-[11px] uppercase tracking-wider text-slate-500 font-semibold">
                    {t("cautions")}
                  </div>
                  <ul className="mt-1 space-y-1">
                    {current.cautions.map((c, i) => (
                      <li key={i} className="text-[13px] text-slate-800 flex gap-2">
                        <span className="text-amber-500">!</span>
                        {c}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </GlassCard>
          </motion.div>
        ) : (
          <motion.p
            key="empty"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="text-center text-[12px] text-slate-500 py-6"
          >
            {t("noAnalysisYet")}
          </motion.p>
        )}
      </AnimatePresence>
    </div>
  );
}
