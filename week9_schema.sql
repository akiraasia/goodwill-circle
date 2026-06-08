-- Week 9 Trust, Scam Defense, Financial Help Verification, QR Connections, and Impact Summary

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS trusted_account_status TEXT NOT NULL DEFAULT 'standard'
    CHECK (trusted_account_status IN ('standard', 'trusted', 'limited', 'flagged')),
  ADD COLUMN IF NOT EXISTS trust_reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trust_reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS trust_note TEXT;

ALTER TABLE public.help_requests
  ADD COLUMN IF NOT EXISTS financial_help_verification_status TEXT NOT NULL DEFAULT 'not_required'
    CHECK (financial_help_verification_status IN ('not_required', 'needed', 'pending', 'verified', 'rejected')),
  ADD COLUMN IF NOT EXISTS scam_check_status TEXT NOT NULL DEFAULT 'not_checked'
    CHECK (scam_check_status IN ('not_checked', 'low_risk', 'review', 'blocked')),
  ADD COLUMN IF NOT EXISTS scam_risk_score INTEGER NOT NULL DEFAULT 0 CHECK (scam_risk_score BETWEEN 0 AND 100),
  ADD COLUMN IF NOT EXISTS requester_trust_snapshot TEXT,
  ADD COLUMN IF NOT EXISTS security_checked_at TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS public.media_authenticity_checks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  provider TEXT NOT NULL DEFAULT 'reality_defender',
  target_type TEXT NOT NULL
    CHECK (target_type IN ('profile_photo', 'financial_help', 'request', 'campaign', 'agenda_item')),
  target_id UUID,
  media_url TEXT NOT NULL,
  provider_request_id TEXT,
  status TEXT NOT NULL DEFAULT 'queued'
    CHECK (status IN ('queued', 'uploaded', 'processing', 'authentic', 'suspicious', 'fake', 'unable_to_evaluate', 'failed')),
  result_status TEXT,
  confidence_score INTEGER CHECK (confidence_score IS NULL OR confidence_score BETWEEN 0 AND 100),
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.financial_help_verifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  request_id UUID REFERENCES public.help_requests(id) ON DELETE CASCADE NOT NULL,
  requester_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  evidence_url TEXT,
  note TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'verified', 'rejected', 'needs_more_info')),
  media_check_id UUID REFERENCES public.media_authenticity_checks(id) ON DELETE SET NULL,
  reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  review_note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  UNIQUE (request_id)
);

