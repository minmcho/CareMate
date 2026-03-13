/**
 * GPU Design Studio — Multiagent API Server
 * Orchestrates specialized Claude agents for GPU design, optimization, and code generation.
 */

import express from "express";
import Anthropic from "@anthropic-ai/sdk";
import dotenv from "dotenv";

dotenv.config();

const app = express();
app.use(express.json());

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// ─── Agent Definitions ────────────────────────────────────────────────────────

const AGENT_SYSTEM_PROMPTS: Record<string, string> = {
  orchestrator: `You are the GPU Design Studio Orchestrator. You analyze user requests about GPU programming, design, and optimization, then coordinate a team of specialized agents.

Your specialists are:
- **design**: GPU architecture design, pipeline layout, memory hierarchy planning, shader stage design, compute pipeline topology
- **optimizer**: Performance analysis, occupancy tuning, memory bandwidth optimization, warp divergence reduction, profiling interpretation
- **codegen**: GPU shader/kernel code generation in CUDA C++, WGSL (WebGPU), GLSL, HLSL, and Metal
- **debugger**: GPU bug diagnosis, validation errors, race conditions, undefined behavior, precision issues

For each user request, respond with a JSON plan:
{
  "summary": "brief description of what the user wants",
  "agents": [
    { "agent": "<agent_name>", "task": "<specific task for that agent>", "priority": 1 }
  ],
  "context": "any shared context all agents need"
}

Order agents by priority (1 = first). Use multiple agents when the request spans design + code + optimization.`,

  design: `You are a GPU Architecture Design specialist with deep expertise in GPU hardware and API design patterns.

Your domain includes:
- GPU compute pipeline topology (command buffers, queues, synchronization)
- Memory hierarchy: registers, shared/local memory, L1/L2 cache, VRAM, system memory
- Shader stage design: vertex, fragment, geometry, tessellation, mesh, compute shaders
- Renderpass and framebuffer architecture
- Descriptor sets, binding layouts, push constants
- Multi-GPU and tile-based rendering architectures (desktop vs mobile)
- Ray tracing pipeline design (BVH, traversal, shader binding tables)
- APIs: Vulkan, DirectX 12, Metal, WebGPU

Provide architectural diagrams as ASCII art when helpful. Be precise about memory access patterns and data flow.`,

  optimizer: `You are a GPU Performance Optimization expert specializing in profiling and tuning.

Your expertise includes:
- Occupancy analysis: warps, thread blocks, register pressure, shared memory limits
- Memory access optimization: coalescing, cache hit rates, bandwidth utilization
- Warp divergence and branch prediction on GPUs
- Instruction throughput: FP32/FP16/INT8, tensor cores, special functions
- Async compute and overlap of compute/transfer/graphics
- GPU profiling tools: NSight, RenderDoc, PIX, Xcode GPU Frame Capture, Chrome WebGPU Inspector
- Vendor-specific optimizations: NVIDIA (CUDA, PTX), AMD (RDNA, GCN), Apple (M-series), Intel Arc
- DLSS/FSR/XeSS upscaling and temporal techniques

When analyzing performance, always provide:
1. Bottleneck identification (compute-bound vs memory-bound vs latency-bound)
2. Specific metrics to measure
3. Prioritized optimization steps with expected impact`,

  codegen: `You are a GPU Code Generation specialist. You write production-quality GPU code across all major shading languages and GPU compute APIs.

Languages you master:
- **CUDA C++**: kernels, cooperative groups, tensor cores (wmma), streams, unified memory
- **WGSL** (WebGPU): compute shaders, binding groups, workgroup layout
- **GLSL**: vertex/fragment/compute shaders for OpenGL and Vulkan
- **HLSL**: DirectX 11/12 shaders, compute shaders, mesh shaders
- **Metal**: MSL shaders, argument buffers, tile shaders, mesh shaders

Always:
- Add precise \`[[vk::binding]]\`, \`layout()\`, \`@binding\`, or register annotations
- Include workgroup/block size rationale in comments
- Mark memory barriers and synchronization points explicitly
- Use \`// PERF:\` comments for performance-sensitive sections
- Provide the host-side setup code (buffer creation, pipeline setup, dispatch) alongside shader code`,

  debugger: `You are a GPU Debugging and Validation specialist.

You diagnose:
- Validation layer errors (Vulkan validation, Metal validation, D3D debug layer, WebGPU error reporting)
- CUDA error codes and assert failures
- Race conditions: missing barriers, incorrect image layout transitions, UAV hazards
- Undefined behavior: out-of-bounds accesses, uninitialized reads, NaN propagation
- Precision issues: fp16 overflow, denormals, divergent derivatives
- Deadlocks: semaphore mismatches, queue submission ordering
- Driver crashes and TDR (Timeout Detection and Recovery) events

For each issue, provide:
1. Root cause analysis
2. Minimal reproduction case
3. Fix with explanation
4. Prevention strategies`,
};

