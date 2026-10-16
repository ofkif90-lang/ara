CREATE TABLE IF NOT EXISTS monthly_stats_snapshots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  month text NOT NULL,
  year int NOT NULL,
  total_users int NOT NULL DEFAULT 0,
  total_properties int NOT NULL DEFAULT 0,
  published_properties int NOT NULL DEFAULT 0,
  sold_properties int NOT NULL DEFAULT 0,
  reserved_properties int NOT NULL DEFAULT 0,
  pending_requests int NOT NULL DEFAULT 0,
  total_inquiries int NOT NULL DEFAULT 0,
  total_leads int NOT NULL DEFAULT 0,
  closed_deals int NOT NULL DEFAULT 0,
  active_deals int NOT NULL DEFAULT 0,
  total_commission numeric NOT NULL DEFAULT 0,
  new_users_this_month int NOT NULL DEFAULT 0,
  new_properties_this_month int NOT NULL DEFAULT 0,
  new_deals_this_month int NOT NULL DEFAULT 0,
  commission_this_month numeric NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(month, year)
);

ALTER TABLE monthly_stats_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "select_snapshots_admin" ON monthly_stats_snapshots FOR SELECT
  TO authenticated USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );