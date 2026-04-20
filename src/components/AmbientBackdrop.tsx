import { motion } from "motion/react";

/**
 * Soft, slowly-drifting ambient gradient orbs behind every screen.
 * Gives the "liquid glass" surfaces something translucent to layer over.
 */
export default function AmbientBackdrop() {
  return (
    <div aria-hidden className="fixed inset-0 -z-10 overflow-hidden pointer-events-none">
      <div className="absolute inset-0 bg-gradient-to-b from-[#eef2ff] via-[#fdf4ff] to-[#ecfeff]" />
      <motion.div
        initial={{ x: -40, y: -20 }}
        animate={{ x: [-40, 40, -20, -40], y: [-20, 30, 10, -20] }}
        transition={{ duration: 28, repeat: Infinity, ease: "easeInOut" }}
        className="absolute top-[-10%] left-[-15%] w-[70vw] h-[70vw] rounded-full bg-gradient-to-br from-indigo-300/50 via-violet-300/40 to-transparent blur-3xl"
      />
      <motion.div
        initial={{ x: 30, y: 20 }}
        animate={{ x: [30, -20, 40, 30], y: [20, -10, 30, 20] }}
        transition={{ duration: 32, repeat: Infinity, ease: "easeInOut" }}
        className="absolute bottom-[-20%] right-[-20%] w-[75vw] h-[75vw] rounded-full bg-gradient-to-br from-fuchsia-200/50 via-rose-200/40 to-transparent blur-3xl"
      />
      <motion.div
        initial={{ opacity: 0.4 }}
        animate={{ opacity: [0.3, 0.5, 0.35, 0.45] }}
        transition={{ duration: 12, repeat: Infinity, ease: "easeInOut" }}
        className="absolute top-[30%] right-[10%] w-[45vw] h-[45vw] rounded-full bg-gradient-to-br from-cyan-200/40 via-sky-200/30 to-transparent blur-3xl"
      />
    </div>
  );
}
