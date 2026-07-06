-- week18_schema.sql
-- Request Connection Hub repair migration.

-- 1. Deduplicate request_volunteers
DELETE FROM public.request_volunteers a USING (
  SELECT MIN(ctid) as min_ctid, request_id, volunteer_id
  FROM public.request_volunteers
  GROUP BY request_id, volunteer_id HAVING COUNT(*) > 1
) b
WHERE a.request_id = b.request_id 
  AND a.volunteer_id = b.volunteer_id 
  AND a.ctid <> b.min_ctid;

-- Now safe to add unique index/constraint
CREATE UNIQUE INDEX IF NOT EXISTS request_volunteers_request_volunteer_uidx
  ON public.request_volunteers (request_id, volunteer_id);

-- 2. Deduplicate community_starter_request_joins
DELETE FROM public.community_starter_request_joins a USING (
  SELECT MIN(ctid) as min_ctid, request_id, user_id
  FROM public.community_starter_request_joins
  GROUP BY request_id, user_id HAVING COUNT(*) > 1
) b
WHERE a.request_id = b.request_id 
  AND a.user_id = b.user_id 
  AND a.ctid <> b.min_ctid;

CREATE UNIQUE INDEX IF NOT EXISTS community_starter_request_joins_request_user_uidx
  ON public.community_starter_request_joins (request_id, user_id);

-- 3. Required columns for request joins, contacts, and completion flows
ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS contact_choice JSONB,
  ADD COLUMN IF NOT EXISTS join_type TEXT NOT NULL DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

ALTER TABLE public.campaign_members
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'accepted',
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

ALTER TABLE public.agenda_participants
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'accepted',
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS helper_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS support_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.nonprofit_agenda_items
  ADD COLUMN IF NOT EXISTS helper_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS support_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER NOT NULL DEFAULT 0;

UPDATE public.request_volunteers
SET join_role = COALESCE(NULLIF(join_role, ''), 'helper'),
    join_type = COALESCE(NULLIF(join_type, ''), 'individual');

UPDATE public.campaign_members
SET join_role = COALESCE(NULLIF(join_role, ''), 'helper'),
    status = COALESCE(NULLIF(status, ''), 'accepted');

UPDATE public.agenda_participants
SET join_role = COALESCE(NULLIF(join_role, ''), 'helper'),
    status = COALESCE(NULLIF(status, ''), 'accepted');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conrelid = 'public.request_volunteers'::regclass AND conname = 'request_volunteers_role_check'
  ) THEN
    ALTER TABLE public.request_volunteers ADD CONSTRAINT request_volunteers_role_check CHECK (join_role IN ('helpee', 'helper'));
  END IF;
END;
$$;

-- 4. Community starter hub columns
ALTER TABLE public.community_starter_requests
  ADD COLUMN IF NOT EXISTS tags TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  ADD COLUMN IF NOT EXISTS allow_join_need BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS join_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helper_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS goodwill_impact_score INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS tag_credit_bonus INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS art_asset_path TEXT,
  ADD COLUMN IF NOT EXISTS contact_options JSONB NOT NULL DEFAULT '[]'::JSONB,
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open',
  ADD COLUMN IF NOT EXISTS seed_helper_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS seed_join_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE public.community_starter_requests SET seed_join_count = 24, seed_helper_count = 6 WHERE title = 'How do I get my first internship?';
UPDATE public.community_starter_requests SET seed_join_count = 18, seed_helper_count = 5 WHERE title = 'What skills should I learn for AI/ML in 2026?';
UPDATE public.community_starter_requests SET seed_join_count = 31, seed_helper_count = 8 WHERE title = 'Can someone review my resume?';
UPDATE public.community_starter_requests SET seed_join_count = 29, seed_helper_count = 7 WHERE title = 'How do I prepare for placement interviews?';
UPDATE public.community_starter_requests SET seed_join_count = 17, seed_helper_count = 4 WHERE title = 'Which projects should I build for my portfolio?';
UPDATE public.community_starter_requests SET seed_join_count = 21, seed_helper_count = 6 WHERE title = 'Can someone explain this topic to me?';
UPDATE public.community_starter_requests SET seed_join_count = 13, seed_helper_count = 3 WHERE title = 'Looking for teammates for a hackathon';
UPDATE public.community_starter_requests SET seed_join_count = 16, seed_helper_count = 4 WHERE title = 'Which certification is worth doing?';
UPDATE public.community_starter_requests SET seed_join_count = 19, seed_helper_count = 5 WHERE title = 'How do I improve my LinkedIn profile?';
UPDATE public.community_starter_requests SET seed_join_count = 11, seed_helper_count = 3 WHERE title = 'Need feedback on my startup idea';

