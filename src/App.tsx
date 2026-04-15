/**
 * VitalPath AI — main application shell.
 *
 * - Apple "liquid glass" surfaces throughout.
 * - Motion-powered screen transitions.
 * - Safety-first: every message/output passes through the safety validator.
 */

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { AnimatePresence, motion } from "motion/react";

import AmbientBackdrop from "./components/AmbientBackdrop";
import BreathingOverlay from "./components/BreathingOverlay";
import CrisisModal from "./components/CrisisModal";
import TabBar, { TabKey } from "./components/TabBar";
import VitalHeader from "./components/VitalHeader";
import OnboardingView from "./views/OnboardingView";
import HomeView from "./views/HomeView";
import ChatView from "./views/ChatView";
import VideoView from "./views/VideoView";
import HabitsView from "./views/HabitsView";
import ProfileView from "./views/ProfileView";
import JournalView from "./views/JournalView";
import CommunityView from "./views/CommunityView";
import PlanView from "./views/PlanView";
import type {
  BreathworkTechnique,
  ChatMessage,
  CommunityPost,
  CommunityTopic,
  CrisisEvent,
  DailyPlan,
  Habit,
  JournalEntry,
  Language,
  VideoAnalysis,
  WeeklyPlan,
  WellnessProfile,
  WellnessSession,
} from "./lib/types";
import { newId, storage } from "./lib/storage";
import { getBreakerState } from "./lib/ai";
import { hashForAudit } from "./lib/safety";

