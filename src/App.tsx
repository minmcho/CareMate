/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useState, ReactNode } from "react";
import { Calendar, Pill, Languages, Utensils, Settings, GraduationCap, Bot } from "lucide-react";
import { cn } from "./lib/utils";
import { Language, useTranslation } from "./lib/i18n";
import ScheduleView from "./components/ScheduleView";
import MedicationView from "./components/MedicationView";
import TranslateView from "./components/TranslateView";
import DietView from "./components/DietView";
import GuidanceView from "./components/GuidanceView";
import AssistantView from "./components/AssistantView";

export default function App() {
  const [activeTab, setActiveTab] = useState<
    "schedule" | "medication" | "diet" | "guidance" | "assistant"
  >("schedule");
  const [lang, setLang] = useState<Language>("my"); // Default to Myanmar for caregiver
  const t = useTranslation(lang);

  const languages: Language[] = ["en", "my", "th", "ar"];
  const handleLanguageSwitch = () => {
    const currentIndex = languages.indexOf(lang);
    const nextIndex = (currentIndex + 1) % languages.length;
    setLang(languages[nextIndex]);
  };

  return (
    <div className="flex flex-col h-screen bg-gradient-to-br from-indigo-50/80 via-blue-50/80 to-purple-50/80 text-slate-900 font-sans selection:bg-indigo-100">
      {/* Header */}
      <header className="bg-white/60 backdrop-blur-xl border-b border-white/50 px-5 py-4 flex items-center justify-between shrink-0 sticky top-0 z-10 shadow-sm">
        <h1 className="text-2xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent tracking-tight">CareMate SG</h1>
        <button
          onClick={handleLanguageSwitch}
          className="flex items-center gap-2 px-4 py-2 rounded-full bg-white/80 shadow-sm border border-white/50 text-sm font-semibold hover:bg-white transition-all active:scale-95"
        >
          <Languages className="w-4 h-4 text-indigo-500" />
          {lang.toUpperCase()}
        </button>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 overflow-y-auto pb-20">
        {activeTab === "schedule" && <ScheduleView lang={lang} />}
        {activeTab === "medication" && <MedicationView lang={lang} />}
        {activeTab === "diet" && <DietView lang={lang} />}
        {activeTab === "guidance" && <GuidanceView lang={lang} />}
        {activeTab === "assistant" && <AssistantView lang={lang} />}
      </main>

      {/* Bottom Navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/70 backdrop-blur-xl border-t border-white/50 flex items-center justify-around pb-safe pt-2 px-2 z-20 shadow-[0_-8px_30px_rgba(0,0,0,0.04)]">
        <NavItem
          icon={<Calendar className="w-5 h-5" />}
          label={t("schedule")}
          isActive={activeTab === "schedule"}
          onClick={() => setActiveTab("schedule")}
        />
        <NavItem
          icon={<Pill className="w-5 h-5" />}
          label={t("medication")}
          isActive={activeTab === "medication"}
          onClick={() => setActiveTab("medication")}
        />
        <NavItem
          icon={<Utensils className="w-5 h-5" />}
          label={t("diet")}
          isActive={activeTab === "diet"}
          onClick={() => setActiveTab("diet")}
        />
        <NavItem
          icon={<GraduationCap className="w-5 h-5" />}
          label={t("guidance")}
          isActive={activeTab === "guidance"}
          onClick={() => setActiveTab("guidance")}
        />
        <NavItem
          icon={<Bot className="w-5 h-5" />}
          label={t("assistant")}
          isActive={activeTab === "assistant"}
          onClick={() => setActiveTab("assistant")}
        />
      </nav>
    </div>
  );
}

function NavItem({
  icon,
  label,
  isActive,
  onClick,
}: {
  icon: ReactNode;
  label: string;
  isActive: boolean;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={cn(
        "flex flex-col items-center justify-center w-full py-2 gap-1 transition-all active:scale-95",
        isActive ? "text-indigo-600" : "text-slate-400 hover:text-slate-600",
      )}
    >
      <div className={cn(
        "p-1.5 rounded-xl transition-all duration-300", 
        isActive ? "bg-gradient-to-br from-indigo-500 to-purple-500 text-white shadow-md shadow-indigo-200" : "bg-transparent"
      )}>
        {icon}
      </div>
      <span className={cn("text-[10px] font-semibold tracking-wide", isActive ? "text-indigo-600" : "")}>{label}</span>
    </button>
  );
}
