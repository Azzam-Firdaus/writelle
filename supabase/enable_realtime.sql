-- ==============================================================================
-- SUPABASE REALTIME REPLICATION SCRIPT
-- Jalankan query ini di Supabase SQL Editor agar event Realtime (Notifikasi, 
-- Laporan Baru, Status Moderasi, Likes, & Komentar) langsung aktif secara real-time.
-- ==============================================================================

-- 1. Mengatur Replica Identity ke FULL agar data lengkap dikirim saat UPDATE / DELETE
ALTER TABLE public.reports REPLICA IDENTITY FULL;
ALTER TABLE public.stories REPLICA IDENTITY FULL;
ALTER TABLE public.likes REPLICA IDENTITY FULL;
ALTER TABLE public.comments REPLICA IDENTITY FULL;
ALTER TABLE public.curator_audit_logs REPLICA IDENTITY FULL;

-- 2. Menambahkan tabel ke Publikasi Realtime (supabase_realtime)
DO $$
BEGIN
  -- Tabel reports (untuk notifikasi admin CMS real-time)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
  END IF;

  -- Tabel stories (untuk update konten & sensor moderasi real-time)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'stories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.stories;
  END IF;

  -- Tabel likes (untuk like counter real-time)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'likes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
  END IF;

  -- Tabel comments (untuk komentar real-time)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'comments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
  END IF;

  -- Tabel curator_audit_logs (untuk log audit admin real-time)
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'curator_audit_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.curator_audit_logs;
  END IF;
END $$;
