-- VitalPath AI — initial schema (run once or via Alembic).
-- All tables use UUID primary keys and cascade deletes.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Profiles
CREATE TABLE IF NOT EXISTS wellness_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(64) UNIQUE NOT NULL,
    display_name VARCHAR(120) NOT NULL,
    preferred_language VARCHAR(8) DEFAULT 'en',
    dietary_preferences TEXT[] DEFAULT '{}',
    wellness_goals TEXT[] DEFAULT '{}',
    comforts TEXT[] DEFAULT '{}',
    avoid TEXT[] DEFAULT '{}',
    streak_days INTEGER DEFAULT 0,
    streak_freeze_available BOOLEAN DEFAULT TRUE,
    last_check_in_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON wellness_profiles(user_id);

-- Sessions
CREATE TABLE IF NOT EXISTS wellness_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    kind VARCHAR(16) NOT NULL,
    title VARCHAR(160) NOT NULL,
    summary VARCHAR(1024) DEFAULT '',
    tags TEXT[] DEFAULT '{}',
    mood_before INTEGER,
    mood_after INTEGER,
    duration_sec INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT now()
);

-- Habits
CREATE TABLE IF NOT EXISTS habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    title VARCHAR(120) NOT NULL,
    emoji VARCHAR(8) DEFAULT '🌿',
    goal VARCHAR(24) NOT NULL,
    target_per_week INTEGER DEFAULT 3,
    completed_this_week INTEGER DEFAULT 0,
    history TEXT[] DEFAULT '{}'
);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    role VARCHAR(16) NOT NULL,
    content VARCHAR(4096) NOT NULL,
    agent VARCHAR(24),
    safety_flags TEXT[] DEFAULT '{}',
    created_at TIMESTAMP DEFAULT now()
);

-- Video analyses
CREATE TABLE IF NOT EXISTS video_analyses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    mode VARCHAR(16) NOT NULL,
    storage_url VARCHAR(512) NOT NULL,
    result JSONB DEFAULT '{}',
    score INTEGER DEFAULT 0,
    safety_flag BOOLEAN DEFAULT FALSE,
    duration_sec INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT now()
);

-- Crisis audits (no raw text, hash only)
CREATE TABLE IF NOT EXISTS crisis_audits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE SET NULL,
    trigger_hash VARCHAR(64) NOT NULL,
    language VARCHAR(8) DEFAULT 'en',
    created_at TIMESTAMP DEFAULT now(),
    resolved_at TIMESTAMP
);

-- Journal entries (encrypted at rest)
CREATE TABLE IF NOT EXISTS journal_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content_encrypted VARCHAR(16384) NOT NULL,
    content_preview VARCHAR(400) DEFAULT '',
    mood_score INTEGER,
    tags TEXT[] DEFAULT '{}',
    is_private BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);

-- Community topics
CREATE TABLE IF NOT EXISTS community_topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1024) DEFAULT '',
    category VARCHAR(32) NOT NULL,
    icon VARCHAR(8) DEFAULT '💬',
    member_count INTEGER DEFAULT 0,
    is_official BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now()
);

-- Community posts
CREATE TABLE IF NOT EXISTS community_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES community_topics(id) ON DELETE CASCADE,
    author_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    content VARCHAR(4096) NOT NULL,
    safety_flags TEXT[] DEFAULT '{}',
    like_count INTEGER DEFAULT 0,
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_posts_topic ON community_posts(topic_id);

-- Community replies
CREATE TABLE IF NOT EXISTS community_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
    author_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    content VARCHAR(2048) NOT NULL,
    safety_flags TEXT[] DEFAULT '{}',
    is_hidden BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_replies_post ON community_replies(post_id);

-- Topic membership
CREATE TABLE IF NOT EXISTS topic_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    topic_id UUID REFERENCES community_topics(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP DEFAULT now()
);

-- Audit log (immutable)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id VARCHAR(64),
    action VARCHAR(64) NOT NULL,
    resource VARCHAR(64) NOT NULL,
    resource_id VARCHAR(64),
    ip_address VARCHAR(45),
    user_agent VARCHAR(512),
    details JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON audit_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);

-- Seed official community topics
INSERT INTO community_topics (title, description, category, icon, is_official) VALUES
    ('Stress & Calm', 'Share calming techniques and stress management tips.', 'stress', '🌿', TRUE),
    ('Better Sleep', 'Wind-down routines, sleep hygiene, and restful nights.', 'sleep', '🌙', TRUE),
    ('Healthy Eating', 'Nutrition tips, meal ideas, and mindful eating.', 'nutrition', '🥗', TRUE),
    ('Movement & Exercise', 'Workouts, stretches, and staying active together.', 'movement', '🏃', TRUE),
    ('Mindfulness', 'Meditation, breathing, and present-moment awareness.', 'mindfulness', '🧘', TRUE),
    ('Hydration', 'Water intake tips and hydration reminders.', 'hydration', '💧', TRUE),
    ('Journaling', 'Reflective writing prompts and journaling practice.', 'mindfulness', '📝', TRUE),
    ('Wellness Wins', 'Celebrate milestones, streaks, and personal victories.', 'movement', '🎉', TRUE)
ON CONFLICT DO NOTHING;
