-- week16_schema.sql

-- 1. Add helper/helpie counts and support metrics to parent entities
ALTER TABLE public.help_requests 
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS support_count INTEGER DEFAULT 0;

ALTER TABLE public.campaigns 
  ADD COLUMN IF NOT EXISTS helper_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS support_count INTEGER DEFAULT 0;

ALTER TABLE public.nonprofit_agenda_items 
  ADD COLUMN IF NOT EXISTS helper_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS helpie_count INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS support_count INTEGER DEFAULT 0;

-- 2. Add join_role to campaign_members and agenda_participants
ALTER TABLE public.campaign_members 
  ADD COLUMN IF NOT EXISTS join_role TEXT DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'accepted';

ALTER TABLE public.agenda_participants 
  ADD COLUMN IF NOT EXISTS join_role TEXT DEFAULT 'helper',
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'accepted';

-- 3. Create generic entity_supports table
CREATE TABLE IF NOT EXISTS public.entity_supports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  entity_id UUID NOT NULL,
  entity_type TEXT NOT NULL CHECK (entity_type IN ('request', 'campaign', 'agenda')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, entity_id, entity_type)
);

ALTER TABLE public.entity_supports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Supports viewable by everyone." ON public.entity_supports FOR SELECT USING (true);
CREATE POLICY "Users can insert own support." ON public.entity_supports FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own support." ON public.entity_supports FOR DELETE USING (auth.uid() = user_id);

-- 4. RPC for toggling support
CREATE OR REPLACE FUNCTION public.toggle_support(
  p_entity_id UUID,
  p_entity_type TEXT
)
RETURNS INTEGER AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_exists BOOLEAN;
  v_new_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  
  SELECT EXISTS (
    SELECT 1 FROM public.entity_supports 
    WHERE user_id = v_user_id AND entity_id = p_entity_id AND entity_type = p_entity_type
  ) INTO v_exists;

  IF v_exists THEN
    DELETE FROM public.entity_supports 
    WHERE user_id = v_user_id AND entity_id = p_entity_id AND entity_type = p_entity_type;
    
    IF p_entity_type = 'request' THEN
      UPDATE public.help_requests SET support_count = GREATEST(0, support_count - 1) WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    ELSIF p_entity_type = 'campaign' THEN
      UPDATE public.campaigns SET support_count = GREATEST(0, support_count - 1) WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    ELSIF p_entity_type = 'agenda' THEN
      UPDATE public.nonprofit_agenda_items SET support_count = GREATEST(0, support_count - 1) WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    END IF;
  ELSE
    INSERT INTO public.entity_supports (user_id, entity_id, entity_type) 
    VALUES (v_user_id, p_entity_id, p_entity_type);
    
    IF p_entity_type = 'request' THEN
      UPDATE public.help_requests SET support_count = support_count + 1 WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    ELSIF p_entity_type = 'campaign' THEN
      UPDATE public.campaigns SET support_count = support_count + 1 WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    ELSIF p_entity_type = 'agenda' THEN
      UPDATE public.nonprofit_agenda_items SET support_count = support_count + 1 WHERE id = p_entity_id RETURNING support_count INTO v_new_count;
    END IF;
  END IF;

  RETURN v_new_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC for fetching opposing contacts
CREATE OR REPLACE FUNCTION public.get_entity_contacts(
  p_entity_id UUID,
  p_entity_type TEXT,
  p_my_role TEXT
)
RETURNS TABLE (
  participant_id UUID,
  name TEXT,
  email TEXT,
  status TEXT
) AS $$
DECLARE
  v_target_role TEXT;
BEGIN
  IF p_my_role = 'helper' THEN
    v_target_role := 'helpee';
  ELSE
    v_target_role := 'helper';
  END IF;

  IF p_entity_type = 'request' THEN
    RETURN QUERY
    SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), rv.status
    FROM public.request_volunteers rv
    JOIN auth.users u ON rv.volunteer_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE rv.request_id = p_entity_id AND rv.join_role = v_target_role;
  ELSIF p_entity_type = 'campaign' THEN
    RETURN QUERY
    SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), cm.status
    FROM public.campaign_members cm
    JOIN auth.users u ON cm.user_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE cm.campaign_id = p_entity_id AND cm.join_role = v_target_role;
  ELSIF p_entity_type = 'agenda' THEN
    RETURN QUERY
    SELECT u.id, COALESCE(p.name, 'Unknown'), COALESCE(u.email::TEXT, ''), ap.status
    FROM public.agenda_participants ap
    JOIN auth.users u ON ap.user_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE ap.agenda_id = p_entity_id AND ap.join_role = v_target_role;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Update join_nonprofit_agenda_item to accept a role
CREATE OR REPLACE FUNCTION public.join_nonprofit_agenda_item(
  p_agenda_item_id UUID,
  p_role TEXT DEFAULT 'helper'
)
RETURNS void AS $$
DECLARE
  v_agenda RECORD;
BEGIN
  SELECT * INTO v_agenda
  FROM public.nonprofit_agenda_items
  WHERE id = p_agenda_item_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Agenda item not found'; END IF;
  IF v_agenda.status != 'open' THEN RAISE EXCEPTION 'Agenda item is not open'; END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_agenda.ngo_id
      AND account_type = 'ngo'
      AND verification_status = 'verified'
  ) THEN
    RAISE EXCEPTION 'Only verified NGO agenda items can accept volunteers';
  END IF;
  IF v_agenda.ngo_id = auth.uid() THEN RAISE EXCEPTION 'Creator cannot connect as volunteer'; END IF;
  IF v_agenda.seats_filled >= v_agenda.seats_needed THEN RAISE EXCEPTION 'Agenda item is full'; END IF;

  INSERT INTO public.agenda_participants (agenda_item_id, volunteer_id, join_role)
  VALUES (p_agenda_item_id, auth.uid(), p_role)
  ON CONFLICT (agenda_item_id, volunteer_id) DO NOTHING;

  IF FOUND THEN
    UPDATE public.nonprofit_agenda_items
    SET seats_filled = seats_filled + 1
    WHERE id = p_agenda_item_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
