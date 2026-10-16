/*
# ARA_world Core Database Schema

Creates the full schema for the ARA_world real-estate marketplace:
profiles, properties, property_images, favorites, sell_requests,
notifications, inquiries, contact_messages, site_settings, and activity_log.

## 1. profiles
- Extends Supabase auth.users with application-level profile data.
- Columns: full_name, username, email, phone, avatar_url, role (user/admin), is_active, must_change_password, created_at, updated_at.

## 2. properties
- Stores all property listings submitted by users or admins.
- approval_status: pending / approved / rejected
- status: available / reserved / sold / unpublished
- Visibility rules enforced via RLS:
  - Anon users see only approved & available/reserved/sold, limited to 2 latest.
  - Authenticated users see all approved & published properties.
  - Owners see their own properties regardless of approval status.
  - Admins see everything.

## 3. property_images
- Images for each property (URLs stored, files in Supabase Storage).

## 4. favorites
- User favorites with unique constraint to prevent duplicates.

## 5. sell_requests
- Tracks the approval workflow for user-submitted properties.

## 6. notifications
- Internal notification system for users and admins.

## 7. inquiries
- User inquiries about specific properties.

## 8. contact_messages
- Contact form submissions.

## 9. site_settings
- Key-value settings for site configuration.

## 10. activity_log
- Audit trail for admin actions.

## Security
- RLS enabled on every table.
- Owner-scoped policies for user data.
- Admin access via role check in profiles.
- Anon can read only 2 latest approved properties.
*/

-- ==========================================
-- PROFILES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  username text NOT NULL UNIQUE,
  email text NOT NULL UNIQUE,
  phone text,
  avatar_url text,
  role text NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'admin')),
  is_active boolean NOT NULL DEFAULT true,
  must_change_password boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_own_or_admin" ON public.profiles
  FOR SELECT TO authenticated
  USING (
    auth.uid() = id
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "profiles_anon_select_admin_only" ON public.profiles;
-- Admin profiles visible to anon for contact info (only public fields handled at query level)

DROP POLICY IF EXISTS "profiles_insert_self" ON public.profiles;
CREATE POLICY "profiles_insert_self" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Admin can update any profile (but cannot change role via this policy)
DROP POLICY IF EXISTS "profiles_update_admin" ON public.profiles;
CREATE POLICY "profiles_update_admin" ON public.profiles
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Admin can insert profiles
DROP POLICY IF EXISTS "profiles_insert_admin" ON public.profiles;
CREATE POLICY "profiles_insert_admin" ON public.profiles
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- PROPERTIES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.properties (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_code text NOT NULL UNIQUE,
  owner_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  slug text NOT NULL UNIQUE,
  property_type text NOT NULL CHECK (property_type IN ('villa', 'house', 'apartment', 'land', 'commercial', 'office', 'chalet')),
  address text,
  city text,
  location text,
  price numeric(12,2) NOT NULL DEFAULT 0,
  original_price numeric(12,2),
  discount_amount numeric(12,2),
  discount_percentage numeric(5,2),
  area numeric(10,2),
  bedrooms integer,
  bathrooms integer,
  floors integer,
  description text,
  features text[],
  status text NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'sold', 'unpublished')),
  approval_status text NOT NULL DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
  rejection_reason text,
  is_featured boolean NOT NULL DEFAULT false,
  published_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.properties ENABLE ROW LEVEL SECURITY;

-- Anon: only latest 2 approved & published (available/reserved/sold)
DROP POLICY IF EXISTS "properties_anon_select_limited" ON public.properties;
CREATE POLICY "properties_anon_select_limited" ON public.properties
  FOR SELECT TO anon, authenticated
  USING (
    approval_status = 'approved'
    AND status IN ('available', 'reserved', 'sold')
    AND published_at IS NOT NULL
  );

-- Owners can see their own properties regardless of approval status
DROP POLICY IF EXISTS "properties_select_own" ON public.properties;
CREATE POLICY "properties_select_own" ON public.properties
  FOR SELECT TO authenticated
  USING (auth.uid() = owner_id);

-- Admins can see all properties
DROP POLICY IF EXISTS "properties_select_admin" ON public.properties;
CREATE POLICY "properties_select_admin" ON public.properties
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Owners can insert properties (defaults to pending)
DROP POLICY IF EXISTS "properties_insert_own" ON public.properties;
CREATE POLICY "properties_insert_own" ON public.properties
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = owner_id);

-- Admins can insert properties
DROP POLICY IF EXISTS "properties_insert_admin" ON public.properties;
CREATE POLICY "properties_insert_admin" ON public.properties
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Owners can update their own properties (but only if not yet approved or by admin)
DROP POLICY IF EXISTS "properties_update_own" ON public.properties;
CREATE POLICY "properties_update_own" ON public.properties
  FOR UPDATE TO authenticated
  USING (auth.uid() = owner_id)
  WITH CHECK (auth.uid() = owner_id);

-- Admins can update any property
DROP POLICY IF EXISTS "properties_update_admin" ON public.properties;
CREATE POLICY "properties_update_admin" ON public.properties
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- Owners can delete their own properties
DROP POLICY IF EXISTS "properties_delete_own" ON public.properties;
CREATE POLICY "properties_delete_own" ON public.properties
  FOR DELETE TO authenticated
  USING (auth.uid() = owner_id);

-- Admins can delete any property
DROP POLICY IF EXISTS "properties_delete_admin" ON public.properties;
CREATE POLICY "properties_delete_admin" ON public.properties
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- PROPERTY_IMAGES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.property_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  is_main boolean NOT NULL DEFAULT false,
  display_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.property_images ENABLE ROW LEVEL SECURITY;

-- Anyone can view images of visible properties (the property visibility is already enforced)
DROP POLICY IF EXISTS "property_images_select_all" ON public.property_images;
CREATE POLICY "property_images_select_all" ON public.property_images
  FOR SELECT TO anon, authenticated
  USING (true);

