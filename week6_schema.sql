-- Week 6 Contact, Completion Review, and Campaign Feed Updates

-- Phone numbers are used only to launch the device phone/SMS/video app.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS phone TEXT;

ALTER TABLE public.request_volunteers
  ADD COLUMN IF NOT EXISTS completion_message TEXT;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, photo_url, phone)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.raw_user_meta_data->>'avatar_url',
    new.raw_user_meta_data->>'phone'
  )
  ON CONFLICT (id) DO UPDATE
    SET name = EXCLUDED.name,
        photo_url = EXCLUDED.photo_url,
        phone = EXCLUDED.phone;

  INSERT INTO public.user_stats (user_id, credits, free_requests)
  VALUES (new.id, 50, 1)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TABLE IF NOT EXISTS public.campaign_members (
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (campaign_id, user_id)
);

ALTER TABLE public.campaign_members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Campaign members viewable by everyone." ON public.campaign_members;
DROP POLICY IF EXISTS "Authenticated users can join campaigns." ON public.campaign_members;

CREATE POLICY "Campaign members viewable by everyone."
  ON public.campaign_members
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can join campaigns."
  ON public.campaign_members
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.request_help_completion_review(
  p_request_id UUID,
  p_message TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_request RECORD;
BEGIN
  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  IF v_request.status = 'completed' THEN RAISE EXCEPTION 'Request already completed'; END IF;

  UPDATE public.request_volunteers
  SET status = 'completion_requested',
      completion_message = NULLIF(p_message, '')
  WHERE request_id = p_request_id
    AND volunteer_id = auth.uid()
    AND status IN ('accepted', 'completion_requested');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Only a helper on this request can request completion review';
  END IF;

  INSERT INTO public.notifications (user_id, title, message)
  VALUES (
    v_request.creator_id,
    'Confirm completed help',
    'A helper marked "' || v_request.title || '" complete. ' ||
      COALESCE(NULLIF(p_message, ''), 'Please review and confirm when ready.')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.mark_request_completed(p_request_id UUID)
RETURNS void AS $$
DECLARE
  v_request RECORD;
  v_volunteer RECORD;
BEGIN
  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  IF auth.uid() != v_request.creator_id THEN RAISE EXCEPTION 'Only the creator can complete this request'; END IF;
  IF v_request.status = 'completed' THEN RAISE EXCEPTION 'Request already completed'; END IF;

  UPDATE public.help_requests SET status = 'completed' WHERE id = p_request_id;

  FOR v_volunteer IN
    SELECT volunteer_id, id FROM public.request_volunteers
    WHERE request_id = p_request_id
      AND status IN ('accepted', 'completion_requested')
  LOOP
    UPDATE public.request_volunteers SET status = 'completed' WHERE id = v_volunteer.id;

    UPDATE public.user_stats
    SET credits = credits + v_request.goodwill_reward,
        credits_earned = COALESCE(credits_earned, 0) + v_request.goodwill_reward,
        impact_score = impact_score + v_request.goodwill_reward,
        help_count = help_count + 1,
        reputation_score = COALESCE(reputation_score, 0) + 10
    WHERE user_id = v_volunteer.volunteer_id;

    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id)
    VALUES (v_volunteer.volunteer_id, v_request.goodwill_reward, 'EARN', p_request_id);

    INSERT INTO public.goodwill_chain_links (source_user_id, affected_user_id, source_type, reference_id, impact_value)
    VALUES (v_volunteer.volunteer_id, v_request.creator_id, 'help', p_request_id, v_request.goodwill_reward);

    INSERT INTO public.notifications (user_id, title, message)
    VALUES (
      v_volunteer.volunteer_id,
      'Help Completed!',
      'You earned ' || v_request.goodwill_reward || ' credits for helping with "' || v_request.title || '"'
    );

    PERFORM public.check_and_award_badges(v_volunteer.volunteer_id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
