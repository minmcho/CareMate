/**
 * VitalPath AI — localisation layer.
 * Supported: English, Burmese, Thai, Simplified Chinese, Japanese, Korean.
 */

import type { Language } from "./types";

type Dictionary = {
  appName: string;
  tagline: string;
  home: string;
  chat: string;
  video: string;
  habits: string;
  profile: string;
  greetingMorning: string;
  greetingAfternoon: string;
  greetingEvening: string;
  todaysFocus: string;
  dailyCheckIn: string;
  howAreYouFeeling: string;
  streak: string;
  days: string;
  freezeStreak: string;
  freezeUsed: string;
  weeklyProgress: string;
  startBreathing: string;
  breathingTitle: string;
  breathingSubtitle: string;
  coachPlaceholder: string;
  send: string;
  coachWelcome: string;
  coachThinking: string;
  coachDisclaimer: string;
  recordMeal: string;
  recordExercise: string;
  analyzing: string;
  analysisReady: string;
  nutritionEstimate: string;
  formNotes: string;
  wellnessScore: string;
  safetyFlag: string;
  highlights: string;
  cautions: string;
  newHabit: string;
  addHabit: string;
  habitTitle: string;
  habitGoal: string;
  habitTarget: string;
  myHabits: string;
  completedToday: string;
  markDone: string;
  undo: string;
  preferences: string;
  dietary: string;
  wellnessGoals: string;
  comforts: string;
  avoid: string;
  language: string;
  signOut: string;
  privacyTitle: string;
  privacyBody: string;
  wellnessNotMedicine: string;
  onboardTitle: string;
  onboardSubtitle: string;
  onboardCTA: string;
  namePrompt: string;
  continue: string;
  crisisTitle: string;
  crisisBody: string;
  crisisCall: string;
  crisisText: string;
  close: string;
  tryBreathing: string;
  nutritionTag: string;
  stressTag: string;
  sleepTag: string;
  movementTag: string;
  mindfulnessTag: string;
  hydrationTag: string;
  vegetarian: string;
  vegan: string;
  glutenFree: string;
  lowSugar: string;
  halal: string;
  kosher: string;
  meditation: string;
  walking: string;
  yoga: string;
  knee: string;
  back: string;
  online: string;
  offline: string;
  fallbackActive: string;
  blockedMedicalClaim: string;
  recording: string;
  stopRecording: string;
  retake: string;
  analyze: string;
  mealMode: string;
  exerciseMode: string;
  noAnalysisYet: string;
  cameraUnavailable: string;
  startChatting: string;
  suggested: string;
  moodCalm: string;
  moodOk: string;
  moodTired: string;
  moodStressed: string;
  moodLow: string;
  yourProfile: string;
  accountId: string;
  dataLocal: string;
  deleteData: string;
  confirmDelete: string;
  welcomeBack: string;
  // Journal
  journal: string;
  newEntry: string;
  journalTitle: string;
  journalContent: string;
  journalEmpty: string;
  save: string;
  edit: string;
  delete: string;
  // Community
  community: string;
  topics: string;
  joinTopic: string;
  leaveTopic: string;
  members: string;
  writePost: string;
  postPlaceholder: string;
  replies: string;
  replyPlaceholder: string;
  noPosts: string;
  official: string;
  // Plan + breathwork
  plan: string;
  today: string;
  week: string;
  dailyPlan: string;
  weeklyPlan: string;
  planFocus: string;
  markComplete: string;
  markIncomplete: string;
  planEmpty: string;
  regeneratePlan: string;
  startBreathwork: string;
  breathwork: string;
  choosePattern: string;
  benefits: string;
  round: string;
  of: string;
  startSession: string;
  finishSession: string;
  inhale: string;
  hold: string;
  exhale: string;
  morning: string;
  midday: string;
  evening: string;
  night: string;
  // Sleep
  sleep: string;
  sleepLog: string;
  sleepQuality: string;
  sleepDuration: string;
  sleepTrend: string;
  bedtime: string;
  wakeTime: string;
  logSleep: string;
  deepSleep: string;
  remSleep: string;
  sleepEmpty: string;
  // Mood
  mood: string;
  moodCheckIn: string;
  logMood: string;
  energy: string;
  moodTrend: string;
  moodEmpty: string;
  // Insights
  insights: string;
  weeklyInsights: string;
  insightsEmpty: string;
  aiPowered: string;
  // Challenges
  challengesTitle: string;
  joinChallenge: string;
  challengeProgress: string;
  daysCompleted: string;
  participants: string;
};

