-- =========================================================================
-- WRITTLE: PERBAIKAN COVER URL & STORAGE BUCKET
-- Pastikan seluruh teks di bawah ini di-copy SEMUANYA (Ctrl+A lalu Run),
-- jangan ada baris yang ter-blok/ter-highlight sebagian saja.
-- =========================================================================

-- LANGKAH 1: Tambahkan kolom cover_url ke tabel stories
ALTER TABLE public.stories 
ADD COLUMN IF NOT EXISTS cover_url TEXT;

-- LANGKAH 2: Hapus view lama agar tidak terjadi konflik urutan kolom
DROP VIEW IF EXISTS public.public_stories_view CASCADE;

-- LANGKAH 3: Buat ulang public_stories_view dengan kolom cover_url
CREATE VIEW public.public_stories_view AS
SELECT 
    s.id,
    s.category_id,
    COALESCE(c.name, 'Reflections') AS category_name,
    COALESCE(c.slug, 'reflections') AS category_slug,
    s.title,
    s.content,
    s.cover_url,
    s.is_anonymous,
    CASE 
        WHEN s.is_anonymous THEN 'Anonymous' 
        ELSE COALESCE(p.pen_name, 'Author')
    END AS author_name,
    CASE 
        WHEN s.is_anonymous THEN NULL 
        ELSE p.avatar_url 
    END AS author_avatar_url,
    COALESCE(s.published_at, s.created_at) AS published_at,
    s.created_at,
    s.views_count,
    COALESCE(like_counts.count, 0)::INTEGER AS likes_count,
    COALESCE(comment_counts.count, 0)::INTEGER AS comments_count
FROM public.stories s
LEFT JOIN public.categories c ON s.category_id = c.id
LEFT JOIN public.profiles p ON s.user_id = p.id
LEFT JOIN (
    SELECT story_id, COUNT(*) AS count 
    FROM public.likes 
    GROUP BY story_id
) like_counts ON s.id = like_counts.story_id
LEFT JOIN (
    SELECT story_id, COUNT(*) AS count 
    FROM public.comments 
    GROUP BY story_id
) comment_counts ON s.id = comment_counts.story_id
WHERE s.status = 'published' AND s.deleted_at IS NULL;

-- LANGKAH 4: Berikan hak akses membaca view kepada anon dan authenticated
GRANT SELECT ON public.public_stories_view TO anon, authenticated;

-- LANGKAH 5: Buat bucket penyimpanan 'story_covers' untuk galeri
INSERT INTO storage.buckets (id, name, public)
VALUES ('story_covers', 'story_covers', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- LANGKAH 6: Kebijakan RLS Penyimpanan
DROP POLICY IF EXISTS "Story covers are publicly viewable" ON storage.objects;
CREATE POLICY "Story covers are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'story_covers');

DROP POLICY IF EXISTS "Story covers insert policy" ON storage.objects;
CREATE POLICY "Story covers insert policy"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'story_covers');

DROP POLICY IF EXISTS "Story covers update policy" ON storage.objects;
CREATE POLICY "Story covers update policy"
ON storage.objects FOR UPDATE
USING (bucket_id = 'story_covers');

DROP POLICY IF EXISTS "Story covers delete policy" ON storage.objects;
CREATE POLICY "Story covers delete policy"
ON storage.objects FOR DELETE
USING (bucket_id = 'story_covers');
