// ─── Instagram Automation Types ────────────────────────────────────────────

export type NicheId =
  | "motivational_quotes"
  | "personal_finance"
  | "ai_technology"
  | "health_wellness"
  | "aesthetic_nature";

export type PostStatus = "pending" | "generating" | "scheduled" | "posted" | "failed";

export interface NicheConfig {
  id: NicheId;
  name: string;
  description: string;
  icon: string;
  color: string;
  avgMonthlyRevenue: string;
  successAccounts: SuccessAccount[];
  contentStyle: string;
  postingFrequency: string;
  bestPostTimes: string[];
  hashtagGroups: string[][];
  contentPromptTemplate: string;
}

export interface SuccessAccount {
  handle: string;
  followers: string;
  monthlyEarnings: string;
  strategy: string;
}

export interface Post {
  id: number;
  niche: NicheId;
  caption: string;
  hashtags: string;
  imagePrompt: string;
  imageUrl?: string;
  status: PostStatus;
  scheduledAt?: string;
  postedAt?: string;
  igPostId?: string;
  createdAt: string;
  errorMessage?: string;
}

export interface IgAccount {
  id: number;
  niche: NicheId;
  igUserId: string;
  igAccessToken: string;
  igUsername: string;
  createdAt: string;
}

export interface SchedulerStats {
  totalPosts: number;
  postedToday: number;
  scheduled: number;
  failed: number;
  nextPost?: Post;
}

export interface GenerateContentRequest {
  niche: NicheId;
  customTopic?: string;
  scheduledAt?: string;
}

export interface GenerateContentResponse {
  post: Post;
}

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
}
