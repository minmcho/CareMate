/**
 * GPU Design Studio — Client-side API layer
 * Communicates with the multiagent Express server via SSE streaming.
 */

export interface AgentInfo {
  id: string;
  name: string;
  description: string;
  icon: string;
}

export interface OrchestratorPlan {
  summary: string;
  agents: Array<{ agent: string; task: string; priority: number }>;
  context: string;
}

export interface AgentResult {
  agent: string;
  task: string;
  response: string;
  tokens: number;
}

export interface StudioResponse {
  plan: OrchestratorPlan;
  results: AgentResult[];
  totalTokens: number;
}

export type SSEEvent =
  | { type: "orchestrating"; message: string }
  | { type: "plan"; plan: OrchestratorPlan }
  | { type: "agent_start"; agent: string; task: string }
  | { type: "agent_result"; result: AgentResult }
  | { type: "done"; response?: StudioResponse }
  | { type: "error"; message: string };

export type ChatMessage = {
  id: string;
  role: "user" | "assistant" | "system";
  content: string;
  agent?: string;
  plan?: OrchestratorPlan;
  results?: AgentResult[];
  timestamp: number;
};

const GPU_STUDIO_API = "http://localhost:3001";

/** Fetch the list of available specialist agents */
export async function fetchAgents(): Promise<AgentInfo[]> {
  const res = await fetch(`${GPU_STUDIO_API}/api/gpu-studio/agents`);
  if (!res.ok) throw new Error(`Failed to fetch agents: ${res.statusText}`);
  const data = await res.json();
  return data.agents as AgentInfo[];
}

/**
 * Send a query to the GPU Studio orchestrator.
 * Calls onEvent for each SSE event received.
 */
export async function queryGPUStudio(
  message: string,
  history: ChatMessage[],
  onEvent: (event: SSEEvent) => void,
  signal?: AbortSignal
): Promise<void> {
  const historyForServer = history.map((m) => ({
    role: m.role,
    content: m.content,
    agent: m.agent,
  }));

  const res = await fetch(`${GPU_STUDIO_API}/api/gpu-studio/query`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message, history: historyForServer }),
    signal,
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Server error ${res.status}: ${text}`);
  }

  const reader = res.body?.getReader();
  if (!reader) throw new Error("No response body");

  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";

    for (const line of lines) {
      if (!line.startsWith("data: ")) continue;
      const json = line.slice(6).trim();
      if (!json) continue;
      try {
        const event = JSON.parse(json) as SSEEvent;
        onEvent(event);
      } catch {
        // skip malformed chunks
      }
    }
  }
}

/**
 * Call a single specialist agent directly (bypasses orchestrator).
 */
export async function queryAgent(
  agentName: string,
  task: string,
  context: string,
  history: ChatMessage[],
  onEvent: (event: SSEEvent) => void,
  signal?: AbortSignal
): Promise<void> {
  const historyForServer = history.map((m) => ({
    role: m.role,
    content: m.content,
  }));

  const res = await fetch(
    `${GPU_STUDIO_API}/api/gpu-studio/agent/${agentName}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task, context, history: historyForServer }),
      signal,
    }
  );

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Server error ${res.status}: ${text}`);
  }

  const reader = res.body?.getReader();
  if (!reader) throw new Error("No response body");

  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;

    buffer += decoder.decode(value, { stream: true });
    const lines = buffer.split("\n");
    buffer = lines.pop() ?? "";

    for (const line of lines) {
      if (!line.startsWith("data: ")) continue;
      const json = line.slice(6).trim();
      if (!json) continue;
      try {
        const event = JSON.parse(json) as SSEEvent;
        onEvent(event);
      } catch {
        // skip malformed chunks
      }
    }
  }
}

export const AGENT_COLORS: Record<string, string> = {
  design: "blue",
  optimizer: "amber",
  codegen: "emerald",
  debugger: "red",
};

export const AGENT_LABELS: Record<string, string> = {
  design: "Architecture Designer",
  optimizer: "Performance Optimizer",
  codegen: "Code Generator",
  debugger: "GPU Debugger",
};
