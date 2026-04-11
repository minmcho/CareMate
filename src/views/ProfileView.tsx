import { motion } from "motion/react";
import { ShieldCheck, Database, LogOut, Languages, Heart, Leaf, Activity, CircleOff } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { Language, WellnessGoal, WellnessProfile } from "../lib/types";
import { availableLanguages, useTranslation } from "../lib/i18n";

interface ProfileViewProps {
  lang: Language;
  profile: WellnessProfile;
  onProfileChange: (p: WellnessProfile) => void;
  onDeleteData: () => void;
  onLanguageChange: (lang: Language) => void;
}

const DIETS = [
  { key: "vegetarian", label: "Vegetarian" },
  { key: "vegan", label: "Vegan" },
  { key: "gluten-free", label: "Gluten-free" },
  { key: "low-sugar", label: "Low sugar" },
  { key: "halal", label: "Halal" },
  { key: "kosher", label: "Kosher" },
];

const GOALS: WellnessGoal[] = ["stress", "sleep", "nutrition", "movement", "mindfulness", "hydration"];

const COMFORTS = ["meditation", "walking", "yoga", "music", "nature"];
const AVOID = ["knee-stress", "back-stress", "high-impact", "caffeine"];

export default function ProfileView({
  lang,
  profile,
  onProfileChange,
  onDeleteData,
  onLanguageChange,
}: ProfileViewProps) {
  const t = useTranslation(lang);

  function toggle<T extends string>(list: T[], value: T): T[] {
    return list.includes(value) ? list.filter((v) => v !== value) : [...list, value];
  }

  return (
    <div className="px-5 pb-36 space-y-5">
      {/* Profile card */}
      <GlassCard
        tone="lilac"
        initial={{ opacity: 0, y: 14 }}
        animate={{ opacity: 1, y: 0 }}
      >
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-3xl bg-gradient-to-br from-indigo-500 via-violet-500 to-fuchsia-500 grid place-items-center text-white text-2xl font-bold shadow-[0_15px_30px_-10px_rgba(139,92,246,0.55)]">
            {profile.displayName.slice(0, 1).toUpperCase()}
          </div>
          <div className="flex-1 min-w-0">
            <input
              value={profile.displayName}
              onChange={(e) => onProfileChange({ ...profile, displayName: e.target.value })}
              className="w-full bg-transparent text-[22px] font-bold text-slate-900 tracking-tight outline-none"
            />
            <div className="text-[11px] text-slate-500 font-semibold">
              {t("accountId")}: {profile.id.slice(0, 8)}
            </div>
          </div>
        </div>
      </GlassCard>

      {/* Language */}
      <GlassCard tone="sky">
        <div className="flex items-center gap-2 mb-3">
          <Languages className="w-4 h-4 text-indigo-500" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("language")}
          </h3>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {availableLanguages.map((l) => (
            <button
              key={l.code}
              onClick={() => onLanguageChange(l.code)}
              className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border transition-all ${
                lang === l.code
                  ? "bg-indigo-500 text-white border-transparent"
                  : "bg-white/70 text-slate-600 border-white/80"
              }`}
            >
              {l.label}
            </button>
          ))}
        </div>
      </GlassCard>

      {/* Dietary */}
      <GlassCard tone="mint">
        <div className="flex items-center gap-2 mb-3">
          <Leaf className="w-4 h-4 text-emerald-600" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("dietary")}
          </h3>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {DIETS.map((d) => {
            const active = profile.dietaryPreferences.includes(d.key);
            return (
              <button
                key={d.key}
                onClick={() =>
                  onProfileChange({
                    ...profile,
                    dietaryPreferences: toggle(profile.dietaryPreferences, d.key),
                  })
                }
                className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border transition-all ${
                  active
                    ? "bg-emerald-500 text-white border-transparent"
                    : "bg-white/70 text-slate-600 border-white/80"
                }`}
              >
                {d.label}
              </button>
            );
          })}
        </div>
      </GlassCard>

      {/* Wellness goals */}
      <GlassCard tone="rose">
        <div className="flex items-center gap-2 mb-3">
          <Heart className="w-4 h-4 text-rose-500" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("wellnessGoals")}
          </h3>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {GOALS.map((g) => {
            const active = profile.wellnessGoals.includes(g);
            return (
              <button
                key={g}
                onClick={() =>
                  onProfileChange({
                    ...profile,
                    wellnessGoals: toggle(profile.wellnessGoals, g),
                  })
                }
                className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border capitalize transition-all ${
                  active
                    ? "bg-rose-500 text-white border-transparent"
                    : "bg-white/70 text-slate-600 border-white/80"
                }`}
              >
                {g}
              </button>
            );
          })}
        </div>
      </GlassCard>

      {/* Comforts */}
      <GlassCard tone="amber">
        <div className="flex items-center gap-2 mb-3">
          <Activity className="w-4 h-4 text-amber-600" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("comforts")}
          </h3>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {COMFORTS.map((c) => {
            const active = profile.comforts.includes(c);
            return (
              <button
                key={c}
                onClick={() =>
                  onProfileChange({ ...profile, comforts: toggle(profile.comforts, c) })
                }
                className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border capitalize transition-all ${
                  active
                    ? "bg-amber-500 text-white border-transparent"
                    : "bg-white/70 text-slate-600 border-white/80"
                }`}
              >
                {c}
              </button>
            );
          })}
        </div>
      </GlassCard>

      {/* Avoid */}
      <GlassCard tone="neutral">
        <div className="flex items-center gap-2 mb-3">
          <CircleOff className="w-4 h-4 text-slate-600" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("avoid")}
          </h3>
        </div>
        <div className="flex flex-wrap gap-1.5">
          {AVOID.map((a) => {
            const active = profile.avoid.includes(a);
            return (
              <button
                key={a}
                onClick={() =>
                  onProfileChange({ ...profile, avoid: toggle(profile.avoid, a) })
                }
                className={`px-3 py-1.5 rounded-full text-[12px] font-semibold border capitalize transition-all ${
                  active
                    ? "bg-slate-700 text-white border-transparent"
                    : "bg-white/70 text-slate-600 border-white/80"
                }`}
              >
                {a.replace(/-/g, " ")}
              </button>
            );
          })}
        </div>
      </GlassCard>

      {/* Privacy */}
      <GlassCard tone="neutral">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-emerald-500" />
          <h3 className="text-[13px] uppercase tracking-wider text-slate-500 font-semibold">
            {t("privacyTitle")}
          </h3>
        </div>
        <p className="text-[12px] text-slate-600 mt-2 leading-relaxed">{t("privacyBody")}</p>
        <div className="mt-3 flex items-center gap-2 text-[11px] font-semibold text-slate-500">
          <Database className="w-3.5 h-3.5" />
          {t("dataLocal")}
        </div>
        <div className="mt-3 flex gap-2">
          <GlassButton
            variant="ghost"
            size="sm"
            fullWidth
            onClick={() => {
              if (confirm(t("confirmDelete"))) onDeleteData();
            }}
            icon={<LogOut className="w-3.5 h-3.5" />}
          >
            {t("deleteData")}
          </GlassButton>
        </div>
      </GlassCard>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.2 }}
        className="text-center text-[10px] text-slate-400 leading-relaxed"
      >
        VitalPath AI · {t("wellnessNotMedicine")}
      </motion.div>
    </div>
  );
}
