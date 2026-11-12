-- ==========================================================
-- WRITTLE: SUPABASE POSTGRESQL INITIAL DATABASE SCHEMA
-- Ref: docs/DATABASE_AND_API.md & docs/BUSINESS_AND_SYSTEM_DESIGN.md
-- ==========================================================

-- 1. PROFILES TABLE
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  pen_name VARCHAR(32) NOT NULL UNIQUE,
  bio VARCHAR(200),
  avatar_url TEXT,
  role VARCHAR(20) NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin', 'curator')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-create profile on user signup (BR-001) with Google / OAuth metadata support
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  extracted_name TEXT;
  candidate_pen_name TEXT;
  extracted_avatar TEXT;
BEGIN
  -- Extract display name from OAuth provider metadata or custom metadata
  extracted_name := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'user_name',
    NEW.raw_user_meta_data->>'pen_name'
  );

  -- Extract avatar URL from OAuth provider metadata
  extracted_avatar := COALESCE(
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.raw_user_meta_data->>'picture'
  );

  -- If name is present, sanitize and trim to at most 24 characters
  IF extracted_name IS NOT NULL AND TRIM(extracted_name) <> '' THEN
    candidate_pen_name := SUBSTRING(TRIM(extracted_name), 1, 24);

    -- Ensure pen_name is unique by checking existing profiles
    IF EXISTS (SELECT 1 FROM public.profiles WHERE pen_name = candidate_pen_name) THEN
      candidate_pen_name := candidate_pen_name || '_' || SUBSTRING(NEW.id::TEXT, 1, 6);
    END IF;
  ELSE
    candidate_pen_name := 'Author_' || SUBSTRING(NEW.id::TEXT, 1, 6);
  END IF;

  INSERT INTO public.profiles (id, pen_name, avatar_url)
  VALUES (
    NEW.id,
    candidate_pen_name,
    extracted_avatar
  )
  ON CONFLICT (id) DO UPDATE SET
    avatar_url = COALESCE(public.profiles.avatar_url, EXCLUDED.avatar_url);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. CATEGORIES TABLE
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  slug VARCHAR(50) NOT NULL UNIQUE,
  description VARCHAR(255),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed default categories
INSERT INTO public.categories (name, slug, description)
VALUES 
  ('Reflections', 'reflections', 'Introspective thoughts and personal growth'),
  ('Romance', 'romance', 'Love, heartbreak, and emotional encounters'),
  ('Life Lessons', 'life-lessons', 'Experiences that shaped perspectives'),
  ('Fiction', 'fiction', 'Creative storytelling and imaginative prose'),
  ('Confessions', 'confessions', 'Secrets and untold burdens shared safely')
ON CONFLICT (slug) DO NOTHING;

-- 3. STORIES TABLE
CREATE TABLE IF NOT EXISTS public.stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id),
  title VARCHAR(120) NOT NULL,
  content TEXT NOT NULL,
  cover_url TEXT,
  is_anonymous BOOLEAN NOT NULL DEFAULT TRUE,
  status VARCHAR(20) NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived', 'moderated')),
  views_count INTEGER NOT NULL DEFAULT 0,
  published_at TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. COMMENTS TABLE
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content VARCHAR(1000) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure parent_comment_id exists if comments table was created earlier without it
ALTER TABLE public.comments 
ADD COLUMN IF NOT EXISTS parent_comment_id UUID REFERENCES public.comments(id) ON DELETE CASCADE;

-- 5. LIKES TABLE
CREATE TABLE IF NOT EXISTS public.likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_story_like UNIQUE (story_id, user_id)
);

-- 6. BOOKMARKS TABLE
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_story_bookmark UNIQUE (story_id, user_id)
);

-- 6.5 FOLLOWS TABLE (Readers & Following Connections)
CREATE TABLE IF NOT EXISTS public.follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  following_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_user_follow UNIQUE (follower_id, following_id)
);

-- 7. REPORTS TABLE
CREATE TABLE IF NOT EXISTS public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES public.stories(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  reason VARCHAR(50) NOT NULL,
  details VARCHAR(500),
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'dismissed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT unique_story_report UNIQUE (story_id, reporter_id)
);

