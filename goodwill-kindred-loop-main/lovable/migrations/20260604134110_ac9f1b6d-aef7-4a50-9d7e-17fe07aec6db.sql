-- Phase 2: media, reactions, comments, stories

ALTER TABLE public.help_requests ADD COLUMN IF NOT EXISTS media_url TEXT;

CREATE TABLE IF NOT EXISTS public.reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.help_requests(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'cheer',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(request_id, profile_id, type)
);
CREATE INDEX IF NOT EXISTS idx_reactions_request ON public.reactions(request_id);

CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.help_requests(id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_comments_request ON public.comments(request_id, created_at);

CREATE TABLE IF NOT EXISTS public.stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT,
  media_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + INTERVAL '24 hours')
);
CREATE INDEX IF NOT EXISTS idx_stories_active ON public.stories(expires_at DESC);
