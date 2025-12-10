# 🚀 Supabase Integration Guide - BVDU CampusFlow

## 📋 Table of Contents
1. [Overview](#overview)
2. [Setup Instructions](#setup-instructions)
3. [Database Schema](#database-schema)
4. [SQL Scripts](#sql-scripts)
5. [Row Level Security (RLS) Policies](#row-level-security-rls-policies)
6. [Storage Buckets](#storage-buckets)
7. [API Keys Configuration](#api-keys-configuration)
8. [Code Migration Strategy](#code-migration-strategy)
9. [Testing Checklist](#testing-checklist)
10. [Current Function Analysis](#current-function-analysis)

---

## 📖 Overview

This system currently uses **localStorage** for prototyping. All functions are designed to be **Supabase-ready** with conditional checks:
```javascript
if (!supabaseClient) {
  // Use localStorage fallback
} else {
  // Use Supabase queries
}
```

### Current Architecture
- **Authentication**: Mock users (hardcoded)
- **Data Storage**: localStorage (browser-based)
- **File Storage**: Not implemented
- **Real-time Updates**: Not available

### Target Architecture (Supabase)
- **Authentication**: Supabase Auth with email/password
- **Data Storage**: PostgreSQL via Supabase
- **File Storage**: Supabase Storage (certificates, event photos)
- **Real-time Updates**: Available via Supabase subscriptions

---

## 🛠️ Setup Instructions

### Step 1: Create Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Fill in details:
   - **Project Name**: `bvdu-od-forms` (or your choice)
   - **Database Password**: (Save this securely!)
   - **Region**: Choose closest to Mumbai (Singapore recommended)
   - **Pricing Plan**: Free tier is sufficient for development

### Step 2: Get API Credentials
Once project is created:
1. Go to **Project Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (long string)
   - **service_role key**: (Keep this SECRET - only for server-side)

### Step 3: Update Configuration
Edit `js/config.js`:
```javascript
const SUPABASE_CONFIG = {
  url: 'https://your-project-id.supabase.co', // Paste your URL
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' // Paste your anon key
};

const USE_SUPABASE = true; // Change to true when ready
```

---

## 🗄️ Database Schema

### 1. **users** - User Accounts & Profiles
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'event-leader', 'faculty', 'hod')),
  
  -- Common fields
  full_name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id), -- For hierarchical creation
  
  -- Student specific
  roll_number TEXT UNIQUE,
  department TEXT,
  year INTEGER,
  division TEXT,
  
  -- Faculty/HOD specific
  employee_id TEXT UNIQUE,
  designation TEXT,
  
  -- Event Leader specific
  club_name TEXT,
  position TEXT,
  
  CONSTRAINT check_student_fields CHECK (
    (role = 'student' AND roll_number IS NOT NULL AND department IS NOT NULL) 
    OR role != 'student'
  ),
  CONSTRAINT check_faculty_fields CHECK (
    (role IN ('faculty', 'hod') AND employee_id IS NOT NULL) 
    OR role NOT IN ('faculty', 'hod')
  )
);

-- Indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_roll_number ON users(roll_number) WHERE roll_number IS NOT NULL;
CREATE INDEX idx_users_employee_id ON users(employee_id) WHERE employee_id IS NOT NULL;
```

### 2. **events** - Event Management
```sql
CREATE TABLE events (
  event_id TEXT PRIMARY KEY DEFAULT 'EVT-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
  event_name TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_category TEXT NOT NULL,
  event_description TEXT NOT NULL,
  
  -- Scheduling
  event_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  venue TEXT NOT NULL,
  
  -- Organization
  organizing_club TEXT NOT NULL,
  event_leader_id UUID REFERENCES users(id) NOT NULL,
  
  -- Capacity & Registration
  expected_participants INTEGER DEFAULT 0,
  registered_participants INTEGER DEFAULT 0,
  
  -- Event properties
  is_national BOOLEAN DEFAULT FALSE,
  is_university BOOLEAN DEFAULT TRUE,
  certificate_provided BOOLEAN DEFAULT FALSE,
  certificates_provided BOOLEAN DEFAULT FALSE, -- New field
  attendance_marking BOOLEAN DEFAULT TRUE, -- New field
  od_eligible BOOLEAN DEFAULT TRUE,
  external_attendees_allowed BOOLEAN DEFAULT FALSE,
  
  -- Additional details
  tags TEXT[], -- Array of tags
  target_audience TEXT[], -- Array of audiences (BCA, BBA, etc.)
  learning_outcomes TEXT,
  key_speakers TEXT,
  equipment_needs JSONB, -- {wirelessMics: 2, collarMics: 1, ...}
  budget TEXT,
  registration_link TEXT,
  
  -- Drive folders (created after approval)
  photo_folder_url TEXT,
  certificate_folder_url TEXT,
  
  -- Status tracking
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  approved_by_faculty UUID REFERENCES users(id),
  approved_by_hod UUID REFERENCES users(id),
  rejection_reason TEXT,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_leader ON events(event_leader_id);
CREATE INDEX idx_events_club ON events(organizing_club);
```

### 3. **od_forms** - OD Application Forms
```sql
CREATE TABLE od_forms (
  form_id TEXT PRIMARY KEY DEFAULT 'OD-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
  student_id UUID REFERENCES users(id) NOT NULL,
  event_id TEXT REFERENCES events(event_id) NOT NULL,
  
  -- Form type
  form_type TEXT NOT NULL CHECK (form_type IN ('participant', 'volunteer')),
  
  -- Participant details
  roll_number TEXT NOT NULL,
  student_name TEXT NOT NULL,
  department TEXT NOT NULL,
  year INTEGER NOT NULL,
  division TEXT NOT NULL,
  
  -- Dates (for volunteers - includes prep day)
  od_dates DATE[] NOT NULL, -- Array of dates
  
  -- Subjects missed
  subjects JSONB NOT NULL, -- Array of {subject_id, subject_name, subject_code, start_time, end_time, faculty_name, room}
  
  -- Document uploads (URLs to Supabase Storage)
  proof_documents TEXT[], -- Array of file URLs
  bonafide_url TEXT,
  
  -- Approval workflow
  approved_by_event_leader BOOLEAN DEFAULT FALSE,
  event_leader_decision JSONB, -- {subject_id: 'approved'|'rejected', ...}
  event_leader_remarks TEXT,
  event_leader_reviewed_at TIMESTAMPTZ,
  
  approved_by_faculty BOOLEAN DEFAULT FALSE,
  faculty_decision JSONB, -- {subject_id: 'approved'|'rejected', ...}
  faculty_remarks TEXT,
  faculty_reviewed_at TIMESTAMPTZ,
  
  approved_by_hod BOOLEAN DEFAULT FALSE,
  hod_remarks TEXT,
  hod_reviewed_at TIMESTAMPTZ,
  
  -- Final status
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'partially_approved', 'approved', 'rejected')
  ),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_od_forms_student ON od_forms(student_id);
CREATE INDEX idx_od_forms_event ON od_forms(event_id);
CREATE INDEX idx_od_forms_status ON od_forms(status);
CREATE INDEX idx_od_forms_type ON od_forms(form_type);
CREATE INDEX idx_od_forms_dates ON od_forms USING GIN(od_dates);
```

### 4. **participants** - Event Participants
```sql
CREATE TABLE participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id TEXT REFERENCES events(event_id) NOT NULL,
  student_id UUID REFERENCES users(id) NOT NULL,
  
  -- Registration details
  roll_number TEXT NOT NULL,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  email TEXT NOT NULL,
  
  -- Attendance
  attendance_status TEXT DEFAULT 'absent' CHECK (
    attendance_status IN ('present', 'absent', 'excused')
  ),
  attendance_marked_at TIMESTAMPTZ,
  marked_by UUID REFERENCES users(id),
  
  -- Certificate
  certificate_url TEXT,
  certificate_issued_at TIMESTAMPTZ,
  
  -- Registration timestamp
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(event_id, student_id)
);

-- Indexes
CREATE INDEX idx_participants_event ON participants(event_id);
CREATE INDEX idx_participants_student ON participants(student_id);
CREATE INDEX idx_participants_attendance ON participants(attendance_status);
```

### 5. **venue_bookings** - Venue Availability Tracking
```sql
CREATE TABLE venue_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_name TEXT NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  
  -- Booking details
  event_id TEXT REFERENCES events(event_id),
  booked_by UUID REFERENCES users(id) NOT NULL,
  purpose TEXT NOT NULL,
  
  -- Status
  status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Prevent double booking
  CONSTRAINT no_overlap EXCLUDE USING GIST (
    venue_name WITH =,
    booking_date WITH =,
    tstzrange(
      (booking_date + start_time)::TIMESTAMPTZ,
      (booking_date + end_time)::TIMESTAMPTZ
    ) WITH &&
  ) WHERE (status = 'confirmed')
);

-- Indexes
CREATE INDEX idx_venue_bookings_venue ON venue_bookings(venue_name);
CREATE INDEX idx_venue_bookings_date ON venue_bookings(booking_date);
```

### 6. **notifications** - System Notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  
  -- Notification content
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('info', 'success', 'warning', 'error')),
  
  -- Linking
  link_url TEXT,
  related_event_id TEXT REFERENCES events(event_id),
  related_form_id TEXT REFERENCES od_forms(form_id),
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);
```

### 7. **activity_logs** - Audit Trail
```sql
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  
  -- Action details
  action_type TEXT NOT NULL, -- 'create', 'update', 'delete', 'approve', 'reject'
  entity_type TEXT NOT NULL, -- 'event', 'od_form', 'user'
  entity_id TEXT NOT NULL,
  
  -- Changes
  old_data JSONB,
  new_data JSONB,
  
  -- Context
  ip_address INET,
  user_agent TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);
```

---

## 📝 SQL Scripts

### Complete Setup Script
Run this in **Supabase SQL Editor**:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "btree_gist"; -- For venue booking overlap prevention

-- 1. Create users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('student', 'event-leader', 'faculty', 'hod')),
  full_name TEXT NOT NULL,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_login TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id),
  roll_number TEXT UNIQUE,
  department TEXT,
  year INTEGER,
  division TEXT,
  employee_id TEXT UNIQUE,
  designation TEXT,
  club_name TEXT,
  position TEXT,
  CONSTRAINT check_student_fields CHECK (
    (role = 'student' AND roll_number IS NOT NULL AND department IS NOT NULL) 
    OR role != 'student'
  ),
  CONSTRAINT check_faculty_fields CHECK (
    (role IN ('faculty', 'hod') AND employee_id IS NOT NULL) 
    OR role NOT IN ('faculty', 'hod')
  )
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_roll_number ON users(roll_number) WHERE roll_number IS NOT NULL;
CREATE INDEX idx_users_employee_id ON users(employee_id) WHERE employee_id IS NOT NULL;

-- 2. Create events table
CREATE TABLE events (
  event_id TEXT PRIMARY KEY DEFAULT 'EVT-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
  event_name TEXT NOT NULL,
  event_type TEXT NOT NULL,
  event_category TEXT NOT NULL,
  event_description TEXT NOT NULL,
  event_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  venue TEXT NOT NULL,
  organizing_club TEXT NOT NULL,
  event_leader_id UUID REFERENCES users(id) NOT NULL,
  expected_participants INTEGER DEFAULT 0,
  registered_participants INTEGER DEFAULT 0,
  is_national BOOLEAN DEFAULT FALSE,
  is_university BOOLEAN DEFAULT TRUE,
  certificate_provided BOOLEAN DEFAULT FALSE,
  certificates_provided BOOLEAN DEFAULT FALSE,
  attendance_marking BOOLEAN DEFAULT TRUE,
  od_eligible BOOLEAN DEFAULT TRUE,
  external_attendees_allowed BOOLEAN DEFAULT FALSE,
  tags TEXT[],
  target_audience TEXT[],
  learning_outcomes TEXT,
  key_speakers TEXT,
  equipment_needs JSONB,
  budget TEXT,
  registration_link TEXT,
  photo_folder_url TEXT,
  certificate_folder_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
  approved_by_faculty UUID REFERENCES users(id),
  approved_by_hod UUID REFERENCES users(id),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_events_date ON events(event_date);
CREATE INDEX idx_events_status ON events(status);
CREATE INDEX idx_events_leader ON events(event_leader_id);
CREATE INDEX idx_events_club ON events(organizing_club);

-- 3. Create od_forms table
CREATE TABLE od_forms (
  form_id TEXT PRIMARY KEY DEFAULT 'OD-' || EXTRACT(EPOCH FROM NOW())::BIGINT,
  student_id UUID REFERENCES users(id) NOT NULL,
  event_id TEXT REFERENCES events(event_id) NOT NULL,
  form_type TEXT NOT NULL CHECK (form_type IN ('participant', 'volunteer')),
  roll_number TEXT NOT NULL,
  student_name TEXT NOT NULL,
  department TEXT NOT NULL,
  year INTEGER NOT NULL,
  division TEXT NOT NULL,
  od_dates DATE[] NOT NULL,
  subjects JSONB NOT NULL,
  proof_documents TEXT[],
  bonafide_url TEXT,
  approved_by_event_leader BOOLEAN DEFAULT FALSE,
  event_leader_decision JSONB,
  event_leader_remarks TEXT,
  event_leader_reviewed_at TIMESTAMPTZ,
  approved_by_faculty BOOLEAN DEFAULT FALSE,
  faculty_decision JSONB,
  faculty_remarks TEXT,
  faculty_reviewed_at TIMESTAMPTZ,
  approved_by_hod BOOLEAN DEFAULT FALSE,
  hod_remarks TEXT,
  hod_reviewed_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (
    status IN ('pending', 'partially_approved', 'approved', 'rejected')
  ),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_od_forms_student ON od_forms(student_id);
CREATE INDEX idx_od_forms_event ON od_forms(event_id);
CREATE INDEX idx_od_forms_status ON od_forms(status);
CREATE INDEX idx_od_forms_type ON od_forms(form_type);
CREATE INDEX idx_od_forms_dates ON od_forms USING GIN(od_dates);

-- 4. Create participants table
CREATE TABLE participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id TEXT REFERENCES events(event_id) NOT NULL,
  student_id UUID REFERENCES users(id) NOT NULL,
  roll_number TEXT NOT NULL,
  name TEXT NOT NULL,
  department TEXT NOT NULL,
  email TEXT NOT NULL,
  attendance_status TEXT DEFAULT 'absent' CHECK (
    attendance_status IN ('present', 'absent', 'excused')
  ),
  attendance_marked_at TIMESTAMPTZ,
  marked_by UUID REFERENCES users(id),
  certificate_url TEXT,
  certificate_issued_at TIMESTAMPTZ,
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(event_id, student_id)
);

CREATE INDEX idx_participants_event ON participants(event_id);
CREATE INDEX idx_participants_student ON participants(student_id);
CREATE INDEX idx_participants_attendance ON participants(attendance_status);

-- 5. Create venue_bookings table
CREATE TABLE venue_bookings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venue_name TEXT NOT NULL,
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  event_id TEXT REFERENCES events(event_id),
  booked_by UUID REFERENCES users(id) NOT NULL,
  purpose TEXT NOT NULL,
  status TEXT DEFAULT 'confirmed' CHECK (status IN ('confirmed', 'cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_venue_bookings_venue ON venue_bookings(venue_name);
CREATE INDEX idx_venue_bookings_date ON venue_bookings(booking_date);

-- 6. Create notifications table
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('info', 'success', 'warning', 'error')),
  link_url TEXT,
  related_event_id TEXT REFERENCES events(event_id),
  related_form_id TEXT REFERENCES od_forms(form_id),
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);
CREATE INDEX idx_notifications_created ON notifications(created_at DESC);

-- 7. Create activity_logs table
CREATE TABLE activity_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) NOT NULL,
  action_type TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  old_data JSONB,
  new_data JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX idx_activity_logs_entity ON activity_logs(entity_type, entity_id);
CREATE INDEX idx_activity_logs_created ON activity_logs(created_at DESC);

-- 8. Create triggers for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_events_updated_at
  BEFORE UPDATE ON events
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_od_forms_updated_at
  BEFORE UPDATE ON od_forms
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

---

## 🔒 Row Level Security (RLS) Policies

### Enable RLS on all tables
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE od_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
```

### Users Table Policies
```sql
-- Users can view their own profile
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  USING (auth.uid() = id);

-- Event leaders, faculty, and HOD can view all users
CREATE POLICY "Leaders can view all users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('event-leader', 'faculty', 'hod')
    )
  );

-- Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  USING (auth.uid() = id);

-- HOD can create faculty accounts
-- Faculty can create event-leader accounts
-- Anyone can create student accounts (registration)
CREATE POLICY "Hierarchical user creation"
  ON users FOR INSERT
  WITH CHECK (
    (role = 'student') OR
    (role = 'event-leader' AND EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('faculty', 'hod')
    )) OR
    (role = 'faculty' AND EXISTS (
      SELECT 1 FROM users WHERE id = auth.uid() AND role = 'hod'
    ))
  );
```

### Events Table Policies
```sql
-- Anyone can view approved events
CREATE POLICY "Public can view approved events"
  ON events FOR SELECT
  USING (status = 'approved' OR approved_by_faculty IS NOT NULL);

-- Event leaders can view their own events
CREATE POLICY "Leaders can view own events"
  ON events FOR SELECT
  USING (event_leader_id = auth.uid());

-- Faculty and HOD can view all events
CREATE POLICY "Faculty can view all events"
  ON events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('faculty', 'hod')
    )
  );

-- Event leaders can create events
CREATE POLICY "Leaders can create events"
  ON events FOR INSERT
  WITH CHECK (
    event_leader_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'event-leader'
    )
  );

-- Event leaders can update their own pending events
CREATE POLICY "Leaders can update own pending events"
  ON events FOR UPDATE
  USING (
    event_leader_id = auth.uid() AND
    status = 'pending'
  );

