-- week17_schema.sql
-- Supports multiple joiners (both helpers and helpies), individual/multiple selections,
-- and post/instruction box inside every help request.

-- 1. Required columns for request joins, contacts, and completion flows
ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS contact_choice JSONB;

ALTER TABLE public.campaign_members
  ADD COLUMN IF NOT EXISTS join_role TEXT DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'accepted';

ALTER TABLE public.agenda_participants
  ADD COLUMN IF NOT EXISTS join_role TEXT DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'accepted';

ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS join_type TEXT;

UPDATE public.request_volunteers
SET join_type = 'individual'
WHERE join_type IS NULL;

ALTER TABLE public.request_volunteers
  ALTER COLUMN join_type SET DEFAULT 'individual',
  ALTER COLUMN join_type SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'request_volunteers_join_type_check'
  ) THEN
    ALTER TABLE public.request_volunteers
      ADD CONSTRAINT request_volunteers_join_type_check
      CHECK (join_type IN ('individual', 'multiple'));
  END IF;
END;
$$;

ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER DEFAULT 0;

ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;

ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;

ALTER TABLE public.nonprofit_agenda_items
  ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;

ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

ALTER TABLE public.campaign_members
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

ALTER TABLE public.agenda_participants
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

-- 2. Add join_type to community_starter_request_joins
ALTER TABLE public.community_starter_request_joins
  ADD COLUMN IF NOT EXISTS join_type TEXT;

UPDATE public.community_starter_request_joins
SET join_type = 'individual'
WHERE join_type IS NULL;

ALTER TABLE public.community_starter_request_joins
  ALTER COLUMN join_type SET DEFAULT 'individual',
  ALTER COLUMN join_type SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'community_starter_request_joins_join_type_check'
  ) THEN
    ALTER TABLE public.community_starter_request_joins
      ADD CONSTRAINT community_starter_request_joins_join_type_check
      CHECK (join_type IN ('individual', 'multiple'));
  END IF;
END;
$$;

-- 3. Create help_request_posts table for comments/instructions
CREATE TABLE IF NOT EXISTS public.help_request_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID NOT NULL, -- references either help_requests or community_starter_requests
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable RLS and add policies
ALTER TABLE public.help_request_posts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Help request posts are viewable by everyone." ON public.help_request_posts;
CREATE POLICY "Help request posts are viewable by everyone."
  ON public.help_request_posts
  FOR SELECT
  USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert posts." ON public.help_request_posts;
CREATE POLICY "Authenticated users can insert posts."
  ON public.help_request_posts
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

GRANT SELECT, INSERT ON public.help_request_posts TO authenticated;
GRANT SELECT ON public.help_request_posts TO anon;

CREATE INDEX IF NOT EXISTS help_request_posts_request_created_idx
  ON public.help_request_posts (request_id, created_at);

