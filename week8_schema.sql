-- Week 8 Nonprofit Agenda, Volunteer Credentials, and NGO-issued Rewards

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS account_type TEXT NOT NULL DEFAULT 'individual'
    CHECK (account_type IN ('individual', 'ngo', 'college', 'admin')),
  ADD COLUMN IF NOT EXISTS organization_name TEXT,
  ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (verification_status IN ('unverified', 'pending', 'verified', 'rejected', 'suspended')),
  ADD COLUMN IF NOT EXISTS verification_note TEXT,
  ADD COLUMN IF NOT EXISTS verification_requested_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS public.app_admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.profile_verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  requested_account_type TEXT NOT NULL
    CHECK (requested_account_type IN ('individual', 'ngo', 'college')),
  organization_name TEXT,
  note TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  review_note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.abuse_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  target_type TEXT NOT NULL
    CHECK (target_type IN ('profile', 'request', 'campaign', 'agenda_item', 'confession', 'comment')),
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'reviewing', 'resolved', 'dismissed')),
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ
);

ALTER TABLE public.profile_verification_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.abuse_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_admins ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins are self-viewable." ON public.app_admins;
DROP POLICY IF EXISTS "Users can view own verification requests." ON public.profile_verification_requests;
DROP POLICY IF EXISTS "Admins can view verification requests." ON public.profile_verification_requests;
DROP POLICY IF EXISTS "Users can view own abuse reports." ON public.abuse_reports;
DROP POLICY IF EXISTS "Authenticated users can report abuse." ON public.abuse_reports;

CREATE POLICY "Admins are self-viewable."
  ON public.app_admins
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can view own verification requests."
  ON public.profile_verification_requests
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Admins can view verification requests."
  ON public.profile_verification_requests
  FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.app_admins WHERE user_id = auth.uid()));

CREATE POLICY "Users can view own abuse reports."
  ON public.abuse_reports
  FOR SELECT
  USING (auth.uid() = reporter_id);

CREATE POLICY "Authenticated users can report abuse."
  ON public.abuse_reports
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;
CREATE POLICY "Users can update own public profile."
  ON public.profiles
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

REVOKE UPDATE ON public.profiles FROM anon, authenticated;
GRANT UPDATE (name, photo_url, bio, phone, account_type, organization_name)
  ON public.profiles TO authenticated;