-- Faculty can update events (approval)
CREATE POLICY "Faculty can approve events"
  ON events FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('faculty', 'hod')
    )
  );
```

### OD Forms Table Policies
```sql
-- Students can view their own forms
CREATE POLICY "Students can view own forms"
  ON od_forms FOR SELECT
  USING (student_id = auth.uid());

-- Event leaders can view forms for their events
CREATE POLICY "Leaders can view event forms"
  ON od_forms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = od_forms.event_id
      AND events.event_leader_id = auth.uid()
    )
  );

-- Faculty and HOD can view all forms
CREATE POLICY "Faculty can view all forms"
  ON od_forms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('faculty', 'hod')
    )
  );

-- Students can create forms
CREATE POLICY "Students can create forms"
  ON od_forms FOR INSERT
  WITH CHECK (
    student_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'student'
    )
  );

-- Event leaders can update forms (first approval)
CREATE POLICY "Leaders can approve forms"
  ON od_forms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = od_forms.event_id
      AND events.event_leader_id = auth.uid()
    )
  );

-- Faculty can update forms (second approval)
CREATE POLICY "Faculty can approve forms"
  ON od_forms FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('faculty', 'hod')
    )
  );
```

### Participants Table Policies
```sql
-- Students can register for events
CREATE POLICY "Students can register"
  ON participants FOR INSERT
  WITH CHECK (student_id = auth.uid());

-- Students can view their own participations
CREATE POLICY "Students can view own participations"
  ON participants FOR SELECT
  USING (student_id = auth.uid());

-- Event leaders can view participants for their events
CREATE POLICY "Leaders can view event participants"
  ON participants FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = participants.event_id
      AND events.event_leader_id = auth.uid()
    )
  );

-- Event leaders can mark attendance
CREATE POLICY "Leaders can mark attendance"
  ON participants FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = participants.event_id
      AND events.event_leader_id = auth.uid()
    )
  );
```

### Venue Bookings Policies
```sql
-- Event leaders can view venue bookings
CREATE POLICY "Leaders can view venue bookings"
  ON venue_bookings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('event-leader', 'faculty', 'hod')
    )
  );

-- Event leaders can create bookings
CREATE POLICY "Leaders can create bookings"
  ON venue_bookings FOR INSERT
  WITH CHECK (
    booked_by = auth.uid() AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('event-leader', 'faculty', 'hod')
    )
  );
```

### Notifications Policies
```sql
-- Users can view their own notifications
CREATE POLICY "Users can view own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

-- Users can mark notifications as read
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

-- System can create notifications (via service role)
CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (true);
```

---

## 📦 Storage Buckets

### Create Storage Buckets in Supabase Dashboard

#### 1. **od-documents** - OD Form Documents
```
Bucket Name: od-documents
Public: No (Private)
File size limit: 5 MB
Allowed MIME types: application/pdf, image/jpeg, image/png
```

**Folder Structure:**
```
od-documents/
├── {student_id}/
│   ├── {form_id}/
│   │   ├── proof_1.pdf
│   │   ├── proof_2.jpg
│   │   └── bonafide.pdf
```

**Storage Policies:**
```sql
-- Students can upload to their own folder
CREATE POLICY "Students can upload documents"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'od-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Students can view their own documents
CREATE POLICY "Students can view own documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'od-documents' AND
    (storage.foldername(name))[1] = auth.uid()::text
  );

