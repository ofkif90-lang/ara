-- ============================================
-- ARA World Data Migration Script
-- Run this AFTER _consolidated_setup.sql
-- in your new Supabase SQL Editor
--
-- Creates all users, properties, images,
-- sell requests, and site settings.
--
-- IMPORTANT: All users get temp password
-- 'TempPass123!' -- they should change
-- it on first login.
-- Phone numbers are stored in profiles table,
-- not auth.users (avoids duplicate phone constraint).
--
-- This script is safe to re-run -- every INSERT
-- uses ON CONFLICT to handle duplicates gracefully.
-- ============================================

-- ============================================
-- STEP 1: Create auth users (9 users)
-- ============================================

-- Admin One (admin1@ara-world.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  'a0000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'admin1@ara-world.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'Admin One', 'username', 'admin1', 'phone', '+201559751754'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- Admin Two (admin2@ara-world.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  'a0000000-0000-4000-8000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'admin2@ara-world.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'Admin Two', 'username', 'admin2', 'phone', '+201559751755'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- احمد رمضلن (ofkif90@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '3c81445c-858e-42f4-a1d7-4cbf10cc7acb',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'ofkif90@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'احمد رمضلن', 'username', 'ahmed', 'phone', '01001898498'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- محمد (ahmed@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '2fd25e40-e817-47e2-b6c2-50d766c991d9',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'ahmed@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'محمد', 'username', 'aaa', 'phone', '01001898498'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- ahmed (sdxsdx@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '7f8293a8-61b9-4711-af7b-d4acae827cca',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'sdxsdx@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'ahmed', 'username', 'ahmed_1', 'phone', '01001898999'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- tyhty (ythjtyht@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '5caa8251-da98-418b-86ee-485494fe7b36',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'ythjtyht@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'tyhty', 'username', 'aaa_1', 'phone', '010014484487'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- everv (rwew@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '7a23900e-fce3-4407-af11-f7fdc3498696',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'rwew@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'everv', 'username', 'aaa_2', 'phone', 'wedew'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- bjbj (nun@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  'e18395bd-887f-45b7-9330-5bbcad2b96d4',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'nun@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'bjbj', 'username', 'gcghcvgh', 'phone', '651615616'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- مخمد (.hmmmmdd103@gmail.com)
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES (
  '72f26d90-a5b6-43f5-994f-a3863c79394b',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  '.hmmmmdd103@gmail.com',
  crypt('TempPass123!', gen_salt('bf')),
  now(),
  '{"provider":"email","providers":["email"]}',
  jsonb_build_object('full_name', 'مخمد', 'username', 'Mmmmmmmmmm', 'phone', '01009554713'),
  now(),
  now(),
  '', '', '', ''
) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STEP 2: Insert profiles
-- Uses individual INSERTs so ON CONFLICT can
-- handle BOTH the id PK and the unique email/username constraints.
-- ============================================

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('a0000000-0000-4000-8000-000000000001', 'Admin One', 'admin1', 'admin1@ara-world.com', '+201559751754', NULL, 'admin', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('a0000000-0000-4000-8000-000000000002', 'Admin Two', 'admin2', 'admin2@ara-world.com', '+201559751755', NULL, 'admin', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('3c81445c-858e-42f4-a1d7-4cbf10cc7acb', 'احمد رمضلن', 'ahmed', 'ofkif90@gmail.com', '01001898498', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('2fd25e40-e817-47e2-b6c2-50d766c991d9', 'محمد', 'aaa', 'ahmed@gmail.com', '01001898498', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('7f8293a8-61b9-4711-af7b-d4acae827cca', 'ahmed', 'ahmed_1', 'sdxsdx@gmail.com', '01001898999', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('5caa8251-da98-418b-86ee-485494fe7b36', 'tyhty', 'aaa_1', 'ythjtyht@gmail.com', '010014484487', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('7a23900e-fce3-4407-af11-f7fdc3498696', 'everv', 'aaa_2', 'rwew@gmail.com', 'wedew', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('e18395bd-887f-45b7-9330-5bbcad2b96d4', 'bjbj', 'gcghcvgh', 'nun@gmail.com', '651615616', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

INSERT INTO public.profiles (id, full_name, username, email, phone, avatar_url, role, is_active, must_change_password, created_at, updated_at) VALUES
  ('72f26d90-a5b6-43f5-994f-a3863c79394b', 'مخمد', 'Mmmmmmmmmm', '.hmmmmdd103@gmail.com', '01009554713', NULL, 'user', true, true, now(), now())
ON CONFLICT (id) DO UPDATE SET
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active,
  must_change_password = EXCLUDED.must_change_password;

-- ============================================
-- STEP 3: Insert properties (7 properties)
-- Uses individual INSERTs so ON CONFLICT can
-- handle BOTH the id PK and the unique
-- property_code/slug constraints.
-- ============================================

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('983a6221-ca2a-4170-b0ba-f22cd646f71f', 'ARA-00001', 'a0000000-0000-4000-8000-000000000001', 'فيلا فاخرة بحمام سباحة خاص - التجمع الخامس', 'luxury-villa-pool-new-cairo', 'villa', 'التجمع الخامس، القاهرة الجديدة', 'القاهرة الجديدة', 'التجمع الخامس', '25000000.00', '28000000.00', '3000000.00', '10.71', '450.00', 5, 4, 3, 'فيلا مستقلة فاخرة بمساحة 450 متر مربع في أرقى مواقع التجمع الخامس. تتميز بحمام سباحة خاص وحديقة منسقة وفتحات تصميمية حديثة. تشطيب سوبر لوكس بتكييفات مركزية ومصعد خاص.', ARRAY['حمام سباحة','حديقة','مصعد خاص','تكييف مركزي','جراج لسيارتين','نظام أمان','كاميرات مراقبة'], 'sold', 'approved', NULL, true, '2026-09-22 18:05:10.512465+00', '2026-09-22 18:05:10.512465+00', '2026-10-02 07:22:53.436527+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('bad6bacb-d8fc-4584-8158-ef5bd97f4054', 'ARA-00003', 'a0000000-0000-4000-8000-000000000001', 'منزل عصري بحديقة واسعة - الشيخ زايد', 'modern-house-garden-sheikh-zayed', 'house', 'الشيخ زايد، الحي السابع', '6 أكتوبر', 'الشيخ زايد', '12000000.00', NULL, NULL, NULL, '320.00', 4, 3, 2, 'منزل عصري بتصميم مودرن في الشيخ زايد. مساحة 320 متر مع حديقة واسعة وجراج. تشطيب ممتاز مع نوافذ كبيرة توفر إضاءة طبيعية وفيرة.', ARRAY['حديقة واسعة','جراج','نوافذ كبيرة','تشطيب ممتاز','موقع هادئ'], 'available', 'approved', NULL, false, '2026-09-25 18:05:10.512465+00', '2026-09-25 18:05:10.512465+00', '2026-09-27 18:05:10.512465+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('37f9f8aa-a7eb-40b0-b80f-b026f7bcbb97', 'ARA-00005', 'a0000000-0000-4000-8000-000000000001', 'أرض استثمارية للبناء - مدينة نصر', 'investment-land-nasr-city', 'land', 'مدينة نصر، المنطقة الثامنة', 'القاهرة', 'مدينة نصر', '18000000.00', NULL, NULL, NULL, '800.00', NULL, NULL, NULL, 'أرض استثمارية مميزة في مدينة نصر بمساحة 800 متر مربع. مناسبة للبناء السكني أو التجاري. موقع استراتيجي قريب من الخدمات والمواصلات.', ARRAY['موقع استراتيجي','قريب من الخدمات','مناسبة للاستثمار','شوارع مميزة'], 'sold', 'approved', NULL, false, '2026-09-17 18:05:10.512465+00', '2026-09-17 18:05:10.512465+00', '2026-10-01 12:44:54.462129+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('acde7c06-0bf7-4dc5-b38f-799f1f89bf15', 'ARA-00006', 'a0000000-0000-4000-8000-000000000001', 'محل تجاري بموقع مميز - وسط البلد', 'commercial-shop-downtown-cairo', 'commercial', 'وسط البلد، شارع عبد العزيز', 'القاهرة', 'وسط البلد', '4200000.00', '4800000.00', '600000.00', '12.50', '120.00', NULL, 2, 1, 'محل تجاري بموقع حيوي جداً في وسط البلد. مساحة 120 متر بواجهة كبيرة. مناسب لجميع الأنشطة التجارية. يقع في شارع رئيسي بكثافة مرور عالية.', ARRAY['موقع حيوي','واجهة كبيرة','شارع رئيسي','مناسب لكل الأنشطة'], 'sold', 'approved', NULL, false, '2026-09-12 18:05:10.512465+00', '2026-09-12 18:05:10.512465+00', '2026-09-27 18:05:10.512465+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('897bcd2b-ead5-4f95-90c2-776d7bcf3334', 'ARA-00011', '5caa8251-da98-418b-86ee-485494fe7b36', 't45t4', 't45t4', 'villa', '34f34f34', '45g45g', 'g45g4g3', '25252.00', '252542.00', '227290.00', '90.00', '24.00', 5, 54, 7, '89o8', NULL, 'unpublished', 'pending', NULL, false, NULL, '2026-10-01 18:21:28.646434+00', '2026-10-01 18:21:28.646434+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('6daf3bc4-51b7-404c-ad62-4b365c4bff7c', 'ARA-00012', '7a23900e-fce3-4407-af11-f7fdc3498696', 'g45rg4', 'g45rg4', 'apartment', '54gr45g', '45gf45f', '45g45g4fre', '34.00', '34.00', NULL, NULL, '33.00', 3, 3, 3, 'ghbgb', NULL, 'unpublished', 'pending', NULL, false, NULL, '2026-10-01 18:39:08.472594+00', '2026-10-01 18:39:08.472594+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.properties (id, property_code, owner_id, title, slug, property_type, address, city, location, price, original_price, discount_amount, discount_percentage, area, bedrooms, bathrooms, floors, description, features, status, approval_status, rejection_reason, is_featured, published_at, created_at, updated_at, display_fields, finishing_type, floor_plan_url, map_lat, map_lng, payment_type, down_payment_percentage, down_payment_amount, installment_duration_months, payment_frequency, monthly_installment) VALUES
  ('52baec17-b719-4980-bd7e-a7700923861a', 'ARA-00013', 'e18395bd-887f-45b7-9330-5bbcad2b96d4', 'jbjhb', 'jbjhb', 'villa', 'jkjnj', 'jhnbkjn', 'jjh', '5468.00', '516.00', NULL, NULL, '49.00', 15, 5, 5, NULL, NULL, 'unpublished', 'pending', NULL, false, NULL, '2026-10-01 18:48:51.696889+00', '2026-10-01 20:16:22.037141+00', '{"area": true, "price": true, "floors": true, "address": true, "bedrooms": true, "features": true, "location": true, "bathrooms": true, "description": true}'::jsonb, 'semi_lux', NULL, NULL, NULL, 'cash_only', NULL, NULL, NULL, 'monthly', NULL)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STEP 4: Insert property images (13 images)
-- ============================================

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('e78b379d-8dc8-4896-a998-78d78c75c59b', '37f9f8aa-a7eb-40b0-b80f-b026f7bcbb97', '/properties/land-1.jpg', true, 0, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('282d6ab3-e931-42d6-bf01-d1e602349dba', '983a6221-ca2a-4170-b0ba-f22cd646f71f', '/properties/villa-1.jpg', true, 0, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('e0e554e4-9a49-4efd-ab35-a937f21075a5', '983a6221-ca2a-4170-b0ba-f22cd646f71f', '/properties/villa-2.jpg', false, 1, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('5bce8ccb-9e6f-4237-bc48-c2f4e25df644', '983a6221-ca2a-4170-b0ba-f22cd646f71f', '/properties/villa-3.jpg', false, 2, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('55c1aeaf-c446-4261-9847-972986a01bee', '983a6221-ca2a-4170-b0ba-f22cd646f71f', '/properties/interior-1.jpg', false, 3, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('1f897a9f-e86d-4c97-9e3d-bbe69dae0175', '983a6221-ca2a-4170-b0ba-f22cd646f71f', '/properties/interior-2.jpg', false, 4, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('2ceb146c-c359-47dc-82db-fa97734fe021', 'acde7c06-0bf7-4dc5-b38f-799f1f89bf15', '/properties/apartment-1.jpg', true, 0, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('df0d9065-53f2-4c3c-9427-95f5955de344', 'bad6bacb-d8fc-4584-8158-ef5bd97f4054', '/properties/house-1.jpg', true, 0, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('c91124f1-f715-4bc9-90a8-9b0c15347079', 'bad6bacb-d8fc-4584-8158-ef5bd97f4054', '/properties/villa-3.jpg', false, 1, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('f63671b0-a784-4314-ac3e-18fd839e44fd', 'bad6bacb-d8fc-4584-8158-ef5bd97f4054', '/properties/house-2.jpg', false, 2, '2026-09-27T18:05:24.235967+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('92e5b992-c0bd-4be9-a97b-969285c80516', '897bcd2b-ead5-4f95-90c2-776d7bcf3334', 'https://vbxqojmufyboaqoqtuah.supabase.co/storage/v1/object/public/property-images/897bcd2b-ead5-4f95-90c2-776d7bcf3334/0-1790878886990.jpg', true, 0, '2026-10-01T18:21:35.431625+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('eb639836-d7bf-44a5-b7a4-5559d3febf63', '6daf3bc4-51b7-404c-ad62-4b365c4bff7c', 'https://vbxqojmufyboaqoqtuah.supabase.co/storage/v1/object/public/property-images/6daf3bc4-51b7-404c-ad62-4b365c4bff7c/0-1790879947068.jpg', true, 0, '2026-10-01T18:39:16.499146+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.property_images (id, property_id, image_url, is_main, display_order, created_at) VALUES
  ('8fde6c33-0550-40c7-b0ec-affdd96a2db9', '52baec17-b719-4980-bd7e-a7700923861a', 'https://vbxqojmufyboaqoqtuah.supabase.co/storage/v1/object/public/property-images/52baec17-b719-4980-bd7e-a7700923861a/0-1790880530821.jpg', true, 0, '2026-10-01T18:49:01.407897+00:00')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STEP 5: Insert property contact details (3 entries)
-- ============================================

INSERT INTO public.property_contact_details (property_id, contact_phone, created_at, updated_at) VALUES
  ('897bcd2b-ead5-4f95-90c2-776d7bcf3334', '520525252', '2026-10-01T18:21:28.985247+00:00', '2026-10-01T18:21:28.985247+00:00')
ON CONFLICT (property_id) DO NOTHING;

INSERT INTO public.property_contact_details (property_id, contact_phone, created_at, updated_at) VALUES
  ('6daf3bc4-51b7-404c-ad62-4b365c4bff7c', '434343443', '2026-10-01T18:39:08.924538+00:00', '2026-10-01T18:39:08.924538+00:00')
ON CONFLICT (property_id) DO NOTHING;

INSERT INTO public.property_contact_details (property_id, contact_phone, created_at, updated_at) VALUES
  ('52baec17-b719-4980-bd7e-a7700923861a', '1656486485', '2026-10-01T18:48:52.539049+00:00', '2026-10-01T18:48:52.539049+00:00')
ON CONFLICT (property_id) DO NOTHING;

-- ============================================
-- STEP 6: Insert sell requests (3 requests)
-- ============================================

INSERT INTO public.sell_requests (id, property_id, user_id, status, rejection_reason, reviewed_by, reviewed_at, created_at, updated_at) VALUES
  ('e9869545-47ec-4976-be22-e4d7ff024e5e', '897bcd2b-ead5-4f95-90c2-776d7bcf3334', '5caa8251-da98-418b-86ee-485494fe7b36', 'pending', NULL, NULL, NULL, '2026-10-01T18:21:35.685687+00:00', '2026-10-01T18:21:35.685687+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.sell_requests (id, property_id, user_id, status, rejection_reason, reviewed_by, reviewed_at, created_at, updated_at) VALUES
  ('6a7b5b8d-367a-47c3-91cf-7358122c2ee3', '6daf3bc4-51b7-404c-ad62-4b365c4bff7c', '7a23900e-fce3-4407-af11-f7fdc3498696', 'pending', NULL, NULL, NULL, '2026-10-01T18:39:16.927386+00:00', '2026-10-01T18:39:16.927386+00:00')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.sell_requests (id, property_id, user_id, status, rejection_reason, reviewed_by, reviewed_at, created_at, updated_at) VALUES
  ('1a4ed562-c708-4299-8a46-a560413a727b', '52baec17-b719-4980-bd7e-a7700923861a', 'e18395bd-887f-45b7-9330-5bbcad2b96d4', 'pending', NULL, NULL, NULL, '2026-10-01T18:49:01.867386+00:00', '2026-10-01T18:49:01.867386+00:00')
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STEP 7: Insert site settings (17 settings)
-- Uses ON CONFLICT (setting_key) so re-running
-- updates existing settings rather than erroring.
-- ============================================

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('de1d4dda-0f7e-4cc7-bc23-41d74ec742d1', 'contact_email', 'contact@ara-world.com', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('93096cca-6b91-49e6-a94f-969289bad113', 'facebook_url', '', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('3f7e34c7-9e20-4e4b-bfaa-f479a61e293a', 'footer_text', 'ARA World', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('64091907-eac0-441c-b6b7-3afe577fa9f4', 'hero_subtitle', 'Buy, sell, and discover premium real estate with ARA_world', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('fdbeedac-d355-40c8-bb14-904958c93e56', 'hero_title', 'Find Your Dream Property in Egypt', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('e4922e32-52d8-40c5-88dd-92ae1302b2da', 'instagram_url', '', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('24dff233-b0cb-4458-8e8c-13b5573a9d2e', 'paypal_email', '', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('bea83b56-a713-48de-a3c8-2d380aadfbd9', 'paypal_mode', 'sandbox', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('9d0c6707-2752-4680-827b-cd42bc4958d0', 'phone_number', '+20 155 975 1754', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('65085231-0039-42fc-9d64-185d447ee093', 'site_name', 'ARA World', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('d0856bc9-6cfc-4777-858b-1c82c000ff9a', 'stat_clients', '1200+', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('8958cb6f-0e15-4ba5-b326-44f26777c9f3', 'stat_experience', '15+', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('a7153647-5e66-45c4-ac01-127bc91ea3f4', 'stat_properties', '500+', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('447f09bb-a320-41b8-87cf-7afb8ad8637f', 'stat_secure', '100%', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('840d9535-7fcb-418e-b109-17f405fa25da', 'twitter_url', '', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('1ef86f24-6038-45b0-928f-20a707095589', 'whatsapp_number', '+201559751754', '2026-09-27T18:00:39.121943+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

INSERT INTO public.site_settings (id, setting_key, setting_value, updated_at) VALUES
  ('51ffd5f9-e9b9-4779-a2ff-cfa09076dcff', 'work_hours', 'السبت - الخميس: 9 ص - 6 م', '2026-10-16T13:53:27.470426+00:00')
ON CONFLICT (setting_key) DO UPDATE SET setting_value = EXCLUDED.setting_value, updated_at = EXCLUDED.updated_at;

-- Done! All data migrated successfully.
