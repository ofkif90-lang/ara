-- Add homepage stats and site settings keys
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