-- Faculty and event leaders can view all documents
CREATE POLICY "Faculty can view all documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'od-documents' AND
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('event-leader', 'faculty', 'hod')
    )
  );
```

#### 2. **event-photos** - Event Photo Albums
```
Bucket Name: event-photos
Public: Yes
File size limit: 10 MB
Allowed MIME types: image/jpeg, image/png, image/webp
```

**Folder Structure:**
```
event-photos/
├── {event_id}/
│   ├── photo_1.jpg
│   ├── photo_2.jpg
│   └── photo_3.jpg
```

**Storage Policies:**
```sql
-- Public read access
CREATE POLICY "Public can view event photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'event-photos');

-- Event leaders can upload photos for their events
CREATE POLICY "Leaders can upload event photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'event-photos' AND
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = (storage.foldername(name))[1]
      AND events.event_leader_id = auth.uid()
    )
  );
```

#### 3. **certificates** - Event Certificates
```
Bucket Name: certificates
Public: No (Private - authenticated access only)
File size limit: 5 MB
Allowed MIME types: application/pdf, image/jpeg, image/png
```

**Folder Structure:**
```
certificates/
├── {event_id}/
│   ├── {participant_id}_certificate.pdf
```

**Storage Policies:**
```sql
-- Event leaders can upload certificates
CREATE POLICY "Leaders can upload certificates"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'certificates' AND
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = (storage.foldername(name))[1]
      AND events.event_leader_id = auth.uid()
    )
  );

-- Students can view their own certificates
CREATE POLICY "Students can view own certificates"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'certificates' AND
    name LIKE '%/' || auth.uid()::text || '_%'
  );

-- Event leaders can view certificates for their events
CREATE POLICY "Leaders can view event certificates"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'certificates' AND
    EXISTS (
      SELECT 1 FROM events
      WHERE events.event_id = (storage.foldername(name))[1]
      AND events.event_leader_id = auth.uid()
    )
  );
