/**
 * Breathwork catalog + daily / weekly plan generator.
 *
 * Plans are generated deterministically from the profile's wellness goals so
 * the same week yields the same schedule (idempotent) and so the tests can
 * assert on shape without mocking a clock.
 */

import type {
  BreathworkTechnique,
  DailyPlan,
  PlanItem,
  PlanKind,
  PlanTimeOfDay,
  WeeklyPlan,
  WellnessGoal,
  WellnessProfile,
} from "./types";
import { newId } from "./storage";

// ---------------------------------------------------------------------------
// Breathwork catalog
// ---------------------------------------------------------------------------

export const BREATHWORK_CATALOG: BreathworkTechnique[] = [
  {
    id: "box-4-4-4-4",
    name: "Box breathing",
    summary: "Four-count inhale, hold, exhale, hold. Centers focus quickly.",
    pattern: [4, 4, 4, 4],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 6,
    benefits: ["Lowers stress", "Steadies attention", "Pre-meeting reset"],
    goal: "stress",
  },
  {
    id: "four-seven-eight",
    name: "4-7-8 relaxing breath",
    summary: "Long exhale activates the parasympathetic system — ideal before sleep.",
    pattern: [4, 7, 8, 0],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 4,
    benefits: ["Pre-sleep wind-down", "Reduces anxious tension"],
    goal: "sleep",
  },
  {
    id: "coherent-5-5",
    name: "Coherent breathing",
    summary: "Slow 5-in / 5-out rhythm tunes heart-rate variability.",
    pattern: [5, 0, 5, 0],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 12,
    benefits: ["HRV coherence", "Daily grounding"],
    goal: "mindfulness",
  },
  {
    id: "pursed-lip",
    name: "Pursed-lip breathing",
    summary: "In through the nose, out slowly through pursed lips — eases breathlessness.",
    pattern: [2, 0, 4, 0],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 10,
    benefits: ["Post-exertion recovery", "Steady oxygen exchange"],
    goal: "movement",
  },
  {
    id: "extended-exhale",
    name: "Extended exhale",
    summary: "A 4-in / 6-out pattern to gently downshift the nervous system.",
    pattern: [4, 2, 6, 0],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 8,
    benefits: ["Evening calm", "Mindful pause"],
    goal: "mindfulness",
  },
  {
    id: "energizing-bellows",
    name: "Energizing bellows",
    summary: "Fast, short inhales and exhales to kick-start morning alertness.",
    pattern: [1, 0, 1, 0],
    phases: ["inhale", "hold", "exhale", "hold2"],
    rounds: 24,
    benefits: ["Wakeful energy", "Clears fog"],
    goal: "movement",
  },
];

export function findTechnique(id: string): BreathworkTechnique | undefined {
  return BREATHWORK_CATALOG.find((t) => t.id === id);
}

export function breathworkForGoal(goal: WellnessGoal): BreathworkTechnique {
  return (
    BREATHWORK_CATALOG.find((t) => t.goal === goal) ?? BREATHWORK_CATALOG[0]
  );
}

// ---------------------------------------------------------------------------
// Daily / weekly plan generation
// ---------------------------------------------------------------------------

type Template = Omit<PlanItem, "id" | "completed">;

