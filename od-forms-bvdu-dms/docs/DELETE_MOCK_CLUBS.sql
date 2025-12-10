-- Delete mock/sample clubs from the database

-- Delete the 6 sample clubs that were inserted
DELETE FROM clubs 
WHERE name IN (
  'Coding Club',
  'Dance Club',
  'Cricket Club',
  'Photography Club',
  'Literary Club',
  'Environmental Club'
);

-- Verify deletion
SELECT COUNT(*) as remaining_clubs FROM clubs;

-- Show remaining clubs (if any)
SELECT id, name, category, founded_year, is_active 
FROM clubs 
ORDER BY created_at DESC;