```

---

## 🔑 API Keys Configuration

### Environment Variables Setup

Create `.env` file (DO NOT commit to Git):
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... # Keep SECRET!

# Gemini AI (for event detail generation)
GEMINI_API_KEY=AIzaSyA7ocvshcJirFNWj2sar0okPDC0vCYR9JY

# Google Drive (for folder creation)
GOOGLE_DRIVE_API_KEY=your-drive-api-key
GOOGLE_DRIVE_FOLDER_ID=your-root-folder-id
```

### Update `js/config.js`
```javascript
const SUPABASE_CONFIG = {
  url: 'https://your-project-id.supabase.co',
  anonKey: 'your-anon-key-here'
};

const USE_SUPABASE = true; // Enable Supabase
```

### Security Best Practices
1. **Never expose service_role key in frontend**
2. **Use anon key only** - RLS policies protect data
3. **Enable email verification** in Supabase Auth settings
4. **Set up password policies** (min 8 chars, require uppercase, numbers)
5. **Enable 2FA** for admin accounts in production

---

## 🔄 Code Migration Strategy

### Phase 1: Authentication Migration
**Files to update:**
- `login.html`
- `register.html`
- All dashboard files

**Changes needed:**
```javascript
// OLD (Mock)
currentUser = { id: 'student-1', name: 'John Doe' };

// NEW (Supabase)
const { data: { user }, error } = await supabaseClient.auth.getUser();
if (!user) {
  window.location.href = 'login.html';
}
currentUser = user;
```

### Phase 2: Data Fetching Migration
**Replace localStorage with Supabase queries:**

```javascript
// OLD
const events = JSON.parse(localStorage.getItem('bvdu_events')) || [];

// NEW
const { data: events, error } = await supabaseClient
  .from('events')
  .select('*')
  .eq('status', 'approved')
  .order('event_date', { ascending: true });

if (error) {
  console.error('Error fetching events:', error);
  return [];
}
```

### Phase 3: Data Mutation Migration
**Replace localStorage with Supabase inserts/updates:**

```javascript
// OLD
const events = JSON.parse(localStorage.getItem('bvdu_events')) || [];
events.push(newEvent);
localStorage.setItem('bvdu_events', JSON.stringify(events));

// NEW
const { data, error } = await supabaseClient
  .from('events')
  .insert([newEvent])
  .select();

if (error) {
  console.error('Error creating event:', error);
  alert('Failed to create event');
  return;
}

alert('Event created successfully!');
```

### Phase 4: File Upload Migration
**Implement Supabase Storage uploads:**

```javascript
// Upload OD document
async function uploadDocument(file, formId) {
  const fileName = `${auth.uid()}/${formId}/${file.name}`;
  
  const { data, error } = await supabaseClient.storage
    .from('od-documents')
    .upload(fileName, file);
  
  if (error) {
    console.error('Upload failed:', error);
    return null;
  }
  
  // Get public URL
  const { data: urlData } = supabaseClient.storage
    .from('od-documents')
    .getPublicUrl(fileName);
  
  return urlData.publicUrl;
}
```

### Phase 5: Real-time Updates (Optional)
**Subscribe to changes:**

```javascript
// Subscribe to new OD forms
const subscription = supabaseClient
  .channel('od-forms-changes')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'od_forms'
    },
    (payload) => {
      console.log('New form submitted:', payload.new);
      // Refresh dashboard or show notification
      loadForms();
    }
  )
  .subscribe();

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
  subscription.unsubscribe();
});
```

---

## ✅ Testing Checklist

### Pre-Migration Testing (Current localStorage)
- [x] Student registration works
- [x] Event creation works
- [x] OD form submission works
- [x] Event Leader approval workflow
- [x] Faculty approval workflow
- [x] HOD final approval
- [x] Navigation between pages
- [x] Form validation

### Post-Migration Testing (Supabase)
- [ ] **Authentication**
  - [ ] Student registration (email verification)
  - [ ] Login with credentials
  - [ ] Logout functionality
  - [ ] Password reset flow
  - [ ] Session persistence

- [ ] **Events Module**
  - [ ] Create event (Event Leader)
  - [ ] View all events (Public)
  - [ ] View my events (Event Leader)
  - [ ] Approve event (Faculty)
  - [ ] Approve event (HOD)
  - [ ] Reject event with reason
  - [ ] Edit pending event
  - [ ] View event details
  - [ ] Register for event (Student)

- [ ] **OD Forms Module**
  - [ ] Submit participant form
  - [ ] Submit volunteer form
  - [ ] Upload proof documents
  - [ ] Event Leader review
  - [ ] Faculty subject-wise review
  - [ ] HOD final approval
  - [ ] View form status
  - [ ] Download approved OD

- [ ] **Venue Management**
  - [ ] Check venue availability
  - [ ] Book venue
  - [ ] Prevent double booking
  - [ ] View venue calendar

