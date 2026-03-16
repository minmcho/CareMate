// ─── SQLite Database Setup ───────────────────────────────────────────────────
import Database from "better-sqlite3";
import path from "path";
import { fileURLToPath } from "url";
import type { Post, IgAccount, NicheId, PostStatus } from "./types.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const DB_PATH = path.join(__dirname, "../../instagram.db");

let db: Database.Database;

export function getDb(): Database.Database {
  if (!db) {
    db = new Database(DB_PATH);
    db.pragma("journal_mode = WAL");
    db.pragma("foreign_keys = ON");
    initSchema(db);
  }
  return db;
}

function initSchema(db: Database.Database): void {
  db.exec(`
    CREATE TABLE IF NOT EXISTS ig_accounts (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      niche         TEXT NOT NULL,
      ig_user_id    TEXT NOT NULL,
      ig_access_token TEXT NOT NULL,
      ig_username   TEXT NOT NULL,
      created_at    TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS posts (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
      niche         TEXT NOT NULL,
      caption       TEXT NOT NULL,
      hashtags      TEXT NOT NULL DEFAULT '',
      image_prompt  TEXT NOT NULL DEFAULT '',
      image_url     TEXT,
      status        TEXT NOT NULL DEFAULT 'pending',
      scheduled_at  TEXT,
      posted_at     TEXT,
      ig_post_id    TEXT,
      error_message TEXT,
      created_at    TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE INDEX IF NOT EXISTS idx_posts_status      ON posts(status);
    CREATE INDEX IF NOT EXISTS idx_posts_scheduled   ON posts(scheduled_at);
    CREATE INDEX IF NOT EXISTS idx_posts_niche       ON posts(niche);
    CREATE INDEX IF NOT EXISTS idx_accounts_niche    ON ig_accounts(niche);
  `);
}

// ─── Post CRUD ───────────────────────────────────────────────────────────────

export function createPost(
  post: Omit<Post, "id" | "createdAt">
): Post {
  const db = getDb();
  const stmt = db.prepare(`
    INSERT INTO posts (niche, caption, hashtags, image_prompt, image_url, status, scheduled_at)
    VALUES (@niche, @caption, @hashtags, @imagePrompt, @imageUrl, @status, @scheduledAt)
  `);
  const result = stmt.run({
    niche: post.niche,
    caption: post.caption,
    hashtags: post.hashtags,
    imagePrompt: post.imagePrompt,
    imageUrl: post.imageUrl ?? null,
    status: post.status,
    scheduledAt: post.scheduledAt ?? null,
  });
  return getPostById(result.lastInsertRowid as number)!;
}

export function getPostById(id: number): Post | undefined {
  const db = getDb();
  const row = db.prepare("SELECT * FROM posts WHERE id = ?").get(id) as any;
  return row ? mapRow(row) : undefined;
}

export function getPosts(options?: {
  niche?: NicheId;
  status?: PostStatus;
  limit?: number;
  offset?: number;
}): Post[] {
  const db = getDb();
  let sql = "SELECT * FROM posts WHERE 1=1";
  const params: any[] = [];
  if (options?.niche) { sql += " AND niche = ?"; params.push(options.niche); }
  if (options?.status) { sql += " AND status = ?"; params.push(options.status); }
  sql += " ORDER BY created_at DESC";
  if (options?.limit) { sql += ` LIMIT ${options.limit}`; }
  if (options?.offset) { sql += ` OFFSET ${options.offset}`; }
  return (db.prepare(sql).all(...params) as any[]).map(mapRow);
}

export function getDuePosts(): Post[] {
  const db = getDb();
  const rows = db.prepare(`
    SELECT * FROM posts
    WHERE status = 'scheduled'
      AND scheduled_at <= datetime('now')
    ORDER BY scheduled_at ASC
  `).all() as any[];
  return rows.map(mapRow);
}

