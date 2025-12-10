-- Create clubs table for managing college clubs
CREATE TABLE IF NOT EXISTS clubs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN ('Technical', 'Cultural', 'Sports', 'Arts', 'Literary', 'Social', 'Science', 'Other')),
  description TEXT,
  club_lead_id UUID REFERENCES users(id) ON DELETE SET NULL,
  founded_year INTEGER CHECK (founded_year >= 1900 AND founded_year <= 2100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_clubs_category ON clubs(category);
CREATE INDEX IF NOT EXISTS idx_clubs_lead ON clubs(club_lead_id);
CREATE INDEX IF NOT EXISTS idx_clubs_active ON clubs(is_active);

-- Enable RLS
ALTER TABLE clubs ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow faculty to view all clubs" ON clubs;
DROP POLICY IF EXISTS "Allow faculty to create clubs" ON clubs;
DROP POLICY IF EXISTS "Allow faculty to update clubs" ON clubs;
DROP POLICY IF EXISTS "Allow faculty to delete clubs" ON clubs;
DROP POLICY IF EXISTS "Allow event leaders to view clubs" ON clubs;
DROP POLICY IF EXISTS "Allow students to view active clubs" ON clubs;

-- RLS Policies for clubs table

-- Faculty can do everything
CREATE POLICY "Allow faculty to view all clubs" ON clubs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'faculty'
    )
  );

CREATE POLICY "Allow faculty to create clubs" ON clubs
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'faculty'
    )
  );

CREATE POLICY "Allow faculty to update clubs" ON clubs
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'faculty'
    )
  );

CREATE POLICY "Allow faculty to delete clubs" ON clubs
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'faculty'
    )
  );

-- Event leaders can view all clubs
CREATE POLICY "Allow event leaders to view clubs" ON clubs
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'event_leader'
    )
  );

-- Students can view active clubs only
CREATE POLICY "Allow students to view active clubs" ON clubs
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    AND EXISTS (
      SELECT 1 FROM users 
      WHERE users.id = auth.uid() 
      AND users.role = 'student'
    )
  );

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_clubs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_clubs_updated_at
  BEFORE UPDATE ON clubs
  FOR EACH ROW
  EXECUTE FUNCTION update_clubs_updated_at();
