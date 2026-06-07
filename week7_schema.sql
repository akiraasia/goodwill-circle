-- Week 7 Anonymous Confessions, Photos, Campaign Votes, and Comments

ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS image_url TEXT;

ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS image_url TEXT;

INSERT INTO storage.buckets (id, name, public)
VALUES ('goodwill-media', 'goodwill-media', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "Goodwill media is public." ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload goodwill media." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their goodwill media." ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their goodwill media." ON storage.objects;

GRANT SELECT ON storage.buckets TO anon, authenticated;
GRANT SELECT ON storage.objects TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON storage.objects TO authenticated;

CREATE POLICY "Goodwill media is public."
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'goodwill-media');

CREATE POLICY "Authenticated users can upload goodwill media."
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN ('requests', 'campaigns', 'confessions')
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can update their goodwill media."
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN ('requests', 'campaigns', 'confessions')
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can delete their goodwill media."
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE TABLE IF NOT EXISTS public.confessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  support_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.confession_supports (
  confession_id UUID REFERENCES public.confessions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (confession_id, user_id)
);

ALTER TABLE public.confessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.confession_supports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Confessions are anonymously viewable." ON public.confessions;
DROP POLICY IF EXISTS "Authenticated users can create anonymous confessions." ON public.confessions;
DROP POLICY IF EXISTS "Confession supports are viewable." ON public.confession_supports;
DROP POLICY IF EXISTS "Authenticated users can support confessions." ON public.confession_supports;

CREATE POLICY "Confessions are anonymously viewable."
  ON public.confessions
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create anonymous confessions."
  ON public.confessions
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = author_id);

CREATE POLICY "Confession supports are viewable."
  ON public.confession_supports
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can support confessions."
  ON public.confession_supports
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

REVOKE SELECT ON public.confessions FROM anon, authenticated;
GRANT SELECT (id, content, image_url, support_count, created_at)
  ON public.confessions TO anon, authenticated;
GRANT INSERT (author_id, content, image_url)
  ON public.confessions TO authenticated;

CREATE OR REPLACE FUNCTION public.update_confession_support_count()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.confessions
    SET support_count = support_count + 1
    WHERE id = NEW.confession_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.confessions
    SET support_count = GREATEST(support_count - 1, 0)
    WHERE id = OLD.confession_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_confession_support_changed ON public.confession_supports;
CREATE TRIGGER on_confession_support_changed
  AFTER INSERT OR DELETE ON public.confession_supports
  FOR EACH ROW EXECUTE PROCEDURE public.update_confession_support_count();

CREATE TABLE IF NOT EXISTS public.campaign_votes (
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.campaign_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.campaign_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Campaign votes are viewable." ON public.campaign_votes;
DROP POLICY IF EXISTS "Authenticated users can vote for campaigns." ON public.campaign_votes;
DROP POLICY IF EXISTS "Campaign comments are viewable." ON public.campaign_comments;
DROP POLICY IF EXISTS "Authenticated users can comment on campaigns." ON public.campaign_comments;

CREATE POLICY "Campaign votes are viewable."
  ON public.campaign_votes
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can vote for campaigns."
  ON public.campaign_votes
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE POLICY "Campaign comments are viewable."
  ON public.campaign_comments
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can comment on campaigns."
  ON public.campaign_comments
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);
