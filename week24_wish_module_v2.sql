-- week24_wish_module_v2.sql
-- Wish Module v2: Virtues, Tasks, Materials, Per-Virtue Chat

-- ─── 1. Add interview_data column to wishes table ───────────────────────────
ALTER TABLE public.wishes
  ADD COLUMN IF NOT EXISTS interview_data JSONB,
  ADD COLUMN IF NOT EXISTS virtue_names TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS path_mode TEXT DEFAULT 'task' CHECK (path_mode IN ('story', 'task'));

-- ─── 2. User Virtues ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wish_virtues (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    virtue_name TEXT NOT NULL CHECK (virtue_name IN ('Courage', 'Wisdom', 'Compassion', 'Discipline', 'Integrity')),
    stat_category TEXT NOT NULL CHECK (stat_category IN ('physical', 'mental', 'ethical')),
    level INTEGER NOT NULL DEFAULT 1,
    xp INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, virtue_name)
);

-- ─── 3. Virtue Tasks ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wish_virtue_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    virtue_name TEXT NOT NULL,
    task_type TEXT NOT NULL CHECK (task_type IN ('social', 'individual')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    xp_reward INTEGER NOT NULL DEFAULT 20,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
    linked_request_id UUID REFERENCES public.help_requests(id) ON DELETE SET NULL,
    social_role TEXT CHECK (social_role IN ('helper', 'helpee')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 4. Virtue Materials Board ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.wish_virtue_materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    virtue_name TEXT NOT NULL,
    material_type TEXT NOT NULL CHECK (material_type IN ('meme', 'book', 'song', 'video', 'article')),
    title TEXT NOT NULL,
    description TEXT,
    url TEXT,
    image_url TEXT,
    poster_name TEXT NOT NULL DEFAULT 'Anonymous',
    upvotes INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 5. Virtue Chat Rooms (per-virtue, replaces category-based chat) ────────
CREATE TABLE IF NOT EXISTS public.wish_virtue_chat (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    virtue_name TEXT NOT NULL,
    sender_name TEXT NOT NULL DEFAULT 'Anonymous',
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── 6. Novel Character States ──────────────────────────────────────────────
ALTER TABLE public.wish_novel_scenes
  ADD COLUMN IF NOT EXISTS character_states JSONB DEFAULT '[]';

-- ─── 7. RLS Policies ────────────────────────────────────────────────────────
ALTER TABLE public.wish_virtues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_virtue_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_virtue_materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_virtue_chat ENABLE ROW LEVEL SECURITY;

-- Virtues (user owns)
CREATE POLICY "Users can CRUD own virtues" ON public.wish_virtues
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Tasks (user owns)
CREATE POLICY "Users can CRUD own tasks" ON public.wish_virtue_tasks
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Materials (any authenticated user can read; authenticated users can insert)
CREATE POLICY "Anyone can read materials" ON public.wish_virtue_materials
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can post materials" ON public.wish_virtue_materials
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Virtue Chat (any authenticated user can read; authenticated users can insert)
CREATE POLICY "Anyone can read virtue chat" ON public.wish_virtue_chat
  FOR SELECT USING (true);
CREATE POLICY "Authenticated users can send virtue chat" ON public.wish_virtue_chat
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ─── 8. hgos_wish_stats — add virtue columns if missing ─────────────────────
-- (The existing table tracks physical/mental/ethical_emotional as floats)
-- We store virtue XP in wish_virtues; no changes needed to hgos_wish_stats.

-- ─── 9. Realtime ─────────────────────────────────────────────────────────────
-- Enable realtime for virtue chat (run once in Supabase dashboard if not enabled)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.wish_virtue_chat;
