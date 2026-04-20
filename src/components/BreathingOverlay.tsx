import { useEffect, useMemo, useRef, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { X } from "lucide-react";
import type { BreathworkTechnique, Language } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { BREATHWORK_CATALOG, findTechnique } from "../lib/plans";

interface BreathingOverlayProps {
  open: boolean;
  lang: Language;
  /** If omitted, the first catalog entry (box breathing) is used. */
  techniqueId?: string;
  onClose: () => void;
  onFinish?: (technique: BreathworkTechnique, completedRounds: number) => void;
}

export default function BreathingOverlay({
  open,
  lang,
  techniqueId,
  onClose,
  onFinish,
}: BreathingOverlayProps) {
  const t = useTranslation(lang);

  const technique = useMemo<BreathworkTechnique>(
    () => findTechnique(techniqueId ?? "") ?? BREATHWORK_CATALOG[0],
    [techniqueId],
  );

  const [phaseIdx, setPhaseIdx] = useState(0);
  const [round, setRound] = useState(1);
  const finishedRef = useRef(false);

  // Reset whenever the overlay opens or the technique changes.
  useEffect(() => {
    if (!open) return;
    setPhaseIdx(0);
    setRound(1);
    finishedRef.current = false;
  }, [open, technique.id]);

  // Advance phases based on the technique's per-phase duration.
  useEffect(() => {
    if (!open) return;
    const currentDuration = technique.pattern[phaseIdx];
    if (currentDuration <= 0) {
      // skip zero-duration "hold" phases immediately
      nextPhase();
      return;
    }
    const id = setTimeout(() => {
      nextPhase();
    }, currentDuration * 1000);
    return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, phaseIdx, technique.id]);

  function nextPhase() {
    setPhaseIdx((prev) => {
      const next = prev + 1;
      if (next >= technique.phases.length) {
        // completed one round
        setRound((r) => {
          const nr = r + 1;
          if (nr > technique.rounds && !finishedRef.current) {
            finishedRef.current = true;
            onFinish?.(technique, technique.rounds);
          }
          return nr;
        });
        return 0;
      }
      return next;
    });
  }

  const phase = technique.phases[phaseIdx];
  const phaseLabel =
    phase === "inhale" ? t("inhale") :
    phase === "exhale" ? t("exhale") :
    t("hold");

  const isExpanding = phase === "inhale";
  const isContracting = phase === "exhale";
  const phaseSeconds = technique.pattern[phaseIdx] || 4;

  const showRound = Math.min(round, technique.rounds);

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
            <div className="mb-6 text-center text-white/80">
              <div className="text-[12px] uppercase tracking-widest text-white/60">
                {technique.name}
              </div>
              <div className="text-[11px] text-white/50 mt-1">
                {t("round")} {showRound} {t("of")} {technique.rounds}
              </div>
            </div>

            <motion.div
              animate={{
                scale: isExpanding ? 1.28 : isContracting ? 0.78 : 1.05,
              }}
              transition={{ duration: phaseSeconds, ease: "easeInOut" }}
              className="relative w-64 h-64 rounded-full bg-gradient-to-br from-indigo-400 via-violet-500 to-fuchsia-500 shadow-[0_0_120px_20px_rgba(139,92,246,0.45)]"
            >
              <div className="absolute inset-4 rounded-full border border-white/40" />
              <div className="absolute inset-10 rounded-full border border-white/20" />
              <motion.div
                animate={{ opacity: [0.25, 0.5, 0.25] }}
                transition={{ duration: Math.max(phaseSeconds, 2), repeat: Infinity }}
                className="absolute inset-0 rounded-full bg-white mix-blend-overlay"
              />
            </motion.div>

            <div className="mt-10 text-center text-white">
              <div className="text-3xl font-bold tracking-tight">{phaseLabel}</div>
              <div className="text-sm text-white/70 mt-1">{technique.summary}</div>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