const MORNING: Record<WellnessGoal, Template> = {
  stress: {
    time: "morning",
    kind: "breath",
    title: "Morning box breathing",
    summary: "Six rounds of 4-4-4-4 to start calm.",
    durationMin: 3,
    goal: "stress",
    techniqueId: "box-4-4-4-4",
  },
  sleep: {
    time: "morning",
    kind: "mindfulness",
    title: "Sunlight + stretch",
    summary: "Two minutes of daylight and a gentle neck stretch anchors the circadian rhythm.",
    durationMin: 5,
    goal: "sleep",
  },
  nutrition: {
    time: "morning",
    kind: "nutrition",
    title: "Protein-forward breakfast",
    summary: "Aim for ~20g of protein + fiber to steady morning energy.",
    durationMin: 15,
    goal: "nutrition",
  },
  movement: {
    time: "morning",
    kind: "movement",
    title: "Energizing bellows",
    summary: "Twenty-four short breaths to wake up the body.",
    durationMin: 2,
    goal: "movement",
    techniqueId: "energizing-bellows",
  },
  mindfulness: {
    time: "morning",
    kind: "mindfulness",
    title: "Three-breath intention",
    summary: "Set one kind intention for the day on the third exhale.",
    durationMin: 2,
    goal: "mindfulness",
  },
  hydration: {
    time: "morning",
    kind: "hydration",
    title: "Mindful glass of water",
    summary: "One slow glass before coffee to replace overnight losses.",
    durationMin: 2,
    goal: "hydration",
  },
};

const MIDDAY: Record<WellnessGoal, Template> = {
  stress: {
    time: "midday",
    kind: "breath",
    title: "2-minute reset",
    summary: "Coherent 5-5 breathing between tasks.",
    durationMin: 2,
    goal: "stress",
    techniqueId: "coherent-5-5",
  },
  sleep: {
    time: "midday",
    kind: "movement",
    title: "Stand + stretch",
    summary: "Five minutes of light movement keeps evening sleepiness earned, not crashed.",
    durationMin: 5,
    goal: "sleep",
  },
  nutrition: {
    time: "midday",
    kind: "nutrition",
    title: "Half-plate veggies",
    summary: "Aim for colour + a palm of protein at lunch.",
    durationMin: 10,
    goal: "nutrition",
  },
  movement: {
    time: "midday",
    kind: "movement",
    title: "10-minute walk",
    summary: "A brisk stroll resets focus and supports metabolism.",
    durationMin: 10,
    goal: "movement",
  },
  mindfulness: {
    time: "midday",
    kind: "mindfulness",
    title: "Mindful minute",
    summary: "Sixty seconds noticing five senses, one at a time.",
    durationMin: 1,
    goal: "mindfulness",
  },
  hydration: {
    time: "midday",
    kind: "hydration",
    title: "Refill check-in",
    summary: "Aim for at least 500ml before lunch is over.",
    durationMin: 1,
    goal: "hydration",
  },
};

const EVENING: Record<WellnessGoal, Template> = {
  stress: {
    time: "evening",
    kind: "reflection",
    title: "Evening unwind",
    summary: "Write one thing that went well today.",
    durationMin: 5,
    goal: "stress",
  },
  sleep: {
    time: "evening",
    kind: "breath",
    title: "4-7-8 wind-down",
    summary: "Four rounds before lights-out to downshift.",
    durationMin: 4,
    goal: "sleep",
    techniqueId: "four-seven-eight",
  },
  nutrition: {
    time: "evening",
    kind: "nutrition",
    title: "Gentle dinner",
    summary: "Finish eating ≥2 hours before bed for better sleep quality.",
    durationMin: 20,
    goal: "nutrition",
  },
  movement: {
    time: "evening",
    kind: "movement",
    title: "Pursed-lip recovery",
    summary: "Ten breaths after any workout to recover smoothly.",
    durationMin: 3,
    goal: "movement",
    techniqueId: "pursed-lip",
  },
  mindfulness: {
    time: "evening",
    kind: "reflection",
    title: "Gratitude journal",
    summary: "Three small gratitudes — specific beats grand.",
    durationMin: 5,
    goal: "mindfulness",
  },
  hydration: {
    time: "evening",
    kind: "hydration",
    title: "Evening tea",
    summary: "A caffeine-free cup to end hydrated without disrupting sleep.",
    durationMin: 5,
    goal: "hydration",
  },
};

const NIGHT: Template = {
  time: "night",
  kind: "sleep",
  title: "Screens-off ritual",
  summary: "Dim lights, cool room, book or breathwork — consistency beats duration.",
  durationMin: 10,
  goal: "sleep",
};