const en: Dictionary = {
  appName: "VitalPath AI",
  tagline: "Wellness, not medicine.",
  home: "Home",
  chat: "Coach",
  video: "Vision",
  habits: "Habits",
  profile: "Profile",
  greetingMorning: "Good morning",
  greetingAfternoon: "Good afternoon",
  greetingEvening: "Good evening",
  todaysFocus: "Today's focus",
  dailyCheckIn: "Daily check-in",
  howAreYouFeeling: "How are you feeling?",
  streak: "Streak",
  days: "days",
  freezeStreak: "Freeze streak",
  freezeUsed: "Freeze used",
  weeklyProgress: "Weekly progress",
  startBreathing: "Start 2-min breathing",
  breathingTitle: "Box breathing",
  breathingSubtitle: "Inhale · Hold · Exhale · Hold",
  coachPlaceholder: "Share what's on your mind…",
  send: "Send",
  coachWelcome: "Hi, I'm your wellness coach. I'm here to support your lifestyle goals — not to diagnose or prescribe. What would you like to focus on today?",
  coachThinking: "Coach is reflecting…",
  coachDisclaimer: "VitalPath offers wellness guidance only. For medical concerns, consult a licensed professional.",
  recordMeal: "Analyze a meal",
  recordExercise: "Check my form",
  analyzing: "Analyzing with vision model…",
  analysisReady: "Analysis ready",
  nutritionEstimate: "Nutrition estimate",
  formNotes: "Form notes",
  wellnessScore: "Wellness score",
  safetyFlag: "Safety flag",
  highlights: "Highlights",
  cautions: "Gentle cautions",
  newHabit: "New habit",
  addHabit: "Add habit",
  habitTitle: "Habit title",
  habitGoal: "Focus area",
  habitTarget: "Times per week",
  myHabits: "My habits",
  completedToday: "Completed today",
  markDone: "Mark done",
  undo: "Undo",
  preferences: "Preferences",
  dietary: "Dietary preferences",
  wellnessGoals: "Wellness goals",
  comforts: "What comforts me",
  avoid: "Avoid / sensitive",
  language: "Language",
  signOut: "Sign out",
  privacyTitle: "Privacy & safety",
  privacyBody: "Your data stays on this device unless you sign in to sync. Crisis inputs are never stored in plain text.",
  wellnessNotMedicine: "Wellness, not medicine",
  onboardTitle: "Welcome to VitalPath",
  onboardSubtitle: "A gentle coach for habits, mindfulness, and movement — always within safe wellness boundaries.",
  onboardCTA: "Get started",
  namePrompt: "What should we call you?",
  continue: "Continue",
  crisisTitle: "You are not alone",
  crisisBody: "We noticed something that sounds serious. Please reach out to people trained to help.",
  crisisCall: "Call a helpline",
  crisisText: "Text support",
  close: "Close",
  tryBreathing: "Try breathing",
  nutritionTag: "Nutrition",
  stressTag: "Stress",
  sleepTag: "Sleep",
  movementTag: "Movement",
  mindfulnessTag: "Mindfulness",
  hydrationTag: "Hydration",
  vegetarian: "Vegetarian",
  vegan: "Vegan",
  glutenFree: "Gluten-free",
  lowSugar: "Low sugar",
  halal: "Halal",
  kosher: "Kosher",
  meditation: "Meditation",
  walking: "Walking",
  yoga: "Yoga",
  knee: "Knee-friendly",
  back: "Back-friendly",
  online: "Online",
  offline: "Offline",
  fallbackActive: "Fallback tips active",
  blockedMedicalClaim: "A response was rewritten to stay within wellness guidance.",
  recording: "Recording…",
  stopRecording: "Stop",
  retake: "Retake",
  analyze: "Analyze",
  mealMode: "Meal",
  exerciseMode: "Movement",
  noAnalysisYet: "No analysis yet. Tap a mode to begin.",
  cameraUnavailable: "Camera preview is simulated in this environment.",
  startChatting: "Start a gentle conversation.",
  suggested: "Suggested",
  moodCalm: "Calm",
  moodOk: "Okay",
  moodTired: "Tired",
  moodStressed: "Stressed",
  moodLow: "Low",
  yourProfile: "Your profile",
  accountId: "Account",
  dataLocal: "Stored on this device",
  deleteData: "Delete local data",
  confirmDelete: "Delete all local data?",
  welcomeBack: "Welcome back",
  journal: "Journal",
  newEntry: "New entry",
  journalTitle: "Title",
  journalContent: "Write your thoughts…",
  journalEmpty: "No journal entries yet. Tap + to begin.",
  save: "Save",
  edit: "Edit",
  delete: "Delete",
  community: "Community",
  topics: "Topics",
  joinTopic: "Join",
  leaveTopic: "Leave",
  members: "members",
  writePost: "Write a post",
  postPlaceholder: "Share something helpful…",
  replies: "Replies",
  replyPlaceholder: "Write a reply…",
  noPosts: "No posts yet. Be the first to share!",
  official: "Official",
  plan: "Plan",
  today: "Today",
  week: "Week",
  dailyPlan: "Today's plan",
  weeklyPlan: "This week",
  planFocus: "Focus",
  markComplete: "Mark complete",
  markIncomplete: "Mark incomplete",
  planEmpty: "Tap Regenerate to build today's plan.",
  regeneratePlan: "Regenerate",
  startBreathwork: "Start breathwork",
  breathwork: "Breathwork",
  choosePattern: "Choose a pattern",
  benefits: "Benefits",
  round: "Round",
  of: "of",
  startSession: "Start",
  finishSession: "Finish",
  inhale: "Inhale",
  hold: "Hold",
  exhale: "Exhale",
  morning: "Morning",
  midday: "Midday",
  evening: "Evening",
  night: "Night",
  sleep: "Sleep",
  sleepLog: "Sleep log",
  sleepQuality: "Sleep quality",
  sleepDuration: "Duration",
  sleepTrend: "Sleep trend",
  bedtime: "Bedtime",
  wakeTime: "Wake time",
  logSleep: "Log sleep",
  deepSleep: "Deep sleep",
  remSleep: "REM sleep",
  sleepEmpty: "No sleep data yet. Log your first night.",
  mood: "Mood",
  moodCheckIn: "Mood check-in",
  logMood: "Log mood",
  energy: "Energy",
  moodTrend: "Mood trend",
  moodEmpty: "No mood data yet. Log how you feel.",
  insights: "Insights",
  weeklyInsights: "Weekly insights",
  insightsEmpty: "Insights will appear after your first week of tracking.",
  aiPowered: "AI-powered",
  challengesTitle: "Challenges",
  joinChallenge: "Join",
  challengeProgress: "Progress",
  daysCompleted: "days completed",
  participants: "participants",
};

