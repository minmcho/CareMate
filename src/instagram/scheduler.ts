// ─── Post Scheduler ──────────────────────────────────────────────────────────
// Runs as a background process. Every 60 seconds, checks for due posts and publishes them.

import { getDuePosts, updatePostStatus, getAccountByNiche, getStats } from "./db.js";
import type { NicheId } from "./types.js";
import { publishPhotoPost, checkPublishingLimit } from "./instagram-api.js";
import type { Post } from "./types.js";

let schedulerInterval: NodeJS.Timeout | null = null;
let isRunning = false;

export function startScheduler(intervalMs = 60_000): void {
  if (schedulerInterval) return; // Already running
  console.log(`[Scheduler] Started — checking every ${intervalMs / 1000}s`);
  schedulerInterval = setInterval(() => runSchedulerTick(), intervalMs);
  runSchedulerTick(); // Run immediately on start
}

export function stopScheduler(): void {
  if (schedulerInterval) {
    clearInterval(schedulerInterval);
    schedulerInterval = null;
    console.log("[Scheduler] Stopped");
  }
}

export function getSchedulerStatus(): { running: boolean; stats: ReturnType<typeof getStats> } {
  return { running: !!schedulerInterval, stats: getStats() };
}

async function runSchedulerTick(): Promise<void> {
  if (isRunning) return; // Prevent overlapping runs
  isRunning = true;

  try {
    const duePosts = getDuePosts();
    if (duePosts.length === 0) return;

    console.log(`[Scheduler] Found ${duePosts.length} post(s) due for publishing`);

    for (const post of duePosts) {
      await processPost(post);
    }
  } catch (err) {
    console.error("[Scheduler] Tick error:", err);
  } finally {
    isRunning = false;
  }
}

async function processPost(post: Post): Promise<void> {
  const account = getAccountByNiche(post.niche);

  if (!account) {
    console.warn(`[Scheduler] No Instagram account connected for niche: ${post.niche}`);
    updatePostStatus(post.id, "failed", {
      errorMessage: `No Instagram account connected for niche: ${post.niche}`,
    });
    return;
  }

  if (!post.imageUrl) {
    console.warn(`[Scheduler] Post ${post.id} has no image URL — skipping`);
    updatePostStatus(post.id, "failed", {
      errorMessage: "No image URL available. Upload an image first.",
    });
    return;
  }

  // Check publishing quota (Instagram allows 50 posts/24h per account)
  try {
    const limit = await checkPublishingLimit(account.igUserId, account.igAccessToken);
    const remaining = (limit.config?.quota_total ?? 50) - (limit.quota_usage ?? 0);
    if (remaining <= 0) {
      console.warn(`[Scheduler] Publishing quota exhausted for ${account.igUsername}`);
      updatePostStatus(post.id, "failed", {
        errorMessage: "Instagram publishing quota exhausted (50/24h). Will retry tomorrow.",
      });
      return;
    }
  } catch (err) {
    console.warn("[Scheduler] Could not check quota, proceeding anyway:", err);
  }

  // Mark as in-progress
  updatePostStatus(post.id, "generating");

  try {
    console.log(`[Scheduler] Publishing post ${post.id} (${post.niche}) to @${account.igUsername}`);

    const igPostId = await publishPhotoPost(
      account.igUserId,
      account.igAccessToken,
      post.imageUrl,
      post.caption,
      post.hashtags
    );

    updatePostStatus(post.id, "posted", {
      igPostId,
      postedAt: new Date().toISOString(),
    });

    console.log(`[Scheduler] ✅ Post ${post.id} published — IG ID: ${igPostId}`);
  } catch (err: any) {
    console.error(`[Scheduler] ❌ Post ${post.id} failed:`, err.message);
    updatePostStatus(post.id, "failed", {
      errorMessage: err.message ?? String(err),
    });
  }
}

// ─── Auto-schedule helper ─────────────────────────────────────────────────────

/**
 * Auto-fill the schedule for a niche for the next N days.
 * Creates posts at the niche's best posting times, generating content via AI.
 */
export async function autoScheduleNiche(
  niche: NicheId,
  daysAhead: number,
  generateFn: (niche: NicheId) => Promise<{
    caption: string;
    hashtags: string;
    imagePrompt: string;
  }>,
  createPostFn: (post: {
    niche: NicheId;
    caption: string;
    hashtags: string;
    imagePrompt: string;
    imageUrl?: string;
    status: "scheduled";
    scheduledAt: string;
  }) => unknown,
  scheduleTimes: string[]
): Promise<number> {
  let created = 0;
  const now = new Date();

  for (const scheduledAt of scheduleTimes.slice(0, daysAhead * 3)) {
    const schedDate = new Date(scheduledAt);
    if (schedDate <= now) continue;

    try {
      const content = await generateFn(niche);
      createPostFn({
        niche,
        caption: content.caption,
        hashtags: content.hashtags,
        imagePrompt: content.imagePrompt,
        status: "scheduled",
        scheduledAt,
      });
      created++;
      await sleep(800);
    } catch (err) {
      console.error(`[AutoSchedule] Failed for ${scheduledAt}:`, err);
    }
  }

  return created;
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
