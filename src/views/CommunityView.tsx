import { useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { ArrowLeft, Heart, MessageCircle, Users, Shield, Send } from "lucide-react";
import GlassCard from "../components/GlassCard";
import type { CommunityPost, CommunityTopic, Language, WellnessGoal, WellnessProfile } from "../lib/types";
import { useTranslation } from "../lib/i18n";
import { newId } from "../lib/storage";

interface CommunityViewProps {
  lang: Language;
  profile: WellnessProfile;
  topics: CommunityTopic[];
  posts: CommunityPost[];
  onTopicsChange: (t: CommunityTopic[]) => void;
  onPostsChange: (p: CommunityPost[]) => void;
}

const DEFAULT_TOPICS: CommunityTopic[] = [
  { id: "t1", title: "Stress & Calm", description: "Share calming techniques and stress management tips.", category: "stress", icon: "🌿", memberCount: 128, isOfficial: true, joined: false },
  { id: "t2", title: "Better Sleep", description: "Wind-down routines, sleep hygiene, and restful nights.", category: "sleep", icon: "🌙", memberCount: 95, isOfficial: true, joined: false },
  { id: "t3", title: "Healthy Eating", description: "Nutrition tips, meal ideas, and mindful eating.", category: "nutrition", icon: "🥗", memberCount: 74, isOfficial: true, joined: false },
  { id: "t4", title: "Movement & Exercise", description: "Workouts, stretches, and staying active together.", category: "movement", icon: "🏃", memberCount: 112, isOfficial: true, joined: false },
  { id: "t5", title: "Mindfulness", description: "Meditation, breathing, and present-moment awareness.", category: "mindfulness", icon: "🧘", memberCount: 156, isOfficial: true, joined: false },
  { id: "t6", title: "Hydration", description: "Water intake tips and hydration reminders.", category: "hydration", icon: "💧", memberCount: 43, isOfficial: true, joined: false },
  { id: "t7", title: "Journaling", description: "Reflective writing prompts and journaling practice.", category: "mindfulness", icon: "📝", memberCount: 67, isOfficial: true, joined: false },
  { id: "t8", title: "Wellness Wins", description: "Celebrate milestones, streaks, and personal victories.", category: "movement", icon: "🎉", memberCount: 89, isOfficial: true, joined: false },
];

export default function CommunityView({
  lang, profile, topics: propTopics, posts, onTopicsChange, onPostsChange,
}: CommunityViewProps) {
  const t = useTranslation(lang);
  const topics = propTopics.length > 0 ? propTopics : DEFAULT_TOPICS;
  const [selectedTopic, setSelectedTopic] = useState<CommunityTopic | null>(null);
  const [draftPost, setDraftPost] = useState("");
  const [filter, setFilter] = useState<WellnessGoal | "all">("all");

  function toggleJoin(topicId: string) {
    const updated = topics.map((tp) =>
      tp.id === topicId
        ? { ...tp, joined: !tp.joined, memberCount: tp.joined ? tp.memberCount - 1 : tp.memberCount + 1 }
        : tp,
    );
    onTopicsChange(updated);
  }

  function submitPost() {
    if (!selectedTopic || !draftPost.trim()) return;
    const post: CommunityPost = {
      id: newId(),
      topicId: selectedTopic.id,
      authorName: profile.displayName,
      content: draftPost.trim(),
      likeCount: 0,
      replyCount: 0,
      safetyFlags: [],
      createdAtISO: new Date().toISOString(),
    };
    onPostsChange([post, ...posts]);
    setDraftPost("");
  }

  const filteredTopics = filter === "all" ? topics : topics.filter((tp) => tp.category === filter);
  const topicPosts = selectedTopic ? posts.filter((p) => p.topicId === selectedTopic.id) : [];

  // Topic detail view
  if (selectedTopic) {
    return (
      <div className="px-1 pt-4 pb-36">
        <button onClick={() => setSelectedTopic(null)} className="flex items-center gap-1 text-indigo-600 text-[13px] font-semibold mb-4">
          <ArrowLeft className="w-4 h-4" /> {t("topics")}
        </button>

        <GlassCard>
          <div className="flex items-center gap-3">
            <span className="text-3xl">{selectedTopic.icon}</span>
            <div className="flex-1">
              <h2 className="text-[18px] font-bold text-slate-900">{selectedTopic.title}</h2>
              <p className="text-[12px] text-slate-500 mt-0.5">{selectedTopic.description}</p>
              <div className="flex items-center gap-2 mt-1.5">
                <span className="flex items-center gap-1 text-[11px] text-slate-400">
                  <Users className="w-3 h-3" /> {selectedTopic.memberCount} {t("members")}
                </span>
                {selectedTopic.isOfficial && (
                  <span className="flex items-center gap-0.5 text-[10px] font-bold text-emerald-600">
                    <Shield className="w-3 h-3" /> {t("official")}
                  </span>
                )}
              </div>
            </div>
            <button
              onClick={() => toggleJoin(selectedTopic.id)}
              className={`px-4 py-1.5 rounded-full text-[12px] font-bold transition-all ${
                selectedTopic.joined
                  ? "bg-slate-100 text-slate-600"
                  : "bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-lg"
              }`}
            >
              {selectedTopic.joined ? t("leaveTopic") : t("joinTopic")}
            </button>
          </div>
        </GlassCard>

        {/* Composer */}
        <div className="mt-4">
          <GlassCard>
            <div className="flex gap-2">
              <textarea
                value={draftPost}
                onChange={(e) => setDraftPost(e.target.value)}
                placeholder={t("postPlaceholder")}
                rows={2}
                className="flex-1 bg-transparent text-[14px] text-slate-900 outline-none resize-none placeholder:text-slate-400"
              />
              <button
                onClick={submitPost}
                disabled={!draftPost.trim()}
                className="self-end w-9 h-9 rounded-full bg-gradient-to-b from-indigo-500 to-violet-600 grid place-items-center shadow-lg disabled:opacity-40"
              >
                <Send className="w-4 h-4 text-white" />
              </button>
            </div>
          </GlassCard>
        </div>

        {/* Posts */}
        <div className="mt-4 space-y-3">
          {topicPosts.length === 0 && (
            <p className="text-[13px] text-slate-400 text-center py-8">{t("noPosts")}</p>
          )}
          <AnimatePresence>
            {topicPosts.map((post) => (
              <motion.div
                key={post.id}
                initial={{ opacity: 0, y: 12 }}
                animate={{ opacity: 1, y: 0 }}
              >
                <GlassCard>
                  <div className="flex items-center gap-2 mb-2">
                    <div className="w-7 h-7 rounded-full bg-gradient-to-br from-indigo-400 to-violet-500 grid place-items-center text-[11px] font-bold text-white">
                      {post.authorName.charAt(0).toUpperCase()}
                    </div>
                    <span className="text-[13px] font-bold text-slate-800">{post.authorName}</span>
                    <span className="text-[10px] text-slate-400 ml-auto">
                      {new Date(post.createdAtISO).toLocaleDateString()}
                    </span>
                  </div>
                  <p className="text-[14px] text-slate-700 leading-relaxed">{post.content}</p>
                  <div className="flex items-center gap-4 mt-3 pt-2 border-t border-slate-100">
                    <button className="flex items-center gap-1 text-[12px] text-slate-400 hover:text-rose-500 transition">
                      <Heart className="w-3.5 h-3.5" /> {post.likeCount}
                    </button>
                    <button className="flex items-center gap-1 text-[12px] text-slate-400 hover:text-indigo-500 transition">
                      <MessageCircle className="w-3.5 h-3.5" /> {post.replyCount}
                    </button>
                  </div>
                </GlassCard>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>
      </div>
    );
  }

  // Topic list view
  return (
    <div className="px-1 pt-4 pb-36">
      <h2 className="text-[22px] font-bold text-slate-900 mb-1">{t("community")}</h2>
      <p className="text-[13px] text-slate-500 mb-4">Connect with people who share your wellness interests.</p>

      {/* Category filter */}
      <div className="flex gap-1.5 overflow-x-auto pb-2 mb-4 -mx-1 px-1 scrollbar-hide">
        {(["all", "stress", "sleep", "nutrition", "movement", "mindfulness", "hydration"] as const).map((cat) => (
          <button
            key={cat}
            onClick={() => setFilter(cat)}
            className={`shrink-0 px-3 py-1.5 rounded-full text-[11px] font-semibold border transition-all ${
              filter === cat
                ? "bg-indigo-500 text-white border-transparent"
                : "bg-white/60 text-slate-600 border-white/80"
            }`}
          >
            {cat === "all" ? "All" : cat.charAt(0).toUpperCase() + cat.slice(1)}
          </button>
        ))}
      </div>

      {/* Topic cards */}
      <div className="space-y-3">
        {filteredTopics.map((topic) => (
          <motion.div key={topic.id} whileTap={{ scale: 0.98 }}>
            <GlassCard>
              <div className="flex items-center gap-3">
                <button onClick={() => { setSelectedTopic(topic); }} className="flex-1 flex items-center gap-3 text-left">
                  <span className="text-2xl">{topic.icon}</span>
                  <div>
                    <div className="flex items-center gap-1.5">
                      <h3 className="text-[15px] font-bold text-slate-900">{topic.title}</h3>
                      {topic.isOfficial && (
                        <Shield className="w-3 h-3 text-emerald-500" />
                      )}
                    </div>
                    <p className="text-[12px] text-slate-500 line-clamp-1 mt-0.5">{topic.description}</p>
                    <span className="flex items-center gap-1 text-[11px] text-slate-400 mt-1">
                      <Users className="w-3 h-3" /> {topic.memberCount} {t("members")}
                    </span>
                  </div>
                </button>
                <button
                  onClick={(e) => { e.stopPropagation(); toggleJoin(topic.id); }}
                  className={`px-3 py-1.5 rounded-full text-[11px] font-bold transition-all shrink-0 ${
                    topic.joined
                      ? "bg-slate-100 text-slate-500"
                      : "bg-gradient-to-b from-indigo-500 to-violet-600 text-white shadow-md"
                  }`}
                >
                  {topic.joined ? t("leaveTopic") : t("joinTopic")}
                </button>
              </div>
            </GlassCard>
          </motion.div>
        ))}
      </div>
    </div>
  );
}
