-- Week 4 Database Schema Updates

DROP TABLE IF EXISTS public.campaign_updates CASCADE;
DROP TABLE IF EXISTS public.campaign_donations CASCADE;
DROP TABLE IF EXISTS public.campaign_members CASCADE;
DROP TABLE IF EXISTS public.campaigns CASCADE;
-- 1. Campaigns Table
CREATE TABLE public.campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    goal_amount INTEGER NOT NULL CHECK (goal_amount > 0),
    current_amount INTEGER DEFAULT 0,
    supporters_count INTEGER DEFAULT 0,
    status TEXT DEFAULT 'active' CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Campaign Donations Table
CREATE TABLE public.campaign_donations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
    donor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount INTEGER NOT NULL CHECK (amount > 0),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. Campaign Updates Table
CREATE TABLE public.campaign_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. Enable RLS
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_updates ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Campaigns viewable by everyone." ON public.campaigns FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create campaigns." ON public.campaigns FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own campaigns." ON public.campaigns FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Campaign donations viewable by everyone." ON public.campaign_donations FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert donations." ON public.campaign_donations FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = donor_id);

CREATE POLICY "Campaign updates viewable by everyone." ON public.campaign_updates FOR SELECT USING (true);
CREATE POLICY "Creators can post updates." ON public.campaign_updates FOR INSERT WITH CHECK (
    auth.role() = 'authenticated' AND 
    auth.uid() = (SELECT creator_id FROM public.campaigns WHERE id = campaign_id)
);

-- 6. Secure RPC for Donating Goodwill Credits to Campaign
CREATE OR REPLACE FUNCTION public.donate_to_campaign(p_campaign_id UUID, p_amount INTEGER)
RETURNS void AS $$
DECLARE
    v_campaign RECORD;
    v_user_stats RECORD;
    v_is_new_supporter BOOLEAN;
BEGIN
    -- Validate amount
    IF p_amount <= 0 THEN
        RAISE EXCEPTION 'Donation amount must be greater than 0';
    END IF;

    -- Get campaign
    SELECT * INTO v_campaign FROM public.campaigns WHERE id = p_campaign_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Campaign not found'; END IF;
    
    IF v_campaign.status != 'active' THEN
        RAISE EXCEPTION 'Campaign is not active';
    END IF;

    -- Get user stats
    SELECT * INTO v_user_stats FROM public.user_stats WHERE user_id = auth.uid();
    
    -- Check if user has enough credits
    IF v_user_stats.credits < p_amount THEN
        RAISE EXCEPTION 'Insufficient Goodwill Credits';
    END IF;

    -- Check if user has donated before to this campaign (for supporter count)
    SELECT NOT EXISTS (
        SELECT 1 FROM public.campaign_donations 
        WHERE campaign_id = p_campaign_id AND donor_id = auth.uid()
    ) INTO v_is_new_supporter;

    -- 1. Deduct credits from donor
    UPDATE public.user_stats SET credits = credits - p_amount WHERE user_id = auth.uid();

    -- 2. Log credit transaction
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (auth.uid(), -p_amount, 'campaign_donation', p_campaign_id);

    -- 3. Log campaign donation
    INSERT INTO public.campaign_donations (campaign_id, donor_id, amount) 
    VALUES (p_campaign_id, auth.uid(), p_amount);

    -- 4. Update campaign totals
    IF v_is_new_supporter THEN
        UPDATE public.campaigns 
        SET current_amount = current_amount + p_amount,
            supporters_count = supporters_count + 1
        WHERE id = p_campaign_id;
    ELSE
        UPDATE public.campaigns 
        SET current_amount = current_amount + p_amount
        WHERE id = p_campaign_id;
    END IF;

    -- 5. Auto-complete campaign if goal reached
    IF (v_campaign.current_amount + p_amount) >= v_campaign.goal_amount THEN
        UPDATE public.campaigns SET status = 'completed' WHERE id = p_campaign_id;
        
        -- Insert an automatic update
        INSERT INTO public.campaign_updates (campaign_id, message)
        VALUES (p_campaign_id, '🎉 Campaign goal reached! Thank you to all supporters!');
    END IF;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