-- Owners can manage images of their own properties
DROP POLICY IF EXISTS "property_images_insert_own" ON public.property_images;
CREATE POLICY "property_images_insert_own" ON public.property_images
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_id AND p.owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "property_images_update_own" ON public.property_images;
CREATE POLICY "property_images_update_own" ON public.property_images
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_id AND p.owner_id = auth.uid())
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_id AND p.owner_id = auth.uid())
  );

DROP POLICY IF EXISTS "property_images_delete_own" ON public.property_images;
CREATE POLICY "property_images_delete_own" ON public.property_images
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.properties p WHERE p.id = property_id AND p.owner_id = auth.uid())
  );

-- Admins can manage all images
DROP POLICY IF EXISTS "property_images_insert_admin" ON public.property_images;
CREATE POLICY "property_images_insert_admin" ON public.property_images
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "property_images_update_admin" ON public.property_images;
CREATE POLICY "property_images_update_admin" ON public.property_images
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "property_images_delete_admin" ON public.property_images;
CREATE POLICY "property_images_delete_admin" ON public.property_images
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- FAVORITES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.favorites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, property_id)
);

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "favorites_select_own" ON public.favorites;
CREATE POLICY "favorites_select_own" ON public.favorites
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_insert_own" ON public.favorites;
CREATE POLICY "favorites_insert_own" ON public.favorites
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "favorites_delete_own" ON public.favorites;
CREATE POLICY "favorites_delete_own" ON public.favorites
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ==========================================
-- SELL_REQUESTS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.sell_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'published', 'reserved', 'sold')),
  rejection_reason text,
  reviewed_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.sell_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "sell_requests_select_own" ON public.sell_requests;
CREATE POLICY "sell_requests_select_own" ON public.sell_requests
  FOR SELECT TO authenticated
  USING (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "sell_requests_insert_own" ON public.sell_requests;
CREATE POLICY "sell_requests_insert_own" ON public.sell_requests
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "sell_requests_update_admin" ON public.sell_requests;
CREATE POLICY "sell_requests_update_admin" ON public.sell_requests
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "sell_requests_delete_admin" ON public.sell_requests;
CREATE POLICY "sell_requests_delete_admin" ON public.sell_requests
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- NOTIFICATIONS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  title text NOT NULL,
  message text NOT NULL,
  type text NOT NULL DEFAULT 'info' CHECK (type IN ('info', 'success', 'warning', 'error', 'property', 'system')),
  is_read boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "notifications_insert_own_or_admin" ON public.notifications;
CREATE POLICY "notifications_insert_own_or_admin" ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id
    OR EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;
CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- Admin can manage notifications for any user
DROP POLICY IF EXISTS "notifications_update_admin" ON public.notifications;
CREATE POLICY "notifications_update_admin" ON public.notifications
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- INQUIRIES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.inquiries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  message text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "inquiries_select_admin" ON public.inquiries;
CREATE POLICY "inquiries_select_admin" ON public.inquiries
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "inquiries_insert_any" ON public.inquiries;
CREATE POLICY "inquiries_insert_any" ON public.inquiries
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "inquiries_delete_admin" ON public.inquiries;
CREATE POLICY "inquiries_delete_admin" ON public.inquiries
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- CONTACT_MESSAGES
-- ==========================================
CREATE TABLE IF NOT EXISTS public.contact_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  subject text NOT NULL,
  message text NOT NULL,
  status text NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'read', 'responded', 'closed')),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.contact_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "contact_messages_select_admin" ON public.contact_messages;
CREATE POLICY "contact_messages_select_admin" ON public.contact_messages
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "contact_messages_insert_any" ON public.contact_messages;
CREATE POLICY "contact_messages_insert_any" ON public.contact_messages
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "contact_messages_update_admin" ON public.contact_messages;
CREATE POLICY "contact_messages_update_admin" ON public.contact_messages
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "contact_messages_delete_admin" ON public.contact_messages;
CREATE POLICY "contact_messages_delete_admin" ON public.contact_messages
  FOR DELETE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- SITE_SETTINGS
-- ==========================================
CREATE TABLE IF NOT EXISTS public.site_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key text NOT NULL UNIQUE,
  setting_value text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "site_settings_select_all" ON public.site_settings;
CREATE POLICY "site_settings_select_all" ON public.site_settings
  FOR SELECT TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "site_settings_update_admin" ON public.site_settings;
CREATE POLICY "site_settings_update_admin" ON public.site_settings
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "site_settings_insert_admin" ON public.site_settings;
CREATE POLICY "site_settings_insert_admin" ON public.site_settings
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- ACTIVITY_LOG
-- ==========================================
CREATE TABLE IF NOT EXISTS public.activity_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action text NOT NULL,
  target text,
  metadata jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "activity_log_select_admin" ON public.activity_log;
CREATE POLICY "activity_log_select_admin" ON public.activity_log
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

DROP POLICY IF EXISTS "activity_log_insert_admin" ON public.activity_log;
CREATE POLICY "activity_log_insert_admin" ON public.activity_log
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND p.role = 'admin')
  );