-- 8. PRIVACY-PRESERVING PUBLIC STORIES VIEW
DROP VIEW IF EXISTS public.public_stories_view CASCADE;
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
    COALESCE((SELECT COUNT(*) FROM public.likes l WHERE l.story_id = s.id), 0)::INT AS likes_count,
    COALESCE((SELECT COUNT(*) FROM public.comments cm WHERE cm.story_id = s.id), 0)::INT AS comments_count
FROM public.stories s
LEFT JOIN public.categories c ON s.category_id = c.id
LEFT JOIN public.profiles p ON s.user_id = p.id
WHERE s.status = 'published' AND s.deleted_at IS NULL;

-- Grant access to public_stories_view so mobile clients (anon & authenticated) can query stories
GRANT SELECT ON public.public_stories_view TO anon, authenticated;

-- ==========================================================
-- 8.5 PERFORMANCE & RLS HIGH-EFFICIENCY INDEXES
-- ==========================================================

-- Story feed pagination, status filtering, and chronological sorting (Partial Compound Index)
CREATE INDEX IF NOT EXISTS idx_stories_status_published_at 
ON public.stories (status, published_at DESC) 
WHERE deleted_at IS NULL;

-- Fast category filtering on active published stories
CREATE INDEX IF NOT EXISTS idx_stories_category_id 
ON public.stories (category_id) 
WHERE status = 'published' AND deleted_at IS NULL;

-- Fast author draft & published story lookups + FK cascade acceleration
CREATE INDEX IF NOT EXISTS idx_stories_user_id 
ON public.stories (user_id);

-- User-specific like checks for batch feed queries (eliminates Seq Scan when checking liked state)
CREATE INDEX IF NOT EXISTS idx_likes_user_id 
ON public.likes (user_id);

-- Keepsakes / Bookmarks feed query acceleration (ordered chronologically)
CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id_created 
ON public.bookmarks (user_id, created_at DESC);

-- Story reader comments retrieval and count acceleration
CREATE INDEX IF NOT EXISTS idx_comments_story_id 
ON public.comments (story_id, created_at ASC);

-- Nested comment reply hierarchy acceleration
CREATE INDEX IF NOT EXISTS idx_comments_parent_id 
ON public.comments (parent_comment_id) 
WHERE parent_comment_id IS NOT NULL;

-- Admin CMS pending reports queue acceleration
CREATE INDEX IF NOT EXISTS idx_reports_status_created 
ON public.reports (status, created_at DESC);

-- Curator & Admin audit trail chronological lookup
CREATE INDEX IF NOT EXISTS idx_curator_audit_logs_created 
ON public.curator_audit_logs (created_at DESC);

-- ==========================================================
-- 9. ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Public profiles are viewable by everyone" 
ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" 
ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Categories Policies
CREATE POLICY "Categories are readable by everyone" 
ON public.categories FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert categories" 
ON public.categories FOR INSERT 
WITH CHECK (auth.role() = 'authenticated');

-- Stories Policies
CREATE POLICY "Published stories are viewable by everyone" 
ON public.stories FOR SELECT 
USING (status = 'published' AND deleted_at IS NULL);

CREATE POLICY "Users can view their own drafts and archived stories" 
ON public.stories FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own stories" 
ON public.stories FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own stories" 
ON public.stories FOR UPDATE 
USING (auth.uid() = user_id);

-- Comments Policies
CREATE POLICY "Comments on published stories are readable by everyone" 
ON public.comments FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.stories 
    WHERE stories.id = comments.story_id 
    AND stories.status = 'published' 
    AND stories.deleted_at IS NULL
  )
);

CREATE POLICY "Authenticated users can create comments" 
ON public.comments FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments or comments on their stories" 
ON public.comments FOR DELETE 
USING (
  auth.uid() = user_id 
  OR EXISTS (
    SELECT 1 FROM public.stories 
    WHERE stories.id = comments.story_id 
    AND stories.user_id = auth.uid()
  )
);

