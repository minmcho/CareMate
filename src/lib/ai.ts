/**
 * AI transport layer.
 *
 * Responsibilities:
 *  - Call the upstream model (Gemini in this reference build, but the same
 *    wire format as the backend's Llama/Qwen gateway).
 *  - Retry with exponential backoff.
 *  - Respect the circuit breaker.
 *  - Run pre-/post- safety scans.
 *
 * The view layer should only ever talk to `askCoach` and `analyseVideo`.
 */

import { GoogleGenAI } from "@google/genai";

import type {
  ChatMessage,
  VideoAnalysis,
  WellnessProfile,
} from "./types";
import { newId } from "./storage";
import { scanAssistantOutput, scanUserInput } from "./safety";
import {
  AgentKind,
  buildSystemPrompt,
  fallbackReply,
  fallbackVideoAnalysis,
  recallContext,
  route,
} from "./mcp";
import { CircuitBreaker } from "./circuitBreaker";

const breaker = new CircuitBreaker();

const API_KEY =
  typeof process !== "undefined" && process.env && process.env.GEMINI_API_KEY
    ? process.env.GEMINI_API_KEY
    : "";

const ai = API_KEY ? new GoogleGenAI({ apiKey: API_KEY }) : null;

const MODEL_MAP: Record<AgentKind, string> = {
  llama4: "gemini-2.5-flash",
  qwen35: "gemini-2.5-flash",
  qwen35vl: "gemini-2.5-flash",
  fallback: "gemini-2.5-flash",
};

export interface CoachRequest {
  text: string;
  profile: WellnessProfile | null;
  history: ChatMessage[];
}

export interface CoachResponse {
  message: ChatMessage;
  safetyRewritten: boolean;
  crisisTriggered: boolean;
}

async function withRetry<T>(fn: () => Promise<T>, maxAttempts = 3): Promise<T> {
  let attempt = 0;
  let lastErr: unknown;
  while (attempt < maxAttempts) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      attempt += 1;
      const backoff = Math.pow(2, attempt - 1) * 1000;
      await new Promise((r) => setTimeout(r, backoff));
    }
  }
  throw lastErr;
}

export async function askCoach(req: CoachRequest): Promise<CoachResponse> {
  const inputScan = scanUserInput(req.text);
  if (!inputScan.passed && inputScan.category === "crisis") {
    return {
      message: {
        id: newId(),
        role: "assistant",
        content:
          "I'm really glad you reached out. What you're feeling sounds serious and you deserve immediate support from people trained to help. Please use the resources on the screen to contact a local helpline.",
        agent: "fallback",
        createdAtISO: new Date().toISOString(),
        safetyFlags: ["crisis"],
      },
      safetyRewritten: false,
      crisisTriggered: true,
    };
  }

  const decision = route(inputScan.sanitized, false);

  if (!breaker.allow() || !ai) {
    return {
      message: fallbackReply(inputScan.sanitized),
      safetyRewritten: false,
      crisisTriggered: false,
    };
  }

  const context = recallContext(req.history, inputScan.sanitized, 3);
  const systemPrompt = buildSystemPrompt(req.profile);
  const conversation = context
    .map((m) => `${m.role === "user" ? "USER" : "COACH"}: ${m.content}`)
    .join("\n");

  const prompt = `${systemPrompt}\n\nRECENT MEMORY:\n${conversation}\n\nUSER: ${inputScan.sanitized}\nCOACH:`;

  try {
    const raw = await withRetry(async () => {
      const response = await ai.models.generateContent({
        model: MODEL_MAP[decision.agent],
        contents: prompt,
      });
      return response.text?.trim() || "";
    });

    if (!raw) throw new Error("Empty response from model.");

    const outScan = scanAssistantOutput(raw);
    breaker.recordSuccess();
    return {
      message: {
        id: newId(),
        role: "assistant",
        content: outScan.sanitized,
        agent: decision.agent,
        createdAtISO: new Date().toISOString(),
        safetyFlags: outScan.passed ? [] : [outScan.category],
        suggestions: pickSuggestions(inputScan.sanitized),
      },
      safetyRewritten: !outScan.passed,
      crisisTriggered: false,
    };
  } catch (err) {
    console.warn("AI call failed, using fallback:", err);
    breaker.recordFailure();
    return {
      message: fallbackReply(inputScan.sanitized),
      safetyRewritten: false,
      crisisTriggered: false,
    };
  }
}