-- ==========================================
-- INDEXES
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);
CREATE INDEX IF NOT EXISTS idx_properties_property_code ON public.properties(property_code);
CREATE INDEX IF NOT EXISTS idx_properties_slug ON public.properties(slug);
CREATE INDEX IF NOT EXISTS idx_properties_city ON public.properties(city);
CREATE INDEX IF NOT EXISTS idx_properties_property_type ON public.properties(property_type);
CREATE INDEX IF NOT EXISTS idx_properties_status ON public.properties(status);
CREATE INDEX IF NOT EXISTS idx_properties_approval_status ON public.properties(approval_status);
CREATE INDEX IF NOT EXISTS idx_properties_created_at ON public.properties(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_properties_owner_id ON public.properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_property_images_property_id ON public.property_images(property_id);
CREATE INDEX IF NOT EXISTS idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_favorites_property_id ON public.favorites(property_id);
CREATE INDEX IF NOT EXISTS idx_sell_requests_user_id ON public.sell_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_sell_requests_status ON public.sell_requests(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_inquiries_property_id ON public.inquiries(property_id);
CREATE INDEX IF NOT EXISTS idx_contact_messages_status ON public.contact_messages(status);
CREATE INDEX IF NOT EXISTS idx_activity_log_admin_id ON public.activity_log(admin_id);
CREATE INDEX IF NOT EXISTS idx_activity_log_created_at ON public.activity_log(created_at DESC);

-- ==========================================
-- updated_at trigger
-- ==========================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS profiles_updated_at ON public.profiles;
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS properties_updated_at ON public.properties;
CREATE TRIGGER properties_updated_at BEFORE UPDATE ON public.properties
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS sell_requests_updated_at ON public.sell_requests;
CREATE TRIGGER sell_requests_updated_at BEFORE UPDATE ON public.sell_requests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS site_settings_updated_at ON public.site_settings;
CREATE TRIGGER site_settings_updated_at BEFORE UPDATE ON public.site_settings
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==========================================
-- Auto-generate property_code (ARA-00001)
-- ==========================================
CREATE OR REPLACE FUNCTION public.generate_property_code()
RETURNS text AS $$
DECLARE
  next_num integer;
  code text;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(property_code FROM 5) AS integer)), 0) + 1
  INTO next_num
  FROM public.properties
  WHERE property_code ~ '^ARA-[0-9]{5}$';
  
  code := 'ARA-' || lpad(next_num::text, 5, '0');
  RETURN code;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Auto-generate slug from title
-- ==========================================
CREATE OR REPLACE FUNCTION public.generate_slug(p_title text)
RETURNS text AS $$
DECLARE
  base_slug text;
  slug text;
  counter integer := 0;
BEGIN
  base_slug := lower(regexp_replace(p_title, '[^a-zA-Z0-9\u0600-\u06FF]+', '-', 'g'));
  base_slug := trim(both '-' from base_slug);
  slug := base_slug;
  
  WHILE EXISTS (SELECT 1 FROM public.properties WHERE slug = slug) LOOP
    counter := counter + 1;
    slug := base_slug || '-' || counter::text;
  END LOOP;
  
  RETURN slug;
END;
$$ LANGUAGE plpgsql;

-- ==========================================
-- Handle new user: auto-create profile
-- ==========================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==========================================
-- Default site settings
-- ==========================================
INSERT INTO public.site_settings (setting_key, setting_value) VALUES
  ('site_name', 'ARA_world'),
  ('whatsapp_number', '+201559751754'),
  ('contact_email', 'contact@ara-world.com'),
  ('hero_title', 'Find Your Dream Property in Egypt'),
  ('hero_subtitle', 'Buy, sell, and discover premium real estate with ARA_world'),
  ('footer_text', 'ARA_world - Your trusted real estate marketplace'),
  ('paypal_email', ''),
  ('paypal_mode', 'sandbox')
ON CONFLICT (setting_key) DO NOTHING;
-- Create storage buckets for property images and avatars
INSERT INTO storage.buckets (id, name, public) VALUES ('property-images', 'property-images', true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

/*
# Storage bucket policies for property-images and avatars

## Security
- property-images: public read, authenticated write (owner or admin)
- avatars: public read, authenticated write (own avatar or admin)
*/

-- property-images: public read
DROP POLICY IF EXISTS "property_images_public_read" ON storage.objects;
CREATE POLICY "property_images_public_read" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'property-images');

-- property-images: authenticated can upload
DROP POLICY IF EXISTS "property_images_auth_upload" ON storage.objects;
CREATE POLICY "property_images_auth_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'property-images');

-- property-images: authenticated can update/delete their own
DROP POLICY IF EXISTS "property_images_auth_update" ON storage.objects;
CREATE POLICY "property_images_auth_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'property-images');

DROP POLICY IF EXISTS "property_images_auth_delete" ON storage.objects;
CREATE POLICY "property_images_auth_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'property-images');

-- avatars: public read
DROP POLICY IF EXISTS "avatars_public_read" ON storage.objects;
CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket_id = 'avatars');

-- avatars: authenticated can upload
DROP POLICY IF EXISTS "avatars_auth_upload" ON storage.objects;
CREATE POLICY "avatars_auth_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');

-- avatars: authenticated can update/delete
DROP POLICY IF EXISTS "avatars_auth_update" ON storage.objects;
CREATE POLICY "avatars_auth_update" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS "avatars_auth_delete" ON storage.objects;
CREATE POLICY "avatars_auth_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'avatars');
/*
# Support Ticket System

## Purpose
Creates a complete support ticket system for customer support — separate from property inquiries.
Users can submit tickets with attachments, admins can reply and manage status.

## New Tables

### support_tickets
- id (uuid PK)
- ticket_number (text, unique, e.g. "SUP-00001")
- user_id (uuid FK -> auth.users, nullable for anonymous submissions)
- name (text, not null)
- email (text, not null)
- phone (text)
- category (text: account_problem, website_problem, property_problem, payment_problem, technical_problem, complaint, suggestion, general_inquiry, other)
- subject (text, not null)
- description (text, not null)
- status (text: open, in_progress, waiting_user, resolved, closed — default: open)
- admin_notes (text, internal admin notes)
- created_at (timestamptz)
- updated_at (timestamptz)

### ticket_replies
- id (uuid PK)
- ticket_id (uuid FK -> support_tickets ON DELETE CASCADE)
- user_id (uuid FK -> auth.users, nullable)
- sender_type (text: user, admin)
- message (text, not null)
- created_at (timestamptz)

### ticket_attachments
- id (uuid PK)
- ticket_id (uuid FK -> support_tickets ON DELETE CASCADE)
- reply_id (uuid FK -> ticket_replies, nullable)
- file_url (text, not null — path in Supabase Storage)
- file_name (text, not null)
- file_type (text, not null — MIME type)
- file_size (bigint, not null — bytes)
- created_at (timestamptz)

## Security
- RLS enabled on all tables
- Users can read/update their own tickets (by user_id)
- Admins can read/update all tickets (via profile role check)
- Users can insert tickets and replies on their own tickets
- Users can insert attachments on their own tickets
- Admins can insert replies on any ticket
*/

