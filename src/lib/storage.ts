/**
 * Local persistence layer.
 *
 * On iOS this is SwiftData. In the web reference app we use localStorage as a
 * deterministic stand-in with the same shape — the view-models never touch the
 * storage primitive directly, so swapping implementations is trivial.
 */

import type {
  ChatMessage,
  CrisisEvent,
  Habit,
  VideoAnalysis,
  WellnessProfile,
  WellnessSession,
} from "./types";

const NS = "vitalpath.v1";

const keys = {
  profile: `${NS}.profile`,
  chat: `${NS}.chat`,
  sessions: `${NS}.sessions`,
  habits: `${NS}.habits`,
  videos: `${NS}.videos`,
  crises: `${NS}.crises`,
} as const;

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

function write<T>(key: string, value: T): void {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* quota exceeded — ignore in reference app */
  }
}

export const storage = {
  getProfile(): WellnessProfile | null {
    return read<WellnessProfile | null>(keys.profile, null);
  },
  setProfile(p: WellnessProfile): void {
    write(keys.profile, p);
  },
  clear(): void {
    for (const k of Object.values(keys)) localStorage.removeItem(k);
  },

  getChat(): ChatMessage[] {
    return read<ChatMessage[]>(keys.chat, []);
  },
  setChat(messages: ChatMessage[]): void {
    write(keys.chat, messages);
  },

  getSessions(): WellnessSession[] {
    return read<WellnessSession[]>(keys.sessions, []);
  },
  setSessions(s: WellnessSession[]): void {
    write(keys.sessions, s);
  },

  getHabits(): Habit[] {
    return read<Habit[]>(keys.habits, []);
  },
  setHabits(h: Habit[]): void {
    write(keys.habits, h);
  },

  getVideos(): VideoAnalysis[] {
    return read<VideoAnalysis[]>(keys.videos, []);
  },
  setVideos(v: VideoAnalysis[]): void {
    write(keys.videos, v);
  },

  getCrises(): CrisisEvent[] {
    return read<CrisisEvent[]>(keys.crises, []);
  },
  setCrises(c: CrisisEvent[]): void {
    write(keys.crises, c);
  },
};

export function newId(): string {
  // RFC4122-ish random id, good enough for local-only persistence.
  const bytes = new Uint8Array(16);
  if (typeof crypto !== "undefined" && crypto.getRandomValues) {
    crypto.getRandomValues(bytes);
  } else {
    for (let i = 0; i < 16; i++) bytes[i] = Math.floor(Math.random() * 256);
  }
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = Array.from(bytes, (b) => b.toString(16).padStart(2, "0")).join("");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}
