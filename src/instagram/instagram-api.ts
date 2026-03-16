// ─── Instagram Graph API Client ──────────────────────────────────────────────
// Docs: https://developers.facebook.com/docs/instagram-api/
// Requirements: Instagram Business/Creator Account + Facebook App

const IG_API_BASE = "https://graph.instagram.com/v21.0";
const FB_API_BASE = "https://graph.facebook.com/v21.0";

export interface IgMediaContainer {
  id: string;
}

export interface IgPublishResult {
  id: string;
}

export interface IgUserInfo {
  id: string;
  username: string;
  account_type: string;
  media_count: number;
}

// ─── Auth helpers ─────────────────────────────────────────────────────────────

/**
 * Exchange a short-lived token for a long-lived token (60 days).
 * Call this once when the user connects their account.
 */
export async function exchangeForLongLivedToken(
  shortLivedToken: string,
  appId: string,
  appSecret: string
): Promise<{ access_token: string; token_type: string; expires_in: number }> {
  const url = new URL(`${FB_API_BASE}/oauth/access_token`);
  url.searchParams.set("grant_type", "fb_exchange_token");
  url.searchParams.set("client_id", appId);
  url.searchParams.set("client_secret", appSecret);
  url.searchParams.set("fb_exchange_token", shortLivedToken);

  const res = await fetch(url.toString());
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Token exchange failed: ${JSON.stringify(err)}`);
  }
  return res.json();
}

/**
 * Refresh a long-lived token (can be refreshed if it's at least 24h old and not expired).
 */
export async function refreshLongLivedToken(
  accessToken: string
): Promise<{ access_token: string; token_type: string; expires_in: number }> {
  const url = new URL(`${FB_API_BASE}/oauth/access_token`);
  url.searchParams.set("grant_type", "ig_refresh_token");
  url.searchParams.set("access_token", accessToken);

  const res = await fetch(url.toString());
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Token refresh failed: ${JSON.stringify(err)}`);
  }
  return res.json();
}

// ─── User info ────────────────────────────────────────────────────────────────

export async function getIgUserInfo(
  igUserId: string,
  accessToken: string
): Promise<IgUserInfo> {
  const url = new URL(`${IG_API_BASE}/${igUserId}`);
  url.searchParams.set("fields", "id,username,account_type,media_count");
  url.searchParams.set("access_token", accessToken);

  const res = await fetch(url.toString());
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to get user info: ${JSON.stringify(err)}`);
  }
  return res.json();
}

// ─── Publishing: Photo post ───────────────────────────────────────────────────

/**
 * Step 1: Create a media container for a photo post.
 * @param imageUrl - Publicly accessible URL of the image (HTTPS required)
 * @param caption  - Post caption including hashtags
 */
export async function createPhotoContainer(
  igUserId: string,
  accessToken: string,
  imageUrl: string,
  caption: string
): Promise<IgMediaContainer> {
  const url = `${IG_API_BASE}/${igUserId}/media`;
  const body = new URLSearchParams({
    image_url: imageUrl,
    caption,
    access_token: accessToken,
  });

  const res = await fetch(url, { method: "POST", body });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to create media container: ${JSON.stringify(err)}`);
  }
  return res.json();
}

/**
 * Step 1b: Create a container for a Reel (video post).
 * @param videoUrl - Publicly accessible HTTPS URL to an MP4 video
 */
export async function createReelContainer(
  igUserId: string,
  accessToken: string,
  videoUrl: string,
  caption: string,
  coverUrl?: string
): Promise<IgMediaContainer> {
  const url = `${IG_API_BASE}/${igUserId}/media`;
  const body = new URLSearchParams({
    media_type: "REELS",
    video_url: videoUrl,
    caption,
    access_token: accessToken,
  });
  if (coverUrl) body.set("cover_url", coverUrl);

  const res = await fetch(url, { method: "POST", body });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to create reel container: ${JSON.stringify(err)}`);
  }
  return res.json();
}

/**
 * Step 2: Poll container status until FINISHED (for video) or assume ready for photo.
 */
export async function waitForContainerReady(
  containerId: string,
  accessToken: string,
  maxWaitMs = 120_000
): Promise<void> {
  const deadline = Date.now() + maxWaitMs;
  while (Date.now() < deadline) {
    const url = new URL(`${IG_API_BASE}/${containerId}`);
    url.searchParams.set("fields", "status_code,status");
    url.searchParams.set("access_token", accessToken);

    const res = await fetch(url.toString());
    const data = (await res.json()) as { status_code: string; status?: string };

    if (data.status_code === "FINISHED") return;
    if (data.status_code === "ERROR") {
      throw new Error(`Container processing failed: ${data.status ?? "unknown error"}`);
    }
    await sleep(5000);
  }
  throw new Error("Container timed out waiting for FINISHED status");
}

/**
 * Step 3: Publish the media container.
 */
export async function publishContainer(
  igUserId: string,
  accessToken: string,
  containerId: string
): Promise<IgPublishResult> {
  const url = `${IG_API_BASE}/${igUserId}/media_publish`;
  const body = new URLSearchParams({
    creation_id: containerId,
    access_token: accessToken,
  });

  const res = await fetch(url, { method: "POST", body });
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to publish media: ${JSON.stringify(err)}`);
  }
  return res.json();
}