function pickSuggestions(text: string): string[] {
  const lower = text.toLowerCase();
  if (/\bsleep\b/.test(lower)) return ["Wind-down routine", "Caffeine check", "Body scan"];
  if (/\bstress|anxious|overwhelm/.test(lower)) return ["Box breathing", "Short walk", "Journaling"];
  if (/\bfood|meal|eat|hungry/.test(lower)) return ["Plate method", "Mindful eating", "Hydration"];
  if (/\bpain|sore|tight/.test(lower)) return ["Gentle stretch", "Rest day", "Foam roll"];
  return ["Breathing", "Hydration", "Gratitude"];
}

export interface VideoRequest {
  mode: "meal" | "exercise";
  durationSec: number;
  thumbnailDataUrl?: string;
  profile: WellnessProfile | null;
}

export async function analyseVideo(req: VideoRequest): Promise<VideoAnalysis> {
  // In a real build this uploads to Supabase Storage and a Celery worker
  // invokes Qwen 3.5 VL. Here we simulate a short processing delay then
  // either call the vision model (if available) or fall back.
  if (!breaker.allow() || !ai) {
    await wait(900);
    return fallbackVideoAnalysis(req.mode);
  }
  try {
    // We don't actually post the frames to the model in the reference app
    // — we just ask the LLM to produce a structured wellness-safe analysis
    // so the UI has realistic copy.
    const prompt =
      req.mode === "meal"
        ? "Imagine a balanced, wellness-friendly meal. Respond with ONLY JSON: {\"nutrition_estimate\":string,\"highlights\":string[],\"cautions\":string[],\"score\":number}. Keep language wellness-safe, never medical."
        : "Imagine a safe bodyweight exercise. Respond with ONLY JSON: {\"form_notes\":string[],\"highlights\":string[],\"cautions\":string[],\"score\":number}. Keep language wellness-safe, never medical.";

    const text = await withRetry(async () => {
      const response = await ai.models.generateContent({
        model: MODEL_MAP.qwen35vl,
        contents: prompt,
      });
      return response.text?.trim() || "";
    });

    const parsed = safeParseJson(text);
    breaker.recordSuccess();
    const analysis: VideoAnalysis = {
      id: newId(),
      mode: req.mode,
      durationSec: req.durationSec,
      thumbnailDataUrl: req.thumbnailDataUrl,
      nutritionEstimate:
        req.mode === "meal" ? safeString(parsed?.nutrition_estimate, "Balanced plate estimate.") : undefined,
      formNotes: req.mode === "exercise" ? safeStringArray(parsed?.form_notes) : undefined,
      safetyFlag: false,
      cautions: safeStringArray(parsed?.cautions),
      highlights: safeStringArray(parsed?.highlights),
      score: clampScore(parsed?.score),
      createdAtISO: new Date().toISOString(),
    };
    const outScan = scanAssistantOutput(JSON.stringify(analysis));
    if (!outScan.passed) {
      analysis.safetyFlag = true;
    }
    return analysis;
  } catch (err) {
    console.warn("Vision call failed, using fallback:", err);
    breaker.recordFailure();
    return fallbackVideoAnalysis(req.mode);
  }
}

function wait(ms: number): Promise<void> {
  return new Promise((r) => setTimeout(r, ms));
}

function safeParseJson(text: string): Record<string, unknown> | null {
  try {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    return JSON.parse(match[0]);
  } catch {
    return null;
  }
}

function safeString(value: unknown, fallback: string): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function safeStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((v): v is string => typeof v === "string");
}

function clampScore(value: unknown): number {
  const n = typeof value === "number" ? value : 80;
  return Math.max(0, Math.min(100, Math.round(n)));
}

export function getBreakerState() {
  return breaker.snapshot;
}
