import { motion, AnimatePresence } from "motion/react";
import { Phone, MessageSquareHeart, X, LifeBuoy } from "lucide-react";
import { crisisResources, useTranslation } from "../lib/i18n";
import type { Language } from "../lib/types";
import GlassButton from "./GlassButton";

interface CrisisModalProps {
  open: boolean;
  lang: Language;
  onClose: () => void;
  onBreathing: () => void;
}

export default function CrisisModal({ open, lang, onClose, onBreathing }: CrisisModalProps) {
  const t = useTranslation(lang);
  const resources = crisisResources[lang] ?? crisisResources.en;

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          key="overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.25 }}
          className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-md grid place-items-center p-6"
          role="dialog"
          aria-modal="true"
        >
          <motion.div
            initial={{ y: 30, scale: 0.96, opacity: 0 }}
            animate={{ y: 0, scale: 1, opacity: 1 }}
            exit={{ y: 20, scale: 0.98, opacity: 0 }}
            transition={{ type: "spring", stiffness: 260, damping: 26 }}
            className="relative w-full max-w-sm rounded-[32px] overflow-hidden bg-white/90 backdrop-blur-2xl border border-white/80 shadow-[0_40px_80px_-20px_rgba(15,23,42,0.45)]"
          >
            {/* Ambient gradient */}
            <div className="absolute inset-0 bg-gradient-to-br from-rose-100 via-white to-indigo-100 opacity-80" />
            <div className="absolute -top-24 -right-24 w-56 h-56 rounded-full bg-rose-200/60 blur-3xl" />

            <button
              onClick={onClose}
              aria-label={t("close")}
              className="absolute top-4 right-4 z-10 w-9 h-9 rounded-full bg-white/70 backdrop-blur border border-white/80 grid place-items-center text-slate-500 hover:text-slate-700"
            >
              <X className="w-4 h-4" />
            </button>

            <div className="relative p-7 pt-10">
              <div className="w-14 h-14 rounded-3xl bg-gradient-to-br from-rose-500 to-fuchsia-600 grid place-items-center shadow-[0_15px_30px_-8px_rgba(244,63,94,0.55)]">
                <LifeBuoy className="w-7 h-7 text-white" />
              </div>
              <h2 className="mt-4 text-[22px] font-bold tracking-tight text-slate-900">{t("crisisTitle")}</h2>
              <p className="mt-2 text-[14px] leading-relaxed text-slate-600">{t("crisisBody")}</p>

              <div className="mt-5 space-y-2">
                {resources.map((r) => (
                  <a
                    key={r.number}
                    href={`tel:${r.number.replace(/[^\d+]/g, "")}`}
                    className="flex items-center justify-between gap-3 p-3 rounded-2xl bg-white/70 border border-white/80 backdrop-blur-xl hover:bg-white transition-colors"
                  >
                    <div className="min-w-0">
                      <div className="text-[13px] font-semibold text-slate-800 truncate">{r.name}</div>
                      <div className="text-[12px] text-slate-500">{r.number}</div>
                    </div>
                    <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 grid place-items-center shrink-0">
                      <Phone className="w-4 h-4" />
                    </div>
                  </a>
                ))}
              </div>

              <div className="mt-5 flex gap-2">
                <GlassButton
                  variant="ghost"
                  size="md"
                  fullWidth
                  onClick={onBreathing}
                  icon={<MessageSquareHeart className="w-4 h-4" />}
                >
                  {t("tryBreathing")}
                </GlassButton>
                <GlassButton variant="primary" size="md" fullWidth onClick={onClose}>
                  {t("close")}
                </GlassButton>
              </div>

              <p className="mt-4 text-[10px] text-slate-400 text-center leading-relaxed">
                {t("privacyBody")}
              </p>
            </div>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
