-- Week 10 Auth Gate, Guest Access Support, and Private Phase 0 Signup Backup

-- Private owner/admin table for Phase 0 signup exports. No client-facing RLS
-- policies are created, so users cannot read or write this table directly.
CREATE TABLE IF NOT EXISTS public.phase_zero_signup_backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL,
  signed_up_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  exported_at TIMESTAMPTZ
);

ALTER TABLE public.phase_zero_signup_backups ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.phase_zero_signup_backups FROM anon, authenticated;

CREATE INDEX IF NOT EXISTS phase_zero_signup_backups_signed_up_at_idx
  ON public.phase_zero_signup_backups (signed_up_at DESC);

CREATE UNIQUE INDEX IF NOT EXISTS phase_zero_signup_backups_email_unique_idx
  ON public.phase_zero_signup_backups (email);

CREATE OR REPLACE FUNCTION public.capture_phase_zero_signup_backup()
RETURNS trigger AS $$
DECLARE
  v_name TEXT;
  v_email TEXT;
BEGIN
  v_email := lower(trim(COALESCE(NEW.email, '')));

  -- Anonymous guest sessions do not have an email and should not enter
  -- the owner signup export.
  IF v_email = '' THEN
    RETURN NEW;
  END IF;

  v_name := trim(COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  ));

  INSERT INTO public.phase_zero_signup_backups (
    user_id,
    name,
    email,
    signed_up_at
  )
  VALUES (
    NEW.id,
    v_name,
    v_email,
    COALESCE(NEW.created_at, now())
  )
  ON CONFLICT (user_id) DO UPDATE SET
    name = EXCLUDED.name,
    email = EXCLUDED.email;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.capture_phase_zero_signup_backup() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.capture_phase_zero_signup_backup() FROM anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_phase_zero_signup_backup ON auth.users;
CREATE TRIGGER on_auth_user_phase_zero_signup_backup
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.capture_phase_zero_signup_backup();

-- Repair/replace the base signup trigger so new accounts do not show as
-- "New User" when profile metadata is present. Supabase Auth already enforces
-- one account per email; this keeps the app profile row aligned with auth.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  v_name TEXT;
BEGIN
  v_name := NULLIF(trim(COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    ''
  )), '');

  IF v_name IS NULL AND NULLIF(trim(COALESCE(NEW.email, '')), '') IS NOT NULL THEN
    v_name := split_part(NEW.email, '@', 1);
  END IF;
  IF v_name IS NULL THEN
    v_name := 'Guest helper';
  END IF;

  INSERT INTO public.profiles (id, name, photo_url, phone)
  VALUES (
    NEW.id,
    v_name,
    NULLIF(NEW.raw_user_meta_data->>'avatar_url', ''),
    NULLIF(NEW.raw_user_meta_data->>'phone', '')
  )
  ON CONFLICT (id) DO UPDATE
    SET name = COALESCE(NULLIF(public.profiles.name, ''), EXCLUDED.name),
        photo_url = COALESCE(NULLIF(public.profiles.photo_url, ''), EXCLUDED.photo_url),
        phone = COALESCE(NULLIF(public.profiles.phone, ''), EXCLUDED.phone);

  INSERT INTO public.user_stats (user_id, credits, free_requests)
  VALUES (NEW.id, 50, 1)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION public.repair_current_user_profile()
