
-- Phase 1 MVP schema

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  photo_url TEXT,
  credits INT NOT NULL DEFAULT 100,
  free_requests INT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.sessions (
  token TEXT PRIMARY KEY,
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX sessions_profile_idx ON public.sessions(profile_id);

CREATE TABLE public.help_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  level TEXT NOT NULL DEFAULT 'normal',
  anonymous BOOLEAN NOT NULL DEFAULT false,
  status TEXT NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX help_requests_created_idx ON public.help_requests(created_at DESC);
CREATE INDEX help_requests_status_idx ON public.help_requests(status);

CREATE TABLE public.help_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL REFERENCES public.help_requests(id) ON DELETE CASCADE,
  helper_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  message TEXT,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (request_id, helper_id)
);

CREATE TABLE public.credits_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  delta INT NOT NULL,
  reason TEXT NOT NULL,
  request_id UUID REFERENCES public.help_requests(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX credits_ledger_profile_idx ON public.credits_ledger(profile_id, created_at DESC);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  message TEXT NOT NULL,
  link TEXT,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX notifications_profile_idx ON public.notifications(profile_id, created_at DESC);
