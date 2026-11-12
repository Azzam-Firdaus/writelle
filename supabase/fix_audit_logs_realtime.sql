-- ==============================================================================
-- FIX & ENHANCE: Real-Time Audit Logs & Admin Story Deletion
-- Jalankan query ini di Supabase SQL Editor untuk memastikan:
-- 1. Realtime replication aktif untuk tabel curator_audit_logs
-- 2. Foreign key relationship antara curator_audit_logs dan profiles terdaftar
-- 3. Dedicated RPCs (record_audit_log_admin & soft_delete_story_admin) aktif
-- ==============================================================================

-- 1. Pastikan tabel curator_audit_logs sudah ada
CREATE TABLE IF NOT EXISTS public.curator_audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  curator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  curator_name VARCHAR(50),
  action VARCHAR(50) NOT NULL,
  target_type VARCHAR(30) NOT NULL,
  target_id TEXT,
  target_title TEXT,
  details TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Tambahkan Foreign Key constraint ke profiles (agar PostgREST join aman)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'fk_curator_audit_logs_profiles'
  ) THEN
    ALTER TABLE public.curator_audit_logs 
    ADD CONSTRAINT fk_curator_audit_logs_profiles 
    FOREIGN KEY (curator_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;

-- 3. Pastikan RLS aktif & kebijakan INSERT/SELECT mengizinkan Admin & Curator
ALTER TABLE public.curator_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins and Curators can insert audit logs" ON public.curator_audit_logs;
CREATE POLICY "Admins and Curators can insert audit logs" 
ON public.curator_audit_logs FOR INSERT 
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins and Curators can view audit logs" ON public.curator_audit_logs;
CREATE POLICY "Admins and Curators can view audit logs" 
ON public.curator_audit_logs FOR SELECT 
USING (public.is_admin());

-- 4. Dedicated RPC: soft_delete_story_admin (Bypass RLS kendala update cerita antar user)
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

  RETURN jsonb_build_object('success', true, 'story_id', target_story_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Dedicated RPC: record_audit_log_admin (Pencatatan log aman & terjamin)
CREATE OR REPLACE FUNCTION public.record_audit_log_admin(
  p_action VARCHAR,
  p_target_type VARCHAR,
  p_target_id TEXT DEFAULT NULL,
  p_target_title TEXT DEFAULT NULL,
  p_details TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
  caller_pen_name TEXT;
  new_log_id UUID;
BEGIN
  SELECT role, pen_name INTO caller_role, caller_pen_name
  FROM public.profiles
  WHERE id = auth.uid();

  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can record audit logs.';
  END IF;

  INSERT INTO public.curator_audit_logs (
    curator_id,
    curator_name,
    action,
    target_type,
    target_id,
    target_title,
    details
  ) VALUES (
    auth.uid(),
    COALESCE(caller_pen_name, 'Curator'),
    p_action,
    p_target_type,
    p_target_id,
    p_target_title,
    p_details
  ) RETURNING id INTO new_log_id;

  RETURN jsonb_build_object('success', true, 'id', new_log_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Hak Akses Eksekusi RPC
GRANT EXECUTE ON FUNCTION public.soft_delete_story_admin(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.record_audit_log_admin(VARCHAR, VARCHAR, TEXT, TEXT, TEXT) TO authenticated;

-- 7. Realtime Replication Setup
ALTER TABLE public.curator_audit_logs REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'curator_audit_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.curator_audit_logs;
  END IF;
END $$;
