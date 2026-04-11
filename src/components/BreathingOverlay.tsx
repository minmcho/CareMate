import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { X } from "lucide-react";
import type { Language } from "../lib/types";
import { useTranslation } from "../lib/i18n";

interface BreathingOverlayProps {
  open: boolean;
  lang: Language;
  onClose: () => void;
}

const PHASES: { label: (t: (k: never) => string) => string; duration: number }[] = [
  { label: () => "Inhale", duration: 4000 },
  { label: () => "Hold", duration: 4000 },
  { label: () => "Exhale", duration: 4000 },
  { label: () => "Hold", duration: 4000 },
];

export default function BreathingOverlay({ open, lang, onClose }: BreathingOverlayProps) {
  const t = useTranslation(lang);
  const [phase, setPhase] = useState(0);

  useEffect(() => {
    if (!open) return;
    setPhase(0);
    const id = setInterval(() => setPhase((p) => (p + 1) % PHASES.length), 4000);
    return () => clearInterval(id);
  }, [open]);

  const current = PHASES[phase];
  const expanding = phase === 0;
  const contracting = phase === 2;

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          key="breathe-overlay"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{ duration: 0.3 }}
          className="fixed inset-0 z-40 bg-slate-900/80 backdrop-blur-xl grid place-items-center"
        >
          <button
            onClick={onClose}
            aria-label={t("close")}
            className="absolute top-8 right-6 w-10 h-10 rounded-full bg-white/10 text-white/80 border border-white/10 grid place-items-center hover:bg-white/20"
          >
            <X className="w-5 h-5" />
          </button>

          <div className="relative flex flex-col items-center">
            <motion.div
              animate={{
                scale: expanding ? 1.25 : contracting ? 0.8 : 1.05,
              }}
              transition={{ duration: 4, ease: "easeInOut" }}
              className="relative w-64 h-64 rounded-full bg-gradient-to-br from-indigo-400 via-violet-500 to-fuchsia-500 shadow-[0_0_120px_20px_rgba(139,92,246,0.45)]"
            >
              <div className="absolute inset-4 rounded-full border border-white/40" />
              <div className="absolute inset-10 rounded-full border border-white/20" />
              <motion.div
                animate={{ opacity: [0.25, 0.5, 0.25] }}
                transition={{ duration: 4, repeat: Infinity }}
                className="absolute inset-0 rounded-full bg-white mix-blend-overlay"
              />
            </motion.div>

            <div className="mt-10 text-center text-white">
              <div className="text-3xl font-bold tracking-tight">{current.label(t as never)}</div>
              <div className="text-sm text-white/70 mt-1">{t("breathingSubtitle")}</div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