RETURNS void AS $$
DECLARE
  v_user RECORD;
  v_name TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;

  SELECT
    id,
    email,
    raw_user_meta_data
  INTO v_user
  FROM auth.users
  WHERE id = auth.uid();

  v_name := NULLIF(trim(COALESCE(
    v_user.raw_user_meta_data->>'full_name',
    v_user.raw_user_meta_data->>'name',
    ''
  )), '');

  IF v_name IS NULL AND NULLIF(trim(COALESCE(v_user.email, '')), '') IS NOT NULL THEN
    v_name := split_part(v_user.email, '@', 1);
  END IF;
  IF v_name IS NULL THEN
    v_name := 'Guest helper';
  END IF;

  INSERT INTO public.profiles (id, name, photo_url, phone)
  VALUES (
    auth.uid(),
    v_name,
    NULLIF(v_user.raw_user_meta_data->>'avatar_url', ''),
    NULLIF(v_user.raw_user_meta_data->>'phone', '')
  )
  ON CONFLICT (id) DO UPDATE
    SET name = COALESCE(NULLIF(public.profiles.name, ''), EXCLUDED.name),
        photo_url = COALESCE(NULLIF(public.profiles.photo_url, ''), EXCLUDED.photo_url),
        phone = COALESCE(NULLIF(public.profiles.phone, ''), EXCLUDED.phone);

  INSERT INTO public.user_stats (user_id, credits, free_requests)
  VALUES (auth.uid(), 50, 1)
  ON CONFLICT (user_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.repair_current_user_profile() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.repair_current_user_profile() TO authenticated;

CREATE OR REPLACE FUNCTION public.export_phase_zero_signup_backup_csv()
RETURNS TEXT AS $$
DECLARE
  v_csv TEXT;
BEGIN
  IF NOT public.is_app_admin() THEN
    RAISE EXCEPTION 'Admin required';
  END IF;

  SELECT
    'name,email' ||
    COALESCE(
      E'\n' || string_agg(
        '"' || replace(COALESCE(name, ''), '"', '""') ||
        '","' || replace(COALESCE(email, ''), '"', '""') || '"',
        E'\n'
        ORDER BY signed_up_at ASC
      ),
      ''
    )
  INTO v_csv
  FROM public.phase_zero_signup_backups;

  UPDATE public.phase_zero_signup_backups
  SET exported_at = now()
  WHERE exported_at IS NULL;

  RETURN v_csv;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.export_phase_zero_signup_backup_csv() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.export_phase_zero_signup_backup_csv() TO authenticated;

-- Strong verification replaces vague free-text verification with concrete,
-- reviewer-auditable signals: LinkedIn, confirmed email, phone OTP, and a
-- profile photo queued for server-side Reality Defender analysis.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT,
  ADD COLUMN IF NOT EXISTS email_otp_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS phone_otp_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS profile_photo_check_status TEXT NOT NULL DEFAULT 'not_submitted'
    CHECK (profile_photo_check_status IN ('not_submitted', 'queued', 'authentic', 'suspicious', 'fake', 'failed')),
  ADD COLUMN IF NOT EXISTS profile_photo_check_id UUID REFERENCES public.media_authenticity_checks(id) ON DELETE SET NULL;

ALTER TABLE public.profile_verification_requests
  ADD COLUMN IF NOT EXISTS linkedin_url TEXT,
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS email_otp_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS phone_otp_verified_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS profile_photo_check_id UUID REFERENCES public.media_authenticity_checks(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS verification_method TEXT NOT NULL DEFAULT 'manual'
    CHECK (verification_method IN ('manual', 'strong_identity'));

CREATE INDEX IF NOT EXISTS profile_verification_requests_strong_idx
  ON public.profile_verification_requests (user_id, status, created_at DESC)
  WHERE verification_method = 'strong_identity';

CREATE OR REPLACE FUNCTION public.request_profile_strong_verification(
  p_account_type TEXT,
  p_organization_name TEXT DEFAULT NULL,
  p_linkedin_url TEXT DEFAULT NULL,
  p_phone_number TEXT DEFAULT NULL,
  p_profile_photo_url TEXT DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_user RECORD;
  v_linkedin_url TEXT;
  v_phone_number TEXT;
  v_profile_photo_url TEXT;
  v_media_check_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_account_type NOT IN ('individual', 'ngo', 'college') THEN
    RAISE EXCEPTION 'Invalid account type';
  END IF;

  SELECT
    phone,
    email_confirmed_at,
    phone_confirmed_at
  INTO v_user
  FROM auth.users
  WHERE id = auth.uid();

  IF v_user.email_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Email OTP verification is required';
  END IF;
  IF v_user.phone_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Phone OTP verification is required';
  END IF;

  v_linkedin_url := lower(trim(COALESCE(p_linkedin_url, '')));
  v_phone_number := trim(COALESCE(p_phone_number, ''));
  v_profile_photo_url := trim(COALESCE(p_profile_photo_url, ''));

  IF v_linkedin_url !~ '^https://([a-z0-9-]+\.)?linkedin\.com/.+' THEN
    RAISE EXCEPTION 'A valid LinkedIn profile URL is required';
  END IF;
  IF length(v_phone_number) < 8 THEN
    RAISE EXCEPTION 'A verified phone number is required';
  END IF;
  IF COALESCE(v_user.phone, '') != v_phone_number THEN
    RAISE EXCEPTION 'Submitted phone number must match the OTP-verified phone number';
  END IF;
  IF v_profile_photo_url = '' THEN
    RAISE EXCEPTION 'A profile photo is required for verification';
  END IF;
  IF p_account_type IN ('ngo', 'college') AND NULLIF(trim(COALESCE(p_organization_name, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Organization name is required';
  END IF;

  INSERT INTO public.media_authenticity_checks (
    user_id,
    provider,
    target_type,
    target_id,
    media_url,
    status
  )
  VALUES (
    auth.uid(),
    'reality_defender',
    'profile_photo',
    auth.uid(),
    v_profile_photo_url,
    'queued'
  )
  RETURNING id INTO v_media_check_id;

  INSERT INTO public.profiles (
    id,
    name,
    phone,
    account_type,
    organization_name,
    linkedin_url,
    email_otp_verified_at,
    phone_otp_verified_at,
    verification_status,
    verification_note,
    verification_requested_at,
    profile_photo_check_status,
    profile_photo_check_id
  )
  VALUES (
    auth.uid(),
    split_part(COALESCE((SELECT email FROM auth.users WHERE id = auth.uid()), 'Goodwill member'), '@', 1),
    v_phone_number,
    p_account_type,
    NULLIF(trim(COALESCE(p_organization_name, '')), ''),
    v_linkedin_url,
    v_user.email_confirmed_at,
    v_user.phone_confirmed_at,
    'pending',
    'Strong verification submitted: LinkedIn, email OTP, phone OTP, and Reality Defender profile photo queue.',
    now(),
    'queued',
    v_media_check_id
  )
  ON CONFLICT (id) DO UPDATE
    SET account_type = EXCLUDED.account_type,
        organization_name = EXCLUDED.organization_name,
        linkedin_url = EXCLUDED.linkedin_url,
        phone = EXCLUDED.phone,
        email_otp_verified_at = EXCLUDED.email_otp_verified_at,
        phone_otp_verified_at = EXCLUDED.phone_otp_verified_at,
        verification_status = EXCLUDED.verification_status,
        verification_note = EXCLUDED.verification_note,
        verification_requested_at = EXCLUDED.verification_requested_at,
        profile_photo_check_status = EXCLUDED.profile_photo_check_status,
        profile_photo_check_id = EXCLUDED.profile_photo_check_id;

  INSERT INTO public.profile_verification_requests (
    user_id,
    requested_account_type,
    organization_name,
    note,
    linkedin_url,
    phone_number,
    email_otp_verified_at,
    phone_otp_verified_at,
    profile_photo_url,
    profile_photo_check_id,
    verification_method
  )
  VALUES (
    auth.uid(),
    p_account_type,
    NULLIF(trim(COALESCE(p_organization_name, '')), ''),
    'Strong verification submitted.',
    v_linkedin_url,
    v_phone_number,
    v_user.email_confirmed_at,
    v_user.phone_confirmed_at,
    v_profile_photo_url,
    v_media_check_id,
    'strong_identity'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.request_profile_strong_verification(TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.request_profile_strong_verification(TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.record_profile_photo_reality_defender_result(
  p_check_id UUID,
  p_provider_request_id TEXT,
  p_result_status TEXT,
  p_confidence_score INTEGER DEFAULT NULL
)
RETURNS void AS $$
DECLARE
  v_status TEXT;
  v_user_id UUID;
BEGIN
  IF NOT public.is_app_admin() THEN RAISE EXCEPTION 'Admin required'; END IF;

  v_status := CASE lower(COALESCE(p_result_status, ''))
    WHEN 'authentic' THEN 'authentic'
    WHEN 'fake' THEN 'fake'
    WHEN 'suspicious' THEN 'suspicious'
    ELSE 'failed'
  END;

  UPDATE public.media_authenticity_checks
  SET provider_request_id = p_provider_request_id,
      result_status = p_result_status,
      confidence_score = p_confidence_score,
      status = v_status,
      reviewed_at = now(),
      updated_at = now()
  WHERE id = p_check_id
    AND provider = 'reality_defender'
    AND target_type = 'profile_photo'
  RETURNING user_id INTO v_user_id;

  IF v_user_id IS NULL THEN RAISE EXCEPTION 'Profile photo check not found'; END IF;

  UPDATE public.profiles
  SET profile_photo_check_status = v_status,
      trusted_account_status = CASE
        WHEN v_status = 'authentic' AND verification_status = 'verified' THEN 'trusted'
        WHEN v_status IN ('suspicious', 'fake') THEN 'flagged'
        ELSE trusted_account_status
      END,
      trust_reviewed_at = now(),
      trust_note = CASE
        WHEN v_status = 'authentic' THEN 'Profile photo passed Reality Defender media authenticity review.'
        WHEN v_status IN ('suspicious', 'fake') THEN 'Profile photo was flagged by Reality Defender and needs manual review.'
        ELSE trust_note
      END
  WHERE id = v_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.record_profile_photo_reality_defender_result(UUID, TEXT, TEXT, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_profile_photo_reality_defender_result(UUID, TEXT, TEXT, INTEGER) TO authenticated;

-- Keep the public media bucket for public app media only.
DROP POLICY IF EXISTS "Authenticated users can upload goodwill media." ON storage.objects;
DROP POLICY IF EXISTS "Users can update their goodwill media." ON storage.objects;

CREATE POLICY "Authenticated users can upload goodwill media."
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN ('requests', 'campaigns', 'confessions')
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can update their goodwill media."
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'goodwill-media'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] IN ('requests', 'campaigns', 'confessions')
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

-- Private verification photos are not public profile photos. Users upload them
-- for review only; admins and backend workers can read them to create signed
-- URLs for Reality Defender without exposing the image in the app.
INSERT INTO storage.buckets (id, name, public)
VALUES ('goodwill-verification', 'goodwill-verification', false)
ON CONFLICT (id) DO UPDATE SET public = false;

DROP POLICY IF EXISTS "Users can upload own verification media." ON storage.objects;
DROP POLICY IF EXISTS "Users can update own verification media." ON storage.objects;
DROP POLICY IF EXISTS "Admins can view verification media." ON storage.objects;

CREATE POLICY "Users can upload own verification media."
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'goodwill-verification'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = 'profiles'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Users can update own verification media."
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'goodwill-verification'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[2] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'goodwill-verification'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = 'profiles'
    AND (storage.foldername(name))[2] = auth.uid()::text
  );

CREATE POLICY "Admins can view verification media."
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'goodwill-verification'
    AND public.is_app_admin()
  );