// ─── Types ────────────────────────────────────────────────────────────────────

interface OrchestratorPlan {
  summary: string;
  agents: Array<{ agent: string; task: string; priority: number }>;
  context: string;
}

interface AgentResult {
  agent: string;
  task: string;
  response: string;
  tokens: number;
}

interface StudioResponse {
  plan: OrchestratorPlan;
  results: AgentResult[];
  totalTokens: number;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

async function runAgent(
  agentName: string,
  task: string,
  context: string,
  conversationHistory: Anthropic.MessageParam[]
): Promise<{ response: string; tokens: number }> {
  const systemPrompt = AGENT_SYSTEM_PROMPTS[agentName];
  if (!systemPrompt) throw new Error(`Unknown agent: ${agentName}`);

  const messages: Anthropic.MessageParam[] = [
    ...conversationHistory,
    {
      role: "user",
      content: context
        ? `Context from orchestrator: ${context}\n\nYour specific task: ${task}`
        : task,
    },
  ];

  const stream = client.messages.stream({
    model: "claude-opus-4-6",
    max_tokens: 4096,
    thinking: { type: "adaptive" },
    system: systemPrompt,
    messages,
  });

  const message = await stream.finalMessage();

  const textContent = message.content
    .filter((b): b is Anthropic.TextBlock => b.type === "text")
    .map((b) => b.text)
    .join("");

  return {
    response: textContent,
    tokens: message.usage.input_tokens + message.usage.output_tokens,
  };
}

async function runOrchestrator(
  userRequest: string,
  conversationHistory: Anthropic.MessageParam[]
): Promise<OrchestratorPlan> {
  const messages: Anthropic.MessageParam[] = [
    ...conversationHistory,
    { role: "user", content: userRequest },
  ];

  const stream = client.messages.stream({
    model: "claude-opus-4-6",
    max_tokens: 1024,
    thinking: { type: "adaptive" },
    system:
      AGENT_SYSTEM_PROMPTS.orchestrator +
      "\n\nRespond ONLY with valid JSON. No markdown, no explanation outside the JSON.",
    messages,
  });

  const message = await stream.finalMessage();

  const text = message.content
    .filter((b): b is Anthropic.TextBlock => b.type === "text")
    .map((b) => b.text)
    .join("");

  // Extract JSON from the response
  const jsonMatch = text.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    // Fallback plan if orchestrator doesn't return clean JSON
    return {
      summary: userRequest,
      agents: [{ agent: "codegen", task: userRequest, priority: 1 }],
      context: "",
    };
  }

  return JSON.parse(jsonMatch[0]) as OrchestratorPlan;
}

// ─── Routes ───────────────────────────────────────────────────────────────────

/** POST /api/gpu-studio/query
 *  Body: { message: string, history: Array<{role, content}> }
 *  Streams SSE: { type: "plan"|"agent_start"|"agent_result"|"done"|"error" }
 */
