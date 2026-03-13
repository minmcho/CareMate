/**
 * GPU Design Studio — Multiagent AI interface
 * A collaborative workspace powered by specialized Claude agents for
 * GPU architecture design, optimization, code generation, and debugging.
 */

import React, { useState, useRef, useCallback, useEffect } from "react";
import { motion, AnimatePresence } from "motion/react";
import {
  Cpu,
  Zap,
  Code2,
  Bug,
  Send,
  StopCircle,
  ChevronDown,
  ChevronUp,
  Sparkles,
  Activity,
  Network,
  Copy,
  Check,
} from "lucide-react";
import { cn } from "../lib/utils";
import {
  queryGPUStudio,
  queryAgent,
  AGENT_COLORS,
  AGENT_LABELS,
  type ChatMessage,
  type AgentResult,
  type OrchestratorPlan,
  type SSEEvent,
} from "../lib/gpuAgents";

// ─── Constants ────────────────────────────────────────────────────────────────

const AGENT_ICONS: Record<string, React.ReactElement> = {
  design: <Cpu className="w-4 h-4" />,
  optimizer: <Zap className="w-4 h-4" />,
  codegen: <Code2 className="w-4 h-4" />,
  debugger: <Bug className="w-4 h-4" />,
};

const AGENT_BADGE_CLASSES: Record<string, string> = {
  design: "bg-blue-100 text-blue-700 border-blue-200",
  optimizer: "bg-amber-100 text-amber-700 border-amber-200",
  codegen: "bg-emerald-100 text-emerald-700 border-emerald-200",
  debugger: "bg-red-100 text-red-700 border-red-200",
};

const AGENT_ACCENT: Record<string, string> = {
  design: "border-l-blue-500",
  optimizer: "border-l-amber-500",
  codegen: "border-l-emerald-500",
  debugger: "border-l-red-500",
};

const EXAMPLE_PROMPTS = [
  "Design a Vulkan compute pipeline for particle simulation with 1M particles",
  "Generate a WGSL compute shader for matrix multiplication with tiling optimization",
  "Optimize a CUDA kernel that's hitting memory bandwidth bottleneck",
  "Debug a Vulkan validation error: image layout transition missing barrier",
  "Design GPU memory hierarchy for a real-time ray tracer using RTX",
  "Generate GLSL vertex and fragment shaders for PBR rendering",
];

// ─── Sub-components ───────────────────────────────────────────────────────────

function AgentBadge({ agent }: { agent: string }) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs font-semibold border",
        AGENT_BADGE_CLASSES[agent] ?? "bg-slate-100 text-slate-600 border-slate-200"
      )}
    >
      {AGENT_ICONS[agent] ?? <Sparkles className="w-3 h-3" />}
      {AGENT_LABELS[agent] ?? agent}
    </span>
  );
}

