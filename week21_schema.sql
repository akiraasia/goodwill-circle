-- week21_schema.sql
-- Campaign/Agenda Credit Transfers and Agenda Photo Upload

-- 1. Add image_url to nonprofit_agenda_items
ALTER TABLE public.nonprofit_agenda_items
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. Drop the old 3-parameter function
DROP FUNCTION IF EXISTS public.confirm_and_like_helper(UUID, UUID, BOOLEAN);

-- 3. Create the new 4-parameter function
CREATE OR REPLACE FUNCTION public.confirm_and_like_helper(
  p_entity_id UUID, p_entity_type TEXT, p_helper_id UUID, p_liked BOOLEAN
) RETURNS void AS $$
DECLARE
  v_helpie_id UUID := auth.uid();
  v_is_starter BOOLEAN := false;
  v_actual_reward INTEGER := 10;
  v_title TEXT;
  v_helpie_credits INTEGER;
  v_campaign_funds INTEGER;
  v_creator_id UUID;
BEGIN
  IF v_helpie_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  IF p_entity_type = 'request' THEN
    SELECT EXISTS(SELECT 1 FROM public.community_starter_requests WHERE id = p_entity_id) INTO v_is_starter;
    
    IF v_is_starter THEN
      IF NOT EXISTS (SELECT 1 FROM public.community_starter_request_joins WHERE request_id = p_entity_id AND user_id = v_helpie_id AND join_role = 'helpee') THEN
        RAISE EXCEPTION 'Only joined helpies can confirm helpers';
      END IF;
      
      SELECT COALESCE(tag_credit_bonus, 10), title
      INTO v_actual_reward, v_title
      FROM public.community_starter_requests
      WHERE id = p_entity_id;
    ELSE
      IF NOT EXISTS (SELECT 1 FROM public.help_requests WHERE id = p_entity_id AND creator_id = v_helpie_id) AND NOT EXISTS (SELECT 1 FROM public.request_volunteers WHERE request_id = p_entity_id AND volunteer_id = v_helpie_id AND join_role = 'helpee') THEN
        RAISE EXCEPTION 'Only joined helpies or the creator can confirm helpers';
      END IF;
      
      SELECT COALESCE(goodwill_reward, 10), title
      INTO v_actual_reward, v_title
      FROM public.help_requests
      WHERE id = p_entity_id;
      
      SELECT credits INTO v_helpie_credits FROM public.user_stats WHERE user_id = v_helpie_id;
      IF v_helpie_credits < v_actual_reward THEN
        RAISE EXCEPTION 'Insufficient credits to confirm helper';
      END IF;
    END IF;

  ELSIF p_entity_type = 'campaign' THEN
    SELECT creator_id, title, COALESCE(current_amount, 0)
    INTO v_creator_id, v_title, v_campaign_funds
    FROM public.campaigns
    WHERE id = p_entity_id;

    IF v_creator_id IS NULL THEN RAISE EXCEPTION 'Campaign not found'; END IF;
    IF v_helpie_id != v_creator_id THEN RAISE EXCEPTION 'Only the campaign creator can confirm helpers'; END IF;

    v_actual_reward := 15;
    
    IF v_campaign_funds < v_actual_reward THEN
      RAISE EXCEPTION 'Insufficient campaign funds to confirm helper. Wait for more donations.';
    END IF;

  ELSIF p_entity_type = 'agenda' THEN
    SELECT ngo_id, title
    INTO v_creator_id, v_title
    FROM public.nonprofit_agenda_items
    WHERE id = p_entity_id;

    IF v_creator_id IS NULL THEN RAISE EXCEPTION 'Agenda not found'; END IF;
    IF v_helpie_id != v_creator_id THEN RAISE EXCEPTION 'Only the NGO can confirm helpers'; END IF;

    v_actual_reward := 20;

    SELECT credits INTO v_helpie_credits FROM public.user_stats WHERE user_id = v_helpie_id;
    IF v_helpie_credits < v_actual_reward THEN
      RAISE EXCEPTION 'Insufficient NGO credits to confirm helper';
    END IF;

  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;

  IF EXISTS (SELECT 1 FROM public.connection_confirmations WHERE request_id = p_entity_id AND helper_id = p_helper_id AND helpie_id = v_helpie_id) THEN
    UPDATE public.connection_confirmations SET liked = p_liked WHERE request_id = p_entity_id AND helper_id = p_helper_id AND helpie_id = v_helpie_id;
  ELSE
    -- 1. Insert confirmation record (we reuse request_id column for entity_id)
    INSERT INTO public.connection_confirmations (request_id, helper_id, helpie_id, liked) VALUES (p_entity_id, p_helper_id, v_helpie_id, p_liked);
    
    -- 2. Deduct credits
    IF p_entity_type = 'request' AND NOT v_is_starter THEN
      UPDATE public.user_stats SET credits = credits - v_actual_reward WHERE user_id = v_helpie_id;
      INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) VALUES (v_helpie_id, -v_actual_reward, 'SPEND', p_entity_id);
    ELSIF p_entity_type = 'campaign' THEN
      UPDATE public.campaigns SET current_amount = GREATEST(0, current_amount - v_actual_reward) WHERE id = p_entity_id;
    ELSIF p_entity_type = 'agenda' THEN
      UPDATE public.user_stats SET credits = credits - v_actual_reward WHERE user_id = v_helpie_id;
      INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) VALUES (v_helpie_id, -v_actual_reward, 'SPEND', p_entity_id);
    END IF;
    
    -- 3. Add credits to helper
    UPDATE public.user_stats 
    SET credits = credits + v_actual_reward, 
        credits_earned = COALESCE(credits_earned, 0) + v_actual_reward, 
        impact_score = impact_score + v_actual_reward,
        help_count = COALESCE(help_count, 0) + 1,
        reputation_score = COALESCE(reputation_score, 0) + 10
    WHERE user_id = p_helper_id;
    
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (p_helper_id, v_actual_reward, 'EARN', p_entity_id);
    
    -- 4. Create Goodwill Chain Link
    INSERT INTO public.goodwill_chain_links (
      source_user_id,
      affected_user_id,
      source_type,
      reference_id,
      impact_value
    )
    VALUES (p_helper_id, v_helpie_id, p_entity_type, p_entity_id, v_actual_reward);
    
    -- 5. Trigger Badge System for helper
    PERFORM public.check_and_award_badges(p_helper_id);
    
    -- 6. Send Notification to Helper
    INSERT INTO public.notifications (user_id, title, message)
    VALUES (
      p_helper_id,
      'Connection Confirmed: ' || COALESCE(v_title, 'Help Request'),
      'You earned ' || v_actual_reward || ' credits for your help!'
    );
    
    -- 7. Update helper status to completed
    IF p_entity_type = 'request' THEN
      IF v_is_starter THEN
        UPDATE public.community_starter_request_joins SET status = 'completed' WHERE request_id = p_entity_id AND user_id = p_helper_id;
      ELSE
        UPDATE public.request_volunteers SET status = 'completed' WHERE request_id = p_entity_id AND volunteer_id = p_helper_id;
        IF (SELECT helpie_count FROM public.help_requests WHERE id = p_entity_id) <= 1 THEN
          UPDATE public.help_requests SET status = 'completed' WHERE id = p_entity_id;
        END IF;
      END IF;
    ELSIF p_entity_type = 'campaign' THEN
      UPDATE public.campaign_members SET status = 'completed' WHERE campaign_id = p_entity_id AND user_id = p_helper_id;
    ELSIF p_entity_type = 'agenda' THEN
      UPDATE public.agenda_participants SET status = 'completed' WHERE agenda_item_id = p_entity_id AND volunteer_id = p_helper_id;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.confirm_and_like_helper(UUID, TEXT, UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_and_like_helper(UUID, TEXT, UUID, BOOLEAN) TO authenticated;
