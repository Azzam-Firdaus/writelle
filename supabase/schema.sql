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
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-create profile on user signup (BR-001)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, pen_name)
  VALUES (
    NEW.id,
    'Author_' || SUBSTRING(NEW.id::TEXT, 1, 6)
  )
  ON CONFLICT (id) DO NOTHING;
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
  content VARCHAR(1000) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

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
CREATE OR REPLACE VIEW public.public_stories_view AS
SELECT 
    s.id,
    s.category_id,
    c.name AS category_name,
    c.slug AS category_slug,
    s.title,
    s.content,
    s.is_anonymous,
    CASE 
        WHEN s.is_anonymous THEN 'Anonymous' 
        ELSE p.pen_name 
    END AS author_name,
    CASE 
        WHEN s.is_anonymous THEN NULL 
        ELSE p.avatar_url 
    END AS author_avatar_url,
    s.published_at,
    s.created_at,
    s.views_count,
    COALESCE(like_counts.count, 0)::INT AS likes_count,
    COALESCE(comment_counts.count, 0)::INT AS comments_count
FROM public.stories s
JOIN public.categories c ON s.category_id = c.id
LEFT JOIN public.profiles p ON s.user_id = p.id
LEFT JOIN (
    SELECT story_id, COUNT(*) AS count FROM public.likes GROUP BY story_id
) like_counts ON s.id = like_counts.story_id
LEFT JOIN (
    SELECT story_id, COUNT(*) AS count FROM public.comments GROUP BY story_id
) comment_counts ON s.id = comment_counts.story_id
WHERE s.status = 'published' AND s.deleted_at IS NULL;

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

-- Reports Policies
CREATE POLICY "Authenticated users can submit a report" 
ON public.reports FOR INSERT 
WITH CHECK (auth.uid() = reporter_id);