export default function App() {
  const [profile, setProfile] = useState<WellnessProfile | null>(() => storage.getProfile());
  const [lang, setLang] = useState<Language>(() => storage.getProfile()?.preferredLanguage ?? "en");
  const [tab, setTab] = useState<TabKey>("home");
  const [messages, setMessages] = useState<ChatMessage[]>(() => storage.getChat());
  const [sessions, setSessions] = useState<WellnessSession[]>(() => storage.getSessions());
  const [habits, setHabits] = useState<Habit[]>(() => storage.getHabits());
  const [videos, setVideos] = useState<VideoAnalysis[]>(() => storage.getVideos());
  const [crises, setCrises] = useState<CrisisEvent[]>(() => storage.getCrises());
  const [journal, setJournal] = useState<JournalEntry[]>(() => storage.getJournal());
  const [communityTopics, setCommunityTopics] = useState<CommunityTopic[]>(() => storage.getCommunityTopics());
  const [communityPosts, setCommunityPosts] = useState<CommunityPost[]>(() => storage.getCommunityPosts());
  const [dailyPlan, setDailyPlan] = useState<DailyPlan | null>(() => storage.getDailyPlan());
  const [weeklyPlan, setWeeklyPlan] = useState<WeeklyPlan | null>(() => storage.getWeeklyPlan());
  const [crisisOpen, setCrisisOpen] = useState(false);
  const [breathingOpen, setBreathingOpen] = useState(false);
  const [breathTechniqueId, setBreathTechniqueId] = useState<string | undefined>(undefined);
  const [fallbackState, setFallbackState] = useState<"online" | "fallback">("online");

  // Seed starter habits on first launch.
  useEffect(() => {
    if (profile && habits.length === 0) {
      const starter: Habit[] = [
        {
          id: newId(),
          title: "Morning breathing",
          emoji: "🧘",
          goal: "mindfulness",
          targetPerWeek: 5,
          completedThisWeek: 0,
          history: [],
        },
        {
          id: newId(),
          title: "10-minute walk",
          emoji: "🏃",
          goal: "movement",
          targetPerWeek: 4,
          completedThisWeek: 0,
          history: [],
        },
        {
          id: newId(),
          title: "Hydrate before meals",
          emoji: "💧",
          goal: "hydration",
          targetPerWeek: 7,
          completedThisWeek: 0,
          history: [],
        },
      ];
      setHabits(starter);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [profile]);

  // Persist on change.
  useEffect(() => {
    if (profile) storage.setProfile(profile);
  }, [profile]);
  useEffect(() => storage.setChat(messages), [messages]);
  useEffect(() => storage.setSessions(sessions), [sessions]);
  useEffect(() => storage.setHabits(habits), [habits]);
  useEffect(() => storage.setVideos(videos), [videos]);
  useEffect(() => storage.setCrises(crises), [crises]);
  useEffect(() => storage.setJournal(journal), [journal]);
  useEffect(() => storage.setCommunityTopics(communityTopics), [communityTopics]);
  useEffect(() => storage.setCommunityPosts(communityPosts), [communityPosts]);
  useEffect(() => storage.setDailyPlan(dailyPlan), [dailyPlan]);
  useEffect(() => storage.setWeeklyPlan(weeklyPlan), [weeklyPlan]);

  // Monitor breaker state every few seconds so the header reflects reality.
  useEffect(() => {
    const id = setInterval(() => {
      setFallbackState(getBreakerState().status === "closed" ? "online" : "fallback");
    }, 3000);
    return () => clearInterval(id);
  }, []);

  const handleLanguage = (next: Language) => {
    setLang(next);
    if (profile) setProfile({ ...profile, preferredLanguage: next });
  };

  const handleSessionLogged = (durationSec: number) => {
    const session: WellnessSession = {
      id: newId(),
      kind: tab === "video" ? "video" : tab === "habits" ? "habit" : "chat",
      title: tab === "video" ? "Video check-in" : tab === "habits" ? "Habit done" : "Coach chat",
      summary: "",
      tags: profile ? profile.wellnessGoals : [],
      durationSec,
      createdAtISO: new Date().toISOString(),
      synced: false,
    };
    setSessions((prev) => [session, ...prev].slice(0, 100));
  };

  const handleCrisis = (rawText?: string) => {
    setCrisisOpen(true);
    const event: CrisisEvent = {
      id: newId(),
      triggerHash: hashForAudit(rawText ?? Date.now().toString()),
      language: lang,
      createdAtISO: new Date().toISOString(),
    };
    setCrises((prev) => [event, ...prev].slice(0, 50));
  };

  const handleDeleteData = () => {
    storage.clear();
    setProfile(null);
    setMessages([]);
    setSessions([]);
    setHabits([]);
    setVideos([]);
    setCrises([]);
    setJournal([]);
    setCommunityTopics([]);
    setCommunityPosts([]);
    setDailyPlan(null);
    setWeeklyPlan(null);
  };

  const handleStartBreathwork = (technique?: BreathworkTechnique) => {
    setBreathTechniqueId(technique?.id);
    setBreathingOpen(true);
  };

  const activeView: ReactNode = useMemo(() => {
    if (!profile) return null;
    switch (tab) {
      case "home":
        return (
          <HomeView
            lang={lang}
            profile={profile}
            habits={habits}
            sessions={sessions}
            onStartBreathing={() => handleStartBreathwork()}
            onOpenChat={() => setTab("chat")}
            onMoodLogged={(score) => {
              handleSessionLogged(30);
              setMessages((prev) => [
                ...prev,
                {
                  id: newId(),
                  role: "system",
                  content: `User mood self-report: ${score}/5`,
                  createdAtISO: new Date().toISOString(),
                },
              ]);
            }}
          />
        );
      case "plan":
        return (
          <PlanView
            lang={lang}
            profile={profile}
            dailyPlan={dailyPlan}
            weeklyPlan={weeklyPlan}
            onDailyPlanChange={setDailyPlan}
            onWeeklyPlanChange={setWeeklyPlan}
            onStartBreathwork={handleStartBreathwork}
            onSessionLogged={handleSessionLogged}
          />
        );
      case "chat":
        return (
          <ChatView
            lang={lang}
            profile={profile}
            messages={messages}
            onMessagesChange={setMessages}
            onCrisis={() => handleCrisis()}
            onBreathing={() => handleStartBreathwork()}
            onSessionLogged={handleSessionLogged}
          />
        );
      case "video":
        return (
          <VideoView
            lang={lang}
            profile={profile}
            recent={videos}
            onNewAnalysis={(analysis) => {
              setVideos((prev) => [analysis, ...prev].slice(0, 20));
              handleSessionLogged(analysis.durationSec);
            }}
          />
        );
      case "habits":
        return (
          <HabitsView
            lang={lang}
            profile={profile}
            habits={habits}
            onHabitsChange={setHabits}
            onProfileChange={setProfile}
            onSessionLogged={handleSessionLogged}
          />
        );
      case "journal":
        return (
          <JournalView
            lang={lang}
            profile={profile}
            entries={journal}
            onEntriesChange={setJournal}
          />
        );
      case "community":
        return (
          <CommunityView
            lang={lang}
            profile={profile}
            topics={communityTopics}
            posts={communityPosts}
            onTopicsChange={setCommunityTopics}
            onPostsChange={setCommunityPosts}
          />
        );
      case "profile":
        return (
          <ProfileView
            lang={lang}
            profile={profile}
            onProfileChange={setProfile}
            onDeleteData={handleDeleteData}
            onLanguageChange={handleLanguage}
          />
        );
      default:
        return null;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, profile, lang, habits, sessions, messages, videos, journal, communityTopics, communityPosts, dailyPlan, weeklyPlan]);

  if (!profile) {
    return (
      <div className="relative min-h-screen text-slate-900 font-sans selection:bg-indigo-100">
        <AmbientBackdrop />
        <OnboardingView
          lang={lang}
          onLanguageChange={handleLanguage}
          onComplete={(p) => {
            setProfile(p);
            setLang(p.preferredLanguage);
          }}
        />
      </div>
    );
  }

  return (
    <div className="relative min-h-screen text-slate-900 font-sans selection:bg-indigo-100">
      <AmbientBackdrop />
      <div className="max-w-md mx-auto">
        <VitalHeader lang={lang} onLanguageChange={handleLanguage} onlineFallback={fallbackState} />
        <main>
          <AnimatePresence mode="wait">
            <motion.div
              key={tab}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -8 }}
              transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
            >
              {activeView}
            </motion.div>
          </AnimatePresence>
        </main>
      </div>

      <TabBar active={tab} onChange={setTab} lang={lang} />
      <CrisisModal
        open={crisisOpen}
        lang={lang}
        onClose={() => setCrisisOpen(false)}
        onBreathing={() => {
          setCrisisOpen(false);
          handleStartBreathwork();
        }}
      />
      <BreathingOverlay
        open={breathingOpen}
        lang={lang}
        techniqueId={breathTechniqueId}
        onClose={() => setBreathingOpen(false)}
        onFinish={(tech) => handleSessionLogged(tech.rounds * tech.pattern.reduce((a, b) => a + b, 0))}
      />
    </div>
  );
}
