import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Plus, BookOpen, ArrowLeft, Trash2, Pencil } from "lucide-react";
import GlassCard from "../components/GlassCard";
import GlassButton from "../components/GlassButton";
import type { JournalEntry, Language, WellnessGoal, WellnessProfile } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { newId } from "../lib/storage";

interface JournalViewProps {
  lang: Language;
  profile: WellnessProfile;
  entries: JournalEntry[];
  onEntriesChange: (entries: JournalEntry[]) => void;
}

const MOOD_EMOJI = ["", "😢", "😟", "😐", "🙂", "😊"];

const TAGS: { key: WellnessGoal; label: string; emoji: string }[] = [
  { key: "stress", label: "Stress", emoji: "🌿" },
  { key: "sleep", label: "Sleep", emoji: "🌙" },
  { key: "nutrition", label: "Nutrition", emoji: "🥗" },
  { key: "movement", label: "Movement", emoji: "🏃" },
  { key: "mindfulness", label: "Mindfulness", emoji: "🧘" },
  { key: "hydration", label: "Hydration", emoji: "💧" },
];

export default function JournalView({ lang, profile, entries, onEntriesChange }: JournalViewProps) {
  const t = useTranslation(lang);
  const [view, setView] = useState<"list" | "edit">("list");
  const [editId, setEditId] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [content, setContent] = useState("");
  const [mood, setMood] = useState<number | undefined>(undefined);
  const [tags, setTags] = useState<WellnessGoal[]>([]);

  function openNew() {
    setEditId(null);
    setTitle("");
    setContent("");
    setMood(undefined);
    setTags([]);
    setView("edit");
  }

  function openEdit(entry: JournalEntry) {
    setEditId(entry.id);
    setTitle(entry.title);
    setContent(entry.content);
    setMood(entry.moodScore);
    setTags(entry.tags);
    setView("edit");
  }

  function save() {
    const now = new Date().toISOString();
    if (editId) {
      onEntriesChange(
        entries.map((e) =>
          e.id === editId
            ? { ...e, title: title.trim(), content, contentPreview: content.slice(0, 80), moodScore: mood, tags, updatedAtISO: now }
            : e,
        ),
      );
    } else {
      const entry: JournalEntry = {
        id: newId(),
        title: title.trim() || "Untitled",
        content,
        contentPreview: content.slice(0, 80),
        moodScore: mood,
        tags,
        createdAtISO: now,
        updatedAtISO: now,
      };
      onEntriesChange([entry, ...entries]);
    }
    setView("list");
  }

  function remove(id: string) {
    onEntriesChange(entries.filter((e) => e.id !== id));
  }

  function toggleTag(g: WellnessGoal) {
    setTags((prev) => (prev.includes(g) ? prev.filter((x) => x !== g) : [...prev, g]));
  }

  if (view === "edit") {
    return (
      <div className="px-1 pt-4 pb-36">
        <button onClick={() => setView("list")} className="flex items-center gap-1 text-indigo-600 text-[13px] font-semibold mb-4">
          <ArrowLeft className="w-4 h-4" /> Back
        </button>
        <h2 className="text-[22px] font-bold text-slate-900 mb-4">{editId ? t("edit") : t("newEntry")}</h2>
        <div className="space-y-3">
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder={t("journalTitle")}
            className="w-full bg-white/70 border border-white/80 rounded-2xl px-4 py-3 text-[15px] text-slate-900 outline-none backdrop-blur-xl"
          />
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            placeholder={t("journalContent")}
            rows={8}
            className="w-full bg-white/70 border border-white/80 rounded-2xl px-4 py-3 text-[15px] text-slate-900 outline-none backdrop-blur-xl resize-none"
          />
          <div>
            <div className="text-[12px] font-semibold text-slate-500 mb-2">Mood</div>
            <div className="flex gap-2">
              {[1, 2, 3, 4, 5].map((s) => (
                <button
                  key={s}
                  onClick={() => setMood(s)}
                  className={`w-10 h-10 rounded-full text-xl grid place-items-center transition-all ${
                    mood === s ? "bg-indigo-100 ring-2 ring-indigo-500 scale-110" : "bg-white/60"
                  }`}
                >
                  {MOOD_EMOJI[s]}
                </button>
              ))}
            </div>
          </div>
          <div>
            <div className="text-[12px] font-semibold text-slate-500 mb-2">Tags</div>
            <div className="flex flex-wrap gap-1.5">
              {TAGS.map((g) => (
                <button
                  key={g.key}
                  onClick={() => toggleTag(g.key)}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-semibold border transition-all ${
                    tags.includes(g.key)
                      ? "bg-indigo-500 text-white border-transparent"
                      : "bg-white/60 text-slate-600 border-white/80"
                  }`}
                >
                  {g.emoji} {g.label}
                </button>
              ))}
            </div>
          </div>
          <GlassButton variant="primary" size="lg" fullWidth onClick={save} disabled={!content.trim()}>
            {t("save")}
          </GlassButton>
        </div>
      </div>
    );
  }

  return (
    <div className="px-1 pt-4 pb-36">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-[22px] font-bold text-slate-900">{t("journal")}</h2>
        <button
          onClick={openNew}
          className="w-9 h-9 rounded-full bg-gradient-to-b from-indigo-500 to-violet-600 grid place-items-center shadow-lg"
        >
          <Plus className="w-5 h-5 text-white" />
        </button>
      </div>

      {entries.length === 0 && (
        <GlassCard>
          <div className="flex flex-col items-center py-8 text-center">
            <BookOpen className="w-10 h-10 text-indigo-300 mb-3" />
            <p className="text-[13px] text-slate-500">{t("journalEmpty")}</p>
          </div>
        </GlassCard>
      )}

      <AnimatePresence>
        {entries.map((entry) => (
          <motion.div
            key={entry.id}
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, height: 0 }}
            className="mb-3"
          >
            <GlassCard>
              <div className="flex items-start justify-between gap-2">
                <button onClick={() => openEdit(entry)} className="flex-1 text-left">
                  <div className="flex items-center gap-2">
                    {entry.moodScore && <span className="text-lg">{MOOD_EMOJI[entry.moodScore]}</span>}
                    <h3 className="text-[15px] font-bold text-slate-900 line-clamp-1">{entry.title}</h3>
                  </div>
                  <p className="text-[13px] text-slate-500 mt-1 line-clamp-2">{entry.contentPreview}</p>
                  <div className="flex items-center gap-2 mt-2">
                    {entry.tags.map((tag) => (
                      <span key={tag} className="text-[10px] font-semibold text-indigo-600 bg-indigo-50 px-2 py-0.5 rounded-full">
                        {tag}
                      </span>
                    ))}
                    <span className="text-[10px] text-slate-400 ml-auto">
                      {new Date(entry.createdAtISO).toLocaleDateString()}
                    </span>
                  </div>
                </button>
                <div className="flex gap-1 shrink-0">
                  <button onClick={() => openEdit(entry)} className="p-1.5 rounded-lg hover:bg-slate-100 transition">
                    <Pencil className="w-3.5 h-3.5 text-slate-400" />
                  </button>
                  <button onClick={() => remove(entry.id)} className="p-1.5 rounded-lg hover:bg-red-50 transition">
                    <Trash2 className="w-3.5 h-3.5 text-red-400" />
                  </button>
                </div>
              </div>
            </GlassCard>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}
