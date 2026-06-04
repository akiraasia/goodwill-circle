-- Week 3 Database Schema Updates

-- Drop previous tables if they exist to avoid conflicts with the new schema
DROP TABLE IF EXISTS public.help_completions CASCADE;
DROP TABLE IF EXISTS public.help_matches CASCADE;
DROP TABLE IF EXISTS public.help_requests CASCADE;
DROP TABLE IF EXISTS public.request_volunteers CASCADE;

-- 1. Create the new help_requests table
CREATE TABLE public.help_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open',
  goodwill_reward INTEGER DEFAULT 0,
  volunteers_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Create the request_volunteers table
CREATE TABLE public.request_volunteers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES public.help_requests(id) ON DELETE CASCADE NOT NULL,
  volunteer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'accepted',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(request_id, volunteer_id) -- Prevent volunteering multiple times
);

-- 3. Enable RLS
ALTER TABLE public.help_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.request_volunteers ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
CREATE POLICY "Requests viewable by everyone." ON public.help_requests FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create requests." ON public.help_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own requests." ON public.help_requests FOR UPDATE USING (auth.uid() = creator_id);

CREATE POLICY "Volunteers are viewable by everyone." ON public.request_volunteers FOR SELECT USING (true);
CREATE POLICY "Authenticated users can volunteer." ON public.request_volunteers FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = volunteer_id);
CREATE POLICY "Volunteers can update their status." ON public.request_volunteers FOR UPDATE USING (auth.uid() = volunteer_id);

-- 5. RPC Function: mark_request_completed
-- This function marks a request as completed, updates the volunteers, and awards credits safely on the backend.
CREATE OR REPLACE FUNCTION public.mark_request_completed(p_request_id UUID)
RETURNS void AS $$
DECLARE
  v_request RECORD;
  v_volunteer RECORD;
BEGIN
  -- Get the request
  SELECT * INTO v_request FROM public.help_requests WHERE id = p_request_id;
  
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  
  -- Ensure only the creator can complete it
  IF auth.uid() != v_request.creator_id THEN
    RAISE EXCEPTION 'Only the creator can complete this request';
  END IF;

  -- Ensure it's not already completed
  IF v_request.status = 'completed' THEN
    RAISE EXCEPTION 'Request already completed';
  END IF;

  -- Update request status
  UPDATE public.help_requests SET status = 'completed' WHERE id = p_request_id;

  -- Loop through all accepted volunteers and award credits
  FOR v_volunteer IN 
    SELECT volunteer_id FROM public.request_volunteers 
    WHERE request_id = p_request_id AND status = 'accepted'
  LOOP
    -- Mark volunteer as completed
    UPDATE public.request_volunteers SET status = 'completed' WHERE id = v_volunteer.id;

    -- Update user stats
    UPDATE public.user_stats 
    SET credits = credits + v_request.goodwill_reward,
        impact_score = impact_score + v_request.goodwill_reward,
        help_count = help_count + 1
    WHERE user_id = v_volunteer.volunteer_id;

    -- Log credit transaction
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (v_volunteer.volunteer_id, v_request.goodwill_reward, 'EARN', p_request_id);

    -- Log Goodwill Action
    INSERT INTO public.goodwill_actions (user_id, action_type, points, reference_id)
    VALUES (v_volunteer.volunteer_id, 'HELP_COMPLETED', v_request.goodwill_reward, p_request_id);
    
    -- Send notification to volunteer
    INSERT INTO public.notifications (user_id, title, message)
    VALUES (v_volunteer.volunteer_id, 'Help Completed!', 'You earned ' || v_request.goodwill_reward || ' credits for helping with "' || v_request.title || '"');
  END LOOP;

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