CREATE OR REPLACE FUNCTION public.is_app_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.app_admins WHERE user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.request_profile_verification(
  p_account_type TEXT,
  p_organization_name TEXT DEFAULT NULL,
  p_note TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_note TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_account_type NOT IN ('individual', 'ngo', 'college') THEN
    RAISE EXCEPTION 'Invalid account type';
  END IF;

  v_note := NULLIF(trim(COALESCE(p_note, '')), '');
  IF v_note IS NULL OR length(v_note) < 12 THEN
    RAISE EXCEPTION 'Verification note is too short';
  END IF;
  IF p_account_type IN ('ngo', 'college') AND NULLIF(trim(COALESCE(p_organization_name, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Organization name is required';
  END IF;

  UPDATE public.profiles
  SET account_type = p_account_type,
      organization_name = NULLIF(trim(COALESCE(p_organization_name, '')), ''),
      verification_status = 'pending',
      verification_note = v_note,
      verification_requested_at = now()
  WHERE id = auth.uid();

  INSERT INTO public.profile_verification_requests (
    user_id,
    requested_account_type,
    organization_name,
    note
  )
  VALUES (
    auth.uid(),
    p_account_type,
    NULLIF(trim(COALESCE(p_organization_name, '')), ''),
    v_note
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.review_profile_verification(
  p_request_id UUID,
  p_approved BOOLEAN,
  p_review_note TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_request RECORD;
BEGIN
  IF NOT public.is_app_admin() THEN RAISE EXCEPTION 'Admin required'; END IF;

  SELECT * INTO v_request
  FROM public.profile_verification_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Verification request not found'; END IF;
  IF v_request.status != 'pending' THEN RAISE EXCEPTION 'Request already reviewed'; END IF;

  UPDATE public.profile_verification_requests
  SET status = CASE WHEN p_approved THEN 'approved' ELSE 'rejected' END,
      reviewed_by = auth.uid(),
      review_note = p_review_note,
      reviewed_at = now()
  WHERE id = p_request_id;

  UPDATE public.profiles
  SET verification_status = CASE WHEN p_approved THEN 'verified' ELSE 'rejected' END,
      account_type = v_request.requested_account_type,
      organization_name = v_request.organization_name,
      verified_by = CASE WHEN p_approved THEN auth.uid() ELSE NULL END,
      verified_at = CASE WHEN p_approved THEN now() ELSE NULL END
  WHERE id = v_request.user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.report_abuse(
  p_target_type TEXT,
  p_target_id UUID,
  p_reason TEXT
)
RETURNS void AS $$
DECLARE
  v_reason TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_target_type NOT IN ('profile', 'request', 'campaign', 'agenda_item', 'confession', 'comment') THEN
    RAISE EXCEPTION 'Invalid report target type';
  END IF;

  v_reason := NULLIF(trim(COALESCE(p_reason, '')), '');
  IF v_reason IS NULL OR length(v_reason) < 8 THEN
    RAISE EXCEPTION 'Report reason is too short';
  END IF;

  INSERT INTO public.abuse_reports (reporter_id, target_type, target_id, reason)
  VALUES (auth.uid(), p_target_type, p_target_id, v_reason);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

INSERT INTO public.badges (id, name, description, icon_name, condition_type, condition_value)
VALUES
  ('mentor', 'Mentor', 'Taught or mentored through a verified nonprofit agenda.', 'school', 'agenda_completed', 1),
  ('community_builder', 'Community Builder', 'Helped build capacity for a nonprofit community.', 'groups', 'agenda_completed', 1),
  ('goodwill_ambassador', 'Goodwill Ambassador', 'Represented Goodwill Circle through verified nonprofit service.', 'workspace_premium', 'agenda_completed', 1)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  icon_name = EXCLUDED.icon_name,
  condition_type = EXCLUDED.condition_type,
  condition_value = EXCLUDED.condition_value;

CREATE TABLE IF NOT EXISTS public.nonprofit_agenda_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ngo_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  ngo_name TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  skill_area TEXT NOT NULL,
  location TEXT NOT NULL,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  seats_needed INTEGER NOT NULL DEFAULT 1 CHECK (seats_needed > 0),
  seats_filled INTEGER NOT NULL DEFAULT 0 CHECK (seats_filled >= 0),
  reward_badge_id TEXT REFERENCES public.badges(id) DEFAULT 'mentor',
  certificate_title TEXT NOT NULL DEFAULT 'Community Mentor',
  certificate_issuer TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('draft', 'open', 'closed', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.campaigns
  ADD COLUMN IF NOT EXISTS verification_status TEXT NOT NULL DEFAULT 'unverified'
    CHECK (verification_status IN ('unverified', 'pending', 'verified', 'rejected')),
  ADD COLUMN IF NOT EXISTS verified_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verified_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.agenda_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agenda_item_id UUID REFERENCES public.nonprofit_agenda_items(id) ON DELETE CASCADE NOT NULL,
  volunteer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'connected' CHECK (status IN ('connected', 'accepted', 'completion_requested', 'completed', 'declined')),
  reflection TEXT,
  certificate_url TEXT,
  connected_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  UNIQUE (agenda_item_id, volunteer_id)
);

CREATE TABLE IF NOT EXISTS public.volunteer_certificates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agenda_item_id UUID REFERENCES public.nonprofit_agenda_items(id) ON DELETE CASCADE NOT NULL,
  volunteer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  issuer_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  issuer_name TEXT NOT NULL,
  title TEXT NOT NULL,
  badge_id TEXT REFERENCES public.badges(id),
  certificate_url TEXT,
  issued_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (agenda_item_id, volunteer_id)
);

ALTER TABLE public.nonprofit_agenda_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.agenda_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteer_certificates ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Nonprofit agenda is viewable." ON public.nonprofit_agenda_items;
DROP POLICY IF EXISTS "Authenticated users can create nonprofit agenda." ON public.nonprofit_agenda_items;
DROP POLICY IF EXISTS "Verified NGOs can create nonprofit agenda." ON public.nonprofit_agenda_items;
DROP POLICY IF EXISTS "NGOs can update own agenda." ON public.nonprofit_agenda_items;
DROP POLICY IF EXISTS "Agenda participants are relevantly viewable." ON public.agenda_participants;
DROP POLICY IF EXISTS "Volunteers can connect to agenda." ON public.agenda_participants;
DROP POLICY IF EXISTS "Certificates are viewable." ON public.volunteer_certificates;

CREATE POLICY "Nonprofit agenda is viewable."
  ON public.nonprofit_agenda_items
  FOR SELECT
  USING (true);

CREATE POLICY "Verified NGOs can create nonprofit agenda."
  ON public.nonprofit_agenda_items
  FOR INSERT
  WITH CHECK (
    auth.role() = 'authenticated'
    AND auth.uid() = ngo_id
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid()
        AND account_type = 'ngo'
        AND verification_status = 'verified'
    )
  );

CREATE POLICY "NGOs can update own agenda."
  ON public.nonprofit_agenda_items
  FOR UPDATE
  USING (auth.uid() = ngo_id)
  WITH CHECK (auth.uid() = ngo_id);

CREATE POLICY "Agenda participants are relevantly viewable."
  ON public.agenda_participants
  FOR SELECT
  USING (
    auth.uid() = volunteer_id
    OR auth.uid() = (
      SELECT ngo_id
      FROM public.nonprofit_agenda_items
      WHERE id = agenda_item_id
    )
  );

CREATE POLICY "Volunteers can connect to agenda."
  ON public.agenda_participants
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated' AND auth.uid() = volunteer_id);

CREATE POLICY "Certificates are viewable."
  ON public.volunteer_certificates
  FOR SELECT
  USING (
    auth.uid() = volunteer_id
    OR auth.uid() = issuer_user_id
  );

CREATE OR REPLACE FUNCTION public.join_nonprofit_agenda_item(p_agenda_item_id UUID)
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

  INSERT INTO public.agenda_participants (agenda_item_id, volunteer_id)
  VALUES (p_agenda_item_id, auth.uid())
  ON CONFLICT (agenda_item_id, volunteer_id) DO NOTHING;

  IF FOUND THEN
    UPDATE public.nonprofit_agenda_items
    SET seats_filled = seats_filled + 1
    WHERE id = p_agenda_item_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.complete_nonprofit_agenda_participant(
  p_participant_id UUID,
  p_certificate_url TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_participant RECORD;
  v_agenda RECORD;
BEGIN
  SELECT * INTO v_participant
  FROM public.agenda_participants
  WHERE id = p_participant_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Participant not found'; END IF;

  SELECT * INTO v_agenda
  FROM public.nonprofit_agenda_items
  WHERE id = v_participant.agenda_item_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Agenda item not found'; END IF;
  IF auth.uid() != v_agenda.ngo_id THEN RAISE EXCEPTION 'Only the NGO can complete this participant'; END IF;
  IF v_participant.status = 'completed' THEN RAISE EXCEPTION 'Participant already completed'; END IF;

  UPDATE public.agenda_participants
  SET status = 'completed',
      certificate_url = p_certificate_url,
      completed_at = now()
  WHERE id = p_participant_id;

  INSERT INTO public.user_badges (user_id, badge_id)
  VALUES (v_participant.volunteer_id, v_agenda.reward_badge_id)
  ON CONFLICT DO NOTHING;

  INSERT INTO public.volunteer_certificates (
    agenda_item_id,
    volunteer_id,
    issuer_user_id,
    issuer_name,
    title,
    badge_id,
    certificate_url
  )
  VALUES (
    v_agenda.id,
    v_participant.volunteer_id,
    v_agenda.ngo_id,
    v_agenda.certificate_issuer,
    v_agenda.certificate_title,
    v_agenda.reward_badge_id,
    p_certificate_url
  )
  ON CONFLICT (agenda_item_id, volunteer_id) DO UPDATE SET
    certificate_url = EXCLUDED.certificate_url,
    issued_at = now();

  UPDATE public.user_stats
  SET impact_score = impact_score + 50,
      reputation_score = COALESCE(reputation_score, 0) + 15
  WHERE user_id = v_participant.volunteer_id;

  INSERT INTO public.goodwill_actions (user_id, action_type, points, reference_id)
  VALUES (v_participant.volunteer_id, 'NGO_AGENDA_COMPLETED', 50, v_agenda.id);

  INSERT INTO public.notifications (user_id, title, message)
  VALUES (
    v_participant.volunteer_id,
    'Certificate issued',
    v_agenda.certificate_issuer || ' issued your ' || v_agenda.certificate_title || ' certificate.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.review_campaign_verification(
  p_campaign_id UUID,
  p_approved BOOLEAN
)
RETURNS void AS $$
BEGIN
  IF NOT public.is_app_admin() THEN RAISE EXCEPTION 'Admin required'; END IF;

  UPDATE public.campaigns
  SET verification_status = CASE WHEN p_approved THEN 'verified' ELSE 'rejected' END,
      verified_by = CASE WHEN p_approved THEN auth.uid() ELSE NULL END,
      verified_at = CASE WHEN p_approved THEN now() ELSE NULL END
  WHERE id = p_campaign_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Campaign not found'; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
