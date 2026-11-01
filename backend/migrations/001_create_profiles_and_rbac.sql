-- Migration: Complete Role-Based Access Control (RBAC) in FIRE-EYE
-- Target: Supabase PostgreSQL auth.users & public.profiles

-- 1. Create profiles table if it does not exist
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- Index for fast role-based lookups
CREATE INDEX IF NOT EXISTS idx_profiles_role ON public.profiles(role);

-- 2. Trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_profiles_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_profiles_updated_at ON public.profiles;
CREATE TRIGGER trigger_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.set_profiles_updated_at();

-- 3. Automatic Profile creation on new Auth signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, role, created_at, updated_at)
    VALUES (
        NEW.id,
        'user', -- Always default to 'user' for public signups
        timezone('utc'::text, now()),
        timezone('utc'::text, now())
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 4. Backfill existing Supabase users into profiles with default 'user'
INSERT INTO public.profiles (id, role, created_at, updated_at)
SELECT id, 'user', created_at, now()
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- 5. Explicitly assign 'admin' role to designated administrator UUID
-- Designated administrator: 7900f312-14ea-49d0-9e1b-626228307084 (aditya@astrix.com)
UPDATE public.profiles
SET role = 'admin', updated_at = now()
WHERE id = '7900f312-14ea-49d0-9e1b-626228307084';

-- Ensure second user (jhaaditya474@gmail.com) is explicitly 'user'
UPDATE public.profiles
SET role = 'user', updated_at = now()
WHERE id = '38289592-1f93-498e-a862-5587b765da2e';

-- 6. Enable Row Level Security (RLS) on profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Security Definer helper function to safely check admin status without recursive policies
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- Drop any existing conflicting policies
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_admin" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_admin_only" ON public.profiles;
DROP POLICY IF EXISTS "profiles_delete_admin_only" ON public.profiles;

-- RLS Policy: Authenticated users can read their own profile
CREATE POLICY "profiles_select_own"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (id = auth.uid());

-- RLS Policy: Admins can read all profiles
CREATE POLICY "profiles_select_admin"
    ON public.profiles
    FOR SELECT
    TO authenticated
    USING (public.is_admin());

-- RLS Policy: Users cannot update their own role; only admins can update profiles
CREATE POLICY "profiles_update_admin_only"
    ON public.profiles
    FOR UPDATE
    TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- RLS Policy: Users cannot delete profiles directly
CREATE POLICY "profiles_delete_admin_only"
    ON public.profiles
    FOR DELETE
    TO authenticated
    USING (public.is_admin());
