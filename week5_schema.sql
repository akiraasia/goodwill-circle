-- Week 5 Gamification & Social Impact Schema Updates

-- ==============================================================================
-- 1. Phase A & D: Analytics Dashboard & Reputation
-- ==============================================================================

-- Add new tracking columns to user_stats
ALTER TABLE public.user_stats 
  ADD COLUMN IF NOT EXISTS credits_earned INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS credits_donated INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS campaigns_supported INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS reputation_score INTEGER DEFAULT 0;

-- ==============================================================================
-- 2. Phase C: Badges System
-- ==============================================================================

DROP TABLE IF EXISTS public.user_badges CASCADE;
DROP TABLE IF EXISTS public.badges CASCADE;

CREATE TABLE public.badges (
  id TEXT PRIMARY KEY, -- e.g., 'first_help', 'campaign_creator'
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT NOT NULL,
  condition_type TEXT NOT NULL, -- e.g., 'help_count', 'credits_donated'
  condition_value INTEGER NOT NULL
);

CREATE TABLE public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id TEXT REFERENCES public.badges(id) ON DELETE CASCADE,
  awarded_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, badge_id)
);

ALTER TABLE public.badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_badges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Badges are viewable by everyone" ON public.badges FOR SELECT USING (true);
CREATE POLICY "User badges are viewable by everyone" ON public.user_badges FOR SELECT USING (true);

-- Insert initial badges
INSERT INTO public.badges (id, name, description, icon_name, condition_type, condition_value) VALUES
('first_help', 'First Help', 'Completed your first help request.', '🏅', 'help_count', 1),
('10_helps', 'Helping Hand', 'Completed 10 help requests.', '🤝', 'help_count', 10),
('first_donation', 'First Donation', 'Donated to a campaign for the first time.', '💖', 'credits_donated', 1),
('100_donated', 'Generous Spirit', 'Donated 100 Goodwill credits.', '💎', 'credits_donated', 100),
('campaign_creator', 'Campaign Creator', 'Created your first campaign.', '📣', 'campaign_count', 1)
ON CONFLICT (id) DO NOTHING;