const my: Dictionary = {
  ...en,
  appName: "VitalPath AI",
  tagline: "ကျန်းမာရေး၊ ဆေးမဟုတ်ပါ။",
  home: "ပင်မ",
  chat: "နည်းပြ",
  video: "ရူပါရုံ",
  habits: "အလေ့အထ",
  profile: "ကိုယ်ရေး",
  greetingMorning: "မင်္ဂလာ နံနက်ခင်း",
  greetingAfternoon: "မင်္ဂလာ နေ့လယ်ခင်း",
  greetingEvening: "မင်္ဂလာ ညနေခင်း",
  todaysFocus: "ယနေ့အာရုံစိုက်ရန်",
  dailyCheckIn: "နေ့စဥ် စစ်ဆေးချက်",
  howAreYouFeeling: "ဘယ်လိုခံစားနေလဲ?",
  streak: "ဆက်တိုက်",
  days: "ရက်",
  freezeStreak: "ဆက်တိုက်ရပ်နားရန်",
  weeklyProgress: "အပတ်စဥ် တိုးတက်မှု",
  startBreathing: "၂ မိနစ် အသက်ရှုလေ့ကျင့်ခန်း",
  crisisTitle: "သင်တစ်ယောက်တည်း မဟုတ်ပါ",
  crisisBody: "အရေးကြီးတဲ့အရာ တစ်ခုခုကို သတိထားမိပါတယ်။ ကူညီနိုင်တဲ့ အဖွဲ့အစည်းကို ဆက်သွယ်ပါ။",
  wellnessNotMedicine: "ကျန်းမာရေး၊ ဆေးမဟုတ်ပါ",
};

const th: Dictionary = {
  ...en,
  tagline: "สุขภาวะ ไม่ใช่การแพทย์",
  home: "หน้าแรก",
  chat: "โค้ช",
  video: "วิเคราะห์",
  habits: "นิสัย",
  profile: "โปรไฟล์",
  greetingMorning: "อรุณสวัสดิ์",
  greetingAfternoon: "สวัสดีตอนบ่าย",
  greetingEvening: "สวัสดีตอนเย็น",
  todaysFocus: "โฟกัสของวันนี้",
  dailyCheckIn: "เช็คอินประจำวัน",
  howAreYouFeeling: "วันนี้รู้สึกอย่างไร?",
  streak: "สตรีค",
  days: "วัน",
  startBreathing: "หายใจ 2 นาที",
  crisisTitle: "คุณไม่ได้อยู่คนเดียว",
  crisisBody: "เราสังเกตเห็นบางอย่างที่อาจจริงจัง กรุณาติดต่อผู้ที่ได้รับการอบรมเพื่อช่วยเหลือ",
  wellnessNotMedicine: "สุขภาวะ ไม่ใช่การแพทย์",
};

