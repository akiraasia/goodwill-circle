-- week26_wish_system_final.sql
-- Missing migrations for Story Mode NPCs and Tasks

-- 1. NPCs for Story Mode
CREATE TABLE IF NOT EXISTS public.wish_story_npcs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.wish_story_sessions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    personality TEXT NOT NULL,
    trust_level INTEGER NOT NULL DEFAULT 0,
    memories JSONB DEFAULT '[]'::jsonb,
    emotions JSONB DEFAULT '{}'::jsonb,
    goals JSONB DEFAULT '[]'::jsonb,
    relationships JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (session_id, name)
);

ALTER TABLE public.wish_story_npcs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own story npcs" ON public.wish_story_npcs
  FOR SELECT USING (
    session_id IN (SELECT id FROM public.wish_story_sessions WHERE user_id = auth.uid())
  );

CREATE POLICY "Users can manage own story npcs" ON public.wish_story_npcs
  USING (
    session_id IN (SELECT id FROM public.wish_story_sessions WHERE user_id = auth.uid())
  )
  WITH CHECK (
    session_id IN (SELECT id FROM public.wish_story_sessions WHERE user_id = auth.uid())
  );

-- 2. Add community task toggle to wish_tasks (if not using virtue_tasks directly)
-- NOTE: week24 added wish_virtue_tasks which has task_type and linked_request_id.
-- We will rely on wish_virtue_tasks for the new AI dual-track task system.
