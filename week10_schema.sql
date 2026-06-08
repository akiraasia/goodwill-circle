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
