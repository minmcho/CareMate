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

-- Sleep records
CREATE TABLE IF NOT EXISTS sleep_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    date_iso VARCHAR(10) NOT NULL,
    bedtime_iso VARCHAR(25),
    waketime_iso VARCHAR(25),
    duration_min INTEGER DEFAULT 0,
    quality_score INTEGER DEFAULT 0,
    deep_min INTEGER DEFAULT 0,
    rem_min INTEGER DEFAULT 0,
    light_min INTEGER DEFAULT 0,
    awake_min INTEGER DEFAULT 0,
    source VARCHAR(16) DEFAULT 'manual',
    notes VARCHAR(512) DEFAULT '',
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sleep_profile ON sleep_records(profile_id);
CREATE INDEX IF NOT EXISTS idx_sleep_date ON sleep_records(date_iso);

-- Mood check-ins
CREATE TABLE IF NOT EXISTS mood_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    score INTEGER NOT NULL,
    energy INTEGER DEFAULT 3,
    tags TEXT[] DEFAULT '{}',
    note VARCHAR(512) DEFAULT '',
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mood_profile ON mood_checkins(profile_id);

-- Weekly insights (AI-generated)
CREATE TABLE IF NOT EXISTS weekly_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    week_iso VARCHAR(10) NOT NULL,
    summary TEXT DEFAULT '',
    highlights TEXT[] DEFAULT '{}',
    suggestions TEXT[] DEFAULT '{}',
    mood_avg FLOAT,
    sleep_avg_min INTEGER,
    streak_days INTEGER DEFAULT 0,
    agent VARCHAR(24) DEFAULT 'deepseek',
    created_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_insights_profile ON weekly_insights(profile_id);

-- Social challenges
CREATE TABLE IF NOT EXISTS challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(200) NOT NULL,
    description VARCHAR(1024) DEFAULT '',
    category VARCHAR(32) NOT NULL,
    icon VARCHAR(8) DEFAULT '🏆',
    target_days INTEGER DEFAULT 7,
    participant_count INTEGER DEFAULT 0,
    starts_at TIMESTAMP DEFAULT now(),
    ends_at TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT now()
);

-- Challenge participants
CREATE TABLE IF NOT EXISTS challenge_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_id UUID REFERENCES challenges(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES wellness_profiles(id) ON DELETE CASCADE,
    progress_days INTEGER DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    joined_at TIMESTAMP DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cp_challenge ON challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_cp_profile ON challenge_participants(profile_id);

-- Seed official challenges
INSERT INTO challenges (title, description, category, icon, target_days) VALUES
    ('7-Day Mindfulness', 'Meditate or breathe mindfully every day for a week.', 'mindfulness', '🧘', 7),
    ('Hydration Hero', 'Drink 8 glasses of water daily for 5 days.', 'hydration', '💧', 5),
    ('Sleep Reset', 'Follow a screens-off ritual for 7 consecutive nights.', 'sleep', '🌙', 7),
    ('Move More Month', 'Log 30 minutes of movement 5 days per week.', 'movement', '🏃', 30),
    ('Gratitude Streak', 'Write 3 gratitudes daily for 14 days.', 'mindfulness', '📝', 14),
    ('Balanced Plate Week', 'Eat veggies at every meal for 7 days.', 'nutrition', '🥗', 7)
ON CONFLICT DO NOTHING;

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