app.post("/api/gpu-studio/query", async (req, res) => {
  const { message, history = [] } = req.body as {
    message: string;
    history: Array<{ role: string; content: string; agent?: string }>;
  };

  if (!message) {
    res.status(400).json({ error: "message is required" });
    return;
  }

  // Set up SSE
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("Access-Control-Allow-Origin", "*");

  const send = (data: object) => {
    res.write(`data: ${JSON.stringify(data)}\n\n`);
  };

  try {
    // Build conversation history for agents
    const conversationHistory: Anthropic.MessageParam[] = history
      .filter((m) => m.role === "user" || m.role === "assistant")
      .map((m) => ({
        role: m.role as "user" | "assistant",
        content: m.content,
      }));

    // 1. Orchestrator plans the work
    send({ type: "orchestrating", message: "Analyzing your request..." });
    const plan = await runOrchestrator(message, conversationHistory);
    send({ type: "plan", plan });

    // 2. Run agents in priority order
    const results: AgentResult[] = [];
    let totalTokens = 0;

    const sortedAgents = [...plan.agents].sort(
      (a, b) => a.priority - b.priority
    );

    for (const agentSpec of sortedAgents) {
      const agentName = agentSpec.agent.toLowerCase();
      if (!AGENT_SYSTEM_PROMPTS[agentName]) continue;

      send({
        type: "agent_start",
        agent: agentName,
        task: agentSpec.task,
      });

      const { response, tokens } = await runAgent(
        agentName,
        agentSpec.task,
        plan.context,
        conversationHistory
      );

      totalTokens += tokens;
      const result: AgentResult = {
        agent: agentName,
        task: agentSpec.task,
        response,
        tokens,
      };
      results.push(result);

      send({ type: "agent_result", result });
    }

    const studioResponse: StudioResponse = { plan, results, totalTokens };
    send({ type: "done", response: studioResponse });
    res.end();
  } catch (err) {
    const message =
      err instanceof Anthropic.APIError
        ? `Claude API error ${err.status}: ${err.message}`
        : err instanceof Error
          ? err.message
          : "Unknown error";
    send({ type: "error", message });
    res.end();
  }
});

/** GET /api/gpu-studio/agents — list available agents */
app.get("/api/gpu-studio/agents", (_req, res) => {
  res.json({
    agents: [
      {
        id: "design",
        name: "Architecture Designer",
        description:
          "GPU pipeline topology, memory hierarchy, API binding design",
        icon: "cpu",
      },
      {
        id: "optimizer",
        name: "Performance Optimizer",
        description:
          "Occupancy tuning, memory coalescing, profiling analysis",
        icon: "zap",
      },
      {
        id: "codegen",
        name: "Code Generator",
        description:
          "CUDA, WGSL, GLSL, HLSL, Metal shader and kernel generation",
        icon: "code",
      },
      {
        id: "debugger",
        name: "GPU Debugger",
        description:
          "Validation errors, race conditions, precision issues, TDR",
        icon: "bug",
      },
    ],
  });
});

/** POST /api/gpu-studio/agent/:name — call a specific agent directly */
app.post("/api/gpu-studio/agent/:name", async (req, res) => {
  const { name } = req.params;
  const { task, context = "", history = [] } = req.body as {
    task: string;
    context?: string;
    history?: Array<{ role: string; content: string }>;
  };

  if (!AGENT_SYSTEM_PROMPTS[name]) {
    res.status(404).json({ error: `Agent '${name}' not found` });
    return;
  }

  if (!task) {
    res.status(400).json({ error: "task is required" });
    return;
  }

  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.setHeader("Access-Control-Allow-Origin", "*");

  const send = (data: object) => res.write(`data: ${JSON.stringify(data)}\n\n`);

  try {
    const conversationHistory: Anthropic.MessageParam[] = history
      .filter((m) => m.role === "user" || m.role === "assistant")
      .map((m) => ({
        role: m.role as "user" | "assistant",
        content: m.content,
      }));

    send({ type: "agent_start", agent: name, task });
    const { response, tokens } = await runAgent(
      name,
      task,
      context,
      conversationHistory
    );
    send({ type: "agent_result", result: { agent: name, task, response, tokens } });
    send({ type: "done" });
    res.end();
  } catch (err) {
    const errMsg =
      err instanceof Anthropic.APIError
        ? `Claude API error ${err.status}: ${err.message}`
        : err instanceof Error
          ? err.message
          : "Unknown error";
    send({ type: "error", message: errMsg });
    res.end();
  }
});

const PORT = process.env.GPU_STUDIO_PORT || 3001;
app.listen(PORT, () => {
  console.log(`GPU Design Studio API server running on port ${PORT}`);
});

export default app;