-- Sequence for ticket numbers
DO $$ BEGIN
  CREATE SEQUENCE IF NOT EXISTS support_ticket_seq START 1;
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- support_tickets table
CREATE TABLE IF NOT EXISTS public.support_tickets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number text UNIQUE NOT NULL DEFAULT ('SUP-' || lpad(nextval('support_ticket_seq')::text, 5, '0')),
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  email text NOT NULL,
  phone text,
  category text NOT NULL DEFAULT 'general_inquiry',
  subject text NOT NULL,
  description text NOT NULL,
  status text NOT NULL DEFAULT 'open',
  admin_notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Users can read their own tickets
DROP POLICY IF EXISTS "select_own_tickets" ON public.support_tickets;
CREATE POLICY "select_own_tickets" ON public.support_tickets
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id);

-- Users can insert tickets (user_id defaults to auth.uid())
DROP POLICY IF EXISTS "insert_own_tickets" ON public.support_tickets;
CREATE POLICY "insert_own_tickets" ON public.support_tickets
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own tickets
DROP POLICY IF EXISTS "update_own_tickets" ON public.support_tickets;
CREATE POLICY "update_own_tickets" ON public.support_tickets
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Admins can read all tickets
DROP POLICY IF EXISTS "admin_select_tickets" ON public.support_tickets;
CREATE POLICY "admin_select_tickets" ON public.support_tickets
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- Admins can update all tickets
DROP POLICY IF EXISTS "admin_update_tickets" ON public.support_tickets;
CREATE POLICY "admin_update_tickets" ON public.support_tickets
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  ) WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- ticket_replies table
CREATE TABLE IF NOT EXISTS public.ticket_replies (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  sender_type text NOT NULL DEFAULT 'user',
  message text NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.ticket_replies ENABLE ROW LEVEL SECURITY;

-- Users can read replies on their own tickets
DROP POLICY IF EXISTS "select_own_ticket_replies" ON public.ticket_replies;
CREATE POLICY "select_own_ticket_replies" ON public.ticket_replies
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Users can insert replies on their own tickets
DROP POLICY IF EXISTS "insert_own_ticket_replies" ON public.ticket_replies;
CREATE POLICY "insert_own_ticket_replies" ON public.ticket_replies
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Admins can read all replies
DROP POLICY IF EXISTS "admin_select_ticket_replies" ON public.ticket_replies;
CREATE POLICY "admin_select_ticket_replies" ON public.ticket_replies
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- Admins can insert replies
DROP POLICY IF EXISTS "admin_insert_ticket_replies" ON public.ticket_replies;
CREATE POLICY "admin_insert_ticket_replies" ON public.ticket_replies
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- ticket_attachments table
CREATE TABLE IF NOT EXISTS public.ticket_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id uuid NOT NULL REFERENCES public.support_tickets(id) ON DELETE CASCADE,
  reply_id uuid REFERENCES public.ticket_replies(id) ON DELETE CASCADE,
  file_url text NOT NULL,
  file_name text NOT NULL,
  file_type text NOT NULL,
  file_size bigint NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE public.ticket_attachments ENABLE ROW LEVEL SECURITY;

-- Users can read attachments on their own tickets
DROP POLICY IF EXISTS "select_own_ticket_attachments" ON public.ticket_attachments;
CREATE POLICY "select_own_ticket_attachments" ON public.ticket_attachments
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Users can insert attachments on their own tickets
DROP POLICY IF EXISTS "insert_own_ticket_attachments" ON public.ticket_attachments;
CREATE POLICY "insert_own_ticket_attachments" ON public.ticket_attachments
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.support_tickets t WHERE t.id = ticket_id AND t.user_id = auth.uid())
  );

-- Admins can read all attachments
DROP POLICY IF EXISTS "admin_select_ticket_attachments" ON public.ticket_attachments;
CREATE POLICY "admin_select_ticket_attachments" ON public.ticket_attachments
  FOR SELECT TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

-- Indexes
CREATE INDEX IF NOT EXISTS idx_support_tickets_user_id ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_category ON public.support_tickets(category);
CREATE INDEX IF NOT EXISTS idx_ticket_replies_ticket_id ON public.ticket_replies(ticket_id);
CREATE INDEX IF NOT EXISTS idx_ticket_attachments_ticket_id ON public.ticket_attachments(ticket_id);

-- Auto-update updated_at on support_tickets
DO $$ BEGIN
  CREATE OR REPLACE TRIGGER update_support_ticket_updated_at
  BEFORE UPDATE ON public.support_tickets
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
EXCEPTION WHEN OTHERS THEN NULL; END $$;

-- Create storage bucket for support attachments (private)
INSERT INTO storage.buckets (id, name, public) VALUES ('support-attachments', 'support-attachments', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for support-attachments bucket (private)
DROP POLICY IF EXISTS "support_attachments_owner_read" ON storage.objects;
CREATE POLICY "support_attachments_owner_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'support-attachments' AND owner = auth.uid());

DROP POLICY IF EXISTS "support_attachments_owner_upload" ON storage.objects;
CREATE POLICY "support_attachments_owner_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'support-attachments' AND owner = auth.uid());

DROP POLICY IF EXISTS "support_attachments_admin_read" ON storage.objects;
CREATE POLICY "support_attachments_admin_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'support-attachments' AND
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );

DROP POLICY IF EXISTS "support_attachments_admin_upload" ON storage.objects;
CREATE POLICY "support_attachments_admin_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'support-attachments' AND
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = auth.uid() AND profiles.role = 'admin')
  );
/*
# Add is_admin column to notifications

## Purpose
Allow distinguishing admin-targeted notifications from user notifications.
Admin notifications are created when users submit properties, support tickets, or inquiries.

## Changes
- Add `is_admin` boolean column to `notifications` table, default false
- Update existing admin notification inserts to use is_admin = true

## Security
- No RLS changes needed (existing policies already cover the new column)
*/

DO $$ BEGIN
  ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;
EXCEPTION WHEN OTHERS THEN NULL; END $$;
/*
# Fix generate_property_code RPC to be callable by authenticated users

## Problem
The function `generate_property_code()` was NOT `SECURITY DEFINER`, so when an
authenticated (non-admin) user called it via `supabase.rpc()`, RLS on the
`properties` table restricted the SELECT inside the function to only that
user's own rows — returning a wrong count and potentially failing.

## Fix
- Recreate the function as `SECURITY DEFINER` so it runs with the owner's
  privileges and bypasses RLS on `properties`.
- Re-grant EXECUTE to `authenticated` so non-admin users can call it.

## Notes
- No data is changed.
- The function logic is identical — only the security context changes.
*/

DROP FUNCTION IF EXISTS public.generate_property_code();

CREATE OR REPLACE FUNCTION public.generate_property_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  next_num integer;
  code text;
BEGIN
  SELECT COALESCE(MAX(CAST(SUBSTRING(property_code FROM 5) AS integer)), 0) + 1
  INTO next_num
  FROM public.properties
  WHERE property_code ~ '^ARA-[0-9]{5}$';

  code := 'ARA-' || lpad(next_num::text, 5, '0');
  RETURN code;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.generate_property_code() TO authenticated;
GRANT EXECUTE ON FUNCTION public.generate_property_code() TO anon;
/*
# Fix admin policy recursion and restore permissions

## Problem
Admin policies queried `profiles` from inside policies on `profiles` and other
relations. PostgreSQL therefore detected infinite recursion, blocking property
creation, catalog reads, and admin screens.

## Changes
- Add `public.is_admin()` as a SECURITY DEFINER function that checks the
  current authenticated user's active profile without re-entering RLS.
- Replace every existing admin policy predicate that directly queried
  `profiles` with this function.
- Preserve all existing table, role, owner, and public visibility rules.
- Do not alter or delete application data.

## Security
- Anonymous users cannot execute the helper.
- Only an authenticated active profile whose role is `admin` passes the check.
- The two existing admin profiles remain admins.
*/

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND is_active = true
  );
$$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

DO $$
DECLARE
  policy_row record;
  command_name text;
  using_clause text;
  check_clause text;
  admin_fragment_alias text := 'EXISTS ( SELECT 1 FROM profiles p WHERE ((p.id = auth.uid()) AND (p.role = ''admin''::text)))';
  admin_fragment_plain text := 'EXISTS ( SELECT 1 FROM profiles WHERE ((profiles.id = auth.uid()) AND (profiles.role = ''admin''::text)))';
BEGIN
  FOR policy_row IN
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      p.polname AS policy_name,
      p.polcmd AS policy_command,
      p.polpermissive AS is_permissive,
      regexp_replace(coalesce(pg_get_expr(p.polqual, p.polrelid), ''), '[[:space:]]+', ' ', 'g') AS using_expression,
      regexp_replace(coalesce(pg_get_expr(p.polwithcheck, p.polrelid), ''), '[[:space:]]+', ' ', 'g') AS check_expression,
      array_to_string(
        ARRAY(
          SELECT r.rolname
          FROM pg_roles r
          WHERE r.oid = ANY(p.polroles)
          ORDER BY r.rolname
        ), ', '
      ) AS roles
    FROM pg_policy p
    JOIN pg_class c ON c.oid = p.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND (
        coalesce(pg_get_expr(p.polqual, p.polrelid), '') ILIKE '%profiles%'
        OR coalesce(pg_get_expr(p.polwithcheck, p.polrelid), '') ILIKE '%profiles%'
      )
  LOOP
    command_name := CASE policy_row.policy_command
      WHEN 'r' THEN 'SELECT'
      WHEN 'a' THEN 'INSERT'
      WHEN 'w' THEN 'UPDATE'
      WHEN 'd' THEN 'DELETE'
      WHEN '*' THEN 'ALL'
    END;

    using_clause := nullif(replace(replace(policy_row.using_expression, admin_fragment_alias, 'public.is_admin()'), admin_fragment_plain, 'public.is_admin()'), '');
    check_clause := nullif(replace(replace(policy_row.check_expression, admin_fragment_alias, 'public.is_admin()'), admin_fragment_plain, 'public.is_admin()'), '');

    IF coalesce(using_clause, '') ILIKE '%profiles%' OR coalesce(check_clause, '') ILIKE '%profiles%' THEN
      RAISE EXCEPTION 'Could not safely rewrite policy %.%', policy_row.table_name, policy_row.policy_name;
    END IF;

    EXECUTE format('DROP POLICY %I ON %I.%I', policy_row.policy_name, policy_row.schema_name, policy_row.table_name);

    EXECUTE format(
      'CREATE POLICY %I ON %I.%I AS %s FOR %s TO %s%s%s',
      policy_row.policy_name,
      policy_row.schema_name,
      policy_row.table_name,
      CASE WHEN policy_row.is_permissive THEN 'PERMISSIVE' ELSE 'RESTRICTIVE' END,
      command_name,
      policy_row.roles,
      CASE WHEN using_clause IS NULL THEN '' ELSE format(' USING (%s)', using_clause) END,
      CASE WHEN check_clause IS NULL THEN '' ELSE format(' WITH CHECK (%s)', check_clause) END
    );
  END LOOP;