-- Likes Policies
CREATE POLICY "Users can read likes" 
ON public.likes FOR SELECT 
USING (true);

CREATE POLICY "Authenticated users can toggle like" 
ON public.likes FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own like" 
ON public.likes FOR DELETE 
USING (auth.uid() = user_id);

-- Bookmarks Policies
CREATE POLICY "Users can only see their own bookmarks" 
ON public.bookmarks FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own bookmark" 
ON public.bookmarks FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own bookmark" 
ON public.bookmarks FOR DELETE 
USING (auth.uid() = user_id);

-- Follows Policies (Readers & Following)
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

-- Reports Policies
CREATE POLICY "Authenticated users can submit a report" 
ON public.reports FOR INSERT 
WITH CHECK (auth.uid() = reporter_id);

-- ==========================================================
-- 9.5 ADMIN & CURATOR ROLE POLICIES & RPCs (RBAC)
-- ==========================================================

-- Check if current user is platform super-admin (role = 'admin')
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current user is admin or curator
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role IN ('admin', 'curator')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Profiles: Admins can update any user profile (appoint/demote curators)
DROP POLICY IF EXISTS "Admins can update all profiles" ON public.profiles;
CREATE POLICY "Admins can update all profiles"
ON public.profiles FOR UPDATE
USING (public.is_platform_admin() OR auth.uid() = id);

-- Categories: Admins can update and delete categories
DROP POLICY IF EXISTS "Admins can update categories" ON public.categories;
CREATE POLICY "Admins can update categories" 
ON public.categories FOR UPDATE USING (public.is_admin());

DROP POLICY IF EXISTS "Admins can delete categories" ON public.categories;
CREATE POLICY "Admins can delete categories" 
ON public.categories FOR DELETE USING (public.is_admin());

