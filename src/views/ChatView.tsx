import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Send, Sparkles, ShieldAlert, Wind } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { ChatMessage, Language, WellnessProfile } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { askCoach, getBreakerState } from "../lib/ai";
import { newId } from "../lib/storage";
import { cn } from "../lib/utils";

interface ChatViewProps {
  lang: Language;
  profile: WellnessProfile;
  messages: ChatMessage[];
  onMessagesChange: (messages: ChatMessage[]) => void;
  onCrisis: () => void;
  onBreathing: () => void;
  onSessionLogged: (durationSec: number) => void;
}

export default function ChatView({
  lang,
  profile,
  messages,
  onMessagesChange,
  onCrisis,
  onBreathing,
  onSessionLogged,
}: ChatViewProps) {
  const t = useTranslation(lang);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [rewriteNotice, setRewriteNotice] = useState<string | null>(null);
  const listRef = useRef<HTMLDivElement>(null);
  const startRef = useRef<number>(Date.now());

  useEffect(() => {
    if (listRef.current) {
      listRef.current.scrollTop = listRef.current.scrollHeight;
    }
  }, [messages, busy]);

  useEffect(() => {
    if (messages.length === 0) {
      onMessagesChange([
        {
          id: newId(),
          role: "assistant",
          content: t("coachWelcome"),
          agent: "llama4",
          createdAtISO: new Date().toISOString(),
          suggestions: ["I feel stressed", "Help me sleep better", "Nutrition tips"],
        },
      ]);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function send(text?: string) {
    const content = (text ?? input).trim();
    if (!content || busy) return;
    setInput("");
    setRewriteNotice(null);

    const userMsg: ChatMessage = {
      id: newId(),
      role: "user",
      content,
      createdAtISO: new Date().toISOString(),
    };
    const next = [...messages, userMsg];
    onMessagesChange(next);
    setBusy(true);

    try {
      const resp = await askCoach({ text: content, profile, history: next });
      const updated = [...next, resp.message];
      onMessagesChange(updated);
      onSessionLogged(Math.max(30, Math.floor((Date.now() - startRef.current) / 1000)));
      startRef.current = Date.now();
      if (resp.crisisTriggered) onCrisis();
      if (resp.safetyRewritten) setRewriteNotice(t("blockedMedicalClaim"));
    } finally {
      setBusy(false);
    }
  }

  const breakerOpen = getBreakerState().status !== "closed";

  return (
    <div className="flex flex-col h-[calc(100vh-180px)] px-5">
      {breakerOpen && (
        <motion.div
          initial={{ opacity: 0, y: -6 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-3 text-[11px] font-semibold text-amber-700 bg-amber-50/80 border border-amber-100 rounded-full px-3 py-1.5 self-center"
        >
          {t("fallbackActive")}
        </motion.div>
      )}

      <div
        ref={listRef}
        className="flex-1 overflow-y-auto space-y-3 pb-4 scroll-smooth"
      >
        <AnimatePresence initial={false}>
          {messages.map((m) => (
            <motion.div
              key={m.id}
              initial={{ opacity: 0, y: 10, scale: 0.98 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ duration: 0.28, ease: [0.22, 1, 0.36, 1] }}
              className={cn("flex", m.role === "user" ? "justify-end" : "justify-start")}
            >
              {m.role === "assistant" ? (
                <GlassCard
                  tone="lilac"
                  padded={false}
                  className="max-w-[85%] rounded-[24px] rounded-bl-md"
                >
                  <div className="px-4 py-3">
                    <div className="flex items-center gap-1.5 mb-1.5">
                      <div className="w-5 h-5 rounded-full bg-gradient-to-br from-indigo-500 to-violet-600 grid place-items-center">
                        <Sparkles className="w-3 h-3 text-white" />
                      </div>
                      <span className="text-[10px] font-semibold uppercase tracking-wider text-violet-700">
                        {m.agent ?? "coach"}
                      </span>
                    </div>
                    <p className="text-[14px] text-slate-800 leading-relaxed whitespace-pre-wrap">
                      {m.content}
                    </p>
                    {m.suggestions && m.suggestions.length > 0 && (
                      <div className="mt-3 flex flex-wrap gap-1.5">
                        {m.suggestions.map((s) => (
                          <button
                            key={s}
                            onClick={() => send(s)}
                            className="text-[11px] font-semibold px-2.5 py-1 rounded-full bg-white/70 border border-white/80 text-violet-700 hover:bg-white transition-colors"
                          >
                            {s}
                          </button>
                        ))}
                      </div>
                    )}
                  </div>
                </GlassCard>
              ) : (
                <div className="max-w-[80%] px-4 py-3 rounded-[24px] rounded-br-md bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-[0_10px_25px_-10px_rgba(99,102,241,0.55)]">
                  <p className="text-[14px] leading-relaxed whitespace-pre-wrap">{m.content}</p>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>

        {busy && (
          <motion.div
            initial={{ opacity: 0, y: 6 }}
            animate={{ opacity: 1, y: 0 }}
            className="flex items-center gap-2 text-[12px] text-slate-500 px-2"
          >
            <div className="flex gap-1">
              {[0, 1, 2].map((i) => (
                <motion.span
                  key={i}
                  animate={{ y: [0, -3, 0] }}
                  transition={{ duration: 0.9, repeat: Infinity, delay: i * 0.12 }}
                  className="w-1.5 h-1.5 rounded-full bg-violet-500"
                />
              ))}
            </div>
            {t("coachThinking")}
          </motion.div>
        )}
      </div>

      {rewriteNotice && (
        <motion.div
          initial={{ opacity: 0, y: 6 }}
          animate={{ opacity: 1, y: 0 }}
          className="mb-2 flex items-center gap-2 text-[11px] text-amber-700 bg-amber-50/80 border border-amber-100 rounded-xl px-3 py-2"
        >
          <ShieldAlert className="w-3.5 h-3.5 shrink-0" />
          <span>{rewriteNotice}</span>
        </motion.div>
      )}

      {/* Composer */}
      <div className="pb-4">
        <div className="flex items-center gap-2 mb-2">
          <GlassButton
            variant="ghost"
            size="sm"
            onClick={onBreathing}
            icon={<Wind className="w-3.5 h-3.5" />}
          >
            {t("tryBreathing")}
          </GlassButton>
        </div>
        <div className="relative flex items-center gap-2 p-1.5 rounded-full bg-white/70 border border-white/80 backdrop-blur-2xl shadow-[0_10px_30px_-15px_rgba(30,30,60,0.25),0_1px_0_rgba(255,255,255,0.9)_inset]">
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") send();
            }}
            placeholder={t("coachPlaceholder")}
            className="flex-1 bg-transparent px-4 py-2.5 text-[14px] text-slate-800 placeholder:text-slate-400 outline-none"
          />
          <motion.button
            whileTap={{ scale: 0.92 }}
            onClick={() => send()}
            disabled={!input.trim() || busy}
            className="w-10 h-10 rounded-full bg-gradient-to-b from-indigo-500 to-violet-600 text-white grid place-items-center shadow-[0_8px_20px_-6px_rgba(99,102,241,0.55)] disabled:opacity-40 disabled:cursor-not-allowed"
            aria-label={t("send")}
          >
            <Send className="w-4 h-4" />
          </motion.button>
        </div>
      </div>
    </div>
  );
}
