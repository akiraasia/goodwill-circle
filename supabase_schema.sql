-- Goodwill Circle Supabase Schema & RLS Policies V1

-- 1. Create Tables
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  name TEXT,
  photo_url TEXT,
  bio TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.user_stats (
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
  credits INTEGER DEFAULT 50 NOT NULL,
  trust_score INTEGER DEFAULT 0 NOT NULL,
  impact_score INTEGER DEFAULT 0 NOT NULL,
  help_count INTEGER DEFAULT 0 NOT NULL,
  campaign_count INTEGER DEFAULT 0 NOT NULL,
  free_requests INTEGER DEFAULT 1 NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.help_requests (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  level INTEGER NOT NULL CHECK (level BETWEEN 1 AND 5),
  is_anonymous BOOLEAN DEFAULT false,
  status TEXT DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'ACCEPTED', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.help_matches (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  request_id UUID REFERENCES public.help_requests(id) ON DELETE CASCADE NOT NULL,
  helper_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'ACTIVE', 'COMPLETED', 'CANCELLED')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(request_id, helper_id)
);

CREATE TABLE public.help_completions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  match_id UUID REFERENCES public.help_matches(id) ON DELETE CASCADE NOT NULL,
  requester_confirmed BOOLEAN DEFAULT false,
  helper_confirmed BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.credit_transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  amount INTEGER NOT NULL,
  transaction_type TEXT NOT NULL, -- 'EARN', 'SPEND', 'BONUS'
  reference_id UUID, -- Can link to request_id or completion_id
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.posts (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  image_url TEXT,
  post_type TEXT NOT NULL, -- 'IMPACT', 'GRATITUDE', 'CAMPAIGN_UPDATE'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.campaigns (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  goal TEXT NOT NULL,
  status TEXT DEFAULT 'ACTIVE',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.campaign_members (
  campaign_id UUID REFERENCES public.campaigns(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY (campaign_id, user_id)
);

CREATE TABLE public.goodwill_actions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  action_type TEXT NOT NULL, -- e.g., 'HELP_COMPLETED', 'CAMPAIGN_JOINED'
  points INTEGER DEFAULT 0,
  reference_id UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE public.notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.help_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.help_matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.help_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.campaign_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goodwill_actions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 3. Basic RLS Policies

-- Profiles: Anyone can read, only owners can update
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- User Stats: Anyone can read, NO ONE can update directly from client (only via triggers/functions)
CREATE POLICY "User stats are viewable by everyone." ON public.user_stats FOR SELECT USING (true);

-- Help Requests: Anyone can read, only auth users can insert, owners can update
CREATE POLICY "Requests viewable by everyone." ON public.help_requests FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create requests." ON public.help_requests FOR INSERT WITH CHECK (auth.role() = 'authenticated');
CREATE POLICY "Users can update own requests." ON public.help_requests FOR UPDATE USING (auth.uid() = requester_id);

-- Help Matches: Helpers and Requesters can see their matches
CREATE POLICY "Users can view their matches." ON public.help_matches FOR SELECT USING (
  auth.uid() IN (helper_id, (SELECT requester_id FROM public.help_requests WHERE id = request_id))
);
CREATE POLICY "Helpers can insert matches." ON public.help_matches FOR INSERT WITH CHECK (auth.uid() = helper_id);

-- Credit Transactions & Goodwill Actions: Only viewable by the user, NO direct inserts/updates from client
CREATE POLICY "Users can view own credit transactions." ON public.credit_transactions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can view own goodwill actions." ON public.goodwill_actions FOR SELECT USING (auth.uid() = user_id);

-- Posts: Anyone can read, only auth users can insert, owners can update
CREATE POLICY "Posts viewable by everyone." ON public.posts FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create posts." ON public.posts FOR INSERT WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = author_id);
CREATE POLICY "Users can update own posts." ON public.posts FOR UPDATE USING (auth.uid() = author_id);

-- 4. Secure Triggers and Functions

-- Trigger for New User Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, photo_url)
  VALUES (new.id, new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');

  INSERT INTO public.user_stats (user_id, credits, free_requests)
  VALUES (new.id, 50, 1);
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Secure Function to complete a help request and transfer credits
-- This is a highly secure function designed to be called by the user confirming completion
CREATE OR REPLACE FUNCTION public.confirm_help_completion(p_match_id UUID)
RETURNS void AS $$
DECLARE
  v_match RECORD;
  v_request RECORD;
  v_requester_stats RECORD;
  v_cost INTEGER;
  v_reward INTEGER;
BEGIN
  -- Get match details
  SELECT * INTO v_match FROM public.help_matches WHERE id = p_match_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Match not found'; END IF;
  
  -- Get request details
  SELECT * INTO v_request FROM public.help_requests WHERE id = v_match.request_id;
  
  -- Ensure the caller is the requester (only requester can confirm completion)
  IF auth.uid() != v_request.requester_id THEN 
    RAISE EXCEPTION 'Only the requester can confirm completion'; 
  END IF;

  -- Ensure not already completed
  IF v_request.status = 'COMPLETED' THEN
    RAISE EXCEPTION 'Request already completed';
  END IF;

  -- Calculate costs and rewards
  v_cost := CASE v_request.level WHEN 1 THEN 5 WHEN 2 THEN 15 WHEN 3 THEN 30 WHEN 4 THEN 60 WHEN 5 THEN 120 ELSE 0 END;
  v_reward := CASE v_request.level WHEN 1 THEN 10 WHEN 2 THEN 25 WHEN 3 THEN 50 WHEN 4 THEN 100 WHEN 5 THEN 250 ELSE 0 END;

  -- Check requester stats (they can use a free request)
  SELECT * INTO v_requester_stats FROM public.user_stats WHERE user_id = v_request.requester_id;
  
  IF v_requester_stats.free_requests > 0 THEN
    -- Use free request
    UPDATE public.user_stats SET free_requests = free_requests - 1 WHERE user_id = v_request.requester_id;
    v_cost := 0; -- No credit cost
  ELSIF v_requester_stats.credits < v_cost THEN
    RAISE EXCEPTION 'Insufficient credits';
  ELSE
    -- Deduct credits from requester
    UPDATE public.user_stats SET credits = credits - v_cost WHERE user_id = v_request.requester_id;
    -- Log deduction
    INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
    VALUES (v_request.requester_id, -v_cost, 'SPEND', v_request.id);
  END IF;

  -- Add credits and stats to helper
  UPDATE public.user_stats 
  SET credits = credits + v_reward, 
      help_count = help_count + 1, 
      impact_score = impact_score + v_reward 
  WHERE user_id = v_match.helper_id;

  -- Log reward
  INSERT INTO public.credit_transactions (user_id, amount, transaction_type, reference_id) 
  VALUES (v_match.helper_id, v_reward, 'EARN', v_request.id);

  -- Log Goodwill Action
  INSERT INTO public.goodwill_actions (user_id, action_type, points, reference_id)
  VALUES (v_match.helper_id, 'HELP_COMPLETED', v_reward, v_request.id);

  -- Update statuses
  UPDATE public.help_requests SET status = 'COMPLETED' WHERE id = v_request.id;
  UPDATE public.help_matches SET status = 'COMPLETED' WHERE id = v_match.id;
  
  -- Create Notifications
  INSERT INTO public.notifications (user_id, title, message)
  VALUES (v_match.helper_id, 'Help Completed!', 'You earned ' || v_reward || ' credits for helping ' || v_request.title);
  
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
