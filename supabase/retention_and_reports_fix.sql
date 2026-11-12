-- ============================================================================
-- MIGRATION: 14-DAY STORY RETENTION, REPORT SUBMISSION, & REALTIME FOLLOWS
-- ============================================================================
-- PANDUAN PENTING MENJALANKAN DI SUPABASE SQL EDITOR:
-- 1. Pastikan TIDAK ADA teks yang ter-highlight / terblok sebagian.
--    (Tekan Ctrl+A untuk memilih SEMUA baris, lalu klik tombol RUN).
-- 2. Jika hanya sebagian teks yang terblok (misalnya baris RETURN saja),
--    Supabase akan menjalankan baris tersebut secara mandiri dan memicu ERROR 42601.
-- ============================================================================

-- 0. PASTIKAN HELPER FUNCTION is_admin SUDAH TERSEDIA
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'curator')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 1. ENSURE deleted_at COLUMN EXISTS ON STORIES
-- (Crucial for 14-day soft-delete retention so stories are not hard-deleted)
ALTER TABLE public.stories 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- 2. CREATE FOLLOWS TABLE & REALTIME PUBLICATION
-- (Required for Readers & Following counts to sync and update in real-time)
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_follow UNIQUE (follower_id, following_id)
);

CREATE INDEX IF NOT EXISTS idx_follows_follower ON public.follows (follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON public.follows (following_id);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view follows" ON public.follows;
CREATE POLICY "Anyone can view follows" 
ON public.follows FOR SELECT USING (true);

DROP POLICY IF EXISTS "Authenticated users can follow" ON public.follows;
CREATE POLICY "Authenticated users can follow" 
ON public.follows FOR INSERT 
WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON public.follows;
CREATE POLICY "Users can unfollow" 
ON public.follows FOR DELETE 
USING (auth.uid() = follower_id);

ALTER TABLE public.follows REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'follows'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
  END IF;

  -- Ensure foreign keys point to public.profiles so Supabase joins profiles directly
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_follows_follower_profiles'
  ) THEN
    ALTER TABLE public.follows 
    ADD CONSTRAINT fk_follows_follower_profiles 
    FOREIGN KEY (follower_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'fk_follows_following_profiles'
  ) THEN
    ALTER TABLE public.follows 
    ADD CONSTRAINT fk_follows_following_profiles 
    FOREIGN KEY (following_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 3. FIX REPORTS RLS POLICY
-- Allows authenticated users to view their own reports so PostgREST RETURNING
-- queries do not throw false RLS errors after a successful INSERT.
DROP POLICY IF EXISTS "Admins can view reports" ON public.reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON public.reports;
DROP POLICY IF EXISTS "Admins and reporters can view reports" ON public.reports;

CREATE POLICY "Admins and reporters can view reports" 
ON public.reports FOR SELECT 
USING (public.is_admin() OR auth.uid() = reporter_id);

-- 4. DEDICATED RPC: SOFT DELETE STORY (Curators & Admins)
CREATE OR REPLACE FUNCTION public.soft_delete_story_admin(target_story_id UUID)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can delete tales.';
  END IF;

  UPDATE public.stories
  SET deleted_at = NOW(), updated_at = NOW()
  WHERE id = target_story_id;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. DEDICATED RPC: RESTORE STORY (Curators & Admins)
-- Restores a soft-deleted story within the 14-day grace window.
CREATE OR REPLACE FUNCTION public.restore_story_admin(target_story_id UUID)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can restore tales.';
  END IF;

  UPDATE public.stories
  SET deleted_at = NULL, updated_at = NOW()
  WHERE id = target_story_id;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. DEDICATED RPC: PERMANENTLY PURGE STORY (Curators & Admins)
CREATE OR REPLACE FUNCTION public.hard_delete_story_admin(target_story_id UUID)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can permanently delete tales.';
  END IF;

  DELETE FROM public.stories
  WHERE id = target_story_id;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. DEDICATED RPC: CLEAN UP EXPIRED STORIES PAST 14 DAYS
CREATE OR REPLACE FUNCTION public.cleanup_expired_deleted_stories()
RETURNS JSONB AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  DELETE FROM public.stories
  WHERE deleted_at IS NOT NULL
    AND deleted_at < (NOW() - INTERVAL '14 days');

  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN jsonb_build_object('success', true, 'purged_count', deleted_count);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. DEDICATED RPC: USER ACCOUNT DELETION (Google Play Policy Compliance)
-- Allows an authenticated user to permanently delete their account and cascading data.
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS JSONB AS $$
DECLARE
  uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Delete from auth.users (cascades to public.profiles, stories, comments, follows, likes)
  DELETE FROM auth.users WHERE id = uid;

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