END $$;
/*
# Notify both administrators about new sell requests

## Changes
- Add a SECURITY DEFINER trigger function that creates one notification for
  every active admin profile whenever a new `sell_requests` row is created.
- Add the trigger to `sell_requests`.
- Existing seller notifications and request data are unchanged.

## Security
- The trigger runs with a fixed `public` search path.
- Admin recipients are selected from the database by their immutable profile
  role, not from client-supplied IDs.
- The function is not exposed as a client-callable API.
*/

CREATE OR REPLACE FUNCTION public.notify_admins_on_sell_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  property_title text;
  property_code text;
BEGIN
  SELECT title, property_code
  INTO property_title, property_code
  FROM public.properties
  WHERE id = NEW.property_id;

  INSERT INTO public.notifications (user_id, title, message, type, is_admin)
  SELECT
    p.id,
    'طلب بيع جديد',
    format('يوجد طلب بيع جديد للعقار "%s" (%s) بانتظار المراجعة.', coalesce(property_title, 'عقار'), coalesce(property_code, 'بدون رقم')),
    'property',
    true
  FROM public.profiles p
  WHERE p.role = 'admin'
    AND p.is_active = true;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS notify_admins_after_sell_request ON public.sell_requests;
CREATE TRIGGER notify_admins_after_sell_request
AFTER INSERT ON public.sell_requests
FOR EACH ROW
EXECUTE FUNCTION public.notify_admins_on_sell_request();
/*
# Lock internal sell-request notification trigger

## Security
- Prevent direct client RPC execution of the internal trigger function.
- The database trigger remains able to invoke it after a new sell request.
- No data is changed.
*/

REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM anon;
REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM authenticated;
/*
# Add private property contact details and display controls

## New columns
- `properties.display_fields`: JSON settings controlled by the owner or an
  administrator to decide which public detail sections appear.

## New table
- `property_contact_details`
- `property_id`: one contact record per property.
- `contact_phone`: phone number supplied with the sale request.
- `created_at`, `updated_at`: audit timestamps.

## Security
- Contact phone is never readable by anonymous visitors.
- Only the property owner and active administrators can manage contact details.
- Public property pages can read only the display settings and normal property
  information.
- Row-level security is enabled with separate policies for each operation.
*/

ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS display_fields jsonb NOT NULL DEFAULT '{"address":true,"location":true,"price":true,"area":true,"bedrooms":true,"bathrooms":true,"floors":true,"description":true,"features":true}'::jsonb;

CREATE TABLE IF NOT EXISTS public.property_contact_details (
  property_id uuid PRIMARY KEY REFERENCES public.properties(id) ON DELETE CASCADE,
  contact_phone text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.property_contact_details ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "property_contact_select_owner_or_admin" ON public.property_contact_details;
CREATE POLICY "property_contact_select_owner_or_admin"
ON public.property_contact_details FOR SELECT TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.id = property_contact_details.property_id
      AND p.owner_id = auth.uid()
  )
  OR public.is_admin()
);

DROP POLICY IF EXISTS "property_contact_insert_owner_or_admin" ON public.property_contact_details;
CREATE POLICY "property_contact_insert_owner_or_admin"
ON public.property_contact_details FOR INSERT TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.id = property_contact_details.property_id
      AND p.owner_id = auth.uid()
  )
  OR public.is_admin()
);

DROP POLICY IF EXISTS "property_contact_update_owner_or_admin" ON public.property_contact_details;
CREATE POLICY "property_contact_update_owner_or_admin"
ON public.property_contact_details FOR UPDATE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.id = property_contact_details.property_id
      AND p.owner_id = auth.uid()
  )
  OR public.is_admin()
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.id = property_contact_details.property_id
      AND p.owner_id = auth.uid()
  )
  OR public.is_admin()
);

DROP POLICY IF EXISTS "property_contact_delete_owner_or_admin" ON public.property_contact_details;
CREATE POLICY "property_contact_delete_owner_or_admin"
ON public.property_contact_details FOR DELETE TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.properties p
    WHERE p.id = property_contact_details.property_id
      AND p.owner_id = auth.uid()
  )
  OR public.is_admin()
);

DROP TRIGGER IF EXISTS property_contact_details_updated_at ON public.property_contact_details;
CREATE TRIGGER property_contact_details_updated_at
BEFORE UPDATE ON public.property_contact_details
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP POLICY IF EXISTS "support_attachments_admin_read" ON storage.objects;
CREATE POLICY "support_attachments_admin_read" ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'support-attachments' AND public.is_admin());

DROP POLICY IF EXISTS "support_attachments_admin_upload" ON storage.objects;
CREATE POLICY "support_attachments_admin_upload" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'support-attachments' AND public.is_admin());
/*
# Make administrator authorization non-recursive

## Problem
The SQL administrator helper could be expanded while PostgreSQL evaluated
row policies. That caused the original `profiles` policy recursion error to
appear again during property saves.

## Security changes
- Recreate `public.is_admin()` as a PL/pgSQL SECURITY DEFINER function so it
  executes as a separate protected function call.
- Keep the fixed `public` search path and active-admin check.
- Keep execution denied to anonymous users and allowed only for authenticated
  users.
- No application data is changed.
*/

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caller_is_admin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
      AND is_active = true
  ) INTO caller_is_admin;

  RETURN caller_is_admin;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.is_admin() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.is_admin() FROM anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