-- Stories: Admins and Curators can view all stories (including moderated) and update status
DROP POLICY IF EXISTS "Admins can view all stories" ON public.stories;
CREATE POLICY "Admins can view all stories" 
ON public.stories FOR SELECT USING (public.is_admin() OR status = 'published' OR auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can update any story status" ON public.stories;
CREATE POLICY "Admins can update any story status" 
ON public.stories FOR UPDATE USING (public.is_admin() OR auth.uid() = user_id);

-- Reports: Admins and Curators can view reports; reporters can view their own submitted reports
DROP POLICY IF EXISTS "Admins can view reports" ON public.reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON public.reports;
CREATE POLICY "Admins and reporters can view reports" 
ON public.reports FOR SELECT USING (public.is_admin() OR auth.uid() = reporter_id);

DROP POLICY IF EXISTS "Admins can update report status" ON public.reports;
CREATE POLICY "Admins can update report status" 
ON public.reports FOR UPDATE USING (public.is_admin());

-- Dedicated RPC: set user role (Guaranteed to bypass client RLS issues for platform admins)
CREATE OR REPLACE FUNCTION public.set_user_role(target_user_id UUID, target_role VARCHAR)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role <> 'admin' THEN
    RAISE EXCEPTION 'Only platform administrators can alter user roles.';
  END IF;

  IF target_role NOT IN ('user', 'curator', 'admin') THEN
    RAISE EXCEPTION 'Invalid role: %', target_role;
  END IF;

  UPDATE public.profiles
  SET role = target_role, updated_at = NOW()
  WHERE id = target_user_id;

  RETURN jsonb_build_object('success', true, 'user_id', target_user_id, 'new_role', target_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dedicated RPC: moderate story (Guaranteed to work for curators & admins)
CREATE OR REPLACE FUNCTION public.moderate_story_admin(target_story_id UUID, new_status VARCHAR)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can moderate tales.';
  END IF;

  IF new_status NOT IN ('published', 'moderated', 'archived', 'draft') THEN
    RAISE EXCEPTION 'Invalid story status: %', new_status;
  END IF;

  UPDATE public.stories
  SET status = new_status, updated_at = NOW()
  WHERE id = target_story_id;

  RETURN jsonb_build_object('success', true, 'story_id', target_story_id, 'new_status', new_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dedicated RPC: update report status (Guaranteed to work for curators & admins)
CREATE OR REPLACE FUNCTION public.update_report_status_admin(target_report_id UUID, new_status VARCHAR)
RETURNS JSONB AS $$
DECLARE
  caller_role TEXT;
BEGIN
  SELECT role INTO caller_role FROM public.profiles WHERE id = auth.uid();
  IF caller_role NOT IN ('admin', 'curator') THEN
    RAISE EXCEPTION 'Only curators and administrators can review reports.';
  END IF;

  UPDATE public.reports
  SET status = new_status
  WHERE id = target_report_id;

  RETURN jsonb_build_object('success', true, 'report_id', target_report_id, 'new_status', new_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Dedicated RPC: soft delete story (Guaranteed to work for curators & admins)
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

-- Dedicated RPC: restore story (Curators & Admins)
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

-- Dedicated RPC: permanently purge story (Curators & Admins)
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

-- Dedicated RPC: clean up expired stories past 14-day retention period
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

-- Dedicated RPC: record audit log (Guaranteed to work for curators & admins)
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

-- ==========================================================
-- 9.6 CURATOR AUDIT LOGS & SUPERVISION (AUDIT TRAIL)
-- ==========================================================

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

ALTER TABLE public.curator_audit_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admins and Curators can insert audit logs" ON public.curator_audit_logs;
CREATE POLICY "Admins and Curators can insert audit logs" 
ON public.curator_audit_logs FOR INSERT 
WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "Admins and Curators can view audit logs" ON public.curator_audit_logs;
CREATE POLICY "Admins and Curators can view audit logs" 
ON public.curator_audit_logs FOR SELECT 
USING (public.is_admin());

-- ==========================================================
-- 10. ROLE GRANTS (Required for Supabase RLS to operate)
-- ==========================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO anon, authenticated;

-- ==========================================================
-- 11. STORAGE BUCKET: STORY COVERS (Upload from Local Gallery)
-- ==========================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('story_covers', 'story_covers', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Story covers are publicly viewable" ON storage.objects;
CREATE POLICY "Story covers are publicly viewable"
ON storage.objects FOR SELECT
USING (bucket_id = 'story_covers');

DROP POLICY IF EXISTS "Authenticated users can upload story covers" ON storage.objects;
CREATE POLICY "Authenticated users can upload story covers"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'story_covers' AND auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their story covers" ON storage.objects;
CREATE POLICY "Users can update their story covers"
ON storage.objects FOR UPDATE
USING (bucket_id = 'story_covers' AND auth.uid() = owner);

DROP POLICY IF EXISTS "Users can delete their story covers" ON storage.objects;
CREATE POLICY "Users can delete their story covers"
ON storage.objects FOR DELETE
USING (bucket_id = 'story_covers' AND auth.uid() = owner);

-- ==========================================================
-- 12. REALTIME REPLICATION (Required for live Admin CMS, Notifications, Feeds)
-- ==========================================================

ALTER TABLE public.reports REPLICA IDENTITY FULL;
ALTER TABLE public.stories REPLICA IDENTITY FULL;
ALTER TABLE public.likes REPLICA IDENTITY FULL;
ALTER TABLE public.comments REPLICA IDENTITY FULL;
ALTER TABLE public.curator_audit_logs REPLICA IDENTITY FULL;
ALTER TABLE public.follows REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'reports'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reports;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'stories'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.stories;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'likes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.likes;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'comments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.comments;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'curator_audit_logs'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.curator_audit_logs;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'follows'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.follows;
  END IF;
END $$;

-- ==========================================================
-- 13. PLATFORM CONFIGURATION (App settings, dynamic homepage ethos)
-- ==========================================================
CREATE TABLE IF NOT EXISTS public.platform_config (
  key VARCHAR(64) PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.platform_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can view platform_config" ON public.platform_config;
CREATE POLICY "Public can view platform_config" ON public.platform_config
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "Admins can update platform_config" ON public.platform_config;
CREATE POLICY "Admins can update platform_config" ON public.platform_config
  FOR ALL USING (public.is_platform_admin());




