# Fixed Year Calculation Logic

## Problem
The old calculation used simple month division (months ÷ 6 = semesters), which doesn't account for semester boundaries.

**Example Issue:**
- Admission: July 2023
- Current: December 2025 (29 months = 4.83 semesters)
- Old Result: Year II ❌
- Correct: Year III ✅ (completed 5 semesters, in 6th sem gap)

## Solution
Check which semester the student is currently in based on date ranges:

### Semester Schedule
- **Odd Semesters (1, 3, 5)**: July 15 - December 31
- **Even Semesters (2, 4, 6)**: January 1 - June 30

### Fixed Calculation
```sql
CREATE OR REPLACE FUNCTION calculate_student_year(
  admission_year INTEGER,
  admission_month INTEGER,
  course_type TEXT,
  check_date DATE DEFAULT NULL
)
RETURNS TEXT AS $$
DECLARE
  evaluation_date DATE;
  current_year INTEGER;
  current_month INTEGER;
  years_since_admission INTEGER;
  current_semester INTEGER;
BEGIN
  evaluation_date := COALESCE(check_date, CURRENT_DATE);
  current_year := EXTRACT(YEAR FROM evaluation_date);
  current_month := EXTRACT(MONTH FROM evaluation_date);
  years_since_admission := current_year - admission_year;
  
  -- Determine current semester based on date
  IF current_month >= 7 THEN
    -- Odd semester (July-Dec): 1st, 3rd, 5th semester
    current_semester := (years_since_admission * 2) + 1;
  ELSE
    -- Even semester (Jan-June): 2nd, 4th, 6th semester
    current_semester := years_since_admission * 2;
  END IF;
  
  -- Determine year based on semester
  IF current_semester <= 2 THEN
    RETURN 'I';
  ELSIF current_semester <= 4 THEN
    RETURN 'II';
  ELSIF current_semester <= 6 THEN
    RETURN 'III';
  ELSIF course_type = 'MBA' AND current_semester > 4 THEN
    RETURN 'Graduated';
  ELSIF current_semester > 6 THEN
    RETURN 'Graduated';
  ELSE
    RETURN 'I';
  END IF;
END;
$$ LANGUAGE plpgsql;
```

## Test Cases

### Test 1: July 2023 Admission, December 2025
```sql
SELECT calculate_student_year(2023, 7, 'BCA', '2025-12-04'::DATE);
-- Years since admission: 2025 - 2023 = 2
-- Current month: 12 (Dec) >= 7 → Odd semester
-- Current semester: (2 * 2) + 1 = 5
-- Result: Year III ✅
```

### Test 2: July 2023 Admission, January 2026
```sql
SELECT calculate_student_year(2023, 7, 'BCA', '2026-01-15'::DATE);
-- Years since admission: 2026 - 2023 = 3
-- Current month: 1 (Jan) < 7 → Even semester
-- Current semester: 3 * 2 = 6
-- Result: Year III ✅
```

### Test 3: July 2023 Admission, July 2026
```sql
SELECT calculate_student_year(2023, 7, 'BCA', '2026-07-15'::DATE);
-- Years since admission: 2026 - 2023 = 3
-- Current month: 7 (July) >= 7 → Odd semester
-- Current semester: (3 * 2) + 1 = 7
-- Result: Graduated ✅
```

### Test 4: July 2024 Admission, December 2025
```sql
SELECT calculate_student_year(2024, 7, 'BCA', '2025-12-04'::DATE);
-- Years since admission: 2025 - 2024 = 1
-- Current month: 12 (Dec) >= 7 → Odd semester
-- Current semester: (1 * 2) + 1 = 3
-- Result: Year II ✅
```

## Execution Steps

1. **Backup current function:**
```sql
-- Drop trigger first
DROP TRIGGER IF EXISTS trigger_update_year_on_login ON users;

-- Backup function (copy definition to notepad)
-- Then drop old function
DROP FUNCTION IF EXISTS calculate_student_year(INTEGER, INTEGER, TEXT, DATE);
```

2. **Create new function** (run SQL above)

3. **Recreate trigger:**
```sql
CREATE TRIGGER trigger_update_year_on_login
  BEFORE UPDATE OF last_login ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_student_year_on_login();
```

4. **Update trigger function for 2-digit PRN:**
```sql
CREATE OR REPLACE FUNCTION update_student_year_on_login()
RETURNS TRIGGER AS $$
DECLARE
  calculated_year TEXT;
  admission_year INTEGER;
  year_prefix INTEGER;
BEGIN
  IF NEW.role = 'student' AND NEW.last_login IS NOT NULL THEN
    -- Extract admission year from PRN (first 2 digits: 23 = 2023)
    year_prefix := SUBSTRING(NEW.prn, 1, 2)::INTEGER;
    admission_year := 2000 + year_prefix;
    
    calculated_year := calculate_student_year(
      admission_year,
      COALESCE(NEW.admission_month, 7),
      NEW.course,
      NULL
    );
    
    -- Update year if changed
    IF calculated_year != NEW.year AND calculated_year != 'Graduated' THEN
      NEW.year := calculated_year;
      
      -- Log promotion
      INSERT INTO activity_logs (user_id, action, details, created_at)
      VALUES (NEW.id, 'auto_promotion', 
              jsonb_build_object('from', OLD.year, 'to', NEW.year, 'date', CURRENT_DATE),
              NOW());
    END IF;
    
    -- Mark as graduated if applicable
    IF calculated_year = 'Graduated' THEN
      NEW.is_active := false;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

5. **Test the function:**
```sql
-- Should return 'III'
SELECT calculate_student_year(2023, 7, 'BCA', '2025-12-04'::DATE);

-- Should return 'II'
SELECT calculate_student_year(2024, 7, 'BCA', '2025-12-04'::DATE);

-- Should return 'I'
SELECT calculate_student_year(2025, 7, 'BCA', '2025-12-04'::DATE);
```

## Summary

**Old Logic:** months ÷ 6 = semesters (inaccurate)
**New Logic:** Check if current date is in odd/even semester period (accurate)

This ensures students are promoted correctly based on actual semester schedules.