function PlanCard({ plan }: { plan: OrchestratorPlan }) {
  const [expanded, setExpanded] = useState(false);
  return (
    <div className="bg-indigo-50 border border-indigo-200 rounded-xl p-3 text-sm">
      <button
        className="flex w-full items-center justify-between font-semibold text-indigo-700 gap-2"
        onClick={() => setExpanded((v) => !v)}
      >
        <span className="flex items-center gap-2">
          <Network className="w-4 h-4 shrink-0" />
          Orchestration Plan
        </span>
        {expanded ? (
          <ChevronUp className="w-4 h-4 shrink-0" />
        ) : (
          <ChevronDown className="w-4 h-4 shrink-0" />
        )}
      </button>
      {expanded && (
        <div className="mt-3 space-y-2">
          <p className="text-slate-600 text-xs">{plan.summary}</p>
          <div className="space-y-1">
            {plan.agents.map((a, i) => (
              <div
                key={i}
                className="flex items-start gap-2 bg-white rounded-lg px-2 py-1.5 border border-indigo-100"
              >
                <span className="text-indigo-400 font-mono text-xs mt-0.5">
                  {a.priority}.
                </span>
                <div>
                  <AgentBadge agent={a.agent.toLowerCase()} />
                  <p className="text-slate-600 text-xs mt-0.5">{a.task}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

function CodeBlock({ code }: { code: string }) {
  const [copied, setCopied] = useState(false);
  const handleCopy = () => {
    navigator.clipboard.writeText(code).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };
  return (
    <div className="relative group">
      <pre className="bg-slate-900 text-slate-100 rounded-lg p-4 overflow-x-auto text-xs leading-relaxed font-mono whitespace-pre-wrap break-words">
        {code}
      </pre>
      <button
        onClick={handleCopy}
        className="absolute top-2 right-2 p-1.5 rounded-md bg-slate-700 hover:bg-slate-600 text-slate-300 opacity-0 group-hover:opacity-100 transition-opacity"
        title="Copy code"
      >
        {copied ? (
          <Check className="w-3.5 h-3.5 text-emerald-400" />
        ) : (
          <Copy className="w-3.5 h-3.5" />
        )}
      </button>
    </div>
  );
}

function FormattedResponse({ text }: { text: string }) {
  // Split on code blocks and render them separately
  const parts = text.split(/(```[\s\S]*?```)/g);
  return (
    <div className="space-y-3">
      {parts.map((part, i) => {
        if (part.startsWith("```")) {
          const lines = part.split("\n");
          const code = lines.slice(1, -1).join("\n");
          return <CodeBlock key={i} code={code} />;
        }
        // Render inline markdown-like formatting
        const html = part
          .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
          .replace(/`([^`]+)`/g, '<code class="bg-slate-100 px-1 rounded text-slate-800 text-xs font-mono">$1</code>')
          .replace(/^(#{1,3})\s+(.+)$/gm, (_, hashes, content) => {
            const size =
              hashes.length === 1
                ? "text-base font-bold"
                : hashes.length === 2
                  ? "text-sm font-bold"
                  : "text-xs font-semibold uppercase tracking-wide text-slate-500";
            return `<p class="${size} mt-3 mb-1">${content}</p>`;
          })
          .replace(/^[-•]\s+(.+)$/gm, '<li class="ml-4 list-disc text-sm">$1</li>')
          .replace(/^(\d+)\.\s+(.+)$/gm, '<li class="ml-4 list-decimal text-sm">$2</li>');
        return (
          <div
            key={i}
            className="text-sm text-slate-700 leading-relaxed"
            dangerouslySetInnerHTML={{ __html: html }}
          />
        );
      })}
    </div>
  );
}

function AgentResultCard({ result }: { result: AgentResult }) {
  const [expanded, setExpanded] = useState(true);
  const accent = AGENT_ACCENT[result.agent] ?? "border-l-slate-400";

  return (
    <div className={cn("border-l-4 bg-white rounded-r-xl shadow-sm border border-l-4 border-slate-100", accent)}>
      <button
        className="flex w-full items-center justify-between p-3 gap-2"
        onClick={() => setExpanded((v) => !v)}
      >
        <div className="flex items-center gap-2 min-w-0">
          <AgentBadge agent={result.agent} />
          <span className="text-xs text-slate-400 truncate">{result.task}</span>
        </div>
        <div className="flex items-center gap-2 shrink-0">
          <span className="text-xs text-slate-400">{result.tokens.toLocaleString()} tok</span>
          {expanded ? (
            <ChevronUp className="w-4 h-4 text-slate-400" />
          ) : (
            <ChevronDown className="w-4 h-4 text-slate-400" />
          )}
        </div>
      </button>
      {expanded && (
        <div className="px-3 pb-3 border-t border-slate-50 pt-3">
          <FormattedResponse text={result.response} />
        </div>
      )}
    </div>
  );
}

function TypingIndicator({ agents }: { agents: string[] }) {
  return (
    <div className="flex items-start gap-3">
      <div className="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shrink-0 shadow-sm">
        <Activity className="w-4 h-4 text-white animate-pulse" />
      </div>
      <div className="bg-white rounded-2xl rounded-tl-sm px-4 py-3 shadow-sm border border-slate-100 text-sm text-slate-600">
        {agents.length === 0 ? (
          <span className="flex items-center gap-2">
            <span>Orchestrating</span>
            <span className="flex gap-1">
              {[0, 1, 2].map((i) => (
                <span
                  key={i}
                  className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-bounce"
                  style={{ animationDelay: `${i * 0.15}s` }}
                />
              ))}
            </span>
          </span>
        ) : (
          <div className="space-y-1">
            <p className="text-xs text-slate-400 font-medium">Running agents</p>
            <div className="flex flex-wrap gap-1.5">
              {agents.map((a) => (
                <span key={a} className="flex items-center gap-1">
                  <AgentBadge agent={a} />
                  <span className="flex gap-0.5">
                    {[0, 1, 2].map((i) => (
                      <span
                        key={i}
                        className="w-1 h-1 bg-slate-300 rounded-full animate-bounce"
                        style={{ animationDelay: `${i * 0.15}s` }}
                      />
                    ))}
                  </span>
                </span>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function GPUStudioView() {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [activeAgents, setActiveAgents] = useState<string[]>([]);
  const [selectedAgent, setSelectedAgent] = useState<string>("auto");
  const [showExamples, setShowExamples] = useState(true);
  const abortRef = useRef<AbortController | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages, activeAgents]);

  const handleStop = useCallback(() => {
    abortRef.current?.abort();
    setIsLoading(false);
    setActiveAgents([]);
  }, []);

  const buildAssistantMessage = useCallback(
    (
      plan: OrchestratorPlan | undefined,
      results: AgentResult[],
      tokens: number
    ): ChatMessage => ({
      id: crypto.randomUUID(),
      role: "assistant",
      content: results.map((r) => r.response).join("\n\n---\n\n"),
      plan,
      results,
      timestamp: Date.now(),
    }),
    []
  );

  const handleSend = useCallback(async () => {
    const text = input.trim();
    if (!text || isLoading) return;

    setInput("");
    setShowExamples(false);
    setIsLoading(true);
    setActiveAgents([]);

    const userMsg: ChatMessage = {
      id: crypto.randomUUID(),
      role: "user",
      content: text,
      timestamp: Date.now(),
    };

    setMessages((prev) => [...prev, userMsg]);

    const controller = new AbortController();
    abortRef.current = controller;

    let currentPlan: OrchestratorPlan | undefined;
    let collectedResults: AgentResult[] = [];
    let totalTokens = 0;

    try {
      const onEvent = (event: SSEEvent) => {
        switch (event.type) {
          case "orchestrating":
            setActiveAgents([]);
            break;

          case "plan":
            currentPlan = event.plan;
            // Show a system message with the plan
            setMessages((prev) => [
              ...prev,
              {
                id: crypto.randomUUID(),
                role: "system",
                content: "",
                plan: event.plan,
                timestamp: Date.now(),
              },
            ]);
            break;

          case "agent_start":
            setActiveAgents((prev) =>
              prev.includes(event.agent) ? prev : [...prev, event.agent]
            );
            break;

          case "agent_result":
            collectedResults = [...collectedResults, event.result];
            totalTokens += event.result.tokens;
            setActiveAgents((prev) =>
              prev.filter((a) => a !== event.result.agent)
            );
            // Append individual result to the last system message or update it
            setMessages((prev) => {
              const last = prev[prev.length - 1];
              if (last?.role === "system" && last.results !== undefined) {
                return [
                  ...prev.slice(0, -1),
                  {
                    ...last,
                    results: [...(last.results ?? []), event.result],
                  },
                ];
              }
              return prev;
            });
            break;

          case "done":
            setActiveAgents([]);
            if (event.response) {
              setMessages((prev) => {
                // Replace the in-progress system message with final assistant message
                const withoutLast =
                  prev[prev.length - 1]?.role === "system"
                    ? prev.slice(0, -1)
                    : prev;
                return [
                  ...withoutLast,
                  buildAssistantMessage(
                    event.response!.plan,
                    event.response!.results,
                    event.response!.totalTokens
                  ),
                ];
              });
            }
            setIsLoading(false);
            break;

          case "error":
            setMessages((prev) => [
              ...prev,
              {
                id: crypto.randomUUID(),
                role: "system",
                content: `Error: ${event.message}`,
                timestamp: Date.now(),
              },
            ]);
            setIsLoading(false);
            setActiveAgents([]);
            break;
        }
      };

      if (selectedAgent === "auto") {
        await queryGPUStudio(text, messages, onEvent, controller.signal);
      } else {
        await queryAgent(
          selectedAgent,
          text,
          "",
          messages,
          onEvent,
          controller.signal
        );
        setIsLoading(false);
        setActiveAgents([]);
      }
    } catch (err) {
      if ((err as Error)?.name !== "AbortError") {
        setMessages((prev) => [
          ...prev,
          {
            id: crypto.randomUUID(),
            role: "system",
            content: `Connection error: ${(err as Error).message}. Make sure the GPU Studio server is running on port 3001.`,
            timestamp: Date.now(),
          },
        ]);
      }
      setIsLoading(false);
      setActiveAgents([]);
    }
  }, [input, isLoading, messages, selectedAgent, buildAssistantMessage]);

  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  const handleExampleClick = (prompt: string) => {
    setInput(prompt);
    textareaRef.current?.focus();
  };

  return (
    <div className="flex flex-col h-full">
      {/* Agent Selector Bar */}
      <div className="bg-white/60 backdrop-blur-xl border-b border-white/50 px-4 py-2.5 shrink-0">
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar">
          <span className="text-xs text-slate-400 font-medium shrink-0">Mode:</span>
          {[
            { id: "auto", label: "Auto (Orchestrated)", icon: <Network className="w-3.5 h-3.5" /> },
            { id: "design", label: "Design", icon: <Cpu className="w-3.5 h-3.5" /> },
            { id: "optimizer", label: "Optimizer", icon: <Zap className="w-3.5 h-3.5" /> },
            { id: "codegen", label: "Codegen", icon: <Code2 className="w-3.5 h-3.5" /> },
            { id: "debugger", label: "Debugger", icon: <Bug className="w-3.5 h-3.5" /> },
          ].map((agent) => (
            <button
              key={agent.id}
              onClick={() => setSelectedAgent(agent.id)}
              className={cn(
                "flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold border shrink-0 transition-all",
                selectedAgent === agent.id
                  ? agent.id === "auto"
                    ? "bg-gradient-to-r from-indigo-500 to-purple-500 text-white border-transparent shadow-sm"
                    : cn(
                        "text-white border-transparent shadow-sm",
                        agent.id === "design" && "bg-blue-500",
                        agent.id === "optimizer" && "bg-amber-500",
                        agent.id === "codegen" && "bg-emerald-500",
                        agent.id === "debugger" && "bg-red-500"
                      )
                  : "bg-white text-slate-600 border-slate-200 hover:border-slate-300"
              )}
            >
              {agent.icon}
              {agent.label}
            </button>
          ))}
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-4">
        {/* Welcome State */}
        {messages.length === 0 && !isLoading && (
          <div className="flex flex-col items-center text-center py-8 px-4">
            <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shadow-lg mb-4">
              <Cpu className="w-8 h-8 text-white" />
            </div>
            <h2 className="text-xl font-bold text-slate-800 mb-1">
              GPU Design Studio
            </h2>
            <p className="text-sm text-slate-500 max-w-xs mb-6">
              Multiagent AI for GPU architecture design, performance
              optimization, shader code generation, and debugging.
            </p>

            {/* Agent pills */}
            <div className="flex flex-wrap justify-center gap-2 mb-6">
              {Object.entries(AGENT_LABELS).map(([id, label]) => (
                <AgentBadge key={id} agent={id} />
              ))}
            </div>

            {/* Example prompts */}
            <AnimatePresence>
              {showExamples && (
                <motion.div
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="w-full max-w-md space-y-2"
                >
                  <p className="text-xs text-slate-400 font-medium mb-2">
                    Try an example:
                  </p>
                  {EXAMPLE_PROMPTS.map((p) => (
                    <button
                      key={p}
                      onClick={() => handleExampleClick(p)}
                      className="w-full text-left px-3 py-2.5 rounded-xl bg-white border border-slate-200 hover:border-indigo-300 hover:bg-indigo-50/50 text-xs text-slate-600 transition-all shadow-sm"
                    >
                      {p}
                    </button>
                  ))}
                </motion.div>
              )}
            </AnimatePresence>
          </div>
        )}

        {/* Chat Messages */}
        <AnimatePresence initial={false}>
          {messages.map((msg) => (
            <motion.div
              key={msg.id}
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.2 }}
            >
              {msg.role === "user" && (
                <div className="flex justify-end">
                  <div className="bg-gradient-to-br from-indigo-500 to-purple-600 text-white rounded-2xl rounded-tr-sm px-4 py-3 max-w-[80%] text-sm shadow-sm">
                    {msg.content}
                  </div>
                </div>
              )}

              {msg.role === "system" && (
                <div className="space-y-3">
                  {msg.plan && <PlanCard plan={msg.plan} />}
                  {msg.results && msg.results.length > 0 && (
                    <div className="space-y-2">
                      {msg.results.map((r, i) => (
                        <AgentResultCard key={i} result={r} />
                      ))}
                    </div>
                  )}
                  {!msg.plan && !msg.results && msg.content && (
                    <div className="bg-red-50 border border-red-200 rounded-xl px-4 py-3 text-sm text-red-700">
                      {msg.content}
                    </div>
                  )}
                </div>
              )}

              {msg.role === "assistant" && (
                <div className="flex items-start gap-3">
                  <div className="w-8 h-8 rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center shrink-0 shadow-sm mt-0.5">
                    <Sparkles className="w-4 h-4 text-white" />
                  </div>
                  <div className="flex-1 min-w-0 space-y-3">
                    {msg.plan && <PlanCard plan={msg.plan} />}
                    {msg.results && msg.results.length > 0 ? (
                      <div className="space-y-2">
                        {msg.results.map((r, i) => (
                          <AgentResultCard key={i} result={r} />
                        ))}
                      </div>
                    ) : (
                      <div className="bg-white rounded-2xl rounded-tl-sm px-4 py-3 shadow-sm border border-slate-100">
                        <FormattedResponse text={msg.content} />
                      </div>
                    )}
                    <p className="text-xs text-slate-400 px-1">
                      {new Date(msg.timestamp).toLocaleTimeString()}
                    </p>
                  </div>
                </div>
              )}
            </motion.div>
          ))}
        </AnimatePresence>

        {/* Typing Indicator */}
        {isLoading && <TypingIndicator agents={activeAgents} />}

        <div ref={bottomRef} />
      </div>

      {/* Input Area */}
      <div className="px-4 pb-4 shrink-0">
        <div className="bg-white rounded-2xl shadow-md border border-slate-200 overflow-hidden">
          <textarea
            ref={textareaRef}
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder={
              selectedAgent === "auto"
                ? "Ask about GPU design, optimization, code generation, or debugging..."
                : `Ask the ${AGENT_LABELS[selectedAgent] ?? selectedAgent}...`
            }
            rows={3}
            className="w-full px-4 pt-3 pb-2 text-sm text-slate-800 placeholder-slate-400 resize-none outline-none bg-transparent leading-relaxed"
            disabled={isLoading}
          />
          <div className="flex items-center justify-between px-3 pb-3 gap-2">
            <div className="flex items-center gap-1.5">
              <span className="text-xs text-slate-400">
                {selectedAgent === "auto" ? (
                  <span className="flex items-center gap-1">
                    <Network className="w-3 h-3" />
                    Orchestrated
                  </span>
                ) : (
                  <AgentBadge agent={selectedAgent} />
                )}
              </span>
            </div>
            <div className="flex items-center gap-2">
              {isLoading ? (
                <button
                  onClick={handleStop}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-red-100 text-red-600 text-xs font-semibold hover:bg-red-200 transition-all"
                >
                  <StopCircle className="w-3.5 h-3.5" />
                  Stop
                </button>
              ) : (
                <button
                  onClick={handleSend}
                  disabled={!input.trim()}
                  className={cn(
                    "flex items-center gap-1.5 px-4 py-1.5 rounded-full text-xs font-semibold transition-all",
                    input.trim()
                      ? "bg-gradient-to-r from-indigo-500 to-purple-500 text-white shadow-sm hover:shadow-md active:scale-95"
                      : "bg-slate-100 text-slate-400 cursor-not-allowed"
                  )}
                >
                  <Send className="w-3.5 h-3.5" />
                  Send
                </button>
              )}
            </div>
          </div>
        </div>
        <p className="text-center text-xs text-slate-400 mt-2">
          Press Enter to send · Shift+Enter for new line
        </p>
      </div>
    </div>
  );
}