-- RPC to check and award badges
CREATE OR REPLACE FUNCTION public.check_and_award_badges(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_stats RECORD;
  v_badge RECORD;
BEGIN
  SELECT * INTO v_stats FROM public.user_stats WHERE user_id = p_user_id;
  
  FOR v_badge IN SELECT * FROM public.badges LOOP
    -- Check conditions based on condition_type
    IF (v_badge.condition_type = 'help_count' AND v_stats.help_count >= v_badge.condition_value) OR
       (v_badge.condition_type = 'credits_donated' AND v_stats.credits_donated >= v_badge.condition_value) OR
       (v_badge.condition_type = 'campaign_count' AND v_stats.campaign_count >= v_badge.condition_value) OR
       (v_badge.condition_type = 'campaigns_supported' AND v_stats.campaigns_supported >= v_badge.condition_value) THEN
       
       -- Insert if not already awarded
       INSERT INTO public.user_badges (user_id, badge_id)
       VALUES (p_user_id, v_badge.id)
       ON CONFLICT DO NOTHING;
       
       -- Add a small reputation bump for a new badge (+5)
       IF FOUND THEN
          UPDATE public.user_stats SET reputation_score = reputation_score + 5 WHERE user_id = p_user_id;
       END IF;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- 3. Phase E: Goodwill Chains
-- ==============================================================================

DROP TABLE IF EXISTS public.goodwill_chain_links CASCADE;

CREATE TABLE public.goodwill_chain_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  source_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  affected_user_id UUID, -- Can be NULL if affected is a campaign
  affected_campaign_id UUID, -- Can be NULL if affected is a user
  source_type TEXT NOT NULL, -- 'help', 'donation'
  reference_id UUID,
  impact_value INTEGER,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.goodwill_chain_links ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Chain links are viewable by everyone" ON public.goodwill_chain_links FOR SELECT USING (true);


-- RPC to get flat metrics for the chain MVP
CREATE OR REPLACE FUNCTION public.get_user_goodwill_chain(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  v_people_helped INTEGER;
  v_campaigns_influenced INTEGER;
  v_credits_propagated INTEGER;
  v_result JSON;
BEGIN
  -- 1. People helped directly by the user
  SELECT COUNT(DISTINCT affected_user_id) INTO v_people_helped
  FROM public.goodwill_chain_links
  WHERE source_user_id = p_user_id AND source_type = 'help';
  
  -- 2. Campaigns supported by those people (Influence)
  SELECT COUNT(DISTINCT affected_campaign_id) INTO v_campaigns_influenced
  FROM public.goodwill_chain_links
  WHERE source_type = 'donation' 
    AND source_user_id IN (
      SELECT affected_user_id FROM public.goodwill_chain_links WHERE source_user_id = p_user_id AND source_type = 'help'
    );
    
  -- 3. Credits propagated (donated by people you helped)
  SELECT COALESCE(SUM(impact_value), 0) INTO v_credits_propagated
  FROM public.goodwill_chain_links
  WHERE source_type = 'donation' 
    AND source_user_id IN (
      SELECT affected_user_id FROM public.goodwill_chain_links WHERE source_user_id = p_user_id AND source_type = 'help'
    );

  v_result := json_build_object(
    'people_helped', v_people_helped,
    'campaigns_influenced', v_campaigns_influenced,
    'credits_propagated', v_credits_propagated
  );
  
  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==============================================================================
-- 4. Updating Existing RPCs to tie it all together
-- ==============================================================================

-- A. Update `mark_request_completed` to include Analytics, Reputation, Chains, and Badges
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
    WHERE request_id = p_request_id AND status = 'accepted'
  LOOP
    UPDATE public.request_volunteers SET status = 'completed' WHERE id = v_volunteer.id;

    -- Analytics & Reputation (+10 reputation for helping)
    UPDATE public.user_stats 
    SET credits = credits + v_request.goodwill_reward,
        credits_earned = credits_earned + v_request.goodwill_reward,
        impact_score = impact_score + v_request.goodwill_reward,
        help_count = help_count + 1,
        reputation_score = reputation_score + 10
    WHERE user_id = v_volunteer.volunteer_id;

    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (v_volunteer.volunteer_id, v_request.goodwill_reward, 'EARN', p_request_id);

    -- Goodwill Chain Link (Volunteer helped Creator)
    INSERT INTO public.goodwill_chain_links (source_user_id, affected_user_id, source_type, reference_id, impact_value)
    VALUES (v_volunteer.volunteer_id, v_request.creator_id, 'help', p_request_id, v_request.goodwill_reward);

    -- Check badges for volunteer
    PERFORM public.check_and_award_badges(v_volunteer.volunteer_id);
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- B. Update `donate_to_campaign` to include Analytics, Chains, and Badges
CREATE OR REPLACE FUNCTION public.donate_to_campaign(p_campaign_id UUID, p_amount INTEGER)
RETURNS void AS $$
DECLARE
    v_campaign RECORD;
    v_user_stats RECORD;
    v_is_new_supporter BOOLEAN;
BEGIN
    IF p_amount <= 0 THEN RAISE EXCEPTION 'Donation amount must be greater than 0'; END IF;

    SELECT * INTO v_campaign FROM public.campaigns WHERE id = p_campaign_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Campaign not found'; END IF;
    IF v_campaign.status != 'active' THEN RAISE EXCEPTION 'Campaign is not active'; END IF;

    SELECT * INTO v_user_stats FROM public.user_stats WHERE user_id = auth.uid();
    IF v_user_stats.credits < p_amount THEN RAISE EXCEPTION 'Insufficient Goodwill Credits'; END IF;

    SELECT NOT EXISTS (
        SELECT 1 FROM public.campaign_donations WHERE campaign_id = p_campaign_id AND donor_id = auth.uid()
    ) INTO v_is_new_supporter;

    -- Analytics Updates for Donor
    UPDATE public.user_stats 
    SET credits = credits - p_amount,
        credits_donated = credits_donated + p_amount,
        campaigns_supported = CASE WHEN v_is_new_supporter THEN campaigns_supported + 1 ELSE campaigns_supported END
    WHERE user_id = auth.uid();

    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (auth.uid(), -p_amount, 'campaign_donation', p_campaign_id);

    INSERT INTO public.campaign_donations (campaign_id, donor_id, amount) 
    VALUES (p_campaign_id, auth.uid(), p_amount);
    
    -- Goodwill Chain Link (Donor -> Campaign)
    INSERT INTO public.goodwill_chain_links (source_user_id, affected_campaign_id, source_type, reference_id, impact_value)
    VALUES (auth.uid(), p_campaign_id, 'donation', p_campaign_id, p_amount);

    IF v_is_new_supporter THEN
        UPDATE public.campaigns 
        SET current_amount = current_amount + p_amount, supporters_count = supporters_count + 1
        WHERE id = p_campaign_id;
    ELSE
        UPDATE public.campaigns SET current_amount = current_amount + p_amount WHERE id = p_campaign_id;
    END IF;

    IF (v_campaign.current_amount + p_amount) >= v_campaign.goal_amount THEN
        UPDATE public.campaigns SET status = 'completed' WHERE id = p_campaign_id;
        
        -- Reputation for Creator: Campaign Fully Funded (+30)
        UPDATE public.user_stats SET reputation_score = reputation_score + 30 WHERE user_id = v_campaign.creator_id;
        -- Check badges for creator
        PERFORM public.check_and_award_badges(v_campaign.creator_id);
    END IF;

    -- Check badges for donor
    PERFORM public.check_and_award_badges(auth.uid());
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- C. Trigger for Campaign Creation Reputation
CREATE OR REPLACE FUNCTION public.handle_campaign_creation()
RETURNS trigger AS $$
BEGIN
  -- Reputation for Campaign Created (+20) and increment campaign_count
  UPDATE public.user_stats 
  SET reputation_score = reputation_score + 20,
      campaign_count = campaign_count + 1
  WHERE user_id = NEW.creator_id;
  
  -- Check badges
  PERFORM public.check_and_award_badges(NEW.creator_id);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_campaign_created ON public.campaigns;
CREATE TRIGGER on_campaign_created
  AFTER INSERT ON public.campaigns
  FOR EACH ROW EXECUTE PROCEDURE public.handle_campaign_creation();