const zh: Dictionary = {
  ...en,
  tagline: "健康指引，非医疗诊断。",
  home: "首页",
  chat: "教练",
  video: "视觉",
  habits: "习惯",
  profile: "个人",
  greetingMorning: "早上好",
  greetingAfternoon: "下午好",
  greetingEvening: "晚上好",
  todaysFocus: "今日重点",
  dailyCheckIn: "每日签到",
  howAreYouFeeling: "今天感觉怎么样？",
  streak: "连续",
  days: "天",
  startBreathing: "开始 2 分钟呼吸",
  crisisTitle: "你并不孤单",
  crisisBody: "我们注意到可能比较严重的情况，请联系专业援助。",
  wellnessNotMedicine: "健康指引，非医疗",
};

const ja: Dictionary = {
  ...en,
  tagline: "ウェルネス、医療ではありません。",
  home: "ホーム",
  chat: "コーチ",
  video: "ビジョン",
  habits: "習慣",
  profile: "プロフィール",
  greetingMorning: "おはようございます",
  greetingAfternoon: "こんにちは",
  greetingEvening: "こんばんは",
  todaysFocus: "今日のフォーカス",
  dailyCheckIn: "デイリーチェックイン",
  howAreYouFeeling: "今日の気分は？",
  streak: "連続",
  days: "日",
  startBreathing: "2分間の呼吸法",
  crisisTitle: "あなたは一人ではありません",
  crisisBody: "深刻な内容が検出されました。専門の相談窓口にご連絡ください。",
  wellnessNotMedicine: "ウェルネス、医療ではありません",
};

const ko: Dictionary = {
  ...en,
  tagline: "웰니스, 의료가 아닙니다.",
  home: "홈",
  chat: "코치",
  video: "비전",
  habits: "습관",
  profile: "프로필",
  greetingMorning: "좋은 아침입니다",
  greetingAfternoon: "좋은 오후입니다",
  greetingEvening: "좋은 저녁입니다",
  todaysFocus: "오늘의 집중",
  dailyCheckIn: "일일 체크인",
  howAreYouFeeling: "오늘 기분 어떠세요?",
  streak: "연속",
  days: "일",
  startBreathing: "2분 호흡 시작",
  crisisTitle: "혼자가 아닙니다",
  crisisBody: "심각할 수 있는 내용이 감지되었습니다. 도움을 줄 수 있는 전문가에게 연락해 주세요.",
  wellnessNotMedicine: "웰니스, 의료가 아닙니다",
};

const dictionaries: Record<Language, Dictionary> = { en, my, th, zh, ja, ko };

export type TKey = keyof Dictionary;

export function useTranslation(lang: Language) {
  const dict = dictionaries[lang] ?? en;
  return (key: TKey): string => dict[key] ?? en[key];
}

export const availableLanguages: { code: Language; label: string; flag: string }[] = [
  { code: "en", label: "English", flag: "EN" },
  { code: "my", label: "မြန်မာ", flag: "MY" },
  { code: "th", label: "ไทย", flag: "TH" },
  { code: "zh", label: "中文", flag: "ZH" },
  { code: "ja", label: "日本語", flag: "JA" },
  { code: "ko", label: "한국어", flag: "KO" },
];

/**
 * Localised crisis resources — displayed in the crisis modal.
 * Extending this list is how we add new jurisdictions.
 */
export const crisisResources: Record<Language, { name: string; number: string; url?: string }[]> = {
  en: [
    { name: "988 Suicide & Crisis Lifeline (US)", number: "988" },
    { name: "Samaritans (UK)", number: "116 123" },
    { name: "Lifeline (AU)", number: "13 11 14" },
  ],
  my: [
    { name: "Mental Health Myanmar", number: "09 7509 32679" },
    { name: "International Lifeline", number: "+1 800 273 8255" },
  ],
  th: [
    { name: "Department of Mental Health (TH)", number: "1323" },
    { name: "Samaritans Thailand", number: "02 713 6793" },
  ],
  zh: [
    { name: "Beijing Crisis Research & Intervention Center", number: "010-82951332" },
    { name: "Lifeline Taiwan", number: "1995" },
  ],
  ja: [
    { name: "Inochi no Denwa", number: "0120-783-556" },
    { name: "TELL Lifeline", number: "03-5774-0992" },
  ],
  ko: [
    { name: "Ministry of Health & Welfare Hotline", number: "1393" },
    { name: "Korea Suicide Prevention", number: "1577-0199" },
  ],
};
