import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ArrowRight, Sparkles, ShieldCheck, Heart } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { Language, WellnessGoal, WellnessProfile } from "../lib/types";
import { availableLanguages, useTranslation } from "../lib/i18n";
import { newId } from "../lib/storage";

interface OnboardingViewProps {
  lang: Language;
  onLanguageChange: (l: Language) => void;
  onComplete: (profile: WellnessProfile) => void;
}

const GOALS: { key: WellnessGoal; label: string; emoji: string }[] = [
  { key: "stress", label: "Stress", emoji: "🌿" },
  { key: "sleep", label: "Sleep", emoji: "🌙" },
  { key: "nutrition", label: "Nutrition", emoji: "🥗" },
  { key: "movement", label: "Movement", emoji: "🏃" },
  { key: "mindfulness", label: "Mindfulness", emoji: "🧘" },
  { key: "hydration", label: "Hydration", emoji: "💧" },
];

export default function OnboardingView({ lang, onLanguageChange, onComplete }: OnboardingViewProps) {
  const t = useTranslation(lang);
  const [step, setStep] = useState(0);
  const [name, setName] = useState("");
  const [goals, setGoals] = useState<WellnessGoal[]>(["mindfulness", "movement"]);

  function toggleGoal(g: WellnessGoal) {
    setGoals((prev) => (prev.includes(g) ? prev.filter((x) => x !== g) : [...prev, g]));
  }

  function finish() {
    const profile: WellnessProfile = {
      id: newId(),
      displayName: name.trim() || "Friend",
      preferredLanguage: lang,
      dietaryPreferences: [],
      wellnessGoals: goals,
      comforts: ["meditation", "walking"],
      avoid: [],
      streakDays: 0,
      streakFreezeAvailable: true,
      createdAtISO: new Date().toISOString(),
    };
    onComplete(profile);
  }

  return (
    <div className="min-h-screen flex flex-col px-6 pt-14 pb-8">
      <div className="flex items-center gap-3 mb-8">
        <div className="relative w-12 h-12 rounded-3xl bg-gradient-to-br from-indigo-500 via-violet-500 to-fuchsia-500 grid place-items-center shadow-[0_15px_30px_-10px_rgba(139,92,246,0.55)]">
          <Sparkles className="w-6 h-6 text-white" />
        </div>
        <div>
          <h1 className="text-[22px] font-bold bg-gradient-to-r from-indigo-700 to-violet-600 bg-clip-text text-transparent tracking-tight leading-none">
            {t("appName")}
          </h1>
          <p className="text-[12px] text-slate-500 font-medium mt-1">{t("tagline")}</p>
        </div>
      </div>

      <AnimatePresence mode="wait">
        {step === 0 && (
          <motion.div
            key="welcome"
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.45, ease: [0.22, 1, 0.36, 1] }}
            className="flex-1 flex flex-col"
          >
            <h2 className="text-[32px] font-bold tracking-tight text-slate-900 leading-tight">
              {t("onboardTitle")}
            </h2>
            <p className="text-[15px] text-slate-600 mt-3 leading-relaxed">{t("onboardSubtitle")}</p>

            <div className="mt-8 space-y-3">
              <GlassCard tone="mint" padded={false}>
                <div className="flex items-center gap-3 p-4">
                  <div className="w-10 h-10 rounded-2xl bg-emerald-100 grid place-items-center">
                    <ShieldCheck className="w-5 h-5 text-emerald-600" />
                  </div>
                  <div>
                    <div className="text-[14px] font-bold text-slate-900">
                      {t("wellnessNotMedicine")}
                    </div>
                    <div className="text-[12px] text-slate-500">
                      Safe, boundary-aware AI guidance
                    </div>
                  </div>
                </div>
              </GlassCard>
              <GlassCard tone="rose" padded={false}>
                <div className="flex items-center gap-3 p-4">
                  <div className="w-10 h-10 rounded-2xl bg-rose-100 grid place-items-center">
                    <Heart className="w-5 h-5 text-rose-600" />
                  </div>
                  <div>
                    <div className="text-[14px] font-bold text-slate-900">Gentle habits</div>
                    <div className="text-[12px] text-slate-500">Streaks that care, not pressure</div>
                  </div>
                </div>
              </GlassCard>
              <GlassCard tone="sky" padded={false}>
                <div className="flex items-center gap-3 p-4">
                  <div className="w-10 h-10 rounded-2xl bg-sky-100 grid place-items-center">
                    <Sparkles className="w-5 h-5 text-sky-600" />
                  </div>
                  <div>
                    <div className="text-[14px] font-bold text-slate-900">Multi-modal coach</div>
                    <div className="text-[12px] text-slate-500">
                      Chat, voice, meal &amp; movement video
                    </div>
                  </div>
                </div>
              </GlassCard>
            </div>

            <div className="mt-auto space-y-3">
              <div className="flex flex-wrap gap-1.5 justify-center">
                {availableLanguages.map((l) => (
                  <button
                    key={l.code}
                    onClick={() => onLanguageChange(l.code)}
                    className={`px-3 py-1.5 rounded-full text-[11px] font-semibold border transition-all ${
                      lang === l.code
                        ? "bg-indigo-500 text-white border-transparent"
                        : "bg-white/60 text-slate-600 border-white/80"
                    }`}
                  >
                    {l.label}
                  </button>
                ))}
              </div>
              <GlassButton
                variant="primary"
                size="lg"
                fullWidth
                onClick={() => setStep(1)}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                {t("onboardCTA")}
              </GlassButton>
            </div>
          </motion.div>
        )}

        {step === 1 && (
          <motion.div
            key="name"
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -30 }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
            className="flex-1 flex flex-col"
          >
            <h2 className="text-[28px] font-bold tracking-tight text-slate-900">
              {t("namePrompt")}
            </h2>
            <p className="text-[13px] text-slate-500 mt-2">{t("privacyBody")}</p>
            <div className="mt-6">
              <input
                autoFocus
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Alex"
                className="w-full bg-white/70 border border-white/80 rounded-2xl px-5 py-4 text-[18px] text-slate-900 outline-none backdrop-blur-xl"
              />
            </div>
            <div className="mt-auto">
              <GlassButton
                variant="primary"
                size="lg"
                fullWidth
                onClick={() => setStep(2)}
                icon={<ArrowRight className="w-4 h-4" />}
              >
                {t("continue")}
              </GlassButton>
            </div>
          </motion.div>
        )}

        {step === 2 && (
          <motion.div
            key="goals"
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -30 }}
            transition={{ duration: 0.4, ease: [0.22, 1, 0.36, 1] }}
            className="flex-1 flex flex-col"
          >
            <h2 className="text-[28px] font-bold tracking-tight text-slate-900">{t("wellnessGoals")}</h2>
            <p className="text-[13px] text-slate-500 mt-2">Pick the focus areas that resonate.</p>
            <div className="mt-6 grid grid-cols-2 gap-3">
              {GOALS.map((g) => {
                const active = goals.includes(g.key);
                return (
                  <motion.button
                    key={g.key}
                    whileTap={{ scale: 0.96 }}
                    onClick={() => toggleGoal(g.key)}
                    className={`p-4 rounded-3xl border text-left transition-all ${
                      active
                        ? "bg-gradient-to-b from-indigo-500 to-violet-600 text-white border-transparent shadow-[0_15px_30px_-10px_rgba(99,102,241,0.55)]"
                        : "bg-white/60 border-white/80 text-slate-700"
                    }`}
                  >
                    <div className="text-2xl">{g.emoji}</div>
                    <div className="mt-2 text-[14px] font-bold">{g.label}</div>
                  </motion.button>
                );
              })}
            </div>
            <div className="mt-auto">
              <GlassButton variant="primary" size="lg" fullWidth onClick={finish}>
                {t("continue")}
              </GlassButton>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
