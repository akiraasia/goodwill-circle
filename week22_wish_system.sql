-- week22_wish_system.sql
-- Wish System and Visual Novel Engine Schema

-- 1. Create wishes table
CREATE TABLE IF NOT EXISTS public.wishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    wish_text TEXT NOT NULL,
    physical_condition TEXT NOT NULL,
    mental_condition TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create wish_stats table
CREATE TABLE IF NOT EXISTS public.wish_stats (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    physical_level INTEGER NOT NULL DEFAULT 1,
    mental_level INTEGER NOT NULL DEFAULT 1,
    ethical_level INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Visual Novel System Tables
CREATE TABLE IF NOT EXISTS public.wish_novels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    cover_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wish_novel_scenes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    novel_id UUID NOT NULL REFERENCES public.wish_novels(id) ON DELETE CASCADE,
    scene_text TEXT NOT NULL,
    image_url TEXT,
    is_ending BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.wish_novel_choices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scene_id UUID NOT NULL REFERENCES public.wish_novel_scenes(id) ON DELETE CASCADE,
    choice_text TEXT NOT NULL,
    next_scene_id UUID REFERENCES public.wish_novel_scenes(id) ON DELETE SET NULL,
    req_physical INTEGER DEFAULT 1,
    req_mental INTEGER DEFAULT 1,
    req_ethical INTEGER DEFAULT 1,
    reward_physical INTEGER DEFAULT 0,
    reward_mental INTEGER DEFAULT 0,
    reward_ethical INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.user_novel_progress (
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    novel_id UUID NOT NULL REFERENCES public.wish_novels(id) ON DELETE CASCADE,
    current_scene_id UUID REFERENCES public.wish_novel_scenes(id) ON DELETE CASCADE,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, novel_id)
);

-- 4. Global Chats for Stats
CREATE TABLE IF NOT EXISTS public.wish_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    category TEXT NOT NULL CHECK (category IN ('physical', 'mental', 'ethical')),
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RLS Policies
ALTER TABLE public.wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_novels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_novel_scenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_novel_choices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_novel_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own wishes" ON public.wishes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wishes" ON public.wishes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wishes" ON public.wishes FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can read own stats" ON public.wish_stats FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own stats" ON public.wish_stats FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own stats" ON public.wish_stats FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Novels are public" ON public.wish_novels FOR SELECT USING (true);
CREATE POLICY "Scenes are public" ON public.wish_novel_scenes FOR SELECT USING (true);
CREATE POLICY "Choices are public" ON public.wish_novel_choices FOR SELECT USING (true);

CREATE POLICY "Users can read own progress" ON public.user_novel_progress FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own progress" ON public.user_novel_progress FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own progress" ON public.user_novel_progress FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Chat messages are public" ON public.wish_chat_messages FOR SELECT USING (true);
CREATE POLICY "Users can insert own chat messages" ON public.wish_chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 6. Insert Seed Data for Abstract Novels
WITH novel_insert AS (
    INSERT INTO public.wish_novels (id, title, description)
    VALUES (gen_random_uuid(), 'The Silent Mountain', 'An abstract journey of self-discovery and physical endurance.')
    RETURNING id
),
scene_1 AS (
    INSERT INTO public.wish_novel_scenes (id, novel_id, scene_text)
    SELECT gen_random_uuid(), id, 'You stand at the base of the Silent Mountain. The air is cold and the path is steep. The mist obscures the summit.' FROM novel_insert
    RETURNING id, novel_id
),
scene_2 AS (
    INSERT INTO public.wish_novel_scenes (id, novel_id, scene_text)
    SELECT gen_random_uuid(), novel_id, 'You pushed through the harsh terrain. Your body feels stronger, your mind clearer. The mist begins to part.' FROM scene_1
    RETURNING id, novel_id
),
scene_3 AS (
    INSERT INTO public.wish_novel_scenes (id, novel_id, scene_text)
    SELECT gen_random_uuid(), novel_id, 'You sat down to meditate. The cold no longer bothers you. You found peace within the mountain.' FROM scene_1
    RETURNING id, novel_id
)
INSERT INTO public.wish_novel_choices (scene_id, choice_text, next_scene_id, req_physical, req_mental, req_ethical, reward_physical, reward_mental, reward_ethical)
VALUES 
((SELECT id FROM scene_1), 'Force your way up the steep path (Requires Physical Lvl 2)', (SELECT id FROM scene_2), 2, 1, 1, 2, 0, 0),
((SELECT id FROM scene_1), 'Sit and meditate in the freezing mist (Requires Mental Lvl 2)', (SELECT id FROM scene_3), 1, 2, 1, 0, 2, 0);