ALTER TABLE public.community_starter_request_joins
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helpee',
  ADD COLUMN IF NOT EXISTS contact_choice JSONB,
  ADD COLUMN IF NOT EXISTS join_type TEXT NOT NULL DEFAULT 'individual',
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'accepted',
  ADD COLUMN IF NOT EXISTS joined_at TIMESTAMPTZ NOT NULL DEFAULT now();

UPDATE public.community_starter_request_joins
SET join_role = COALESCE(NULLIF(join_role, ''), 'helpee'),
    join_type = COALESCE(NULLIF(join_type, ''), 'individual');

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conrelid = 'public.community_starter_request_joins'::regclass AND conname = 'community_starter_request_joins_role_check'
  ) THEN
    ALTER TABLE public.community_starter_request_joins ADD CONSTRAINT community_starter_request_joins_role_check CHECK (join_role IN ('helpee', 'helper'));
  END IF;
END;
$$;

-- 5. Helper RPCs and Updates
CREATE OR REPLACE FUNCTION public.refresh_help_request_counts(p_request_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.help_requests hr
  SET helper_count = (SELECT COUNT(*)::INTEGER FROM public.request_volunteers rv WHERE rv.request_id = hr.id AND rv.join_role = 'helper'),
      helpie_count = 1 + (SELECT COUNT(*)::INTEGER FROM public.request_volunteers rv WHERE rv.request_id = hr.id AND rv.join_role = 'helpee' AND rv.volunteer_id <> hr.creator_id),
      volunteers_count = 1 + (SELECT COUNT(*)::INTEGER FROM public.request_volunteers rv WHERE rv.request_id = hr.id AND rv.volunteer_id <> hr.creator_id),
      join_count = 1 + (SELECT COUNT(*)::INTEGER FROM public.request_volunteers rv WHERE rv.request_id = hr.id AND rv.join_role = 'helpee' AND rv.volunteer_id <> hr.creator_id)
  WHERE hr.id = p_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

CREATE OR REPLACE FUNCTION public.refresh_community_starter_request_counts(p_request_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.community_starter_requests csr
  SET helper_count = csr.seed_helper_count + (SELECT COUNT(*)::INTEGER FROM public.community_starter_request_joins cj WHERE cj.request_id = csr.id AND cj.join_role = 'helper'),
      join_count = csr.seed_join_count + (SELECT COUNT(*)::INTEGER FROM public.community_starter_request_joins cj WHERE cj.request_id = csr.id AND cj.join_role = 'helpee'),
      goodwill_impact_score = LEAST(100, csr.seed_helper_count + csr.seed_join_count + (SELECT COUNT(*)::INTEGER FROM public.community_starter_request_joins cj WHERE cj.request_id = csr.id)),
      updated_at = now()
  WHERE csr.id = p_request_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

-- Seed counters backfill
UPDATE public.community_starter_requests csr
SET helper_count = seed_helper_count, join_count = seed_join_count, goodwill_impact_score = LEAST(100, seed_helper_count + seed_join_count), updated_at = now()
WHERE NOT EXISTS (SELECT 1 FROM public.community_starter_request_joins cj WHERE cj.request_id = csr.id);

UPDATE public.community_starter_requests csr
SET helper_count = csr.seed_helper_count + counts.helper_count,
    join_count = csr.seed_join_count + counts.helpie_count,
    goodwill_impact_score = LEAST(100, csr.seed_helper_count + csr.seed_join_count + counts.total_count),
    updated_at = now()
FROM (
  SELECT request_id, COUNT(*) FILTER (WHERE join_role = 'helper')::INTEGER AS helper_count, COUNT(*) FILTER (WHERE join_role = 'helpee')::INTEGER AS helpie_count, COUNT(*)::INTEGER AS total_count
  FROM public.community_starter_request_joins GROUP BY request_id
) counts
WHERE csr.id = counts.request_id;


CREATE OR REPLACE FUNCTION public.join_help_request(
  p_request_id UUID, p_join_role TEXT DEFAULT 'helper', p_contact_choice JSONB DEFAULT NULL, p_join_type TEXT DEFAULT 'individual'
) RETURNS void AS $$
DECLARE
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helper');
  v_type TEXT := COALESCE(NULLIF(p_join_type, ''), 'individual');
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF v_role NOT IN ('helpee', 'helper') THEN RAISE EXCEPTION 'Invalid role'; END IF;
  IF v_type NOT IN ('individual', 'multiple') THEN RAISE EXCEPTION 'Invalid join type'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.help_requests WHERE id = p_request_id AND status = 'open') THEN
    RAISE EXCEPTION 'Help request not found or not open';
  END IF;

  INSERT INTO public.request_volunteers (request_id, volunteer_id, status, join_role, contact_choice, join_type)
  VALUES (p_request_id, auth.uid(), 'accepted', v_role, p_contact_choice, v_type)
  ON CONFLICT (request_id, volunteer_id) DO UPDATE SET
    status = 'accepted', join_role = EXCLUDED.join_role, contact_choice = EXCLUDED.contact_choice, join_type = EXCLUDED.join_type;

  PERFORM public.refresh_help_request_counts(p_request_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

CREATE OR REPLACE FUNCTION public.join_community_starter_request(
  p_request_id UUID, p_join_role TEXT DEFAULT 'helpee', p_contact_choice JSONB DEFAULT NULL, p_join_type TEXT DEFAULT 'individual'
) RETURNS void AS $$
DECLARE
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helpee');
  v_type TEXT := COALESCE(NULLIF(p_join_type, ''), 'individual');
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF v_role NOT IN ('helpee', 'helper') THEN RAISE EXCEPTION 'Invalid role'; END IF;
  IF v_type NOT IN ('individual', 'multiple') THEN RAISE EXCEPTION 'Invalid join type'; END IF;
  IF NOT EXISTS (SELECT 1 FROM public.community_starter_requests WHERE id = p_request_id) THEN
    RAISE EXCEPTION 'Community starter request not found';
  END IF;

  INSERT INTO public.community_starter_request_joins (request_id, user_id, join_role, contact_choice, join_type, status)
  VALUES (p_request_id, auth.uid(), v_role, p_contact_choice, v_type, 'accepted')
  ON CONFLICT (request_id, user_id) DO UPDATE SET
    join_role = EXCLUDED.join_role, contact_choice = EXCLUDED.contact_choice, join_type = EXCLUDED.join_type, joined_at = now();

  PERFORM public.refresh_community_starter_request_counts(p_request_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;


CREATE OR REPLACE FUNCTION public.request_help_completion_review(
  p_request_id UUID, p_message TEXT DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_is_starter BOOLEAN;
  v_updated_count INTEGER;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  SELECT EXISTS(SELECT 1 FROM public.community_starter_requests WHERE id = p_request_id) INTO v_is_starter;

  IF v_is_starter THEN
    UPDATE public.community_starter_request_joins
    SET status = 'completion_requested'
    WHERE request_id = p_request_id AND user_id = auth.uid() AND join_role = 'helper' AND status IS DISTINCT FROM 'completed';
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    IF v_updated_count = 0 THEN
      INSERT INTO public.community_starter_request_joins (request_id, user_id, join_role, status)
      VALUES (p_request_id, auth.uid(), 'helper', 'completion_requested')
      ON CONFLICT (request_id, user_id) DO UPDATE SET status = 'completion_requested';
    END IF;
  ELSE
    UPDATE public.request_volunteers
    SET status = 'completion_requested', completion_message = NULLIF(trim(COALESCE(p_message, '')), '')
    WHERE request_id = p_request_id AND volunteer_id = auth.uid() AND join_role = 'helper' AND status IS DISTINCT FROM 'completed';
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    IF v_updated_count = 0 THEN
      INSERT INTO public.request_volunteers (request_id, volunteer_id, join_role, status, completion_message)
      VALUES (p_request_id, auth.uid(), 'helper', 'completion_requested', NULLIF(trim(COALESCE(p_message, '')), ''))
      ON CONFLICT (request_id, volunteer_id) DO UPDATE SET status = 'completion_requested', completion_message = NULLIF(trim(COALESCE(p_message, '')), '');
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;


-- 6. Connection Confirmations Table & confirm_and_like_helper RPC
CREATE TABLE IF NOT EXISTS public.connection_confirmations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL,
  helper_id UUID NOT NULL,
  helpie_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  liked BOOLEAN NOT NULL DEFAULT false,
  confirmed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (request_id, helper_id, helpie_id)
);
ALTER TABLE public.connection_confirmations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Confirmations are viewable by authenticated users." ON public.connection_confirmations;
CREATE POLICY "Confirmations are viewable by authenticated users." ON public.connection_confirmations FOR SELECT USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Authenticated users can insert confirmations." ON public.connection_confirmations;
CREATE POLICY "Authenticated users can insert confirmations." ON public.connection_confirmations FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = helpie_id);

GRANT SELECT, INSERT ON public.connection_confirmations TO authenticated;

CREATE OR REPLACE FUNCTION public.confirm_and_like_helper(
  p_request_id UUID, p_helper_id UUID, p_liked BOOLEAN
) RETURNS void AS $$
DECLARE
  v_helpie_id UUID := auth.uid();
  v_is_starter BOOLEAN;
BEGIN
  IF v_helpie_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  SELECT EXISTS(SELECT 1 FROM public.community_starter_requests WHERE id = p_request_id) INTO v_is_starter;
  
  IF v_is_starter THEN
    IF NOT EXISTS (SELECT 1 FROM public.community_starter_request_joins WHERE request_id = p_request_id AND user_id = v_helpie_id AND join_role = 'helpee') THEN
      RAISE EXCEPTION 'Only joined helpies can confirm helpers';
    END IF;
  ELSE
    IF NOT EXISTS (SELECT 1 FROM public.help_requests WHERE id = p_request_id AND creator_id = v_helpie_id) AND NOT EXISTS (SELECT 1 FROM public.request_volunteers WHERE request_id = p_request_id AND volunteer_id = v_helpie_id AND join_role = 'helpee') THEN
      RAISE EXCEPTION 'Only joined helpies or the creator can confirm helpers';
    END IF;
  END IF;

  IF EXISTS (SELECT 1 FROM public.connection_confirmations WHERE request_id = p_request_id AND helper_id = p_helper_id AND helpie_id = v_helpie_id) THEN
    UPDATE public.connection_confirmations SET liked = p_liked WHERE request_id = p_request_id AND helper_id = p_helper_id AND helpie_id = v_helpie_id;
  ELSE
    INSERT INTO public.connection_confirmations (request_id, helper_id, helpie_id, liked) VALUES (p_request_id, p_helper_id, v_helpie_id, p_liked);
    UPDATE public.user_stats SET credits = credits + 1, credits_earned = COALESCE(credits_earned, 0) + 1, impact_score = impact_score + 1 WHERE user_id = p_helper_id;
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) VALUES (p_helper_id, 1, 'EARN', p_request_id);
    
    -- Also update helper status to completed
    IF v_is_starter THEN
      UPDATE public.community_starter_request_joins SET status = 'completed' WHERE request_id = p_request_id AND user_id = p_helper_id;
    ELSE
      UPDATE public.request_volunteers SET status = 'completed' WHERE request_id = p_request_id AND volunteer_id = p_helper_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;


-- 7. get_entity_contacts Updates
DROP FUNCTION IF EXISTS public.get_entity_contacts(UUID, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.get_entity_contacts(
  p_entity_id UUID, p_entity_type TEXT, p_my_role TEXT
) RETURNS TABLE (
  participant_id UUID, name TEXT, email TEXT, phone TEXT, status TEXT, join_type TEXT, role TEXT, is_confirmed BOOLEAN, is_liked BOOLEAN
) AS $$
BEGIN
  IF p_entity_type = 'request' THEN
    IF EXISTS (SELECT 1 FROM public.community_starter_requests WHERE id = p_entity_id) THEN
      RETURN QUERY
      SELECT DISTINCT ON (u.id) u.id, COALESCE(p.name, 'Unknown')::TEXT, COALESCE(u.email::TEXT, '')::TEXT, COALESCE(p.phone, '')::TEXT, COALESCE(cj.status, 'accepted')::TEXT, COALESCE(cj.join_type, 'individual')::TEXT, COALESCE(cj.join_role, 'helpee')::TEXT,
        EXISTS(SELECT 1 FROM public.connection_confirmations cc WHERE cc.request_id = p_entity_id AND cc.helper_id = u.id AND cc.helpie_id = auth.uid()) AS is_confirmed,
        COALESCE((SELECT cc.liked FROM public.connection_confirmations cc WHERE cc.request_id = p_entity_id AND cc.helper_id = u.id AND cc.helpie_id = auth.uid()), false) AS is_liked
      FROM public.community_starter_request_joins cj
      JOIN auth.users u ON cj.user_id = u.id LEFT JOIN public.profiles p ON u.id = p.id
      WHERE cj.request_id = p_entity_id ORDER BY u.id, cj.join_role, cj.joined_at;
    ELSE
      RETURN QUERY
      SELECT DISTINCT ON (sub.id) sub.id, sub.name, sub.email, sub.phone, sub.status, sub.join_type, sub.role, sub.is_confirmed, sub.is_liked FROM (
        SELECT u.id, COALESCE(p.name, 'Unknown')::TEXT AS name, COALESCE(u.email::TEXT, '')::TEXT AS email, COALESCE(p.phone, '')::TEXT AS phone, 'accepted'::TEXT AS status, 'individual'::TEXT AS join_type, 'helpee'::TEXT AS role, false AS is_confirmed, false AS is_liked
        FROM public.help_requests hr JOIN auth.users u ON hr.creator_id = u.id LEFT JOIN public.profiles p ON u.id = p.id WHERE hr.id = p_entity_id
        UNION ALL
        SELECT u.id, COALESCE(p.name, 'Unknown')::TEXT AS name, COALESCE(u.email::TEXT, '')::TEXT AS email, COALESCE(p.phone, '')::TEXT AS phone, COALESCE(rv.status, 'accepted')::TEXT AS status, COALESCE(rv.join_type, 'individual')::TEXT AS join_type, COALESCE(rv.join_role, 'helper')::TEXT AS role,
          EXISTS(SELECT 1 FROM public.connection_confirmations cc WHERE cc.request_id = p_entity_id AND cc.helper_id = u.id AND cc.helpie_id = auth.uid()) AS is_confirmed,
          COALESCE((SELECT cc.liked FROM public.connection_confirmations cc WHERE cc.request_id = p_entity_id AND cc.helper_id = u.id AND cc.helpie_id = auth.uid()), false) AS is_liked
        FROM public.request_volunteers rv JOIN auth.users u ON rv.volunteer_id = u.id LEFT JOIN public.profiles p ON u.id = p.id WHERE rv.request_id = p_entity_id
      ) sub ORDER BY sub.id, sub.role;
    END IF;
  ELSIF p_entity_type = 'campaign' THEN
    RETURN QUERY SELECT DISTINCT ON (u.id) u.id, COALESCE(p.name, 'Unknown')::TEXT, COALESCE(u.email::TEXT, '')::TEXT, COALESCE(p.phone, '')::TEXT, COALESCE(cm.status, 'accepted')::TEXT, 'individual'::TEXT, COALESCE(cm.join_role, 'helper')::TEXT, false, false
    FROM public.campaign_members cm JOIN auth.users u ON cm.user_id = u.id LEFT JOIN public.profiles p ON u.id = p.id WHERE cm.campaign_id = p_entity_id ORDER BY u.id, cm.join_role;
  ELSIF p_entity_type = 'agenda' THEN
    RETURN QUERY SELECT DISTINCT ON (u.id) u.id, COALESCE(p.name, 'Unknown')::TEXT, COALESCE(u.email::TEXT, '')::TEXT, COALESCE(p.phone, '')::TEXT, COALESCE(ap.status, 'accepted')::TEXT, 'individual'::TEXT, COALESCE(ap.join_role, 'helper')::TEXT, false, false
    FROM public.agenda_participants ap JOIN auth.users u ON ap.volunteer_id = u.id LEFT JOIN public.profiles p ON u.id = p.id WHERE ap.agenda_item_id = p_entity_id ORDER BY u.id, ap.join_role;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;