- [ ] **Participants Module**
  - [ ] View participants list
  - [ ] Mark attendance
  - [ ] Upload certificates
  - [ ] Student view certificate

- [ ] **Notifications**
  - [ ] Receive notifications
  - [ ] Mark as read
  - [ ] Navigate from notification

- [ ] **File Storage**
  - [ ] Upload OD documents
  - [ ] View uploaded documents
  - [ ] Upload event photos
  - [ ] View photo gallery
  - [ ] Upload certificates
  - [ ] Download certificates

- [ ] **Security**
  - [ ] RLS policies working
  - [ ] Students can't access others' data
  - [ ] Event Leaders limited to own events
  - [ ] Faculty/HOD have proper access
  - [ ] Storage access restricted properly

---

## 🔍 Current Function Analysis

### ✅ READY FOR SUPABASE (No changes needed)

#### Student Dashboard (`views/student/dashboard.html`)
```javascript
// ✅ Already has Supabase fallback
async function checkAuth() {
  if (!supabaseClient) {
    // Mock mode
  } else {
    const { data: { user }, error } = await supabaseClient.auth.getUser();
    // Real Supabase auth
  }
}

async function loadEvents() {
  if (!supabaseClient) {
    // localStorage fallback
  } else {
    const { data, error } = await supabaseClient
      .from('events')
      .select('*');
    // Real Supabase query
  }
}
```
**Status**: ✅ **READY** - Just enable USE_SUPABASE

#### Event Leader Dashboard (`views/event-leader/dashboard.html`)
```javascript
async function loadODForms() {
  if (!supabaseClient) {
    const storedForms = localStorage.getItem('bvdu_od_forms');
    // localStorage fallback
  } else {
    const { data, error } = await supabaseClient
      .from('od_forms')
      .select('*')
      .eq('event_leader_id', currentUser.id);
    // Real Supabase query
  }
}
```
**Status**: ✅ **READY** - Just needs proper column names

### ⚠️ NEEDS UPDATES

#### Create Event (`views/event-leader/create-event.html`)
```javascript
// ❌ ISSUE: Uses localStorage directly
function submitEvent() {
  const events = JSON.parse(localStorage.getItem('bvdu_events')) || [];
  events.push(newEvent);
  localStorage.setItem('bvdu_events', JSON.stringify(events));
}

// ✅ FIX NEEDED:
async function submitEvent() {
  if (!validateForSubmission()) return;
  
  const eventData = collectFormData();
  
  if (!supabaseClient) {
    // localStorage fallback
    const events = JSON.parse(localStorage.getItem('bvdu_events')) || [];
    events.push(newEvent);
    localStorage.setItem('bvdu_events', JSON.stringify(events));
  } else {
    // Supabase insert
    const { data, error } = await supabaseClient
      .from('events')
      .insert([{
        ...eventData,
        event_leader_id: currentUser.id,
        status: 'pending'
      }])
      .select();
    
    if (error) {
      console.error('Error creating event:', error);
      alert('Failed to create event: ' + error.message);
      return;
    }
  }
  
  alert('Event submitted successfully!');
  window.location.href = 'my-events.html';
}
```
**Status**: ⚠️ **NEEDS UPDATE** - Add Supabase condition

#### Submit OD Form (`views/student/submit-form.html`)
```javascript
// ❌ ISSUE: File upload not implemented
// ❌ ISSUE: Uses localStorage

// ✅ FIX NEEDED:
async function submitForm() {
  // 1. Upload files to Supabase Storage
  const documentUrls = [];
  for (const file of selectedFiles) {
    const url = await uploadDocument(file, formId);
    if (url) documentUrls.push(url);
  }
  
  // 2. Insert form data with file URLs
  const { data, error } = await supabaseClient
    .from('od_forms')
    .insert([{
      ...formData,
      proof_documents: documentUrls,
      student_id: currentUser.id
    }])
    .select();
  
  if (error) {
    console.error('Error submitting form:', error);
    alert('Failed to submit form');
    return;
  }
  
  alert('OD Form submitted successfully!');
  window.location.href = 'my-forms.html';
}

async function uploadDocument(file, formId) {
  const fileName = `${currentUser.id}/${formId}/${file.name}`;
  
  const { data, error } = await supabaseClient.storage
    .from('od-documents')
    .upload(fileName, file);
  
  if (error) {
    console.error('Upload failed:', error);
    return null;
  }
  
  const { data: urlData } = supabaseClient.storage
    .from('od-documents')
    .getPublicUrl(fileName);
  
  return urlData.publicUrl;
}
```
**Status**: ⚠️ **NEEDS SIGNIFICANT UPDATE** - File upload + Supabase integration