CREATE TABLE IF NOT EXISTS public.scam_checkups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  target_type TEXT NOT NULL
    CHECK (target_type IN ('profile', 'request', 'campaign', 'message', 'financial_help')),
  target_id UUID,
  message TEXT NOT NULL,
  risk_score INTEGER NOT NULL CHECK (risk_score BETWEEN 0 AND 100),
  status TEXT NOT NULL
    CHECK (status IN ('low_risk', 'review', 'blocked')),
  signals TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.trusted_connection_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  invite_code TEXT NOT NULL UNIQUE,
  qr_payload TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'used', 'revoked', 'expired')),
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '7 days'),
  used_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  used_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.trusted_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  trusted_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL DEFAULT 'connected' CHECK (status IN ('connected', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE (user_id, trusted_user_id),
  CHECK (user_id != trusted_user_id)
);

ALTER TABLE public.media_authenticity_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_help_verifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scam_checkups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_connection_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trusted_connections ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own media checks." ON public.media_authenticity_checks;
DROP POLICY IF EXISTS "Users can view own financial verifications." ON public.financial_help_verifications;
DROP POLICY IF EXISTS "Users can view own scam checkups." ON public.scam_checkups;
DROP POLICY IF EXISTS "Users can view own connection invites." ON public.trusted_connection_invites;
DROP POLICY IF EXISTS "Users can view own trusted connections." ON public.trusted_connections;

CREATE POLICY "Users can view own media checks."
  ON public.media_authenticity_checks
  FOR SELECT
  USING (auth.uid() = user_id OR public.is_app_admin());

CREATE POLICY "Users can view own financial verifications."
  ON public.financial_help_verifications
  FOR SELECT
  USING (auth.uid() = requester_id OR public.is_app_admin());

CREATE POLICY "Users can view own scam checkups."
  ON public.scam_checkups
  FOR SELECT
  USING (auth.uid() = user_id OR public.is_app_admin());

CREATE POLICY "Users can view own connection invites."
  ON public.trusted_connection_invites
  FOR SELECT
  USING (auth.uid() = inviter_id OR auth.uid() = used_by OR public.is_app_admin());

CREATE POLICY "Users can view own trusted connections."
  ON public.trusted_connections
  FOR SELECT
  USING (auth.uid() = user_id OR auth.uid() = trusted_user_id OR public.is_app_admin());

CREATE OR REPLACE FUNCTION public.create_trusted_connection_invite()
RETURNS TABLE(invite_code TEXT, qr_payload TEXT, expires_at TIMESTAMPTZ) AS $$
DECLARE
  v_code TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  v_code := lower(replace(gen_random_uuid()::text, '-', ''));

  INSERT INTO public.trusted_connection_invites (inviter_id, invite_code, qr_payload)
  VALUES (
    auth.uid(),
    v_code,
    'goodwill-circle://connect?code=' || v_code
  )
  RETURNING trusted_connection_invites.invite_code,
            trusted_connection_invites.qr_payload,
            trusted_connection_invites.expires_at
  INTO invite_code, qr_payload, expires_at;

  RETURN NEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.redeem_trusted_connection_invite(p_invite_code TEXT)
RETURNS void AS $$
DECLARE
  v_invite RECORD;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  SELECT * INTO v_invite
  FROM public.trusted_connection_invites
  WHERE invite_code = lower(trim(p_invite_code))
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Invite not found'; END IF;
  IF v_invite.status != 'open' OR v_invite.expires_at < now() THEN
    RAISE EXCEPTION 'Invite is no longer active';
  END IF;
  IF v_invite.inviter_id = auth.uid() THEN RAISE EXCEPTION 'You cannot connect to yourself'; END IF;

  INSERT INTO public.trusted_connections (user_id, trusted_user_id)
  VALUES (v_invite.inviter_id, auth.uid()), (auth.uid(), v_invite.inviter_id)
  ON CONFLICT (user_id, trusted_user_id) DO NOTHING;

  UPDATE public.trusted_connection_invites
  SET status = 'used',
      used_by = auth.uid(),
      used_at = now()
  WHERE id = v_invite.id;

  UPDATE public.profiles
  SET trusted_account_status = 'trusted',
      trust_reviewed_at = now(),
      trust_note = 'Connected with a trusted Goodwill Circle account.'
  WHERE id IN (v_invite.inviter_id, auth.uid())
    AND trusted_account_status = 'standard';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.run_scam_checkup(
  p_target_type TEXT,
  p_target_id UUID,
  p_message TEXT
)
RETURNS UUID AS $$
DECLARE
  v_message TEXT;
  v_score INTEGER := 0;
  v_signals TEXT[] := '{}';
  v_status TEXT;
  v_check_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_target_type NOT IN ('profile', 'request', 'campaign', 'message', 'financial_help') THEN
    RAISE EXCEPTION 'Invalid check target type';
  END IF;

  v_message := lower(trim(COALESCE(p_message, '')));
  IF length(v_message) < 8 THEN RAISE EXCEPTION 'Add more detail for the safety check'; END IF;

  IF v_message ~ '(upi|bank|wire|crypto|gift card|otp|password|urgent|outside app|whatsapp|telegram)' THEN
    v_score := v_score + 35;
    v_signals := array_append(v_signals, 'Payment or off-platform pressure');
  END IF;
  IF v_message ~ '(guaranteed|double|investment|processing fee|advance fee|refund fee)' THEN
    v_score := v_score + 35;
    v_signals := array_append(v_signals, 'Common financial scam wording');
  END IF;
  IF v_message ~ '(send.*money|pay.*first|share.*code|verify.*otp)' THEN
    v_score := v_score + 30;
    v_signals := array_append(v_signals, 'High-risk action requested');
  END IF;

  v_score := LEAST(v_score, 100);
  v_status := CASE
    WHEN v_score >= 70 THEN 'blocked'
    WHEN v_score >= 35 THEN 'review'
    ELSE 'low_risk'
  END;

  INSERT INTO public.scam_checkups (
    user_id,
    target_type,
    target_id,
    message,
    risk_score,
    status,
    signals
  )
  VALUES (auth.uid(), p_target_type, p_target_id, p_message, v_score, v_status, v_signals)
  RETURNING id INTO v_check_id;

  IF p_target_type IN ('request', 'financial_help') AND p_target_id IS NOT NULL THEN
    UPDATE public.help_requests
    SET scam_check_status = v_status,
        scam_risk_score = v_score,
        security_checked_at = now()
    WHERE id = p_target_id AND creator_id = auth.uid();
  END IF;

  RETURN v_check_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.submit_financial_help_verification(
  p_request_id UUID,
  p_note TEXT,
  p_evidence_url TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_request RECORD;
  v_note TEXT;
  v_verification_id UUID;
  v_media_check_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  SELECT * INTO v_request
  FROM public.help_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  IF v_request.creator_id != auth.uid() THEN
    RAISE EXCEPTION 'Only the requester can verify this financial help request';
  END IF;

  v_note := NULLIF(trim(COALESCE(p_note, '')), '');
  IF v_note IS NULL OR length(v_note) < 20 THEN
    RAISE EXCEPTION 'Add clear verification details for financial help';
  END IF;

  IF NULLIF(trim(COALESCE(p_evidence_url, '')), '') IS NOT NULL THEN
    INSERT INTO public.media_authenticity_checks (
      user_id,
      target_type,
      target_id,
      media_url,
      status
    )
    VALUES (
      auth.uid(),
      'financial_help',
      p_request_id,
      trim(p_evidence_url),
      'queued'
    )
    RETURNING id INTO v_media_check_id;
  END IF;

  INSERT INTO public.financial_help_verifications (
    request_id,
    requester_id,
    evidence_url,
    note,
    media_check_id
  )
  VALUES (p_request_id, auth.uid(), NULLIF(trim(COALESCE(p_evidence_url, '')), ''), v_note, v_media_check_id)
  ON CONFLICT (request_id) DO UPDATE SET
    evidence_url = EXCLUDED.evidence_url,
    note = EXCLUDED.note,
    media_check_id = COALESCE(EXCLUDED.media_check_id, public.financial_help_verifications.media_check_id),
    status = 'pending',
    reviewed_by = NULL,
    review_note = NULL,
    reviewed_at = NULL
  RETURNING id INTO v_verification_id;

  UPDATE public.help_requests
  SET financial_help_verification_status = 'pending',
      requester_trust_snapshot = (
        SELECT trusted_account_status || ':' || verification_status
        FROM public.profiles
        WHERE id = auth.uid()
      )
  WHERE id = p_request_id;

  RETURN v_verification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.record_media_authenticity_result(
  p_check_id UUID,
  p_provider_request_id TEXT,
  p_result_status TEXT,
  p_confidence_score INTEGER DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_status TEXT;
BEGIN
  IF NOT public.is_app_admin() THEN RAISE EXCEPTION 'Admin required'; END IF;

  v_status := CASE lower(COALESCE(p_result_status, ''))
    WHEN 'authentic' THEN 'authentic'
    WHEN 'fake' THEN 'fake'
    WHEN 'suspicious' THEN 'suspicious'
    WHEN 'unable_to_evaluate' THEN 'unable_to_evaluate'
    ELSE 'failed'
  END;

  UPDATE public.media_authenticity_checks
  SET provider_request_id = p_provider_request_id,
      result_status = p_result_status,
      confidence_score = p_confidence_score,
      status = v_status,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_check_id;

  IF NOT FOUND THEN RAISE EXCEPTION 'Media check not found'; END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_platform_impact_summary()
RETURNS TABLE(metric TEXT, value BIGINT) AS $$
BEGIN
  RETURN QUERY
  SELECT 'users', count(*) FROM public.profiles
  UNION ALL
  SELECT 'verified_profiles', count(*) FROM public.profiles WHERE verification_status = 'verified'
  UNION ALL
  SELECT 'trusted_accounts', count(*) FROM public.profiles WHERE trusted_account_status = 'trusted'
  UNION ALL
  SELECT 'open_requests', count(*) FROM public.help_requests WHERE lower(status) = 'open'
  UNION ALL
  SELECT 'completed_requests', count(*) FROM public.help_requests WHERE lower(status) = 'completed'
  UNION ALL
  SELECT 'campaigns', count(*) FROM public.campaigns
  UNION ALL
  SELECT 'agenda_items', count(*) FROM public.nonprofit_agenda_items;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_trusted_connection_invite() TO authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_trusted_connection_invite(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.run_scam_checkup(TEXT, UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_financial_help_verification(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_platform_impact_summary() TO anon, authenticated;
