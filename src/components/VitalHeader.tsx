import { motion } from "motion/react";
import { ShieldCheck, Sparkles } from "lucide-react";
import type { Language } from "../lib/types";
import { availableLanguages, useTranslation } from "../lib/i18n";

interface VitalHeaderProps {
  lang: Language;
  onLanguageChange: (lang: Language) => void;
  onlineFallback: "online" | "fallback";
}

export default function VitalHeader({ lang, onLanguageChange, onlineFallback }: VitalHeaderProps) {
  const t = useTranslation(lang);

  return (
    <header className="sticky top-0 z-20 px-5 pt-6 pb-3">
      <div className="relative flex items-center justify-between">
        {/* Logo cluster */}
        <motion.div
          initial={{ opacity: 0, y: -8 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="flex items-center gap-3"
        >
          <div className="relative w-10 h-10 rounded-2xl bg-gradient-to-br from-indigo-500 via-violet-500 to-fuchsia-500 grid place-items-center shadow-[0_10px_30px_-8px_rgba(139,92,246,0.55)]">
            <Sparkles className="w-5 h-5 text-white" />
            <div className="absolute inset-0 rounded-2xl border border-white/40" />
          </div>
          <div>
            <h1 className="text-[20px] font-bold tracking-tight bg-gradient-to-r from-indigo-700 to-violet-600 bg-clip-text text-transparent leading-none">
              {t("appName")}
            </h1>
            <p className="text-[11px] text-slate-500 font-medium mt-0.5">{t("tagline")}</p>
          </div>
        </motion.div>

        {/* Status + language */}
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/70 border border-white/80 backdrop-blur-xl shadow-sm">
            <span
              className={`w-1.5 h-1.5 rounded-full ${
                onlineFallback === "online" ? "bg-emerald-500" : "bg-amber-500"
              } animate-pulse`}
            />
            <span className="text-[10px] font-semibold text-slate-600">
              {onlineFallback === "online" ? t("online") : t("fallbackActive")}
            </span>
          </div>
          <select
            aria-label={t("language")}
            value={lang}
            onChange={(e) => onLanguageChange(e.target.value as Language)}
            className="appearance-none bg-white/70 border border-white/80 backdrop-blur-xl text-[11px] font-semibold text-slate-700 rounded-full px-3 py-1.5 pr-6 shadow-sm cursor-pointer"
          >
            {availableLanguages.map((l) => (
              <option key={l.code} value={l.code}>
                {l.flag}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Wellness-not-medicine ribbon */}
      <motion.div
        initial={{ opacity: 0, y: -4 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.1 }}
        className="mt-3 flex items-center gap-2 text-[11px] text-emerald-700 bg-emerald-50/70 border border-emerald-100 px-3 py-1.5 rounded-full w-fit backdrop-blur-xl"
      >
        <ShieldCheck className="w-3.5 h-3.5" />
        <span className="font-semibold">{t("wellnessNotMedicine")}</span>
      </motion.div>
    </header>
  );
}
