-- week16_schema.sql
-- 1. Add connection tracking columns to parent entities
ALTER TABLE public.help_requests ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;
ALTER TABLE public.campaigns ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;
ALTER TABLE public.nonprofit_agenda_items ADD COLUMN IF NOT EXISTS completed_connections_count INTEGER DEFAULT 0;

-- 2. Add completion_message to join tables
ALTER TABLE public.request_volunteers ADD COLUMN IF NOT EXISTS completion_message TEXT;
ALTER TABLE public.campaign_members ADD COLUMN IF NOT EXISTS completion_message TEXT;
ALTER TABLE public.agenda_participants ADD COLUMN IF NOT EXISTS completion_message TEXT;

-- 3. Create a comprehensive RPC for completing connections and retrieving emails
CREATE OR REPLACE FUNCTION public.complete_connection(
  p_entity_id UUID,
  p_entity_type TEXT, -- 'request', 'campaign', 'agenda'
  p_participant_id UUID,
  p_completion_message TEXT
)
RETURNS TEXT AS $$
DECLARE
  v_creator_id UUID;
  v_participant_email TEXT;
  v_actual_reward INTEGER := 10; -- Base reward
  v_title TEXT;
BEGIN
  -- 1. Verify entity ownership and get details
  IF p_entity_type = 'request' THEN
    SELECT creator_id, title, COALESCE(goodwill_reward, 10) INTO v_creator_id, v_title, v_actual_reward 
    FROM public.help_requests WHERE id = p_entity_id;
  ELSIF p_entity_type = 'campaign' THEN
    SELECT organizer_id, title INTO v_creator_id, v_title 
    FROM public.campaigns WHERE id = p_entity_id;
  ELSIF p_entity_type = 'agenda' THEN
    SELECT creator_id, title INTO v_creator_id, v_title 
    FROM public.nonprofit_agenda_items WHERE id = p_entity_id;
  ELSE
    RAISE EXCEPTION 'Invalid entity type';
  END IF;

  IF auth.uid() != v_creator_id THEN 
    RAISE EXCEPTION 'Only the creator can complete a connection'; 
  END IF;

  -- 2. Mark participant as completed and increment connection count
  IF p_entity_type = 'request' THEN
    UPDATE public.request_volunteers 
    SET status = 'completed', completion_message = p_completion_message 
    WHERE request_id = p_entity_id AND volunteer_id = p_participant_id;
    
    UPDATE public.help_requests SET completed_connections_count = completed_connections_count + 1 WHERE id = p_entity_id;
  
  ELSIF p_entity_type = 'campaign' THEN
    UPDATE public.campaign_members 
    SET status = 'completed', completion_message = p_completion_message 
    WHERE campaign_id = p_entity_id AND user_id = p_participant_id;
    
    UPDATE public.campaigns SET completed_connections_count = completed_connections_count + 1 WHERE id = p_entity_id;
    v_actual_reward := 15; -- Campaign completion reward

  ELSIF p_entity_type = 'agenda' THEN
    UPDATE public.agenda_participants 
    SET status = 'completed', completion_message = p_completion_message 
    WHERE agenda_id = p_entity_id AND user_id = p_participant_id;
    
    UPDATE public.nonprofit_agenda_items SET completed_connections_count = completed_connections_count + 1 WHERE id = p_entity_id;
    v_actual_reward := 20; -- Agenda completion reward
  END IF;

  -- 3. Award credits to the participant
  UPDATE public.user_stats
  SET credits = credits + v_actual_reward,
      credits_earned = COALESCE(credits_earned, 0) + v_actual_reward,
      impact_score = impact_score + v_actual_reward,
      help_count = help_count + 1,
      reputation_score = COALESCE(reputation_score, 0) + 10
  WHERE user_id = p_participant_id;

  INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id)
  VALUES (p_participant_id, v_actual_reward, 'EARN', p_entity_id);

  INSERT INTO public.goodwill_chain_links (source_user_id, affected_user_id, source_type, reference_id, impact_value)
  VALUES (p_participant_id, v_creator_id, p_entity_type, p_entity_id, v_actual_reward);

  -- 4. Send Notification
  INSERT INTO public.notifications (user_id, title, message)
  VALUES (
    p_participant_id,
    'Connection Completed: ' || v_title,
    'You earned ' || v_actual_reward || ' credits. Message from creator: ' || COALESCE(p_completion_message, 'Thank you!')
  );

  -- 5. Award badges
  PERFORM public.check_and_award_badges(p_participant_id);

  -- 6. Retrieve and return the participant's email (Needs to join auth.users)
  SELECT email INTO v_participant_email FROM auth.users WHERE id = p_participant_id;
  
  RETURN v_participant_email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
