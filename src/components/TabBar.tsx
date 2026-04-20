import { ReactNode } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Home, MessageCircle, Video, Flame, User, BookOpen, Users, Calendar, Sparkles } from "lucide-react";
import { cn } from "../lib/utils";
import type { Language } from "../lib/types";
import { useTranslation } from "../lib/i18n";

export type TabKey =
  | "home"
  | "plan"
  | "insights"
  | "chat"
  | "video"
  | "habits"
  | "journal"
  | "community"
  | "profile";

interface TabBarProps {
  active: TabKey;
  onChange: (key: TabKey) => void;
  lang: Language;
}

export default function TabBar({ active, onChange, lang }: TabBarProps) {
  const t = useTranslation(lang);
  const items: { key: TabKey; label: string; icon: ReactNode }[] = [
    { key: "home", label: t("home"), icon: <Home className="w-[22px] h-[22px]" /> },
    { key: "plan", label: t("plan"), icon: <Calendar className="w-[22px] h-[22px]" /> },
    { key: "insights", label: t("insights"), icon: <Sparkles className="w-[22px] h-[22px]" /> },
    { key: "chat", label: t("chat"), icon: <MessageCircle className="w-[22px] h-[22px]" /> },
    { key: "video", label: t("video"), icon: <Video className="w-[22px] h-[22px]" /> },
    { key: "habits", label: t("habits"), icon: <Flame className="w-[22px] h-[22px]" /> },
    { key: "journal", label: t("journal"), icon: <BookOpen className="w-[22px] h-[22px]" /> },
    { key: "community", label: t("community"), icon: <Users className="w-[22px] h-[22px]" /> },
    { key: "profile", label: t("profile"), icon: <User className="w-[22px] h-[22px]" /> },
  ];

  return (
    <nav className="fixed bottom-0 inset-x-0 z-30 pb-3 px-4 pointer-events-none">
      <div className="pointer-events-auto mx-auto max-w-md">
        <div
          className={cn(
            "relative flex items-center justify-between px-2 py-2 rounded-[32px]",
            "bg-white/60 backdrop-blur-2xl backdrop-saturate-150",
            "border border-white/70",
            "shadow-[0_20px_60px_-20px_rgba(30,30,60,0.25),0_1px_0_rgba(255,255,255,0.9)_inset]",
          )}
        >
          {items.map((item) => {
            const isActive = item.key === active;
            return (
              <button
                key={item.key}
                onClick={() => onChange(item.key)}
                aria-label={item.label}
                className="relative flex-1 flex flex-col items-center justify-center gap-0.5 py-2 z-[1]"
              >
                <AnimatePresence>
                  {isActive && (
                    <motion.span
                      layoutId="tab-pill"
                      className="absolute inset-1 rounded-2xl bg-gradient-to-b from-indigo-500/95 to-violet-600/95 shadow-[0_8px_20px_-6px_rgba(99,102,241,0.55)]"
                      transition={{ type: "spring", stiffness: 420, damping: 34 }}
                    />
                  )}
                </AnimatePresence>
                <span
                  className={cn(
                    "relative transition-colors duration-200",
                    isActive ? "text-white" : "text-slate-500",
                  )}
                >
                  {item.icon}
                </span>
                <span
                  className={cn(
                    "relative text-[10px] font-semibold tracking-wide transition-colors duration-200",
                    isActive ? "text-white" : "text-slate-500",
                  )}
                >
                  {item.label}
                </span>
              </button>
            );
          })}
        </div>
      </div>
    </nav>
  );
}
