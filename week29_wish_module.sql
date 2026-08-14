-- week29_wish_module.sql
-- Wish-only persistence for individual wishes, agent tasks, diary entries and companion context.

CREATE TABLE IF NOT EXISTS public.wish_module_wishes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wish_text TEXT NOT NULL,
  focus_area TEXT NOT NULL CHECK (focus_area IN ('Physical', 'Mental', 'Ethical')),
  feeling TEXT NOT NULL,
  sentiment TEXT NOT NULL DEFAULT 'neutral',
  primary_virtue TEXT NOT NULL DEFAULT 'Courage',
  progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  change_unlocked BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.wish_module_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wish_id UUID NOT NULL REFERENCES public.wish_module_wishes(id) ON DELETE CASCADE,
  task_text TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  virtue TEXT NOT NULL DEFAULT 'Courage',
  difficulty TEXT NOT NULL DEFAULT 'easy' CHECK (difficulty IN ('easy', 'hard')),
  reward_points INTEGER NOT NULL DEFAULT 10,
  duration_minutes INTEGER NOT NULL DEFAULT 5,
  linked_request_id UUID REFERENCES public.help_requests(id) ON DELETE SET NULL,
  is_help_request BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'assigned' CHECK (status IN ('assigned', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.wish_module_diary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  wish_id UUID REFERENCES public.wish_module_wishes(id) ON DELETE SET NULL,
  entry_date DATE NOT NULL,
  mood_index INTEGER NOT NULL DEFAULT 0 CHECK (mood_index BETWEEN 0 AND 4),
  mood_label TEXT NOT NULL DEFAULT 'Hopeful',
  reflection TEXT NOT NULL DEFAULT '',
  gratitude TEXT NOT NULL DEFAULT '',
  thought_of_day TEXT NOT NULL DEFAULT '',
  sentiment TEXT NOT NULL DEFAULT 'neutral',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, entry_date)
);

CREATE INDEX IF NOT EXISTS wish_module_wishes_user_idx ON public.wish_module_wishes(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS wish_module_tasks_wish_idx ON public.wish_module_tasks(wish_id, created_at);
CREATE INDEX IF NOT EXISTS wish_module_diary_user_date_idx ON public.wish_module_diary(user_id, entry_date DESC);

ALTER TABLE public.wish_module_wishes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_module_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wish_module_diary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own wish module wishes" ON public.wish_module_wishes
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wish module wishes" ON public.wish_module_wishes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wish module wishes" ON public.wish_module_wishes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can read own wish module tasks" ON public.wish_module_tasks
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wish module tasks" ON public.wish_module_tasks
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wish module tasks" ON public.wish_module_tasks
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can read own wish module diary" ON public.wish_module_diary
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own wish module diary" ON public.wish_module_diary
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own wish module diary" ON public.wish_module_diary
  FOR UPDATE USING (auth.uid() = user_id);
