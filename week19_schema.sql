-- week19_schema.sql
-- Connection Hub duplication & completed requests lingering fix migration.

-- 1. Update complete_connection function to set request status to completed if creator is the only helpie
CREATE OR REPLACE FUNCTION public.complete_connection(
  p_entity_id UUID,
  p_entity_type TEXT,
  p_participant_id UUID,
  p_completion_message TEXT
)
RETURNS TEXT
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

    -- If creator is the only helpie, set request status to completed
    IF (SELECT helpie_count FROM public.help_requests WHERE id = p_entity_id) <= 1 THEN
      UPDATE public.help_requests SET status = 'completed' WHERE id = p_entity_id;
    END IF;
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
$complete_connection$
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.complete_connection(UUID, TEXT, UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_connection(UUID, TEXT, UUID, TEXT) TO authenticated;


-- 2. Update confirm_and_like_helper to set request status to completed if creator is the only helpie
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
      
      -- If creator is the only helpie, set request status to completed
      IF (SELECT helpie_count FROM public.help_requests WHERE id = p_request_id) <= 1 THEN
        UPDATE public.help_requests SET status = 'completed' WHERE id = p_request_id;
      END IF;
    END IF;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.confirm_and_like_helper(UUID, UUID, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.confirm_and_like_helper(UUID, UUID, BOOLEAN) TO authenticated;


-- 3. Update get_entity_contacts to filter out the request creator from volunteers branch
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
        FROM public.request_volunteers rv 
        JOIN auth.users u ON rv.volunteer_id = u.id 
        LEFT JOIN public.profiles p ON u.id = p.id 
        WHERE rv.request_id = p_entity_id 
          AND rv.volunteer_id <> (SELECT creator_id FROM public.help_requests WHERE id = p_entity_id)
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

REVOKE ALL ON FUNCTION public.get_entity_contacts(UUID, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_entity_contacts(UUID, TEXT, TEXT) TO authenticated;
