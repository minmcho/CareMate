// ─── AI Content Generator (Gemini) ──────────────────────────────────────────
import { GoogleGenAI, Type } from "@google/genai";
import type { NicheId } from "./types.js";
import { NICHES, NICHE_TOPICS } from "./niches.js";

const ai = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY ?? "" });

export interface GeneratedContent {
  caption: string;
  hashtags: string;
  imagePrompt: string;
  topic: string;
}

export async function generateContent(
  niche: NicheId,
  customTopic?: string
): Promise<GeneratedContent> {
  const nicheConfig = NICHES.find((n) => n.id === niche);
  if (!nicheConfig) throw new Error(`Unknown niche: ${niche}`);

  const topics = NICHE_TOPICS[niche] ?? ["general tips"];
  const topic = customTopic ?? topics[Math.floor(Math.random() * topics.length)];

  const systemPrompt = `You are an expert Instagram content creator specializing in the "${nicheConfig.name}" niche.
Your goal is to create viral, engaging content that grows followers and drives monetization.
Content style: ${nicheConfig.contentStyle}
Always write in a way that encourages saves, shares, and follows.`;

  const userPrompt = `Create Instagram post content for the topic: "${topic}"

Return a JSON object with:
1. "caption": Main post caption (2-4 sentences, conversational, ends with a CTA)
2. "hashtags": Space-separated hashtags string (25-30 hashtags mixing popular and niche-specific)
3. "imagePrompt": Detailed prompt for AI image generation (describe visual style, colors, composition, mood — no faces, no people)
4. "topic": The topic used (echo back the topic)

Hashtags MUST include a mix from these groups:
Popular: ${nicheConfig.hashtagGroups[0]?.join(", ")}
Mid-tier: ${nicheConfig.hashtagGroups[1]?.join(", ")}
Niche: ${nicheConfig.hashtagGroups[2]?.join(", ")}`;

  const response = await ai.models.generateContent({
    model: "gemini-2.0-flash",
    contents: [
      { role: "user", parts: [{ text: systemPrompt + "\n\n" + userPrompt }] },
    ],
    config: {
      responseMimeType: "application/json",
      responseSchema: {
        type: Type.OBJECT,
        properties: {
          caption:     { type: Type.STRING },
          hashtags:    { type: Type.STRING },
          imagePrompt: { type: Type.STRING },
          topic:       { type: Type.STRING },
        },
        required: ["caption", "hashtags", "imagePrompt", "topic"],
      },
    },
  });

  const raw = response.text?.trim() ?? "{}";
  const parsed = JSON.parse(raw) as GeneratedContent;

  // Ensure hashtags start with #
  parsed.hashtags = parsed.hashtags
    .split(/\s+/)
    .filter(Boolean)
    .map((h) => (h.startsWith("#") ? h : `#${h}`))
    .join(" ");

  return parsed;
}

export async function generateBulkContent(
  niche: NicheId,
  count: number,
  scheduledTimes: string[]
): Promise<GeneratedContent[]> {
  const results: GeneratedContent[] = [];
  for (let i = 0; i < count; i++) {
    try {
      const content = await generateContent(niche);
      results.push(content);
      // Small delay to avoid rate limiting
      if (i < count - 1) await sleep(1200);
    } catch (err) {
      console.error(`Failed to generate content ${i + 1}/${count}:`, err);
    }
  }
  return results;
}

// ─── Scheduling Helpers ───────────────────────────────────────────────────────

export function getNextPostTimes(
  niche: NicheId,
  count: number,
  startFrom?: Date
): string[] {
  const nicheConfig = NICHES.find((n) => n.id === niche);
  if (!nicheConfig) return [];

  const base = startFrom ?? new Date();
  const times: string[] = [];
  const postTimes = nicheConfig.bestPostTimes; // e.g. ["07:00", "12:00", "20:00"]

  let day = new Date(base);
  day.setSeconds(0, 0);

  let added = 0;
  let daysChecked = 0;

  while (added < count && daysChecked < 60) {
    for (const timeStr of postTimes) {
      if (added >= count) break;
      const [h, m] = timeStr.split(":").map(Number);
      const candidate = new Date(day);
      candidate.setHours(h, m, 0, 0);
      if (candidate > base) {
        times.push(candidate.toISOString());
        added++;
      }
    }
    day = new Date(day.getTime() + 86400000); // +1 day
    daysChecked++;
  }

  return times;
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
