// ─── Instagram API Routes ────────────────────────────────────────────────────
import { Router } from "express";
import type { Request, Response } from "express";
import {
  createPost, getPosts, getPostById, updatePostStatus, deletePost,
  getStats, upsertAccount, getAllAccounts, getAccountByNiche, getDb
} from "./db.js";
import { generateContent, getNextPostTimes } from "./content-generator.js";
import { getSchedulerStatus } from "./scheduler.js";
import { getIgUserInfo, refreshLongLivedToken } from "./instagram-api.js";
import { NICHES } from "./niches.js";
import type { NicheId } from "./types.js";

export const instagramRouter = Router();

// ─── Niches ──────────────────────────────────────────────────────────────────

instagramRouter.get("/niches", (_req: Request, res: Response) => {
  res.json({ success: true, data: NICHES });
});

// ─── Stats & Scheduler ───────────────────────────────────────────────────────

instagramRouter.get("/stats", (_req: Request, res: Response) => {
  try {
    const stats = getStats();
    const scheduler = getSchedulerStatus();
    res.json({ success: true, data: { ...stats, schedulerRunning: scheduler.running } });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Posts ───────────────────────────────────────────────────────────────────

instagramRouter.get("/posts", (req: Request, res: Response) => {
  try {
    const { niche, status, limit = "20", offset = "0" } = req.query as Record<string, string>;
    const posts = getPosts({
      niche: niche as NicheId | undefined,
      status: status as any,
      limit: parseInt(limit),
      offset: parseInt(offset),
    });
    res.json({ success: true, data: posts });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.get("/posts/:id", (req: Request, res: Response) => {
  try {
    const post = getPostById(parseInt(req.params.id));
    if (!post) return res.status(404).json({ success: false, error: "Post not found" });
    res.json({ success: true, data: post });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.post("/posts", async (req: Request, res: Response) => {
  try {
    const { niche, caption, hashtags, imagePrompt, imageUrl, scheduledAt } = req.body;
    if (!niche || !caption) {
      return res.status(400).json({ success: false, error: "niche and caption are required" });
    }
    const post = createPost({
      niche,
      caption,
      hashtags: hashtags ?? "",
      imagePrompt: imagePrompt ?? "",
      imageUrl,
      status: scheduledAt ? "scheduled" : "pending",
      scheduledAt,
    });
    res.json({ success: true, data: post });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.patch("/posts/:id", (req: Request, res: Response) => {
  try {
    const id = parseInt(req.params.id);
    const { status, imageUrl, scheduledAt } = req.body;
    if (status) updatePostStatus(id, status, { imageUrl });
    // Update scheduled time if provided
    if (scheduledAt !== undefined) {
      getDb().prepare("UPDATE posts SET scheduled_at=?, status='scheduled' WHERE id=?").run(scheduledAt, id);
    }
    const post = getPostById(id);
    if (!post) return res.status(404).json({ success: false, error: "Post not found" });
    res.json({ success: true, data: post });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.delete("/posts/:id", (req: Request, res: Response) => {
  try {
    deletePost(parseInt(req.params.id));
    res.json({ success: true });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── AI Content Generation ───────────────────────────────────────────────────

instagramRouter.post("/generate", async (req: Request, res: Response) => {
  try {
    const { niche, customTopic, scheduledAt } = req.body as {
      niche: NicheId;
      customTopic?: string;
      scheduledAt?: string;
    };
    if (!niche) return res.status(400).json({ success: false, error: "niche is required" });

    const content = await generateContent(niche, customTopic);

    const post = createPost({
      niche,
      caption: content.caption,
      hashtags: content.hashtags,
      imagePrompt: content.imagePrompt,
      status: scheduledAt ? "scheduled" : "pending",
      scheduledAt,
    });

    res.json({ success: true, data: post });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

/**
 * Bulk generate + schedule posts for the next N posting slots.
 */
instagramRouter.post("/generate/bulk", async (req: Request, res: Response) => {
  try {
    const { niche, count = 6 } = req.body as { niche: NicheId; count?: number };
    if (!niche) return res.status(400).json({ success: false, error: "niche is required" });

    const scheduleTimes = getNextPostTimes(niche, Math.min(count, 20));
    const created: number[] = [];

    for (let i = 0; i < scheduleTimes.length; i++) {
      const content = await generateContent(niche);
      const post = createPost({
        niche,
        caption: content.caption,
        hashtags: content.hashtags,
        imagePrompt: content.imagePrompt,
        status: "scheduled",
        scheduledAt: scheduleTimes[i],
      });
      created.push(post.id);
      if (i < scheduleTimes.length - 1) await sleep(900);
    }

    res.json({ success: true, data: { created: created.length, postIds: created } });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.get("/schedule/times", (req: Request, res: Response) => {
  try {
    const { niche, count = "7" } = req.query as { niche: NicheId; count?: string };
    if (!niche) return res.status(400).json({ success: false, error: "niche is required" });
    const times = getNextPostTimes(niche, parseInt(count));
    res.json({ success: true, data: times });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ─── Instagram Accounts ───────────────────────────────────────────────────────

instagramRouter.get("/accounts", (_req: Request, res: Response) => {
  try {
    const accounts = getAllAccounts().map((a) => ({
      ...a,
      igAccessToken: "***", // Never expose tokens in API
    }));
    res.json({ success: true, data: accounts });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.post("/accounts", async (req: Request, res: Response) => {
  try {
    const { niche, igUserId, igAccessToken } = req.body;
    if (!niche || !igUserId || !igAccessToken) {
      return res.status(400).json({
        success: false,
        error: "niche, igUserId, and igAccessToken are required",
      });
    }

    // Verify the token works
    const userInfo = await getIgUserInfo(igUserId, igAccessToken);

    const account = upsertAccount({
      niche,
      igUserId: userInfo.id,
      igAccessToken,
      igUsername: userInfo.username,
    });

    res.json({
      success: true,
      data: { ...account, igAccessToken: "***" },
    });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

instagramRouter.post("/accounts/:niche/refresh-token", async (req: Request, res: Response) => {
  try {
    const account = getAccountByNiche(req.params.niche as NicheId);
    if (!account) {
      return res.status(404).json({ success: false, error: "Account not found" });
    }
    const refreshed = await refreshLongLivedToken(account.igAccessToken);
    upsertAccount({
      niche: account.niche,
      igUserId: account.igUserId,
      igAccessToken: refreshed.access_token,
      igUsername: account.igUsername,
    });
    res.json({ success: true, data: { expiresIn: refreshed.expires_in } });
  } catch (err: any) {
    res.status(500).json({ success: false, error: err.message });
  }
});

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