-- 4. Update join_help_request RPC to support join_type
CREATE OR REPLACE FUNCTION public.join_help_request(
  p_request_id UUID,
  p_join_role TEXT DEFAULT 'helper',
  p_contact_choice JSONB DEFAULT NULL,
  p_join_type TEXT DEFAULT 'individual'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $join_help_request$
DECLARE
  v_inserted BOOLEAN;
  v_previous_role TEXT;
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helper');
  v_type TEXT := COALESCE(NULLIF(p_join_type, ''), 'individual');
  v_request RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_role NOT IN ('helpee', 'helper') THEN
    RAISE EXCEPTION 'Invalid join role';
  END IF;

  IF v_type NOT IN ('individual', 'multiple') THEN
    RAISE EXCEPTION 'Invalid join type';
  END IF;

  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id AND status = 'open';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Help request not found or not open';
  END IF;

  SELECT join_role INTO v_previous_role
  FROM public.request_volunteers
  WHERE request_id = p_request_id
    AND volunteer_id = auth.uid()
  FOR UPDATE;

  -- Insert or update volunteer/joiner
  INSERT INTO public.request_volunteers (
    request_id,
    volunteer_id,
    status,
    join_role,
    contact_choice,
    join_type
  )
  VALUES (p_request_id, auth.uid(), 'accepted', v_role, p_contact_choice, v_type)
  ON CONFLICT (request_id, volunteer_id) DO UPDATE SET
    join_role = EXCLUDED.join_role,
    contact_choice = EXCLUDED.contact_choice,
    join_type = EXCLUDED.join_type
  RETURNING (xmax = 0) INTO v_inserted;

  IF v_previous_role IS NULL THEN
    UPDATE public.help_requests
    SET join_count = join_count + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helpie_count = helpie_count + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = helper_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        volunteers_count = volunteers_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        goodwill_impact_score = LEAST(100, goodwill_impact_score + 1)
    WHERE id = p_request_id;
  ELSIF v_previous_role IS DISTINCT FROM v_role THEN
    UPDATE public.help_requests
    SET join_count = GREATEST(0, join_count - CASE WHEN v_previous_role = 'helpee' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helpie_count = GREATEST(0, helpie_count - CASE WHEN v_previous_role = 'helpee' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = GREATEST(0, helper_count - CASE WHEN v_previous_role = 'helper' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        volunteers_count = GREATEST(0, volunteers_count - CASE WHEN v_previous_role = 'helper' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END
    WHERE id = p_request_id;
  END IF;
END;
$join_help_request$;

REVOKE ALL ON FUNCTION public.join_help_request(UUID, TEXT, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_help_request(UUID, TEXT, JSONB, TEXT) TO authenticated;

-- 5. Update join_community_starter_request RPC to support join_type
CREATE OR REPLACE FUNCTION public.join_community_starter_request(
  p_request_id UUID,
  p_join_role TEXT DEFAULT 'helpee',
  p_contact_choice JSONB DEFAULT NULL,
  p_join_type TEXT DEFAULT 'individual'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $join_community_starter_request$
DECLARE
  v_inserted BOOLEAN;
  v_previous_role TEXT;
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helpee');
  v_type TEXT := COALESCE(NULLIF(p_join_type, ''), 'individual');
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_role NOT IN ('helpee', 'helper') THEN
    RAISE EXCEPTION 'Invalid join role';
  END IF;

  IF v_type NOT IN ('individual', 'multiple') THEN
    RAISE EXCEPTION 'Invalid join type';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.community_starter_requests
    WHERE id = p_request_id
      AND status = 'open'
      AND allow_join_need = true
  ) THEN
    RAISE EXCEPTION 'Community starter request not found';
  END IF;

  SELECT join_role INTO v_previous_role
  FROM public.community_starter_request_joins
  WHERE request_id = p_request_id
    AND user_id = auth.uid()
  FOR UPDATE;

  INSERT INTO public.community_starter_request_joins (
    request_id,
    user_id,
    join_role,
    contact_choice,
    join_type
  )
  VALUES (p_request_id, auth.uid(), v_role, p_contact_choice, v_type)
  ON CONFLICT (request_id, user_id) DO UPDATE SET
    join_role = EXCLUDED.join_role,
    contact_choice = EXCLUDED.contact_choice,
    join_type = EXCLUDED.join_type
  RETURNING (xmax = 0) INTO v_inserted;

  IF v_previous_role IS NULL THEN
    UPDATE public.community_starter_requests
    SET join_count = join_count + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = helper_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        goodwill_impact_score = LEAST(100, goodwill_impact_score + 1),
        updated_at = now()
    WHERE id = p_request_id;
  ELSIF v_previous_role IS DISTINCT FROM v_role THEN
    UPDATE public.community_starter_requests
    SET join_count = GREATEST(0, join_count - CASE WHEN v_previous_role = 'helpee' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = GREATEST(0, helper_count - CASE WHEN v_previous_role = 'helper' THEN 1 ELSE 0 END)
          + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        updated_at = now()
    WHERE id = p_request_id;
  END IF;
END;
$join_community_starter_request$;

REVOKE ALL ON FUNCTION public.join_community_starter_request(UUID, TEXT, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_community_starter_request(UUID, TEXT, JSONB, TEXT) TO authenticated;

-- 6. Update complete_connection to match the current campaign/agenda schema
CREATE OR REPLACE FUNCTION public.complete_connection(
  p_entity_id UUID,
  p_entity_type TEXT,
  p_participant_id UUID,
  p_completion_message TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $complete_connection$
DECLARE
  v_creator_id UUID;
  v_participant_email TEXT;
  v_actual_reward INTEGER := 10;
  v_title TEXT;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF p_entity_type = 'request' THEN
    SELECT creator_id, title, COALESCE(goodwill_reward, 10)
    INTO v_creator_id, v_title, v_actual_reward
    FROM public.help_requests
    WHERE id = p_entity_id;
  ELSIF p_entity_type = 'campaign' THEN
    SELECT creator_id, title
    INTO v_creator_id, v_title
    FROM public.campaigns
    WHERE id = p_entity_id;
    v_actual_reward := 15;
  ELSIF p_entity_type = 'agenda' THEN
    SELECT ngo_id, title
    INTO v_creator_id, v_title
    FROM public.nonprofit_agenda_items
    WHERE id = p_entity_id;
    v_actual_reward := 20;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;

  IF v_creator_id IS NULL THEN
    RAISE EXCEPTION 'Entity not found';
  END IF;

  IF auth.uid() != v_creator_id THEN
    RAISE EXCEPTION 'Only the creator can complete a connection';
  END IF;

  IF p_entity_type = 'request' THEN
    UPDATE public.request_volunteers
    SET status = 'completed',
        completion_message = p_completion_message
    WHERE request_id = p_entity_id
      AND volunteer_id = p_participant_id
      AND status IS DISTINCT FROM 'completed';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Participant not found or already completed';
    END IF;

    UPDATE public.help_requests
    SET completed_connections_count = completed_connections_count + 1
    WHERE id = p_entity_id;
  ELSIF p_entity_type = 'campaign' THEN
    UPDATE public.campaign_members
    SET status = 'completed',
        completion_message = p_completion_message
    WHERE campaign_id = p_entity_id
      AND user_id = p_participant_id
      AND status IS DISTINCT FROM 'completed';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Participant not found or already completed';
    END IF;

    UPDATE public.campaigns
    SET completed_connections_count = completed_connections_count + 1
    WHERE id = p_entity_id;
  ELSIF p_entity_type = 'agenda' THEN
    UPDATE public.agenda_participants
    SET status = 'completed',
        completion_message = p_completion_message
    WHERE agenda_item_id = p_entity_id
      AND volunteer_id = p_participant_id
      AND status IS DISTINCT FROM 'completed';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Participant not found or already completed';
    END IF;

    UPDATE public.nonprofit_agenda_items
    SET completed_connections_count = completed_connections_count + 1
    WHERE id = p_entity_id;
  END IF;

  UPDATE public.user_stats
  SET credits = credits + v_actual_reward,
      credits_earned = COALESCE(credits_earned, 0) + v_actual_reward,
      impact_score = impact_score + v_actual_reward,
      help_count = help_count + 1,
      reputation_score = COALESCE(reputation_score, 0) + 10
  WHERE user_id = p_participant_id;

  INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id)
  VALUES (p_participant_id, v_actual_reward, 'EARN', p_entity_id);

  INSERT INTO public.goodwill_chain_links (
    source_user_id,
    affected_user_id,
    source_type,
    reference_id,
    impact_value
  )
  VALUES (p_participant_id, v_creator_id, p_entity_type, p_entity_id, v_actual_reward);

  INSERT INTO public.notifications (user_id, title, message)
  VALUES (
    p_participant_id,
    'Connection Completed: ' || v_title,
    'You earned ' || v_actual_reward || ' credits. Message from creator: ' || COALESCE(p_completion_message, 'Thank you!')
  );

  PERFORM public.check_and_award_badges(p_participant_id);

  SELECT email
  INTO v_participant_email
  FROM auth.users
  WHERE id = p_participant_id;

  RETURN v_participant_email;
END;
$complete_connection$;

REVOKE ALL ON FUNCTION public.complete_connection(UUID, TEXT, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_connection(UUID, TEXT, UUID, TEXT) TO authenticated;

-- 7. Update get_entity_contacts to return join_type and handle community starter request joins
DROP FUNCTION IF EXISTS public.get_entity_contacts(UUID, TEXT, TEXT);

CREATE OR REPLACE FUNCTION public.get_entity_contacts(
  p_entity_id UUID,
  p_entity_type TEXT,
  p_my_role TEXT
)
RETURNS TABLE (
  participant_id UUID,
  name TEXT,
  email TEXT,
  status TEXT,
  join_type TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $get_entity_contacts$
DECLARE
  v_target_role TEXT;
BEGIN
  IF p_my_role = 'helper' THEN
    v_target_role := 'helpee';
  ELSE
    v_target_role := 'helper';
  END IF;

  IF p_entity_type = 'request' THEN
    -- Check if it is a community starter request
    IF EXISTS (SELECT 1 FROM public.community_starter_requests WHERE id = p_entity_id) THEN
      RETURN QUERY
      SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), 'accepted'::TEXT AS status, cj.join_type
      FROM public.community_starter_request_joins cj
      JOIN auth.users u ON cj.user_id = u.id
      LEFT JOIN public.profiles p ON u.id = p.id
      WHERE cj.request_id = p_entity_id AND cj.join_role = v_target_role;
    ELSE
      RETURN QUERY
      SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), rv.status, rv.join_type
      FROM public.request_volunteers rv
      JOIN auth.users u ON rv.volunteer_id = u.id
      LEFT JOIN public.profiles p ON u.id = p.id
      WHERE rv.request_id = p_entity_id AND rv.join_role = v_target_role;
    END IF;
  ELSIF p_entity_type = 'campaign' THEN
    RETURN QUERY
    SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), cm.status, 'individual'::TEXT AS join_type
    FROM public.campaign_members cm
    JOIN auth.users u ON cm.user_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE cm.campaign_id = p_entity_id AND cm.join_role = v_target_role;
  ELSIF p_entity_type = 'agenda' THEN
    RETURN QUERY
    SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), ap.status, 'individual'::TEXT AS join_type
    FROM public.agenda_participants ap
    JOIN auth.users u ON ap.volunteer_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE ap.agenda_item_id = p_entity_id AND ap.join_role = v_target_role;
  END IF;
END;
$get_entity_contacts$;
