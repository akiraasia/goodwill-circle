-- week15_schema.sql
-- Synchronize old help postings to support multiple join roles and scale credits based on participants.

-- 1. Add join_role and contact_choice to request_volunteers
ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS join_role TEXT NOT NULL DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS contact_choice JSONB;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'request_volunteers_role_check'
  ) THEN
    ALTER TABLE public.request_volunteers
      ADD CONSTRAINT request_volunteers_role_check
      CHECK (join_role IN ('helpee', 'helper'));
  END IF;
END;
$$;

-- 2. Create RPC for joining regular help requests
CREATE OR REPLACE FUNCTION public.join_help_request(
  p_request_id UUID,
  p_join_role TEXT DEFAULT 'helper',
  p_contact_choice JSONB DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_inserted BOOLEAN;
  v_role TEXT := COALESCE(NULLIF(p_join_role, ''), 'helper');
  v_request RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_role NOT IN ('helpee', 'helper') THEN
    RAISE EXCEPTION 'Invalid join role';
  END IF;

  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id AND status = 'open';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Help request not found or not open';
  END IF;

  -- Insert or update volunteer/joiner
  INSERT INTO public.request_volunteers (
    request_id,
    volunteer_id,
    status,
    join_role,
    contact_choice
  )
  VALUES (p_request_id, auth.uid(), 'accepted', v_role, p_contact_choice)
  ON CONFLICT (request_id, volunteer_id) DO UPDATE SET
    join_role = EXCLUDED.join_role,
    contact_choice = EXCLUDED.contact_choice
  WHERE public.request_volunteers.join_role = EXCLUDED.join_role
    AND public.request_volunteers.contact_choice IS DISTINCT FROM EXCLUDED.contact_choice
  RETURNING (xmax = 0) INTO v_inserted;

  IF COALESCE(v_inserted, false) THEN
    -- Update counts on the request
    -- Using DO block or direct update to ensure column existence if needed.
    UPDATE public.help_requests
    SET join_count = join_count + CASE WHEN v_role = 'helpee' THEN 1 ELSE 0 END,
        helper_count = helper_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        volunteers_count = volunteers_count + CASE WHEN v_role = 'helper' THEN 1 ELSE 0 END,
        goodwill_impact_score = LEAST(100, goodwill_impact_score + 1)
    WHERE id = p_request_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.join_help_request(UUID, TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_help_request(UUID, TEXT, JSONB) TO authenticated;

-- 3. Update mark_request_completed to handle scaled rewards and creator bonuses
CREATE OR REPLACE FUNCTION public.mark_request_completed(p_request_id UUID)
RETURNS void AS $$
DECLARE
  v_request RECORD;
  v_volunteer RECORD;
  v_helper_rank INTEGER := 0;
  v_actual_reward INTEGER;
  v_creator_bonus INTEGER := 0;
  v_total_helpers INTEGER := 0;
BEGIN
  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  IF auth.uid() != v_request.creator_id THEN RAISE EXCEPTION 'Only the creator can complete this request'; END IF;
  IF v_request.status = 'completed' THEN RAISE EXCEPTION 'Request already completed'; END IF;

  UPDATE public.help_requests SET status = 'completed' WHERE id = p_request_id;

  -- Calculate total helpers for bonus
  SELECT count(*) INTO v_total_helpers FROM public.request_volunteers
  WHERE request_id = p_request_id 
    AND status IN ('accepted', 'completion_requested')
    AND join_role = 'helper';

  FOR v_volunteer IN
    SELECT volunteer_id, id, created_at, join_role FROM public.request_volunteers
    WHERE request_id = p_request_id
      AND status IN ('accepted', 'completion_requested')
    ORDER BY created_at ASC
  LOOP
    UPDATE public.request_volunteers SET status = 'completed' WHERE id = v_volunteer.id;

    IF v_volunteer.join_role = 'helper' THEN
      v_helper_rank := v_helper_rank + 1;
      
      -- "people joining an already existing help should give less credits to join"
      -- Reward scales down by 20% for each subsequent joiner, down to a minimum of 5.
      -- e.g. 1st=100%, 2nd=80%, 3rd=60%, etc.
      v_actual_reward := GREATEST(5, v_request.goodwill_reward - ((v_helper_rank - 1) * (v_request.goodwill_reward / 5)));
      
      UPDATE public.user_stats
      SET credits = credits + v_actual_reward,
          credits_earned = COALESCE(credits_earned, 0) + v_actual_reward,
          impact_score = impact_score + v_actual_reward,
          help_count = help_count + 1,
          reputation_score = COALESCE(reputation_score, 0) + 10
      WHERE user_id = v_volunteer.volunteer_id;

      INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id)
      VALUES (v_volunteer.volunteer_id, v_actual_reward, 'EARN', p_request_id);

      INSERT INTO public.goodwill_chain_links (source_user_id, affected_user_id, source_type, reference_id, impact_value)
      VALUES (v_volunteer.volunteer_id, v_request.creator_id, 'help', p_request_id, v_actual_reward);

      INSERT INTO public.notifications (user_id, title, message)
      VALUES (
        v_volunteer.volunteer_id,
        'Help Completed!',
        'You earned ' || v_actual_reward || ' credits for helping with "' || v_request.title || '"'
      );

      PERFORM public.check_and_award_badges(v_volunteer.volunteer_id);
    END IF;
  END LOOP;

  -- "if i finish a help with five people attached some more credits should go"
  -- Reward the creator for successfully completing a request with multiple helpers
  IF v_total_helpers > 0 THEN
    -- Base bonus is 10 per helper
    v_creator_bonus := v_total_helpers * 10;
    
    UPDATE public.user_stats
    SET credits = credits + v_creator_bonus,
        credits_earned = COALESCE(credits_earned, 0) + v_creator_bonus,
        impact_score = impact_score + (v_creator_bonus / 2)
    WHERE user_id = v_request.creator_id;
    
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id)
    VALUES (v_request.creator_id, v_creator_bonus, 'BONUS', p_request_id);
    
    INSERT INTO public.notifications (user_id, title, message)
    VALUES (
      v_request.creator_id,
      'Collaboration Bonus!',
      'You earned ' || v_creator_bonus || ' bonus credits for finishing a request with ' || v_total_helpers || ' helpers!'
    );
  END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Replace dummy emails in community requests with an instruction to use personal contact info.
UPDATE community_starter_requests
SET contact_options = (
  SELECT jsonb_agg(
    CASE 
      WHEN (elem->>'value') LIKE '%@goodwillcircle.local' 
        OR (elem->>'value') LIKE '%@gmail.com' 
        OR (elem->>'value') LIKE 'mailto:%' THEN 
        jsonb_set(elem, '{value}', '"Your registered email and phone number will be used to connect."')
      ELSE elem
    END
  )
  FROM jsonb_array_elements(contact_options) AS elem
)
WHERE community_request = true;
