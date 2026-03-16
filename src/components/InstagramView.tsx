// ─── Instagram Automation Dashboard ─────────────────────────────────────────
import React, { useState, useEffect, useCallback, ReactNode } from "react";
import {
  Instagram, Sparkles, Clock, CheckCircle2, XCircle, RefreshCw,
  ChevronRight, Trash2, Play, Calendar, TrendingUp, Zap, Plus,
  ExternalLink, Copy, AlertCircle, BarChart2, Users, BookOpen
} from "lucide-react";
import { cn } from "../lib/utils";
import type { NicheConfig, Post, NicheId, PostStatus } from "../instagram/types";

// ─── API helpers ─────────────────────────────────────────────────────────────

const API = "/api/instagram";

async function apiFetch<T>(path: string, opts?: RequestInit): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...opts,
  });
  const json = await res.json();
  if (!json.success) throw new Error(json.error ?? "API error");
  return json.data as T;
}

// ─── Sub-components ───────────────────────────────────────────────────────────

const STATUS_META: Record<PostStatus, { label: string; color: string; icon: ReactNode }> = {
  pending:    { label: "Draft",      color: "text-slate-500 bg-slate-100",   icon: <BookOpen className="w-3 h-3" /> },
  generating: { label: "Generating", color: "text-blue-600 bg-blue-50",      icon: <RefreshCw className="w-3 h-3 animate-spin" /> },
  scheduled:  { label: "Scheduled",  color: "text-amber-600 bg-amber-50",    icon: <Clock className="w-3 h-3" /> },
  posted:     { label: "Posted",     color: "text-emerald-600 bg-emerald-50", icon: <CheckCircle2 className="w-3 h-3" /> },
  failed:     { label: "Failed",     color: "text-red-600 bg-red-50",        icon: <XCircle className="w-3 h-3" /> },
};

function StatusBadge({ status }: { status: PostStatus }) {
  const meta = STATUS_META[status];
  return (
    <span className={cn("inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full", meta.color)}>
      {meta.icon} {meta.label}
    </span>
  );
}