// ─── Carousel post ───────────────────────────────────────────────────────────

/**
 * Post a carousel (up to 10 images).
 */
export async function postCarousel(
  igUserId: string,
  accessToken: string,
  imageUrls: string[],
  caption: string
): Promise<IgPublishResult> {
  if (imageUrls.length < 2 || imageUrls.length > 10) {
    throw new Error("Carousel requires 2–10 images");
  }

  // Create sub-containers for each image
  const childIds: string[] = [];
  for (const imgUrl of imageUrls) {
    const url = `${IG_API_BASE}/${igUserId}/media`;
    const body = new URLSearchParams({
      image_url: imgUrl,
      is_carousel_item: "true",
      access_token: accessToken,
    });
    const res = await fetch(url, { method: "POST", body });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(`Failed to create carousel item: ${JSON.stringify(err)}`);
    }
    const data = (await res.json()) as IgMediaContainer;
    childIds.push(data.id);
  }

  // Create parent carousel container
  const parentUrl = `${IG_API_BASE}/${igUserId}/media`;
  const parentBody = new URLSearchParams({
    media_type: "CAROUSEL",
    caption,
    children: childIds.join(","),
    access_token: accessToken,
  });
  const parentRes = await fetch(parentUrl, { method: "POST", body: parentBody });
  if (!parentRes.ok) {
    const err = await parentRes.json();
    throw new Error(`Failed to create carousel container: ${JSON.stringify(err)}`);
  }
  const parentContainer = (await parentRes.json()) as IgMediaContainer;

  // Publish
  return publishContainer(igUserId, accessToken, parentContainer.id);
}

// ─── Main publish helper ─────────────────────────────────────────────────────

/**
 * High-level helper: create photo container → publish → return post id.
 */
export async function publishPhotoPost(
  igUserId: string,
  accessToken: string,
  imageUrl: string,
  caption: string,
  hashtags: string
): Promise<string> {
  const fullCaption = `${caption}\n.\n.\n.\n${hashtags}`;
  const container = await createPhotoContainer(igUserId, accessToken, imageUrl, fullCaption);
  const result = await publishContainer(igUserId, accessToken, container.id);
  return result.id;
}

// ─── Check API rate limits ────────────────────────────────────────────────────

export async function checkPublishingLimit(
  igUserId: string,
  accessToken: string
): Promise<{ quota_usage: number; config: { quota_total: number; quota_duration: number } }> {
  const url = new URL(`${IG_API_BASE}/${igUserId}/content_publishing_limit`);
  url.searchParams.set("fields", "config,quota_usage");
  url.searchParams.set("access_token", accessToken);

  const res = await fetch(url.toString());
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to check publishing limit: ${JSON.stringify(err)}`);
  }
  const data = (await res.json()) as { data: any[] };
  return data.data?.[0] ?? { quota_usage: 0, config: { quota_total: 50, quota_duration: 86400 } };
}

// ─── Insights ────────────────────────────────────────────────────────────────

export async function getPostInsights(
  postId: string,
  accessToken: string
): Promise<{ impressions: number; reach: number; likes: number; comments: number; saves: number }> {
  const url = new URL(`${IG_API_BASE}/${postId}/insights`);
  url.searchParams.set("metric", "impressions,reach,likes,comments,saved");
  url.searchParams.set("access_token", accessToken);

  const res = await fetch(url.toString());
  if (!res.ok) {
    const err = await res.json();
    throw new Error(`Failed to get insights: ${JSON.stringify(err)}`);
  }
  const data = (await res.json()) as { data: Array<{ name: string; values: Array<{ value: number }> }> };
  const result = { impressions: 0, reach: 0, likes: 0, comments: 0, saves: 0 };
  for (const metric of data.data ?? []) {
    const val = metric.values?.[0]?.value ?? 0;
    if (metric.name === "impressions") result.impressions = val;
    else if (metric.name === "reach") result.reach = val;
    else if (metric.name === "likes") result.likes = val;
    else if (metric.name === "comments") result.comments = val;
    else if (metric.name === "saved") result.saves = val;
  }
  return result;
}

function sleep(ms: number) {
  return new Promise((r) => setTimeout(r, ms));
}