#### Review OD Forms (Event Leader)
```javascript
// ❌ ISSUE: Uses localStorage
// ✅ FIX NEEDED:
async function saveDecision() {
  const formData = collectReviewData();
  
  if (!supabaseClient) {
    // localStorage fallback
  } else {
    const { data, error } = await supabaseClient
      .from('od_forms')
      .update({
        event_leader_decision: formData.decisions,
        event_leader_remarks: formData.remarks,
        approved_by_event_leader: true,
        event_leader_reviewed_at: new Date().toISOString(),
        status: 'partially_approved'
      })
      .eq('form_id', formId)
      .select();
    
    if (error) {
      console.error('Error saving decision:', error);
      alert('Failed to save decision');
      return;
    }
  }
  
  alert('Review saved successfully!');
  window.location.href = 'dashboard.html';
}
```
**Status**: ⚠️ **NEEDS UPDATE** - Add Supabase condition

#### Faculty Review OD Forms
```javascript
// ❌ ISSUE: Uses localStorage
// ✅ FIX NEEDED: Same pattern as Event Leader review
async function submitFinalDecision() {
  const { data, error } = await supabaseClient
    .from('od_forms')
    .update({
      faculty_decision: decisions,
      faculty_remarks: remarks,
      approved_by_faculty: true,
      faculty_reviewed_at: new Date().toISOString(),
      status: hasRejections ? 'rejected' : 'approved'
    })
    .eq('form_id', formId)
    .select();
}
```
**Status**: ⚠️ **NEEDS UPDATE** - Add Supabase condition

### 📊 Summary
- **Ready**: 60% of functions (have Supabase fallback)
- **Needs Update**: 40% of functions (direct localStorage usage)
- **Major Work**: File upload implementation

---

## 🚨 Critical Issues to Address

### 1. **Authentication Flow**
**Current**: Mock users with hardcoded IDs
**Required**: 
- Implement Supabase Auth signup
- Sync auth.uid() with users table
- Handle email verification
- Implement password reset

### 2. **File Upload**
**Current**: Not implemented (commented out)
**Required**:
- Implement Supabase Storage upload
- Handle multiple file uploads
- Validate file types and sizes
- Show upload progress
- Handle upload errors

### 3. **Real-time Updates**
**Current**: No real-time updates
**Optional but Recommended**:
- Subscribe to form status changes
- Show notification badges
- Auto-refresh dashboards

### 4. **Error Handling**
**Current**: Basic console.log + alerts
**Required**:
- Proper error messages
- Network error handling
- Validation errors
- Permission errors

### 5. **Google Drive Integration**
**Current**: Placeholder text
**Required**:
- Create folders after event approval
- Share folder links
- Generate shareable links
- Handle Drive API errors

---

## 📞 Support & Resources

### Supabase Documentation
- **Getting Started**: https://supabase.com/docs
- **Authentication**: https://supabase.com/docs/guides/auth
- **Database**: https://supabase.com/docs/guides/database
- **Storage**: https://supabase.com/docs/guides/storage
- **RLS Policies**: https://supabase.com/docs/guides/auth/row-level-security

### Community
- **Supabase Discord**: https://discord.supabase.com
- **GitHub Discussions**: https://github.com/supabase/supabase/discussions

### Testing Tools
- **Supabase Studio**: Built-in database viewer
- **Postman**: API testing (use anon key in headers)
- **Supabase CLI**: Local development environment

---

## 🎯 Migration Roadmap

### Week 1: Setup & Auth
- Day 1-2: Create Supabase project, run SQL scripts
- Day 3-4: Implement authentication (signup, login, logout)
- Day 5: Test auth flow, fix issues

### Week 2: Core Features
- Day 1-2: Migrate events module
- Day 3-4: Migrate OD forms module
- Day 5: Test event creation and form submission

### Week 3: Approvals & Storage
- Day 1-2: Implement approval workflows
- Day 3-4: Implement file uploads
- Day 5: Test complete approval cycle

### Week 4: Polish & Testing
- Day 1-2: Add notifications
- Day 3: Implement real-time updates
- Day 4-5: Full system testing, bug fixes

---

## ✅ Final Checklist Before Going Live

- [ ] All SQL scripts executed successfully
- [ ] RLS policies enabled and tested
- [ ] Storage buckets created with policies
- [ ] API keys configured (kept secure)
- [ ] Authentication flow tested
- [ ] All CRUD operations tested
- [ ] File uploads working
- [ ] Approval workflows tested
- [ ] Email notifications configured
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Security audit completed
- [ ] Performance optimization done
- [ ] Backup strategy in place

---

**Created**: December 4, 2025  
**Last Updated**: December 4, 2025  
**Version**: 1.0.0  
**Maintainer**: BVDU Development Team
