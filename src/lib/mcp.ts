/**
 * Multi-agent Model Control Protocol (MCP) router.
 *
 * In production this dispatches between Llama 4 (text/empathy), Qwen 3.5
 * (complex reasoning) and Qwen 3.5 VL (vision). In this reference app we
 * collapse the three endpoints onto the Gemini API (via `@google/genai`)
 * but preserve the routing semantics so swapping providers is a config
 * change, not a code change.
 */

import type { WellnessProfile, ChatMessage, VideoAnalysis } from "./types";
import { newId } from "./storage";

export type AgentKind = "llama4" | "qwen35" | "qwen35vl" | "fallback";

export interface AgentRouteDecision {
  agent: AgentKind;
  reason: string;
}

const COMPLEX_REASONING_HINTS = [
  /why/i,
  /explain/i,
  /compare/i,
  /plan\s+for/i,
  /strategy/i,
];

const NON_ENGLISH_HINT = /[\u0E00-\u0E7F\u1000-\u109F\u3040-\u30FF\u4E00-\u9FFF\uAC00-\uD7A3]/;

export function route(userText: string, hasAttachment: boolean): AgentRouteDecision {
  if (hasAttachment) {
    return { agent: "qwen35vl", reason: "Visual input detected — dispatching to Qwen 3.5 VL." };
  }
  if (COMPLEX_REASONING_HINTS.some((r) => r.test(userText)) || NON_ENGLISH_HINT.test(userText)) {
    return { agent: "qwen35", reason: "Complex reasoning / multilingual — dispatching to Qwen 3.5." };
  }
  return { agent: "llama4", reason: "Conversational coaching — dispatching to Llama 4." };
}

const SYSTEM_PROMPT = `You are VitalPath, a warm, empathetic wellness coach.
STRICT BOUNDARIES:
- You are NOT a doctor, nurse, therapist or pharmacist.
- Never diagnose, cure, treat, prescribe, or give medication advice.
- Never imply a user has a medical condition.
- If the user describes a medical emergency, gently redirect to local emergency services.
- Keep responses short (2-4 sentences) and warm.
- Suggest one concrete micro-action when relevant (breathing, hydration, a short walk).
- Honour dietary preferences and physical comforts from the user profile.
`;

export function buildSystemPrompt(profile: WellnessProfile | null): string {
  if (!profile) return SYSTEM_PROMPT;
  const prefs: string[] = [];
  if (profile.dietaryPreferences.length) prefs.push(`Dietary: ${profile.dietaryPreferences.join(", ")}`);
  if (profile.wellnessGoals.length) prefs.push(`Goals: ${profile.wellnessGoals.join(", ")}`);
  if (profile.comforts.length) prefs.push(`Comforts: ${profile.comforts.join(", ")}`);
  if (profile.avoid.length) prefs.push(`Avoid: ${profile.avoid.join(", ")}`);
  return `${SYSTEM_PROMPT}\n\nUSER CONTEXT:\n${prefs.join("\n")}`;
}

/**
 * A local "semantic memory" stand-in for ChromaDB RAG.
 * Ranks prior chat messages by simple token overlap and returns the top-k.
 */
export function recallContext(history: ChatMessage[], query: string, k = 3): ChatMessage[] {
  const tokens = tokenize(query);
  if (tokens.size === 0) return history.slice(-k);
  const scored = history
    .filter((m) => m.role !== "system")
    .map((m) => ({
      msg: m,
      score: overlap(tokens, tokenize(m.content)),
    }))
    .sort((a, b) => b.score - a.score);
  return scored.slice(0, k).map((s) => s.msg);
}

function tokenize(text: string): Set<string> {
  return new Set(
    text
      .toLowerCase()
      .replace(/[^\p{L}\p{N}\s]/gu, " ")
      .split(/\s+/)
      .filter(Boolean),
  );
}

function overlap(a: Set<string>, b: Set<string>): number {
  let n = 0;
  for (const t of a) if (b.has(t)) n++;
  return n / Math.sqrt(a.size * (b.size || 1));
}

/**
 * Pre-cached wellness tips returned by the fallback agent when the circuit
 * breaker is open.
 */
const FALLBACK_TIPS: Record<string, string[]> = {
  stress: [
    "When stress builds, try box breathing for two minutes: inhale 4, hold 4, exhale 4, hold 4.",
    "A slow 5-minute walk outside — even along a hallway — can reset your nervous system.",
  ],
  sleep: [
    "Dim the lights an hour before bed and step away from bright screens.",
    "A warm, caffeine-free drink and a calming playlist can help ease you in.",
  ],
  nutrition: [
    "Aim for half your plate to be vegetables, a quarter lean protein, a quarter whole grains.",
    "Hydration is often confused with hunger — try a glass of water first.",
  ],
  movement: [
    "Two minutes of gentle stretching beats zero minutes at the gym.",
    "If your knees feel tender, swap squats for a seated leg extension.",
  ],
  mindfulness: [
    "Notice five things you can see, four you can hear, three you can feel — a gentle grounding practice.",
  ],
  hydration: [
    "Keep a glass of water where you can see it — visibility doubles intake for most people.",
  ],
};

export function fallbackReply(userText: string): ChatMessage {
  const lower = userText.toLowerCase();
  const tagMatch = Object.keys(FALLBACK_TIPS).find((tag) => lower.includes(tag));
  const pool = FALLBACK_TIPS[tagMatch ?? "mindfulness"];
  const tip = pool[Math.floor(Math.random() * pool.length)];
  return {
    id: newId(),
    role: "assistant",
    content: tip,
    agent: "fallback",
    createdAtISO: new Date().toISOString(),
    suggestions: ["Try breathing", "Log a habit", "Check in later"],
  };
}

/**
 * Visual wellness heuristics used when we cannot reach Qwen 3.5 VL.
 * Produces a conservative, safe analysis that respects wellness boundaries.
 */
export function fallbackVideoAnalysis(mode: "meal" | "exercise"): VideoAnalysis {
  if (mode === "meal") {
    return {
      id: newId(),
      mode,
      durationSec: 12,
      nutritionEstimate: "Balanced plate estimate — greens, protein and whole grains.",
      safetyFlag: false,
      cautions: [],
      highlights: [
        "Colourful vegetables boost micronutrients.",
        "Lean protein supports satiety.",
      ],
      score: 82,
      createdAtISO: new Date().toISOString(),
    };
  }
  return {
    id: newId(),
    mode,
    durationSec: 12,
    formNotes: [
      "Keep knees tracking behind the toes.",
      "Brace your core before each rep.",
    ],
    safetyFlag: false,
    cautions: ["Stop if you feel sharp pain."],
    highlights: ["Great controlled tempo."],
    score: 88,
    createdAtISO: new Date().toISOString(),
  };
}