function buildDayTemplates(goals: WellnessGoal[]): Template[] {
  const primary = (goals[0] ?? "mindfulness") as WellnessGoal;
  const secondary = (goals[1] ?? primary) as WellnessGoal;
  const tertiary = (goals[2] ?? "hydration") as WellnessGoal;

  return [
    MORNING[primary],
    MIDDAY[secondary],
    EVENING[tertiary],
    NIGHT,
  ];
}

function toDateISO(date: Date): string {
  const y = date.getFullYear();
  const m = String(date.getMonth() + 1).padStart(2, "0");
  const d = String(date.getDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function mondayOf(date: Date): Date {
  const copy = new Date(date);
  const day = copy.getDay(); // 0 = Sunday
  const diff = (day === 0 ? -6 : 1 - day); // shift so Monday is 0
  copy.setDate(copy.getDate() + diff);
  copy.setHours(0, 0, 0, 0);
  return copy;
}

/**
 * Build a daily plan for a specific date and profile. Pure (no storage).
 */
export function buildDailyPlan(date: Date, profile: WellnessProfile): DailyPlan {
  const goals = profile.wellnessGoals.length > 0
    ? profile.wellnessGoals
    : (["mindfulness", "movement", "hydration"] as WellnessGoal[]);
  const templates = buildDayTemplates(goals);
  const items: PlanItem[] = templates.map((tpl) => ({
    id: newId(),
    ...tpl,
    completed: false,
  }));
  return {
    id: newId(),
    dateISO: toDateISO(date),
    items,
  };
}

/**
 * Build a seven-day plan starting from the Monday on or before `date`.
 * Each day gets a slight rotation so the week feels varied.
 */
export function buildWeeklyPlan(date: Date, profile: WellnessProfile): WeeklyPlan {
  const start = mondayOf(date);
  const goals = profile.wellnessGoals.length > 0
    ? profile.wellnessGoals
    : (["mindfulness", "movement", "hydration"] as WellnessGoal[]);

  const days: DailyPlan[] = [];
  for (let i = 0; i < 7; i++) {
    const day = new Date(start);
    day.setDate(start.getDate() + i);
    // rotate the goal order each day so the plan isn't repetitive
    const rotated = rotate(goals, i);
    const rotatedProfile: WellnessProfile = { ...profile, wellnessGoals: rotated };
    days.push(buildDailyPlan(day, rotatedProfile));
  }

  return {
    id: newId(),
    weekStartISO: toDateISO(start),
    focus: goals.slice(0, 3),
    days,
  };
}

function rotate<T>(arr: T[], n: number): T[] {
  if (arr.length === 0) return arr;
  const k = ((n % arr.length) + arr.length) % arr.length;
  return [...arr.slice(k), ...arr.slice(0, k)];
}

export function labelForKind(kind: PlanKind): string {
  switch (kind) {
    case "breath": return "Breath";
    case "movement": return "Move";
    case "mindfulness": return "Mind";
    case "hydration": return "Hydrate";
    case "nutrition": return "Nourish";
    case "reflection": return "Reflect";
    case "sleep": return "Sleep";
  }
}

export function emojiForKind(kind: PlanKind): string {
  switch (kind) {
    case "breath": return "🌬️";
    case "movement": return "🏃";
    case "mindfulness": return "🧘";
    case "hydration": return "💧";
    case "nutrition": return "🥗";
    case "reflection": return "📝";
    case "sleep": return "🌙";
  }
}

export function labelForTime(time: PlanTimeOfDay): string {
  switch (time) {
    case "morning": return "Morning";
    case "midday": return "Midday";
    case "evening": return "Evening";
    case "night": return "Night";
  }
}

export function planCompletion(plan: DailyPlan): { done: number; total: number; pct: number } {
  const total = plan.items.length;
  const done = plan.items.filter((i) => i.completed).length;
  const pct = total === 0 ? 0 : Math.round((done / total) * 100);
  return { done, total, pct };
}