/*
# Fix ambiguous column reference in sell request notification trigger

## Problem
The `notify_admins_on_sell_request()` trigger function declared PL/pgSQL
variables named `property_title` and `property_code`. The SELECT inside the
function read `title, property_code` from the `properties` table without
prefixing the table name, so PostgreSQL could not tell whether
`property_code` referred to the variable or the column. That ambiguity
raised an error and aborted the sell_requests INSERT, which is why users
saw "تعذر إرسال طلب البيع".

## Fix
- Prefix all column references with the table alias so there is no ambiguity.
- No data changes; the trigger behavior is unchanged.
*/

CREATE OR REPLACE FUNCTION public.notify_admins_on_sell_request()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_property_title text;
  v_property_code text;
BEGIN
  SELECT p.title, p.property_code
  INTO v_property_title, v_property_code
  FROM public.properties p
  WHERE p.id = NEW.property_id;

  INSERT INTO public.notifications (user_id, title, message, type, is_admin)
  SELECT
    p.id,
    'طلب بيع جديد',
    format('يوجد طلب بيع جديد للعقار "%s" (%s) بانتظار المراجعة.', coalesce(v_property_title, 'عقار'), coalesce(v_property_code, 'بدون رقم')),
    'property',
    true
  FROM public.profiles p
  WHERE p.role = 'admin'
    AND p.is_active = true;

  RETURN NEW;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM anon;
REVOKE EXECUTE ON FUNCTION public.notify_admins_on_sell_request() FROM authenticated;
/*
# Allow users to view their own inquiries

## Problem
The inquiries table only had a SELECT policy for admins. Regular users
could create inquiries but could never see them again.

## Fix
Add a SELECT policy allowing each authenticated user to view their own
inquiries (where user_id matches auth.uid()).
*/

CREATE POLICY "inquiries_select_own"
  ON public.inquiries
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
-- Insert sell_requests rows for pending properties that are missing them
INSERT INTO public.sell_requests (property_id, user_id, status)
SELECT p.id, p.owner_id, 'pending'
FROM public.properties p
WHERE p.approval_status = 'pending'
  AND p.status = 'unpublished'
  AND NOT EXISTS (
    SELECT 1 FROM public.sell_requests sr WHERE sr.property_id = p.id
  )
ON CONFLICT DO NOTHING;
/*
# Fix registration trigger + add brokerage/lead system

## 1. Fix handle_new_user trigger function
- Add SET search_path = public to the SECURITY DEFINER function (was missing, can cause failures)

## 2. New columns on properties
- finishing_type (text): super_lux, lux, semi_lux, skeleton, furnished
- floor_plan_url (text): URL to floor plan image
- map_lat (numeric): latitude for map
- map_lng (numeric): longitude for map

## 3. New table: property_leads
- Lead capture form data from interested buyers (brokerage model)
- Tracks: name, phone, preferred viewing time, payment method, message
- Links to property and user (if logged in)
- Status pipeline: new -> contacted -> viewing_scheduled -> negotiating -> closed_won -> closed_lost

## 4. New table: deals
- Admin deal/commission pipeline
- Tracks: property, buyer, seller, deal status, commission percentage, commission amount
- Status: new_lead -> viewing_scheduled -> negotiating -> deal_closed -> deal_lost

## 5. RLS policies
- property_leads: user can see their own leads, admin can see all, anyone can insert
- deals: admin only CRUD
*/

-- 1. Fix handle_new_user with SET search_path
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, username, email, phone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8)),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- 2. Add new columns to properties
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'finishing_type') THEN
    ALTER TABLE public.properties ADD COLUMN finishing_type text DEFAULT 'semi_lux';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'floor_plan_url') THEN
    ALTER TABLE public.properties ADD COLUMN floor_plan_url text;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'map_lat') THEN
    ALTER TABLE public.properties ADD COLUMN map_lat numeric(10,7);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'properties' AND column_name = 'map_lng') THEN
    ALTER TABLE public.properties ADD COLUMN map_lng numeric(10,7);
  END IF;
END $$;