function StatCard({ label, value, sub, icon, color }: {
  label: string; value: string | number; sub?: string;
  icon: ReactNode; color: string;
}) {
  return (
    <div className="bg-white/70 backdrop-blur rounded-2xl p-4 flex items-center gap-3 shadow-sm border border-white/60">
      <div className={cn("w-10 h-10 rounded-xl flex items-center justify-center text-white shadow-sm", color)}>
        {icon}
      </div>
      <div>
        <p className="text-xl font-bold text-slate-800">{value}</p>
        <p className="text-xs text-slate-500 font-medium">{label}</p>
        {sub && <p className="text-[10px] text-slate-400">{sub}</p>}
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

type Tab = "niches" | "generator" | "queue" | "setup";

export default function InstagramView() {
  const [tab, setTab] = useState<Tab>("niches");
  const [niches, setNiches] = useState<NicheConfig[]>([]);
  const [posts, setPosts] = useState<Post[]>([]);
  const [stats, setStats] = useState<{
    total: number; postedToday: number; scheduled: number;
    failed: number; schedulerRunning: boolean;
  } | null>(null);
  const [selectedNiche, setSelectedNiche] = useState<NicheId | null>(null);
  const [generating, setGenerating] = useState(false);
  const [bulkGenerating, setBulkGenerating] = useState(false);
  const [customTopic, setCustomTopic] = useState("");
  const [toast, setToast] = useState<{ msg: string; ok: boolean } | null>(null);
  const [expandedNiche, setExpandedNiche] = useState<NicheId | null>(null);

  // Setup tab state
  const [setupNiche, setSetupNiche] = useState<NicheId>("motivational_quotes");
  const [igUserId, setIgUserId] = useState("");
  const [igToken, setIgToken] = useState("");
  const [connectingAccount, setConnectingAccount] = useState(false);

  const showToast = (msg: string, ok = true) => {
    setToast({ msg, ok });
    setTimeout(() => setToast(null), 3500);
  };

  const fetchAll = useCallback(async () => {
    try {
      const [n, p, s] = await Promise.all([
        apiFetch<NicheConfig[]>("/niches"),
        apiFetch<Post[]>("/posts?limit=30"),
        apiFetch<any>("/stats"),
      ]);
      setNiches(n);
      setPosts(p);
      setStats(s);
    } catch {/* server might not be running in demo */}
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  // Poll for updates every 30s
  useEffect(() => {
    const id = setInterval(fetchAll, 30_000);
    return () => clearInterval(id);
  }, [fetchAll]);

  async function handleGenerate() {
    if (!selectedNiche) return showToast("Pick a niche first", false);
    setGenerating(true);
    try {
      await apiFetch("/generate", {
        method: "POST",
        body: JSON.stringify({ niche: selectedNiche, customTopic: customTopic || undefined }),
      });
      setCustomTopic("");
      await fetchAll();
      showToast("Post generated and saved as draft!");
    } catch (e: any) {
      showToast(e.message, false);
    } finally {
      setGenerating(false);
    }
  }

  async function handleBulkGenerate() {
    if (!selectedNiche) return showToast("Pick a niche first", false);
    setBulkGenerating(true);
    try {
      const result = await apiFetch<{ created: number }>("/generate/bulk", {
        method: "POST",
        body: JSON.stringify({ niche: selectedNiche, count: 6 }),
      });
      await fetchAll();
      showToast(`${result.created} posts generated & scheduled!`);
    } catch (e: any) {
      showToast(e.message, false);
    } finally {
      setBulkGenerating(false);
    }
  }

  async function handleDeletePost(id: number) {
    try {
      await apiFetch(`/posts/${id}`, { method: "DELETE" });
      setPosts((p) => p.filter((x) => x.id !== id));
      showToast("Post deleted");
    } catch (e: any) {
      showToast(e.message, false);
    }
  }

  async function handleConnectAccount() {
    if (!igUserId || !igToken) return showToast("Fill all fields", false);
    setConnectingAccount(true);
    try {
      await apiFetch("/accounts", {
        method: "POST",
        body: JSON.stringify({ niche: setupNiche, igUserId, igAccessToken: igToken }),
      });
      showToast("Instagram account connected!");
      setIgUserId(""); setIgToken("");
    } catch (e: any) {
      showToast(e.message, false);
    } finally {
      setConnectingAccount(false);
    }
  }

  function copyToClipboard(text: string) {
    navigator.clipboard.writeText(text).then(() => showToast("Copied!"));
  }

  const TABS: { id: Tab; label: string; icon: ReactNode }[] = [
    { id: "niches",    label: "Niches",    icon: <TrendingUp className="w-4 h-4" /> },
    { id: "generator", label: "Generate",  icon: <Sparkles className="w-4 h-4" /> },
    { id: "queue",     label: "Queue",     icon: <Calendar className="w-4 h-4" /> },
    { id: "setup",     label: "Setup",     icon: <Instagram className="w-4 h-4" /> },
  ];

  return (
    <div className="min-h-full pb-4">
      {/* Header */}
      <div className="bg-gradient-to-br from-purple-600 to-pink-600 px-5 pt-6 pb-8">
        <div className="flex items-center gap-3 mb-1">
          <Instagram className="w-7 h-7 text-white" />
          <h2 className="text-2xl font-bold text-white">Instagram Autopilot</h2>
        </div>
        <p className="text-purple-100 text-sm">Faceless niches · AI content · Auto-posting</p>

        {/* Stats row */}
        {stats && (
          <div className="grid grid-cols-4 gap-2 mt-4">
            {[
              { label: "Total", value: stats.total, color: "bg-white/20" },
              { label: "Today", value: stats.postedToday, color: "bg-white/20" },
              { label: "Queued", value: stats.scheduled, color: "bg-white/20" },
              { label: "Failed", value: stats.failed, color: stats.failed > 0 ? "bg-red-400/40" : "bg-white/20" },
            ].map((s) => (
              <div key={s.label} className={cn("rounded-xl p-2 text-center", s.color)}>
                <p className="text-white font-bold text-lg leading-none">{s.value}</p>
                <p className="text-purple-100 text-[10px] mt-0.5">{s.label}</p>
              </div>
            ))}
          </div>
        )}
        {stats && (
          <div className="mt-2 flex items-center gap-1.5">
            <div className={cn("w-2 h-2 rounded-full", stats.schedulerRunning ? "bg-green-300 animate-pulse" : "bg-red-300")} />
            <span className="text-purple-100 text-xs">
              Scheduler {stats.schedulerRunning ? "running" : "stopped"}
            </span>
          </div>
        )}
      </div>

      {/* Tab nav */}
      <div className="flex bg-white/80 backdrop-blur sticky top-0 z-10 border-b border-slate-100 shadow-sm -mt-1">
        {TABS.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={cn(
              "flex-1 flex flex-col items-center py-2.5 gap-0.5 text-[10px] font-semibold transition-colors",
              tab === t.id
                ? "text-purple-600 border-b-2 border-purple-500"
                : "text-slate-400 border-b-2 border-transparent hover:text-slate-600"
            )}
          >
            {t.icon}
            {t.label}
          </button>
        ))}
      </div>

      <div className="px-4 pt-4 space-y-4">
        {/* ── NICHES TAB ── */}
        {tab === "niches" && (
          <div className="space-y-3">
            <p className="text-xs text-slate-500 font-medium">Tap a niche to see details & example accounts</p>
            {niches.map((niche) => (
              <div key={niche.id} className="bg-white rounded-2xl shadow-sm border border-slate-100 overflow-hidden">
                {/* Niche header */}
                <button
                  onClick={() => setExpandedNiche(expandedNiche === niche.id ? null : niche.id)}
                  className="w-full flex items-center gap-3 p-4"
                >
                  <div className={cn(
                    "w-12 h-12 rounded-2xl bg-gradient-to-br flex items-center justify-center text-2xl flex-shrink-0",
                    niche.color
                  )}>
                    {niche.icon}
                  </div>
                  <div className="flex-1 text-left">
                    <p className="font-bold text-slate-800 text-sm">{niche.name}</p>
                    <p className="text-xs text-emerald-600 font-semibold">{niche.avgMonthlyRevenue}/mo</p>
                    <p className="text-[10px] text-slate-400 mt-0.5">{niche.postingFrequency} · Best: {niche.bestPostTimes.join(", ")}</p>
                  </div>
                  <ChevronRight className={cn("w-4 h-4 text-slate-300 transition-transform", expandedNiche === niche.id && "rotate-90")} />
                </button>

                {expandedNiche === niche.id && (
                  <div className="border-t border-slate-50 px-4 pb-4 space-y-3">
                    <p className="text-xs text-slate-600 leading-relaxed pt-2">{niche.description}</p>

                    {/* Content style */}
                    <div className="bg-slate-50 rounded-xl p-3">
                      <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mb-1">Content Style</p>
                      <p className="text-xs text-slate-600">{niche.contentStyle}</p>
                    </div>

                    {/* Success accounts */}
                    <div>
                      <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mb-2">Example Successful Accounts</p>
                      <div className="space-y-2">
                        {niche.successAccounts.map((acc) => (
                          <div key={acc.handle} className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-3 border border-purple-100">
                            <div className="flex items-center justify-between mb-1">
                              <span className="font-bold text-purple-700 text-sm">{acc.handle}</span>
                              <span className="text-xs text-slate-500 font-semibold flex items-center gap-1">
                                <Users className="w-3 h-3" /> {acc.followers}
                              </span>
                            </div>
                            <p className="text-xs text-emerald-600 font-semibold mb-1">{acc.monthlyEarnings}/mo</p>
                            <p className="text-[10px] text-slate-500 leading-relaxed">{acc.strategy}</p>
                          </div>
                        ))}
                      </div>
                    </div>

                    {/* Hashtags */}
                    <div>
                      <p className="text-[10px] text-slate-400 font-semibold uppercase tracking-wider mb-2">Top Hashtags</p>
                      <div className="flex flex-wrap gap-1">
                        {niche.hashtagGroups.flat().slice(0, 12).map((tag) => (
                          <button
                            key={tag}
                            onClick={() => copyToClipboard(tag)}
                            className="text-[10px] bg-purple-50 text-purple-600 px-2 py-0.5 rounded-full font-medium border border-purple-100"
                          >
                            {tag}
                          </button>
                        ))}
                      </div>
                    </div>

                    {/* Quick generate */}
                    <button
                      onClick={() => { setSelectedNiche(niche.id); setTab("generator"); }}
                      className={cn(
                        "w-full py-2.5 rounded-xl text-sm font-bold text-white bg-gradient-to-r flex items-center justify-center gap-2",
                        niche.color
                      )}
                    >
                      <Sparkles className="w-4 h-4" />
                      Generate Content for This Niche
                    </button>
                  </div>
                )}
              </div>
            ))}

            {niches.length === 0 && (
              <div className="text-center py-12 text-slate-400">
                <Instagram className="w-12 h-12 mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">Start the API server to load niches</p>
                <code className="text-xs bg-slate-100 px-2 py-1 rounded mt-2 block">npm run server</code>
              </div>
            )}
          </div>
        )}

        {/* ── GENERATOR TAB ── */}
        {tab === "generator" && (
          <div className="space-y-4">
            {/* Niche selector */}
            <div>
              <p className="text-xs font-semibold text-slate-500 mb-2">Select Niche</p>
              <div className="grid grid-cols-1 gap-2">
                {niches.map((n) => (
                  <button
                    key={n.id}
                    onClick={() => setSelectedNiche(n.id)}
                    className={cn(
                      "flex items-center gap-3 p-3 rounded-xl border-2 text-left transition-all",
                      selectedNiche === n.id
                        ? "border-purple-400 bg-purple-50"
                        : "border-slate-100 bg-white hover:border-slate-200"
                    )}
                  >
                    <span className="text-xl">{n.icon}</span>
                    <div>
                      <p className="font-semibold text-sm text-slate-800">{n.name}</p>
                      <p className="text-[10px] text-emerald-600 font-medium">{n.avgMonthlyRevenue}/mo</p>
                    </div>
                    {selectedNiche === n.id && (
                      <CheckCircle2 className="w-4 h-4 text-purple-500 ml-auto" />
                    )}
                  </button>
                ))}
              </div>
            </div>

            {/* Custom topic */}
            <div>
              <label className="text-xs font-semibold text-slate-500 mb-1.5 block">
                Custom Topic <span className="font-normal text-slate-400">(optional — leave blank for AI to pick)</span>
              </label>
              <input
                value={customTopic}
                onChange={(e) => setCustomTopic(e.target.value)}
                placeholder="e.g. compound interest, sleep optimization, AI art tools..."
                className="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-purple-400 bg-white"
              />
            </div>

            {/* Action buttons */}
            <div className="space-y-2">
              <button
                onClick={handleGenerate}
                disabled={!selectedNiche || generating}
                className="w-full py-3.5 rounded-2xl bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50 shadow-lg shadow-purple-200"
              >
                {generating ? (
                  <><RefreshCw className="w-4 h-4 animate-spin" /> Generating with AI...</>
                ) : (
                  <><Sparkles className="w-4 h-4" /> Generate 1 Post</>
                )}
              </button>

              <button
                onClick={handleBulkGenerate}
                disabled={!selectedNiche || bulkGenerating}
                className="w-full py-3 rounded-2xl bg-gradient-to-r from-amber-500 to-orange-500 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50 shadow-md shadow-orange-100"
              >
                {bulkGenerating ? (
                  <><RefreshCw className="w-4 h-4 animate-spin" /> Generating 6 posts...</>
                ) : (
                  <><Zap className="w-4 h-4" /> Auto-Schedule 6 Posts (1 Week)</>
                )}
              </button>
            </div>

            {/* Info box */}
            <div className="bg-blue-50 border border-blue-100 rounded-2xl p-4 space-y-1.5">
              <div className="flex items-center gap-2">
                <AlertCircle className="w-4 h-4 text-blue-500 flex-shrink-0" />
                <p className="text-xs font-bold text-blue-700">How it works</p>
              </div>
              <ul className="text-xs text-blue-600 space-y-1 pl-6 list-disc">
                <li>Gemini AI writes the caption, hashtags & image prompt</li>
                <li>Posts are saved to the queue with optimal schedule times</li>
                <li>The scheduler auto-publishes via Instagram Graph API</li>
                <li>Connect your IG account in the Setup tab first</li>
                <li>Add an image URL to each post before it can be published</li>
              </ul>
            </div>
          </div>
        )}

        {/* ── QUEUE TAB ── */}
        {tab === "queue" && (
          <div className="space-y-3">
            {/* Filter buttons */}
            <div className="flex gap-2 overflow-x-auto pb-1">
              {(["all", "scheduled", "posted", "pending", "failed"] as const).map((s) => (
                <button
                  key={s}
                  onClick={() => apiFetch<Post[]>(`/posts${s !== "all" ? `?status=${s}` : ""}?limit=30`).then(setPosts).catch(() => {})}
                  className="flex-shrink-0 text-xs px-3 py-1.5 rounded-full bg-white border border-slate-200 font-medium text-slate-600 hover:border-purple-300 hover:text-purple-600 capitalize"
                >
                  {s}
                </button>
              ))}
            </div>

            {posts.length === 0 ? (
              <div className="text-center py-12 text-slate-400">
                <Calendar className="w-12 h-12 mx-auto mb-3 opacity-30" />
                <p className="text-sm font-medium">No posts yet</p>
                <p className="text-xs mt-1">Generate content in the Generate tab</p>
              </div>
            ) : (
              posts.map((post) => (
                <div key={post.id} className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4">
                  <div className="flex items-start justify-between gap-2 mb-2">
                    <div className="flex items-center gap-2 flex-wrap">
                      <StatusBadge status={post.status} />
                      <span className="text-[10px] text-slate-400 font-medium capitalize">
                        {post.niche.replace(/_/g, " ")}
                      </span>
                    </div>
                    <button
                      onClick={() => handleDeletePost(post.id)}
                      className="text-slate-300 hover:text-red-400 transition-colors flex-shrink-0"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>

                  <p className="text-sm text-slate-700 leading-relaxed line-clamp-3">{post.caption}</p>

                  {post.imagePrompt && (
                    <div className="mt-2 bg-purple-50 rounded-lg p-2">
                      <p className="text-[10px] text-purple-500 font-semibold uppercase tracking-wider mb-0.5">Image Prompt</p>
                      <p className="text-xs text-purple-700 line-clamp-2">{post.imagePrompt}</p>
                      <button
                        onClick={() => copyToClipboard(post.imagePrompt)}
                        className="mt-1 flex items-center gap-1 text-[10px] text-purple-500 hover:text-purple-700"
                      >
                        <Copy className="w-3 h-3" /> Copy for Midjourney/DALL-E
                      </button>
                    </div>
                  )}

                  {post.hashtags && (
                    <p className="text-[10px] text-slate-400 mt-2 line-clamp-1">{post.hashtags}</p>
                  )}

                  <div className="flex items-center justify-between mt-2.5">
                    <div className="text-[10px] text-slate-400">
                      {post.scheduledAt && (
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3" />
                          {new Date(post.scheduledAt).toLocaleString()}
                        </span>
                      )}
                      {post.postedAt && (
                        <span className="flex items-center gap-1 text-emerald-500">
                          <CheckCircle2 className="w-3 h-3" />
                          Posted {new Date(post.postedAt).toLocaleString()}
                        </span>
                      )}
                      {!post.scheduledAt && !post.postedAt && (
                        <span>Created {new Date(post.createdAt).toLocaleString()}</span>
                      )}
                    </div>
                    {post.igPostId && (
                      <a
                        href={`https://www.instagram.com/p/${post.igPostId}/`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-1 text-[10px] text-purple-500 hover:text-purple-700"
                      >
                        <ExternalLink className="w-3 h-3" /> View on IG
                      </a>
                    )}
                  </div>

                  {post.errorMessage && (
                    <div className="mt-2 bg-red-50 rounded-lg p-2">
                      <p className="text-[10px] text-red-500">{post.errorMessage}</p>
                    </div>
                  )}
                </div>
              ))
            )}
          </div>
        )}

        {/* ── SETUP TAB ── */}
        {tab === "setup" && (
          <div className="space-y-4">
            {/* Step-by-step guide */}
            <div className="bg-gradient-to-br from-purple-50 to-pink-50 rounded-2xl p-4 border border-purple-100">
              <h3 className="font-bold text-slate-800 mb-3 flex items-center gap-2">
                <Play className="w-4 h-4 text-purple-500" /> Setup Guide
              </h3>
              {[
                {
                  step: "1",
                  title: "Create Instagram Business/Creator Account",
                  desc: "Go to Settings → Account → Switch to Professional Account",
                },
                {
                  step: "2",
                  title: "Create a Facebook App",
                  desc: "Visit developers.facebook.com → Create App → Add Instagram Graph API product",
                },
                {
                  step: "3",
                  title: "Get Instagram User ID & Access Token",
                  desc: "Use Graph API Explorer to get your IG User ID and generate a long-lived token",
                },
                {
                  step: "4",
                  title: "Set GEMINI_API_KEY in .env",
                  desc: "Add your Gemini API key to .env file for AI content generation",
                },
                {
                  step: "5",
                  title: "Run the server",
                  desc: "Run: npm run server — the scheduler starts automatically",
                },
              ].map((item) => (
                <div key={item.step} className="flex gap-3 mb-3 last:mb-0">
                  <div className="w-6 h-6 rounded-full bg-purple-500 text-white text-xs font-bold flex items-center justify-center flex-shrink-0 mt-0.5">
                    {item.step}
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-slate-700">{item.title}</p>
                    <p className="text-xs text-slate-500">{item.desc}</p>
                  </div>
                </div>
              ))}
            </div>

            {/* Connect account form */}
            <div className="bg-white rounded-2xl shadow-sm border border-slate-100 p-4 space-y-3">
              <h3 className="font-bold text-slate-800 flex items-center gap-2">
                <Instagram className="w-4 h-4 text-purple-500" /> Connect Instagram Account
              </h3>

              <div>
                <label className="text-xs font-semibold text-slate-500 mb-1 block">Niche</label>
                <select
                  value={setupNiche}
                  onChange={(e) => setSetupNiche(e.target.value as NicheId)}
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-purple-400 bg-white"
                >
                  {niches.map((n) => (
                    <option key={n.id} value={n.id}>{n.icon} {n.name}</option>
                  ))}
                </select>
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-500 mb-1 block">Instagram User ID</label>
                <input
                  value={igUserId}
                  onChange={(e) => setIgUserId(e.target.value)}
                  placeholder="e.g. 17841400008460005"
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-purple-400"
                />
              </div>

              <div>
                <label className="text-xs font-semibold text-slate-500 mb-1 block">Long-lived Access Token</label>
                <input
                  value={igToken}
                  onChange={(e) => setIgToken(e.target.value)}
                  placeholder="Paste your token here..."
                  type="password"
                  className="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:border-purple-400"
                />
              </div>

              <button
                onClick={handleConnectAccount}
                disabled={connectingAccount || !igUserId || !igToken}
                className="w-full py-3 rounded-xl bg-gradient-to-r from-purple-600 to-pink-600 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50"
              >
                {connectingAccount ? (
                  <><RefreshCw className="w-4 h-4 animate-spin" /> Connecting...</>
                ) : (
                  <><Plus className="w-4 h-4" /> Connect Account</>
                )}
              </button>
            </div>

            {/* .env template */}
            <div className="bg-slate-900 rounded-2xl p-4">
              <div className="flex items-center justify-between mb-2">
                <p className="text-xs font-semibold text-slate-400">.env file template</p>
                <button
                  onClick={() => copyToClipboard("GEMINI_API_KEY=your_key_here\nIG_APP_ID=your_fb_app_id\nIG_APP_SECRET=your_fb_app_secret\nAPI_PORT=3001")}
                  className="text-xs text-slate-400 hover:text-white flex items-center gap-1"
                >
                  <Copy className="w-3 h-3" /> Copy
                </button>
              </div>
              <pre className="text-xs text-green-400 font-mono leading-relaxed">{`GEMINI_API_KEY=your_key_here
IG_APP_ID=your_fb_app_id
IG_APP_SECRET=your_fb_app_secret
API_PORT=3001`}</pre>
            </div>

            {/* Revenue potential */}
            <div className="bg-emerald-50 border border-emerald-100 rounded-2xl p-4">
              <div className="flex items-center gap-2 mb-3">
                <BarChart2 className="w-4 h-4 text-emerald-600" />
                <p className="font-bold text-emerald-800 text-sm">Revenue Potential</p>
              </div>
              <div className="space-y-1.5">
                {[
                  { niche: "Motivational Quotes", rev: "$3K–$15K/mo" },
                  { niche: "Personal Finance", rev: "$5K–$30K/mo" },
                  { niche: "AI & Technology", rev: "$4K–$20K/mo" },
                  { niche: "Health & Wellness", rev: "$3.5K–$18K/mo" },
                  { niche: "Aesthetic Nature", rev: "$2K–$12K/mo" },
                ].map((item) => (
                  <div key={item.niche} className="flex justify-between items-center">
                    <span className="text-xs text-slate-600">{item.niche}</span>
                    <span className="text-xs font-bold text-emerald-600">{item.rev}</span>
                  </div>
                ))}
              </div>
              <p className="text-[10px] text-slate-400 mt-3 leading-relaxed">
                Revenue via: sponsored posts, digital products, affiliate marketing, brand deals. Results vary based on consistency and audience quality.
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Toast */}
      {toast && (
        <div className={cn(
          "fixed bottom-24 left-1/2 -translate-x-1/2 px-4 py-2.5 rounded-full text-sm font-semibold shadow-lg z-50 flex items-center gap-2 transition-all",
          toast.ok
            ? "bg-emerald-500 text-white shadow-emerald-200"
            : "bg-red-500 text-white shadow-red-200"
        )}>
          {toast.ok ? <CheckCircle2 className="w-4 h-4" /> : <XCircle className="w-4 h-4" />}
          {toast.msg}
        </div>
      )}
    </div>
  );
}