export function updatePostStatus(
  id: number,
  status: PostStatus,
  extra?: { igPostId?: string; postedAt?: string; errorMessage?: string; imageUrl?: string }
): void {
  const db = getDb();
  db.prepare(`
    UPDATE posts
    SET status        = @status,
        ig_post_id    = COALESCE(@igPostId, ig_post_id),
        posted_at     = COALESCE(@postedAt, posted_at),
        error_message = COALESCE(@errorMessage, error_message),
        image_url     = COALESCE(@imageUrl, image_url)
    WHERE id = @id
  `).run({
    id,
    status,
    igPostId: extra?.igPostId ?? null,
    postedAt: extra?.postedAt ?? null,
    errorMessage: extra?.errorMessage ?? null,
    imageUrl: extra?.imageUrl ?? null,
  });
}

export function deletePost(id: number): void {
  getDb().prepare("DELETE FROM posts WHERE id = ?").run(id);
}

export function getStats() {
  const db = getDb();
  const total = (db.prepare("SELECT COUNT(*) as c FROM posts").get() as any).c;
  const today = (db.prepare(
    "SELECT COUNT(*) as c FROM posts WHERE status='posted' AND date(posted_at)=date('now')"
  ).get() as any).c;
  const scheduled = (db.prepare(
    "SELECT COUNT(*) as c FROM posts WHERE status='scheduled'"
  ).get() as any).c;
  const failed = (db.prepare(
    "SELECT COUNT(*) as c FROM posts WHERE status='failed'"
  ).get() as any).c;
  const nextPost = db.prepare(
    "SELECT * FROM posts WHERE status='scheduled' ORDER BY scheduled_at ASC LIMIT 1"
  ).get() as any;
  return { total, postedToday: today, scheduled, failed, nextPost: nextPost ? mapRow(nextPost) : undefined };
}

// ─── Account CRUD ────────────────────────────────────────────────────────────

export function upsertAccount(account: Omit<IgAccount, "id" | "createdAt">): IgAccount {
  const db = getDb();
  db.prepare(`
    INSERT INTO ig_accounts (niche, ig_user_id, ig_access_token, ig_username)
    VALUES (@niche, @igUserId, @igAccessToken, @igUsername)
    ON CONFLICT(niche) DO UPDATE SET
      ig_user_id      = excluded.ig_user_id,
      ig_access_token = excluded.ig_access_token,
      ig_username     = excluded.ig_username
  `).run(account);
  return getAccountByNiche(account.niche as NicheId)!;
}

export function getAccountByNiche(niche: NicheId): IgAccount | undefined {
  const row = getDb().prepare(
    "SELECT * FROM ig_accounts WHERE niche = ?"
  ).get(niche) as any;
  if (!row) return undefined;
  return {
    id: row.id,
    niche: row.niche,
    igUserId: row.ig_user_id,
    igAccessToken: row.ig_access_token,
    igUsername: row.ig_username,
    createdAt: row.created_at,
  };
}

export function getAllAccounts(): IgAccount[] {
  return (getDb().prepare("SELECT * FROM ig_accounts").all() as any[]).map((row) => ({
    id: row.id,
    niche: row.niche,
    igUserId: row.ig_user_id,
    igAccessToken: row.ig_access_token,
    igUsername: row.ig_username,
    createdAt: row.created_at,
  }));
}

// ─── Helper ──────────────────────────────────────────────────────────────────

function mapRow(row: any): Post {
  return {
    id: row.id,
    niche: row.niche as NicheId,
    caption: row.caption,
    hashtags: row.hashtags,
    imagePrompt: row.image_prompt,
    imageUrl: row.image_url ?? undefined,
    status: row.status as PostStatus,
    scheduledAt: row.scheduled_at ?? undefined,
    postedAt: row.posted_at ?? undefined,
    igPostId: row.ig_post_id ?? undefined,
    errorMessage: row.error_message ?? undefined,
    createdAt: row.created_at,
  };
}
