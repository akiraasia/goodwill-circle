-- week25_wish_persistence.sql
-- Wish Persistence & Story Progress Tracking

-- ─── 1. Wish History (User's wish + story progression) ────────────────────────
CREATE TABLE IF NOT EXISTS public.wish_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    initial_wish TEXT NOT NULL,
    interview_data JSONB DEFAULT '{}',
    assigned_virtues TEXT[] DEFAULT '{}',
    assigned_stats JSONB DEFAULT '{"physical": 1, "mental": 1, "ethical": 1}',
    path_mode TEXT DEFAULT 'task' CHECK (path_mode IN ('story', 'task')),
    story_progress JSONB DEFAULT '{}',  -- Tracks scene, choices, character states
    completion_status TEXT DEFAULT 'started' CHECK (completion_status IN ('started', 'in_progress', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id)
);

-- ─── 2. Update wishes table to reference wish_history ──────────────────────────
-- (If not already done)
ALTER TABLE public.wishes
  ADD COLUMN IF NOT EXISTS wish_history_id UUID REFERENCES public.wish_history(id) ON DELETE SET NULL;

-- ─── 3. RLS for wish_history ───────────────────────────────────────────────────
ALTER TABLE public.wish_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own wish_history" ON public.wish_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own wish_history" ON public.wish_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own wish_history" ON public.wish_history
  FOR UPDATE USING (auth.uid() = user_id);

-- ─── 4. Story Scene Progress (tracks choices in story mode) ───────────────────
CREATE TABLE IF NOT EXISTS public.wish_story_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    wish_history_id UUID NOT NULL REFERENCES public.wish_history(id) ON DELETE CASCADE,
    current_scene_id TEXT NOT NULL,
    character_states JSONB DEFAULT '{}',
    player_choices JSONB[] DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'paused', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_accessed_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.wish_story_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own story_sessions" ON public.wish_story_sessions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own story_sessions" ON public.wish_story_sessions
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ─── 5. Index for faster queries ──────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS wish_history_user_id_idx ON public.wish_history(user_id);
CREATE INDEX IF NOT EXISTS wish_story_sessions_user_id_idx ON public.wish_story_sessions(user_id);
CREATE INDEX IF NOT EXISTS wish_story_sessions_wish_history_id_idx ON public.wish_story_sessions(wish_history_id);

-- ─── 6. Realtime ─────────────────────────────────────────────────────────────
-- Enable realtime for wish_history changes (run in Supabase dashboard if needed)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.wish_history;
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.wish_story_sessions;
