-- Week 11 Production Auth Finalization: Real Supabase Email and OTP

-- Real email confirmation and SMS OTP are delivered by Supabase Auth, not by
-- public schema. Before production, configure these in Supabase Dashboard:
-- Authentication > Email: enable Confirm email, set Site URL/Redirect URLs,
-- and configure a production SMTP provider.
-- Authentication > Providers > Phone: enable Phone provider and configure
-- Twilio/MessageBird/Vonage/Textlocal with verified sender settings.

-- Remove the earlier auth-delivery fallback queue if it was applied during
-- testing. Production should use Supabase Auth delivery directly.
DROP FUNCTION IF EXISTS public.export_auth_delivery_requests_csv();
DROP FUNCTION IF EXISTS public.resolve_auth_delivery_request(UUID, TEXT, TEXT);
DROP FUNCTION IF EXISTS public.request_auth_delivery_fallback(TEXT, TEXT, TEXT, TEXT);
DROP TABLE IF EXISTS public.auth_delivery_requests;

-- Keep strong verification tied to real Supabase Auth confirmation signals.
-- LinkedIn is optional, but email confirmation, phone OTP, and private photo
-- review are required for a strong identity review.
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
  v_verification_note TEXT;
  v_media_check_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentication required'; END IF;
  IF p_account_type NOT IN ('individual', 'ngo', 'college') THEN
    RAISE EXCEPTION 'Invalid account type';
  END IF;

  SELECT
    email,
    phone,
    email_confirmed_at,
    phone_confirmed_at
  INTO v_user
  FROM auth.users
  WHERE id = auth.uid();

  IF v_user.email_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Confirm your email through Supabase Auth before requesting verification';
  END IF;
  IF v_user.phone_confirmed_at IS NULL THEN
    RAISE EXCEPTION 'Verify your phone OTP through Supabase Auth before requesting verification';
  END IF;

  v_linkedin_url := NULLIF(lower(trim(COALESCE(p_linkedin_url, ''))), '');
  v_phone_number := NULLIF(trim(COALESCE(p_phone_number, '')), '');
  v_profile_photo_url := trim(COALESCE(p_profile_photo_url, ''));

  IF v_linkedin_url IS NOT NULL
    AND v_linkedin_url !~ '^https://([a-z0-9-]+\.)?linkedin\.com/.+' THEN
    RAISE EXCEPTION 'LinkedIn URL must be valid when provided';
  END IF;
  IF v_phone_number IS NULL OR length(v_phone_number) < 8 THEN
    RAISE EXCEPTION 'A verified phone number is required';
  END IF;
  IF COALESCE(v_user.phone, '') != v_phone_number THEN
    RAISE EXCEPTION 'Submitted phone number must match the OTP-verified phone number';
  END IF;
  IF v_profile_photo_url = '' THEN
    RAISE EXCEPTION 'A private profile photo is required for verification';
  END IF;
  IF p_account_type IN ('ngo', 'college') AND NULLIF(trim(COALESCE(p_organization_name, '')), '') IS NULL THEN
    RAISE EXCEPTION 'Organization name is required';
  END IF;

  v_verification_note := 'Strong verification submitted: email confirmed, phone OTP verified, Reality Defender profile photo queue';
  IF v_linkedin_url IS NOT NULL THEN
    v_verification_note := v_verification_note || ', LinkedIn';
  END IF;
  v_verification_note := v_verification_note || '.';

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
    split_part(COALESCE(v_user.email, 'Goodwill member'), '@', 1),
    v_phone_number,
    p_account_type,
    NULLIF(trim(COALESCE(p_organization_name, '')), ''),
    v_linkedin_url,
    v_user.email_confirmed_at,
    v_user.phone_confirmed_at,
    'pending',
    v_verification_note,
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
    v_verification_note,
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