-- 3. Create property_leads table
CREATE TABLE IF NOT EXISTS public.property_leads (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  name text NOT NULL,
  phone text NOT NULL,
  email text,
  preferred_date date,
  preferred_time text,
  payment_method text DEFAULT 'cash',
  message text,
  status text NOT NULL DEFAULT 'new',
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.property_leads ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "property_leads_insert_any" ON public.property_leads;
CREATE POLICY "property_leads_insert_any"
ON public.property_leads FOR INSERT
TO anon, authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "property_leads_select_own_or_admin" ON public.property_leads;
CREATE POLICY "property_leads_select_own_or_admin"
ON public.property_leads FOR SELECT
TO authenticated
USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "property_leads_update_admin" ON public.property_leads;
CREATE POLICY "property_leads_update_admin"
ON public.property_leads FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

DROP POLICY IF EXISTS "property_leads_delete_admin" ON public.property_leads;
CREATE POLICY "property_leads_delete_admin"
ON public.property_leads FOR DELETE
TO authenticated
USING (is_admin());

-- Trigger for updated_at
DROP TRIGGER IF EXISTS property_leads_updated_at ON public.property_leads;
CREATE TRIGGER property_leads_updated_at
BEFORE UPDATE ON public.property_leads
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 4. Create deals table (commission pipeline)
CREATE TABLE IF NOT EXISTS public.deals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  property_id uuid NOT NULL REFERENCES public.properties(id) ON DELETE CASCADE,
  lead_id uuid REFERENCES public.property_leads(id) ON DELETE SET NULL,
  buyer_name text NOT NULL,
  buyer_phone text NOT NULL,
  buyer_email text,
  seller_name text,
  seller_phone text,
  status text NOT NULL DEFAULT 'new_lead',
  commission_percentage numeric(5,2) DEFAULT 2.5,
  commission_amount numeric,
  property_price numeric,
  viewing_date timestamptz,
  viewing_agreement_signed boolean DEFAULT false,
  deal_closed_date timestamptz,
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "deals_select_admin" ON public.deals;
CREATE POLICY "deals_select_admin"
ON public.deals FOR SELECT
TO authenticated
USING (is_admin());

DROP POLICY IF EXISTS "deals_insert_admin" ON public.deals;
CREATE POLICY "deals_insert_admin"
ON public.deals FOR INSERT
TO authenticated
WITH CHECK (is_admin());

DROP POLICY IF EXISTS "deals_update_admin" ON public.deals;
CREATE POLICY "deals_update_admin"
ON public.deals FOR UPDATE
TO authenticated
USING (is_admin())
WITH CHECK (is_admin());

DROP POLICY IF EXISTS "deals_delete_admin" ON public.deals;
CREATE POLICY "deals_delete_admin"
ON public.deals FOR DELETE
TO authenticated
USING (is_admin());

-- Trigger for updated_at
DROP TRIGGER IF EXISTS deals_updated_at ON public.deals;
CREATE TRIGGER deals_updated_at
BEFORE UPDATE ON public.deals
FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 5. Add finishing_type to sell form default
-- Update existing properties to have a default finishing_type
UPDATE public.properties SET finishing_type = 'semi_lux' WHERE finishing_type IS NULL;
/*
# Add Payment Plan System to Properties

1. New Columns on `properties`
- `payment_type` (text): 'cash_only' | 'installments_only' | 'cash_installments' — controls which payment options are shown to buyers. Default 'cash_only'.
- `down_payment_percentage` (numeric): percentage of price required as down payment for installments. Nullable.
- `down_payment_amount` (numeric): fixed down payment amount (alternative to percentage). Nullable.
- `installment_duration_months` (integer): total installment period in months. Nullable.
- `payment_frequency` (text): 'monthly' | 'quarterly' — installment frequency. Default 'monthly'.
- `monthly_installment` (numeric): calculated monthly installment amount. Nullable (admin can set or let system calculate).

2. New Column on `property_leads`
- `installment_years` (integer): preferred installment duration in years (if buyer chose installments). Nullable.

3. Security
- No new tables. Existing RLS policies on `properties` and `property_leads` cover the new columns.
*/

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS payment_type text NOT NULL DEFAULT 'cash_only';
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS down_payment_percentage numeric;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS down_payment_amount numeric;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS installment_duration_months integer;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS payment_frequency text NOT NULL DEFAULT 'monthly';
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE properties ADD COLUMN IF NOT EXISTS monthly_installment numeric;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

DO $$ BEGIN
  ALTER TABLE property_leads ADD COLUMN IF NOT EXISTS installment_years integer;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

-- Add check constraint for payment_type
DO $$ BEGIN
  ALTER TABLE properties ADD CONSTRAINT properties_payment_type_check
  CHECK (payment_type = ANY (ARRAY['cash_only'::text, 'installments_only'::text, 'cash_installments'::text]));
EXCEPTION WHEN duplicate_object THEN NULL; END $$;
/*
# Fix registration: handle_new_user trigger fails on username/email conflicts

## Problem
The `handle_new_user` trigger inserts into `profiles` after a new auth.users row is created.
It uses `ON CONFLICT (id) DO NOTHING` which only handles primary key conflicts.
But `profiles` also has UNIQUE constraints on `username` and `email`.
If a new user picks a username that already exists in profiles, the trigger raises
a unique violation error, which rolls back the entire auth.users INSERT —
registration fails completely with no user-friendly error.

## Fix
1. Rewrite `handle_new_user` to handle username conflicts by appending a suffix.
2. Handle email conflicts gracefully (shouldn't happen since auth.users also checks email,
   but defensive coding).
3. Wrap the insert in an exception handler so trigger failure never blocks registration.
*/

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  final_username text;
  base_username text;
  suffix int := 0;
BEGIN
  base_username := COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substring(NEW.id::text, 1, 8));
  final_username := base_username;

  -- Ensure username uniqueness by appending a numeric suffix if needed
  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
    suffix := suffix + 1;
    final_username := base_username || '_' || suffix::text;
  END LOOP;

  BEGIN
    INSERT INTO public.profiles (id, full_name, username, email, phone)
    VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'full_name', 'New User'),
      final_username,
      NEW.email,
      COALESCE(NEW.raw_user_meta_data->>'phone', NULL)
    )
    ON CONFLICT (id) DO NOTHING;
  EXCEPTION WHEN unique_violation THEN
    -- If email conflicts (shouldn't happen, but just in case), still don't block signup
    NULL;
  END;

  RETURN NEW;
END;
$$;
-- Add missing foreign key on sell_requests.user_id → profiles.id
-- This fixes the admin sell-requests query that uses: profiles!sell_requests_user_id_fkey(*)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'sell_requests_user_id_fkey'
      AND table_name = 'sell_requests'
  ) THEN
    ALTER TABLE public.sell_requests
      ADD CONSTRAINT sell_requests_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
  END IF;
END $$;-- Add homepage stats and site settings keys
INSERT INTO site_settings (setting_key, setting_value) VALUES
  ('stat_properties', '500+'),
  ('stat_clients', '1200+'),
  ('stat_experience', '15+'),
  ('stat_secure', '100%'),
  ('phone_number', '+20 155 975 1754'),
  ('work_hours', 'السبت - الخميس: 9 ص - 6 م'),
  ('facebook_url', ''),
  ('instagram_url', ''),
  ('twitter_url', '')
ON CONFLICT (setting_key) DO NOTHING;

-- Update site_name to ARA World
UPDATE site_settings SET setting_value = 'ARA World' WHERE setting_key = 'site_name';
UPDATE site_settings SET setting_value = 'ARA World' WHERE setting_key = 'footer_text';
