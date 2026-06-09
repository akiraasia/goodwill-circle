-- Week 12 Phase 0 Registration Capture
--
-- Captures Phase 0 registrations even when Supabase Auth email delivery is
-- rate-limited or email confirmation is temporarily optional in the app.
-- Clients can insert through a SECURITY DEFINER RPC, but cannot read the list.

CREATE TABLE IF NOT EXISTS public.phase_zero_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auth_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  name TEXT NOT NULL DEFAULT '',
  email TEXT NOT NULL,
  phone TEXT NOT NULL DEFAULT '',
  signup_source TEXT NOT NULL DEFAULT 'phase_zero',
  registered_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  exported_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

ALTER TABLE public.phase_zero_registrations ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.phase_zero_registrations FROM anon, authenticated;

CREATE UNIQUE INDEX IF NOT EXISTS phase_zero_registrations_email_unique_idx
  ON public.phase_zero_registrations (email);

CREATE INDEX IF NOT EXISTS phase_zero_registrations_registered_at_idx
  ON public.phase_zero_registrations (registered_at DESC);

CREATE OR REPLACE FUNCTION public.register_phase_zero_registration(
  p_name TEXT,
  p_email TEXT,
  p_phone TEXT DEFAULT '',
  p_signup_source TEXT DEFAULT 'phase_zero'
)
RETURNS UUID AS $$
DECLARE
  v_id UUID;
  v_email TEXT;
BEGIN
  v_email := lower(trim(COALESCE(p_email, '')));

  IF v_email = '' OR v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'A valid email is required';
  END IF;

  INSERT INTO public.phase_zero_registrations (
    auth_user_id,
    name,
    email,
    phone,
    signup_source,
    metadata
  )
  VALUES (
    auth.uid(),
    trim(COALESCE(p_name, '')),
    v_email,
    trim(COALESCE(p_phone, '')),
    COALESCE(NULLIF(trim(p_signup_source), ''), 'phase_zero'),
    jsonb_build_object(
      'captured_by', 'week12_registration_rpc',
      'auth_role', auth.role()
    )
  )
  ON CONFLICT (email) DO UPDATE SET
    auth_user_id = COALESCE(EXCLUDED.auth_user_id, public.phase_zero_registrations.auth_user_id),
    name = COALESCE(NULLIF(EXCLUDED.name, ''), public.phase_zero_registrations.name),
    phone = COALESCE(NULLIF(EXCLUDED.phone, ''), public.phase_zero_registrations.phone),
    signup_source = EXCLUDED.signup_source,
    last_seen_at = now(),
    metadata = public.phase_zero_registrations.metadata || EXCLUDED.metadata
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

REVOKE ALL ON FUNCTION public.register_phase_zero_registration(TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.register_phase_zero_registration(TEXT, TEXT, TEXT, TEXT) TO anon, authenticated;

CREATE OR REPLACE FUNCTION public.export_phase_zero_registrations_csv()
RETURNS TEXT AS $$
DECLARE
  v_csv TEXT;
BEGIN
  IF NOT public.is_app_admin() THEN
    RAISE EXCEPTION 'Admin required';
  END IF;

  SELECT
    'name,email,phone,signup_source,registered_at,last_seen_at' ||
    COALESCE(
      E'\n' || string_agg(
        '"' || replace(COALESCE(name, ''), '"', '""') ||
        '","' || replace(COALESCE(email, ''), '"', '""') ||
        '","' || replace(COALESCE(phone, ''), '"', '""') ||
        '","' || replace(COALESCE(signup_source, ''), '"', '""') ||
        '","' || registered_at::TEXT ||
        '","' || last_seen_at::TEXT || '"',
        E'\n'
        ORDER BY registered_at ASC
      ),
      ''
    )
  INTO v_csv
  FROM public.phase_zero_registrations;

  UPDATE public.phase_zero_registrations
  SET exported_at = now()
  WHERE exported_at IS NULL;

  RETURN v_csv;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.export_phase_zero_registrations_csv() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.export_phase_zero_registrations_csv() TO authenticated;
