# 🚀 Next Steps - OD Forms BVDU DMS

**Last Updated:** November 15, 2025  
**Status:** Planning & Architecture Phase  
**Current Version:** v0.4.0

---

## 📋 Table of Contents
1. [System Architecture](#system-architecture)
2. [Role-Based Workflows](#role-based-workflows)
3. [Feature Implementation Plan](#feature-implementation-plan)
4. [Timetable Integration](#timetable-integration)
5. [Volunteer System](#volunteer-system)
6. [Subject-Level Approval System](#subject-level-approval-system)
7. [UI/UX Specifications](#uiux-specifications)
8. [Technical Implementation](#technical-implementation)
9. [Mock Data Requirements](#mock-data-requirements)
10. [Testing Checklist](#testing-checklist)

---

## 🏗️ System Architecture

### ✅ Finalized Role Responsibilities

#### **Event Leader**
- ✅ Create events (only for their own club/organization)
- ✅ Manage events they created (edit, view details)
- ✅ Approve/Reject OD Forms with **subject-level control**
  - Participant OD Forms
  - Volunteer OD Forms
- ✅ Add remarks for each subject approval/rejection
- ❌ **Cannot** approve/reject events created by other event leaders
- ❌ **Cannot** approve events (only faculty can)

#### **Faculty**
- ✅ Approve/Reject **ALL events** (from any event leader)
- ✅ Approve/Reject **ALL OD Forms** with **subject-level control**
  - Participant OD Forms
  - Volunteer OD Forms
- ✅ View Event Leader's subject-level decisions (locked rejections)
- ✅ Add remarks for each subject approval/rejection
- ✅ Can see approval history from Event Leader
- ✅ Manage timetables (create, edit, view) for all courses/semesters/divisions
- 🔨 **Create and manage Event Leader accounts** (NEW)
  - Register new event leaders
  - Assign club/organization
  - Enable/disable event leader access
  - View event leader activity

#### **HOD (Head of Department)**
- ✅ Final approval/rejection of **ALL OD Forms** with **subject-level control**
- ✅ View Event Leader's + Faculty's subject-level decisions
- ✅ Mark attendance **only for fully approved subjects**
- ✅ Add final remarks for each subject
- ✅ Cannot override rejections from Event Leader or Faculty
- ✅ Final stage - decision is absolute
- 🔨 **Create and manage Faculty accounts** (NEW)
  - Register new faculty members
  - Assign department/specialization
  - Enable/disable faculty access
  - View faculty activity

#### **HOD (Head of Department)**
- ✅ Final approval/rejection of **ALL OD Forms** with **subject-level control**
- ✅ View Event Leader's + Faculty's subject-level decisions
- ✅ Mark attendance **only for fully approved subjects**
- ✅ Add final remarks for each subject
- ✅ Cannot override rejections from Event Leader or Faculty
- ✅ Final stage - decision is absolute

---

## 🔄 Role-Based Workflows

### **A. Event Approval Flow**
```
┌─────────────────────┐
│ Event Leader        │
│ Creates Event       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Faculty Reviews     │
│ Approves/Rejects    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Event Visible to    │
│ Students (if approved)│
└─────────────────────┘
```

**Status Flow:**
- Event Leader creates → `faculty_status: 'pending'`
- Faculty approves → `faculty_status: 'approved'` (visible to students)
- Faculty rejects → `faculty_status: 'rejected'` (not visible)

---

### **B. OD Form Approval Flow (Participants & Volunteers)**

```
┌─────────────────────────────────────────────────────┐
│ Student Submits OD Form                             │
│ - Role: Participant OR Volunteer                    │
│ - Subjects: Auto-calculated from timetable          │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│ Event Leader Reviews                                │
│ - Can approve/reject individual subjects            │
│ - Adds remarks per subject                          │
│ - Rejected subjects are LOCKED                      │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│ Faculty Reviews                                     │
│ - Sees Event Leader's decisions (locked rejections) │
│ - Can approve/reject remaining approved subjects    │
│ - Adds remarks per subject                          │
│ - Cannot override Event Leader's rejections         │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│ HOD Reviews (FINAL STAGE)                           │
│ - Sees Event Leader's + Faculty's decisions         │
│ - Can approve/reject remaining approved subjects    │
│ - Marks attendance ONLY for fully approved subjects │
│ - Cannot override previous rejections               │
│ - Decision is FINAL                                 │
└─────────────────────────────────────────────────────┘
```

**Subject Status Flow:**
```
All Subjects → Event Leader Review → Faculty Review → HOD Review
     ↓               ↓                      ↓              ↓
  Pending    Some Approved/Rejected   More Approved   Final Status
                   ↓                      ↓              ↓
              Locked ❌              Locked ❌      Attendance ✅
```

---

## 📊 Dashboard Structure

### **Event Leader Dashboard**

**Tabs:**
1. **📊 My Events**
   - Events created by this event leader
   - Create New Event button
   - View/Edit own events
   - Event status: Pending Faculty / Approved / Rejected

2. **📋 Participant OD Forms** ← NEW
   - OD forms where student is a participant
   - Subject-level approval/rejection interface
   - Individual subject remarks

3. **📋 Volunteer OD Forms** ← NEW
   - OD forms where student is a volunteer
   - Includes prep days + event day subjects
   - Subject-level approval/rejection interface

**Stats Cards:**
- Total Events Created
- Events Pending Faculty Approval
- Participant OD Forms Pending
- Volunteer OD Forms Pending

---

### **Faculty Dashboard**

**Tabs:**
1. **🎯 All Events**
   - Events from ALL event leaders
   - Approve/Reject events
   - View event details
   - Stats: Pending, Approved, Rejected, Total

2. **📋 Participant OD Forms** ← NEW
   - View Event Leader's decisions (with history)
   - Subject-level approval/rejection
   - See locked rejections from Event Leader

3. **📋 Volunteer OD Forms** ← NEW
   - Same as participant but for volunteers
   - View prep day subjects
   - Subject-level control

4. **📅 Manage Timetables** ← NEW
   - Create/Edit timetables
   - Course + Semester + Division based
   - Subject allocation with time slots

**Stats Cards:**
- Events Pending Approval
- Events Approved
- Participant ODs Pending
- Volunteer ODs Pending

---

### **HOD Dashboard**

**Tabs:**
1. **📋 Participant OD Forms (Final Approval)** ← NEW
   - View Event Leader + Faculty decisions
   - Subject-level final approval/rejection
   - Mark attendance for approved subjects
   - See complete approval history

2. **📋 Volunteer OD Forms (Final Approval)** ← NEW
   - Same as participant but for volunteers
   - Final attendance marking

**Stats Cards:**
- Participant ODs Pending Final Approval
- Volunteer ODs Pending Final Approval
- Total Attendance Marked (This Month)
- ODs Fully Approved vs Partially Rejected

---

## 🎓 Timetable Integration

### **Master Timetable Structure**

**Storage:** `localStorage` key: `bvdu_timetables` (prototype)

**Data Model:**
```javascript
{
  timetable_id: 'TT-BCA-III-A-2025',
  course: 'BCA',           // BCA, BBA, BAF, MBA
  semester: 'III',         // I-VI for BCA/BBA/BAF, I-IV for MBA
  division: 'A',           // A, B, C, etc.
  academic_year: '2025-26',
  timetable: {
    'Monday': [
      {
        subject_id: 'SUB001',
        subject_name: 'Data Structures',
        subject_code: 'BCA301',
        start_time: '09:00',
        end_time: '10:00',
        faculty_name: 'Dr. Rajesh Kumar',
        room: 'Lab 402'
      },
      {
        subject_id: 'SUB002',
        subject_name: 'Database Management Systems',
        subject_code: 'BCA302',
        start_time: '10:00',
        end_time: '11:00',
        faculty_name: 'Prof. Sneha Sharma',
        room: 'Room 301'
      }
      // ... more subjects
    ],
    'Tuesday': [...],
    'Wednesday': [...],
    'Thursday': [...],
    'Friday': [...],
    'Saturday': [...]
  },
  created_by: 'faculty_id',
  created_at: '2025-11-15',
  updated_at: '2025-11-15'
}
```

### **Student Profile Enhancement**

**Add to Student Profile:**
```javascript
student_profile: {
  student_id: 'STU2025001',
  name: 'Rahul Kumar',
  email: 'rahul@bvdu.edu.in',
  
  // NEW FIELDS:
  course: 'BCA',          // Required for timetable lookup
  semester: 'III',        // Required for timetable lookup
  division: 'A',          // Required for timetable lookup
  roll_number: '25BCA001',
  
  // Existing fields:
  department: 'Computer Science',
  year: '2025-26'
}
```

### **Subject Auto-Calculation Logic**

**When student selects event + role:**

1. **Get student's timetable:**
   ```javascript
   const timetable = getTimetable(student.course, student.semester, student.division);
   ```

2. **For Participants:**
   - Event date: Dec 15, 2025 (Friday)
   - Event time: 10:00 - 17:00
   - **Calculate:**
     - 1 lecture before: 09:00-10:00
     - Lectures during event: 10:00-17:00
     - 1 lecture after: 17:00-18:00
   - **Get weekday:** Dec 15 = Friday
   - **Lookup:** `timetable['Friday']` for time range 09:00-18:00

3. **For Volunteers:**
   - Prep dates: Dec 12, 13, 14 (Tue, Wed, Thu)
   - Prep time range: 09:00-18:00 (set by event leader)
   - Event date: Dec 15 (Friday)
   - Event time: 10:00-17:00 (with buffer)
   - **Calculate:**
     - All subjects on Dec 12 between 09:00-18:00
     - All subjects on Dec 13 between 09:00-18:00
     - All subjects on Dec 14 between 09:00-18:00
     - All subjects on Dec 15 between 09:00-18:00
   - **Allow manual additions** within prep dates + time range

4. **Overlap Logic:**
   - Event: 10:00 AM - 2:00 PM
   - Lecture: 9:00 AM - 11:00 AM
   - **Count:** 10:00-11:00 (1 hour, not full lecture)
   - **Logic:** Only count actual overlapping period

---

## 🎯 Volunteer System

### **Event Creation Enhancement**

**New Fields in Create Event Form:**

```javascript
event: {
  // Existing fields...
  event_name: 'AI Summit 2025',
  event_date: '2025-12-15',
  event_time: '10:00-17:00',
  
  // NEW FIELDS:
  volunteer_prep_required: true,        // Checkbox
  volunteer_prep_dates: [               // Multi-date picker
    '2025-12-12',
    '2025-12-13', 
    '2025-12-14'
  ],
  volunteer_time_range: {
    start_time: '09:00',               // Volunteers can work from
    end_time: '18:00'                  // Volunteers can work till
  },
  
  // Optional:
  setup_time: '09:00-10:00',           // Before event
  cleanup_time: '17:00-19:00'          // After event
}
```

### **OD Form Role Selection**

**Step 2.5 - Select Your Role (NEW STEP):**

```html
<div class="role-selection">
  <h3>Select Your Role in This Event</h3>
  
  <div class="role-cards">
    <div class="role-card" onclick="selectRole('participant')">
      <input type="radio" name="role" value="participant">
      <div class="role-icon">🎓</div>
      <h4>Participant</h4>
      <p>Attended the event on event day only</p>
      <ul>
        <li>Event day subjects</li>
        <li>1 lecture before</li>
        <li>1 lecture after</li>
      </ul>
    </div>
    
    <div class="role-card" onclick="selectRole('volunteer')">
      <input type="radio" name="role" value="volunteer">
      <div class="role-icon">🤝</div>
      <h4>Volunteer/Organizer</h4>
      <p>Helped organize and conduct the event</p>
      <ul>
        <li>Preparation days subjects</li>
        <li>Event day subjects</li>
        <li>Can add additional subjects</li>
      </ul>
    </div>
  </div>
</div>
```

### **Manual Subject Addition (Volunteers Only)**

```html
<div class="auto-subjects">
  <h4>Auto-Calculated Subjects (Based on Your Timetable)</h4>
  <div class="subjects-list" id="autoSubjectsList">
    <!-- Read-only subjects -->
  </div>
</div>

<div class="manual-subjects" v-if="role === 'volunteer'">
  <button onclick="openAddSubjectModal()">
    + Add Additional Subject
  </button>
  
  <div class="manual-subjects-list" id="manualSubjectsList">
    <!-- User-added subjects -->
  </div>
</div>

<!-- Add Subject Modal -->
<div class="modal" id="addSubjectModal">
  <div class="modal-content">
    <h3>Add Additional Subject</h3>
    
    <label>Date</label>
    <select id="subjectDate">
      <!-- Only prep dates + event date -->
      <option value="2025-12-12">Dec 12, 2025 (Tue)</option>
      <option value="2025-12-13">Dec 13, 2025 (Wed)</option>
      <option value="2025-12-14">Dec 14, 2025 (Thu)</option>
      <option value="2025-12-15">Dec 15, 2025 (Fri)</option>
    </select>
    
    <label>Subject</label>
    <select id="subjectSelect">
      <!-- Load from student's timetable for selected date -->
    </select>
    
    <label>Time</label>
    <input type="text" readonly value="09:00 - 10:00">
    
    <p class="help-text">
      ⚠️ You can only add subjects within the time range 
      set by the event organizer (09:00 - 18:00)
    </p>
    
    <div class="modal-actions">
      <button onclick="addSubject()">Add Subject</button>
      <button onclick="closeModal()">Cancel</button>
    </div>
  </div>
</div>
```

---

## ✅ Subject-Level Approval System

### **Subject Data Model**

```javascript
od_form: {
  form_id: 'OD-2025-001',
  student_id: 'STU2025001',
  event_id: 'EVT-2025-001',
  role: 'volunteer', // or 'participant'
  
  subjects: [
    {
      subject_id: 'SUB001',
      subject_name: 'Data Structures',
      subject_code: 'BCA301',
      date: '2025-12-12',
      day: 'Tuesday',
      start_time: '09:00',
      end_time: '10:00',
      faculty_name: 'Dr. Rajesh Kumar',
      lecture_type: 'auto', // or 'manual' (for volunteers)
      
      // Event Leader Review
      event_leader_status: 'approved', // approved, rejected, pending
      event_leader_remarks: 'Verified attendance during prep',
      event_leader_reviewed_at: '2025-12-13T10:30:00',
      event_leader_reviewed_by: 'EL2025001',
      
      // Faculty Review
      faculty_status: 'approved', // approved, rejected, pending
      faculty_remarks: 'Valid lecture time',
      faculty_reviewed_at: '2025-12-14T14:20:00',
      faculty_reviewed_by: 'FAC2025001',
      
      // HOD Review (Final)
      hod_status: 'approved', // approved, rejected, pending
      hod_remarks: 'Attendance marked',
      hod_reviewed_at: '2025-12-16T11:00:00',
      hod_reviewed_by: 'HOD2025001',
      
      // Final Status (computed)
      final_status: 'approved', // approved only if all three approve
      attendance_marked: true
    },
    {
      subject_id: 'SUB002',
      subject_name: 'DBMS',
      // ... same structure
      event_leader_status: 'rejected',
      event_leader_remarks: 'Student was not present during this time',
      faculty_status: 'locked', // Cannot review rejected subjects
      hod_status: 'locked',
      final_status: 'rejected',
      attendance_marked: false
    }
    // ... more subjects
  ],
  
  // Overall form status
  overall_status: 'partially_approved', // all_approved, partially_approved, all_rejected
  approved_subjects_count: 4,
  rejected_subjects_count: 2,
  total_lectures_missed: 6
}
```

### **Approval Interface Design**

#### **Event Leader/Faculty/HOD Review Page:**

```html
<div class="od-form-review">
  <div class="form-header">
    <h2>OD Form Review</h2>
    <div class="student-info">
      <strong>Student:</strong> Rahul Kumar (STU2025001)<br>
      <strong>Event:</strong> AI Summit 2025<br>
      <strong>Role:</strong> Volunteer<br>
      <strong>Submission Date:</strong> Dec 13, 2025
    </div>
  </div>
  
  <div class="subjects-review-table">
    <table>
      <thead>
        <tr>
          <th>Date</th>
          <th>Time</th>
          <th>Subject</th>
          <th>Faculty</th>
          <!-- Show previous decisions based on role -->
          <th v-if="role === 'faculty'">Event Leader</th>
          <th v-if="role === 'hod'">Event Leader</th>
          <th v-if="role === 'hod'">Faculty</th>
          <th>Your Decision</th>
          <th>Remarks</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Dec 12</td>
          <td>9-10 AM</td>
          <td>Data Structures</td>
          <td>Dr. Rajesh</td>
          <td class="status-approved">✅ Approved</td>
          <td>
            <select class="decision-select">
              <option value="pending">⏳ Pending</option>
              <option value="approved">✅ Approve</option>
              <option value="rejected">❌ Reject</option>
            </select>
          </td>
          <td>
            <input type="text" placeholder="Add remarks...">
          </td>
        </tr>
        
        <tr class="subject-locked">
          <td>Dec 12</td>
          <td>11-12 AM</td>
          <td>Java</td>
          <td>Prof. Singh</td>
          <td class="status-rejected">❌ Rejected</td>
          <td class="locked">🔒 LOCKED</td>
          <td class="locked-reason">
            "Student was not present during prep"
          </td>
        </tr>
        
        <!-- More subjects... -->
      </tbody>
    </table>
  </div>
  
  <div class="decision-summary">
    <h4>Decision Summary</h4>
    <div class="summary-stats">
      <div class="stat">
        <strong>Total Subjects:</strong> 6
      </div>
      <div class="stat success">
        <strong>Approved:</strong> 4
      </div>
      <div class="stat danger">
        <strong>Rejected:</strong> 2
      </div>
      <div class="stat info">
        <strong>Net Lectures:</strong> 4
      </div>
    </div>
  </div>
  
  <div class="action-buttons">
    <button class="btn-bulk-approve">✅ Approve All Pending</button>
    <button class="btn-bulk-reject">❌ Reject All Pending</button>
    <button class="btn-submit-review">📤 Submit Review</button>
  </div>
</div>
```

### **Cascading Approval Rules**

1. **Event Leader rejects a subject:**
   - Subject status = `rejected`
   - Faculty sees: ❌ Rejected (LOCKED)
   - HOD sees: ❌ Rejected (LOCKED)
   - **Cannot be overridden**

2. **Faculty rejects a subject (Event Leader approved):**
   - Event Leader status = `approved`
   - Faculty status = `rejected`
   - HOD sees: EL ✅, Faculty ❌ (LOCKED)
   - **Cannot be overridden**

3. **HOD approves remaining subjects:**
   - Marks attendance for subjects with all three approvals
   - Final status computed: `all_approved`, `partially_approved`, `all_rejected`

4. **Attendance Marking:**
   - **Only** subjects with `event_leader_status === 'approved'` AND `faculty_status === 'approved'` AND `hod_status === 'approved'`
   - Attendance marked = `true`
   - All others = `false`

---

## 🔐 Authentication & Account Management System

### **Registration & Login Architecture**

#### **Registration (Public Access)**
- **Only Students can self-register**
- Registration page creates account with role: `student`
- Required fields:
  - Full Name
  - Email (BVDU email)
  - Password
  - Roll Number
  - Course (BCA, BBA, BAF, MBA)
  - Semester (I-VI or I-IV based on course)
  - Division (A, B, C)
  - Department

#### **Universal Login System**
- **Single login page for ALL roles**
- No role selection dropdown
- System automatically routes based on credentials stored in database
- Login flow:
  ```
  User enters username/password
  ↓
  Backend validates credentials
  ↓
  Returns user object with role
  ↓
  Frontend routes to role-specific dashboard:
  - role === 'student' → student/dashboard.html
  - role === 'event-leader' → event-leader/dashboard.html
  - role === 'faculty' → faculty/dashboard.html
  - role === 'hod' → hod/dashboard.html
  ```

#### **Database User Structure**
```javascript
users: {
  user_id: 'USR-2025-001',
  username: 'faculty1',
  email: 'faculty1@bvdu.edu.in',
  password: 'hashed_password',
  role: 'faculty', // student | event-leader | faculty | hod
  
  // Metadata
  full_name: 'Dr. Amit Kumar',
  created_by: 'hod1', // who created this account
  created_at: '2025-11-16',
  status: 'active', // active | disabled
  last_login: '2025-11-16T10:30:00',
  
  // Role-specific data
  department: 'Computer Science', // for faculty/event-leader
  specialization: 'AI/ML', // for faculty
  club_organization: 'Tech Club', // for event-leader
  course: 'BCA', // for student
  semester: 'III', // for student
  division: 'A', // for student
  roll_number: '25BCA001' // for student
}
```

### **Hierarchical Account Management**

#### **Development Phase (Manual Seeding)**
- Create initial accounts manually:
  - 1 HOD account
  - 2-3 Faculty accounts
  - 3-4 Event Leader accounts
  - 10-15 Student accounts (for testing)

#### **Production Phase (Frontend Management)**

**HOD Dashboard - Manage Faculty Accounts:**
```
┌─────────────────────────────────────────┐
│ Manage Faculty Accounts                 │
├─────────────────────────────────────────┤
│ [+ Create New Faculty]                  │
│                                         │
│ Faculty List:                           │
│ ┌─────────────────────────────────────┐│
│ │ Dr. Amit Kumar                      ││
│ │ Email: amit@bvdu.edu.in             ││
│ │ Dept: Computer Science              ││
│ │ Status: ✅ Active                   ││
│ │ [Edit] [Disable] [View Activity]   ││
│ └─────────────────────────────────────┘│
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ Prof. Sneha Sharma                  ││
│ │ Email: sneha@bvdu.edu.in            ││
│ │ Dept: Management                    ││
│ │ Status: ✅ Active                   ││
│ │ [Edit] [Disable] [View Activity]   ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**Faculty Dashboard - Manage Event Leader Accounts:**
```
┌─────────────────────────────────────────┐
│ Manage Event Leader Accounts            │
├─────────────────────────────────────────┤
│ [+ Create New Event Leader]             │
│                                         │
│ Event Leader List:                      │
│ ┌─────────────────────────────────────┐│
│ │ Rahul Mehta (Tech Club)             ││
│ │ Email: rahul@bvdu.edu.in            ││
│ │ Organization: Tech Club             ││
│ │ Status: ✅ Active                   ││
│ │ Events Created: 12                  ││
│ │ [Edit] [Disable] [View Events]     ││
│ └─────────────────────────────────────┘│
│                                         │
│ ┌─────────────────────────────────────┐│
│ │ Priya Singh (Cultural Committee)    ││
│ │ Email: priya@bvdu.edu.in            ││
│ │ Organization: Cultural Committee    ││
│ │ Status: ✅ Active                   ││
│ │ Events Created: 8                   ││
│ │ [Edit] [Disable] [View Events]     ││
│ └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

### **Create Account Forms**

#### **HOD Creates Faculty Account:**
```html
<form id="createFacultyForm">
  <h3>Create New Faculty Account</h3>
  
  <label>Full Name</label>
  <input type="text" name="full_name" required>
  
  <label>Email (BVDU Email)</label>
  <input type="email" name="email" required>
  
  <label>Department</label>
  <select name="department" required>
    <option>Computer Science</option>
    <option>Management</option>
    <option>Commerce</option>
    <option>Finance</option>
  </select>
  
  <label>Specialization</label>
  <input type="text" name="specialization">
  
  <label>Temporary Password</label>
  <input type="password" name="temp_password" required>
  <small>Faculty will be prompted to change on first login</small>
  
  <button type="submit">Create Faculty Account</button>
</form>
```

#### **Faculty Creates Event Leader Account:**
```html
<form id="createEventLeaderForm">
  <h3>Create New Event Leader Account</h3>
  
  <label>Full Name</label>
  <input type="text" name="full_name" required>
  
  <label>Email (BVDU Email)</label>
  <input type="email" name="email" required>
  
  <label>Club/Organization</label>
  <input type="text" name="club_organization" required>
  <small>E.g., Tech Club, Cultural Committee, Student Council</small>
  
  <label>Department</label>
  <select name="department" required>
    <option>Computer Science</option>
    <option>Management</option>
    <option>Commerce</option>
    <option>Cross-Department</option>
  </select>
  
  <label>Temporary Password</label>
  <input type="password" name="temp_password" required>
  <small>Event Leader will be prompted to change on first login</small>
  
  <button type="submit">Create Event Leader Account</button>
</form>
```

### **Account Management Features**

#### **Common Operations:**
1. **Create Account**
   - Generate unique user ID
   - Hash password
   - Set default status: `active`
   - Record `created_by` field
   - Send welcome email (optional)

2. **Edit Account**
   - Update name, email, department
   - Cannot change role
   - Cannot change username
   - Update timestamp

3. **Disable Account**
   - Set status: `disabled`
   - User cannot login
   - Preserve all data
   - Can be re-enabled

4. **View Activity**
   - Last login timestamp
   - Events created (for event leaders)
   - OD forms reviewed (for faculty/HOD)
   - Approval statistics

#### **Security Features:**
1. **First-time Login:**
   - Force password change
   - Verify email (optional)
   - Accept terms and conditions

2. **Password Requirements:**
   - Minimum 8 characters
   - Must contain: uppercase, lowercase, number, special char
   - Cannot reuse last 3 passwords

3. **Session Management:**
   - Auto-logout after 30 minutes of inactivity
   - Single session per user
   - Remember device (optional)

---

## 🎯 UI/UX Specifications

### **Design System (Google Colors)**

```css
/* Primary Colors */
--google-blue: #4285F4;      /* Primary actions, links */
--google-green: #34A853;     /* Success, approved */
--google-yellow: #FBBC04;    /* Warning, pending */
--google-red: #EA4335;       /* Error, rejected */

/* Gradients */
--gradient-primary: linear-gradient(135deg, #4285F4, #34A853);
--gradient-glow: linear-gradient(135deg, rgba(66,133,244,0.2), rgba(52,168,83,0.2));

/* Glassmorphism */
--glass-bg: rgba(26, 31, 58, 0.6);
--glass-blur: blur(20px);
--glass-border: rgba(255, 255, 255, 0.1);
```

### **Component Patterns**

**Tabs with Badges:**
```html
<div class="tabs">
  <button class="tab active">
    Participant ODs
    <span class="tab-badge">12</span>
  </button>
  <button class="tab">
    Volunteer ODs
    <span class="tab-badge">8</span>
  </button>
</div>
```

**Status Badges:**
```html
<span class="badge badge-approved">✅ Approved</span>
<span class="badge badge-rejected">❌ Rejected</span>
<span class="badge badge-pending">⏳ Pending</span>
<span class="badge badge-locked">🔒 Locked</span>
```

**Decision History:**
```html
<div class="decision-history">
  <div class="decision-item approved">
    <div class="decision-header">
      <span class="decision-role">Event Leader</span>
      <span class="decision-status">✅ Approved</span>
    </div>
    <p class="decision-remarks">"Verified attendance during prep"</p>
    <small>Reviewed by Prof. Sharma on Dec 13, 2025</small>
  </div>
  
  <div class="decision-item rejected">
    <div class="decision-header">
      <span class="decision-role">Faculty</span>
      <span class="decision-status">❌ Rejected</span>
    </div>
    <p class="decision-remarks">"No documentation for cleanup work"</p>
    <small>Reviewed by Dr. Kumar on Dec 14, 2025</small>
  </div>
</div>
```

---

## 🛠️ Technical Implementation

### **Phase 1: Timetable System** ⏳ NOT STARTED
**Estimated Time:** 2-3 days

**Files to Create:**
1. `views/faculty/manage-timetables.html` (NEW)
   - Create/Edit/View timetables
   - Course/Semester/Division selector
   - Weekly grid interface
   - Subject allocation with time slots

2. `js/timetable-manager.js` (NEW)
   - CRUD operations for timetables
   - Validation logic
   - Export/Import functionality

**Tasks:**
- [ ] Create timetable management page
- [ ] Implement weekly grid UI
- [ ] Add subject allocation interface
- [ ] Create mock timetables for testing
- [ ] Test timetable retrieval by course/semester/division

---

### **Phase 2: Student Profile Enhancement** ⏳ NOT STARTED
**Estimated Time:** 1 day

**Files to Modify:**
1. `views/student/profile.html`
   - Add Course dropdown (BCA, BBA, BAF, MBA)
   - Add Semester dropdown (I-VI or I-IV based on course)
   - Add Division field (A, B, C)

2. `register.html`
   - Add same fields during registration

**Tasks:**
- [ ] Update student profile form
- [ ] Update registration form
- [ ] Add validation for course/semester/division
- [ ] Update mock student data with new fields

---

### **Phase 3: Event Creation Enhancement** ⏳ NOT STARTED
**Estimated Time:** 2 days

**Files to Modify:**
1. `views/event-leader/create-event.html`
   - Add "Volunteer Preparation Required" checkbox
   - Add date range picker for prep dates
   - Add time range inputs for volunteer work hours

**Tasks:**
- [ ] Add volunteer prep fields to event form
- [ ] Implement date range validation
- [ ] Update mock events with volunteer data
- [ ] Test event creation with volunteer prep

---

### **Phase 4: Role Selection in OD Form** ⏳ NOT STARTED
**Estimated Time:** 1 day

**Files to Modify:**
1. `views/student/submit-form.html`
   - Add Step 2.5: Role Selection
   - Create role selection UI (cards with radio buttons)
   - Update step navigation

**Tasks:**
- [ ] Design role selection cards
- [ ] Implement role selection logic
- [ ] Update step counter (4 steps → 5 steps)
- [ ] Add conditional logic for volunteer features

---

### **Phase 5: Auto-Subject Calculation** ⏳ NOT STARTED
**Estimated Time:** 3-4 days

**Files to Create:**
1. `js/subject-calculator.js` (NEW)
   - Get student timetable
   - Calculate event date → weekday
   - Find overlapping subjects
   - Apply buffer times (before/after)
   - Handle multi-day events (volunteers)

**Functions Needed:**
```javascript
// Get student's timetable
function getStudentTimetable(course, semester, division) { }

// Convert date to weekday
function getWeekday(dateString) { }

// Find subjects for date + time range
function getSubjectsForTimeRange(timetable, date, startTime, endTime) { }

// Calculate participant subjects
function calculateParticipantSubjects(event, student) { }

// Calculate volunteer subjects
function calculateVolunteerSubjects(event, student) { }

// Calculate time overlap
function calculateOverlap(lectureTime, eventTime) { }
```

**Tasks:**
- [ ] Implement subject calculator
- [ ] Add date-to-weekday conversion
- [ ] Handle time overlap logic
- [ ] Test with mock timetables
- [ ] Add buffer time logic

---

### **Phase 6: Manual Subject Addition (Volunteers)** ⏳ NOT STARTED
**Estimated Time:** 2 days

**Files to Modify:**
1. `views/student/submit-form.html`
   - Add "Add Subject" button (volunteers only)
   - Create modal for subject selection
   - Validate against prep dates + time range

**Tasks:**
- [ ] Create add subject modal
- [ ] Populate date dropdown (only prep dates + event date)
- [ ] Load subjects from student timetable for selected date
- [ ] Validate time range restrictions
- [ ] Allow subject removal

---

### **Phase 7: Subject-Level Approval UI** ⏳ NOT STARTED
**Estimated Time:** 4-5 days

**Files to Create:**
1. `views/event-leader/review-od-participant.html` (NEW)
2. `views/event-leader/review-od-volunteer.html` (NEW)
3. `views/faculty/review-od-participant.html` (NEW)
4. `views/faculty/review-od-volunteer.html` (NEW)
5. `views/hod/review-od-participant.html` (NEW)
6. `views/hod/review-od-volunteer.html` (NEW)

**Tasks:**
- [ ] Create subject review table interface
- [ ] Add individual approve/reject toggles
- [ ] Show previous decisions (locked)
- [ ] Add remarks input per subject
- [ ] Implement bulk actions
- [ ] Create decision summary panel

---

### **Phase 8: Approval Logic Implementation** ⏳ NOT STARTED
**Estimated Time:** 3-4 days

**Files to Create:**
1. `js/approval-engine.js` (NEW)
   - Cascading approval logic
   - Lock rejected subjects
   - Calculate final status
   - Mark attendance

**Functions Needed:**
```javascript
// Event Leader approves/rejects subjects
function eventLeaderReview(formId, subjectId, decision, remarks) { }

// Faculty reviews remaining subjects
function facultyReview(formId, subjectId, decision, remarks) { }

// HOD final review + attendance marking
function hodReview(formId, subjectId, decision, remarks) { }

// Calculate final status for each subject
function calculateSubjectFinalStatus(subject) { }

// Calculate overall form status
function calculateFormFinalStatus(form) { }

// Mark attendance for approved subjects
function markAttendance(formId) { }
```

**Tasks:**
- [ ] Implement approval engine
- [ ] Add cascading logic
- [ ] Test rejection locking
- [ ] Implement attendance marking
- [ ] Add approval history tracking

---

### **Phase 11: Authentication & Account Management System** 🔨 NEW PHASE
**Estimated Time:** 5-6 days

**Files to Create:**
1. `views/hod/manage-faculty.html` (NEW)
   - Create faculty account form
   - Faculty list with edit/disable options
   - Activity tracking dashboard

2. `views/faculty/manage-event-leaders.html` (NEW)
   - Create event leader account form
   - Event leader list with edit/disable options
   - Events and activity overview

3. `js/account-manager.js` (NEW)
   - User creation logic
   - Role-based routing after login
   - Account enable/disable functionality
   - Password hashing and validation

4. `login.html` (MODIFY)
   - Universal login for all roles
   - Remove role selection
   - Add role-based redirect logic

5. `register.html` (MODIFY)
   - Student-only registration
   - Add course/semester/division fields
   - Validate BVDU email format

**Tasks:**
- [ ] Create HOD manage faculty interface
- [ ] Create Faculty manage event leaders interface
- [ ] Implement account creation forms
- [ ] Add password strength validation
- [ ] Implement first-time login password change
- [ ] Create role-based routing logic
- [ ] Add account enable/disable functionality
- [ ] Add activity tracking (last login, events created, etc.)
- [ ] Create mock accounts for testing (1 HOD, 3 Faculty, 4 Event Leaders)
- [ ] Test universal login with all roles
- [ ] Test account creation workflow
- [ ] Test account disable/enable

**Database Changes:**
```javascript
// Add to user object
users: {
  user_id: 'USR-2025-001',
  role: 'student' | 'event-leader' | 'faculty' | 'hod',
  created_by: 'user_id_of_creator',
  status: 'active' | 'disabled',
  last_login: '2025-11-16T10:30:00',
  first_time_login: true | false,
  
  // Role-specific fields
  club_organization: 'Tech Club', // for event-leader
  specialization: 'AI/ML' // for faculty
}
```

---

### **Phase 12: Dashboard Enhancements for Account Management** 🔨 NEW PHASE
**Estimated Time:** 3 days

**Files to Modify:**
1. `views/event-leader/dashboard.html`
   - Add Participant OD Forms tab
   - Add Volunteer OD Forms tab

2. `views/faculty/dashboard.html`
   - Add Participant OD Forms tab
   - Add Volunteer OD Forms tab
   - Add Manage Timetables link
   - **Add Manage Event Leaders tab/section** (NEW)

3. `views/hod/dashboard.html`
   - Add Participant OD Forms tab
   - Add Volunteer OD Forms tab
   - Separate stats for each
   - **Add Manage Faculty tab/section** (NEW)

**Stats Cards for Account Management:**

**HOD Dashboard:**
- Total Faculty Members
- Active Faculty
- Disabled Faculty
- Faculty Added This Month

**Faculty Dashboard:**
- Total Event Leaders
- Active Event Leaders
- Events Created by Leaders
- Event Leaders Added This Month

**Tasks:**
- [ ] Add new tabs to dashboards
- [ ] Update stats cards
- [ ] Link to review pages
- [ ] Add filters (pending, approved, rejected)
- [ ] Add account management sections
- [ ] Create stats cards for accounts
- [ ] Add quick action buttons (Create Faculty, Create Event Leader)

---

### **Phase 13: Mock Data for Account Management** 🔨 NEW PHASE
**Estimated Time:** 2 days

**Mock Data Needed:**

1. **User Accounts:**
   - **1 HOD Account:**
     ```javascript
     {
       user_id: 'HOD-001',
       username: 'hod.cs',
       email: 'hod.cs@bvdu.edu.in',
       password: 'hashed_password',
       role: 'hod',
       full_name: 'Dr. Rajesh Patel',
       department: 'Computer Science',
       status: 'active',
       created_by: 'SYSTEM',
       created_at: '2025-01-01'
     }
     ```
   
   - **3 Faculty Accounts:**
     ```javascript
     {
       user_id: 'FAC-001',
       username: 'faculty.amit',
       email: 'amit@bvdu.edu.in',
       role: 'faculty',
       full_name: 'Dr. Amit Kumar',
       department: 'Computer Science',
       specialization: 'AI/ML',
       status: 'active',
       created_by: 'HOD-001',
       created_at: '2025-02-15'
     }
     ```
   
   - **4 Event Leader Accounts:**
     ```javascript
     {
       user_id: 'EL-001',
       username: 'el.rahul',
       email: 'rahul.mehta@bvdu.edu.in',
       role: 'event-leader',
       full_name: 'Rahul Mehta',
       club_organization: 'Tech Club',
       department: 'Computer Science',
       status: 'active',
       created_by: 'FAC-001',
       created_at: '2025-06-10'
     }
     ```
   
   - **15 Student Accounts:**
     ```javascript
     {
       user_id: 'STU-001',
       username: 'student.25bca001',
       email: '25bca001@bvdu.edu.in',
       role: 'student',
       full_name: 'Priya Singh',
       course: 'BCA',
       semester: 'III',
       division: 'A',
       roll_number: '25BCA001',
       department: 'Computer Science',
       status: 'active',
       created_at: '2025-07-01'
     }
     ```

2. **Timetables:**
   - BCA Sem III Div A
   - BBA Sem II Div B
   - MBA Sem I Div A

3. **Students with Course/Semester/Division:**
   - 10 students with different courses

4. **Events with Volunteer Prep:**
   - 5 events with prep dates + time ranges

4. **OD Forms (Participants + Volunteers):**
   - 10 participant OD forms
   - 10 volunteer OD forms
   - Various approval stages

**Tasks:**
- [ ] Create mock timetables
- [ ] Update student profiles
- [ ] Create events with volunteer data
- [ ] Generate OD forms with subjects
- [ ] Add approval decisions (various stages)

---

## 📝 Mock Data Requirements

### **1. Timetable Mock Data**

```javascript
const mockTimetables = [
  {
    timetable_id: 'TT-BCA-III-A-2025',
    course: 'BCA',
    semester: 'III',
    division: 'A',
    academic_year: '2025-26',
    timetable: {
      'Monday': [
        {
          subject_id: 'SUB001',
          subject_name: 'Data Structures',
          subject_code: 'BCA301',
          start_time: '09:00',
          end_time: '10:00',
          faculty_name: 'Dr. Rajesh Kumar',
          room: 'Lab 402'
        },
        {
          subject_id: 'SUB002',
          subject_name: 'Database Management Systems',
          subject_code: 'BCA302',
          start_time: '10:00',
          end_time: '11:00',
          faculty_name: 'Prof. Sneha Sharma',
          room: 'Room 301'
        },
        {
          subject_id: 'SUB003',
          subject_name: 'Java Programming',
          subject_code: 'BCA303',
          start_time: '11:00',
          end_time: '12:00',
          faculty_name: 'Dr. Amit Singh',
          room: 'Lab 403'
        },
        {
          subject_id: 'SUB004',
          subject_name: 'Web Technologies',
          subject_code: 'BCA304',
          start_time: '13:00',
          end_time: '14:00',
          faculty_name: 'Prof. Priya Desai',
          room: 'Room 302'
        },
        {
          subject_id: 'SUB005',
          subject_name: 'Computer Networks',
          subject_code: 'BCA305',
          start_time: '14:00',
          end_time: '15:00',
          faculty_name: 'Dr. Vikram Patel',
          room: 'Lab 401'
        }
      ],
      'Tuesday': [
        // Similar structure
      ],
      // ... rest of the week
    }
  }
  // More timetables for other courses/semesters
];
```

### **2. Enhanced Event Mock Data**

```javascript
const mockEvents = [
  {
    event_id: 'EVT-2025-001',
    event_name: 'AI & Machine Learning Summit 2025',
    event_date: '2025-12-15',
    start_time: '10:00',
    end_time: '17:00',
    
    // NEW: Volunteer preparation
    volunteer_prep_required: true,
    volunteer_prep_dates: ['2025-12-12', '2025-12-13', '2025-12-14'],
    volunteer_time_range: {
      start_time: '09:00',
      end_time: '18:00'
    },
    
    faculty_status: 'approved',
    od_eligible: true,
    // ... other fields
  }
];
```

### **3. OD Form with Subjects Mock Data**

```javascript
const mockODForms = [
  {
    form_id: 'OD-2025-001',
    student_id: 'STU2025001',
    student_name: 'Rahul Kumar',
    event_id: 'EVT-2025-001',
    event_name: 'AI Summit 2025',
    role: 'volunteer',
    submission_date: '2025-12-13',
    
    subjects: [
      {
        subject_id: 'SUB001',
        subject_name: 'Data Structures',
        date: '2025-12-12',
        day: 'Tuesday',
        start_time: '09:00',
        end_time: '10:00',
        faculty_name: 'Dr. Rajesh Kumar',
        lecture_type: 'auto',
        
        event_leader_status: 'approved',
        event_leader_remarks: 'Verified attendance',
        event_leader_reviewed_at: '2025-12-13T10:30:00',
        
        faculty_status: 'approved',
        faculty_remarks: 'Valid',
        faculty_reviewed_at: '2025-12-14T14:20:00',
        
        hod_status: 'approved',
        hod_remarks: 'Attendance marked',
        hod_reviewed_at: '2025-12-16T11:00:00',
        
        final_status: 'approved',
        attendance_marked: true
      },
      {
        subject_id: 'SUB003',
        subject_name: 'Java Programming',
        date: '2025-12-12',
        day: 'Tuesday',
        start_time: '11:00',
        end_time: '12:00',
        faculty_name: 'Dr. Amit Singh',
        lecture_type: 'auto',
        
        event_leader_status: 'rejected',
        event_leader_remarks: 'Student not present',
        event_leader_reviewed_at: '2025-12-13T10:35:00',
        
        faculty_status: 'locked',
        hod_status: 'locked',
        final_status: 'rejected',
        attendance_marked: false
      }
      // ... more subjects
    ],
    
    overall_status: 'partially_approved',
    approved_subjects_count: 4,
    rejected_subjects_count: 2,
    total_subjects: 6
  }
];
```

---

## ✅ Testing Checklist

### **Timetable System**
- [ ] Create timetable for BCA Sem III Div A
- [ ] Create timetable for BBA Sem II Div B
- [ ] Edit existing timetable
- [ ] View timetable (weekly grid)
- [ ] Retrieve timetable by course/semester/division

### **Event Creation**
- [ ] Create event WITHOUT volunteer prep
- [ ] Create event WITH volunteer prep (multi-day)
- [ ] Validate prep dates (must be before event date)
- [ ] Validate time range (start < end)
- [ ] View created event details

### **Student Profile**
- [ ] Update profile with course/semester/division
- [ ] Register new student with course info
- [ ] Validate course options
- [ ] Validate semester based on course

### **OD Form Submission**
- [ ] Select event
- [ ] Select role (Participant)
- [ ] View auto-calculated subjects
- [ ] Select role (Volunteer)
- [ ] View auto-calculated subjects (multi-day)
- [ ] Add manual subject (volunteer only)
- [ ] Remove manual subject
- [ ] Validate manual subject (within time range)
- [ ] Submit form

### **Event Leader Review**
- [ ] View participant OD forms
- [ ] View volunteer OD forms
- [ ] Approve individual subject
- [ ] Reject individual subject with remarks
- [ ] Bulk approve all pending
- [ ] Bulk reject all pending
- [ ] Submit review

### **Faculty Review**
- [ ] View participant OD forms
- [ ] View volunteer OD forms
- [ ] See Event Leader's decisions (locked rejections)
- [ ] Approve remaining subjects
- [ ] Reject remaining subjects with remarks
- [ ] Cannot override Event Leader's rejections
- [ ] Submit review

### **HOD Review**
- [ ] View participant OD forms
- [ ] View volunteer OD forms
- [ ] See Event Leader + Faculty decisions
- [ ] Approve remaining subjects
- [ ] Reject remaining subjects with remarks
- [ ] Mark attendance for approved subjects only
- [ ] View final decision summary
- [ ] Submit final review

### **Cascading Logic**
- [ ] Event Leader rejects → Faculty sees locked
- [ ] Event Leader rejects → HOD sees locked
- [ ] Faculty rejects → HOD sees locked
- [ ] All approve → Attendance marked
- [ ] Partial approval → Some attendance marked
- [ ] All reject → No attendance marked

---

## 🎯 Key Clarifications & Rules

### **✅ Confirmed Rules**

1. **Event Leader Scope:**
   - ✅ Only manages events they created
   - ❌ Cannot see/approve other event leaders' events

2. **Approval Transparency:**
   - ✅ Faculty sees Event Leader's decisions
   - ✅ HOD sees Event Leader + Faculty decisions
   - ✅ All decisions visible with remarks

3. **Rejection Locking:**
   - ✅ Once rejected, stays rejected (cascades down)
   - ❌ Cannot be overridden by next level
   - ✅ Locked subjects grayed out in UI

4. **Attendance Marking:**
   - ✅ Only HOD marks attendance
   - ✅ Only for subjects approved by all three levels
   - ❌ Rejected subjects = no attendance

5. **Volunteer Privileges:**
   - ✅ Can add manual subjects
   - ✅ Restricted to prep dates + event date
   - ✅ Restricted to organizer's time range
   - ❌ Cannot add random subjects outside event scope

6. **Bulk Actions:**
   - 🔄 Postponed for later consideration
   - May add "Approve All Pending" button

7. **Dispute Feature:**
   - ❌ No dispute feature
   - Decision is final at each level

---

## 📊 Implementation Priority

### **HIGH PRIORITY (Implement First)**
1. ✅ Timetable system (foundation for everything)
2. ✅ Student profile enhancement (course/semester/division)
3. ✅ Subject auto-calculation logic
4. ✅ Subject-level approval UI (all three roles)

### **MEDIUM PRIORITY**
5. Event creation enhancement (volunteer prep)
6. Role selection in OD form
7. Manual subject addition (volunteers)
8. Dashboard enhancements (new tabs)

### **LOW PRIORITY (Polish)**
9. Bulk actions
10. Advanced filtering
11. Approval history timeline
12. Analytics dashboard

---

## 🔄 Recent Changes Log

### **November 15, 2025**
- ✅ Fixed event dropdown loading issue
- ✅ Updated mock events with faculty approval status
- ✅ Changed event date from Nov 25 to Nov 18 (within 3-day deadline)
- ✅ Added missing fields: `od_eligible`, `event_leader_id`, `event_category`
- ✅ Implemented 3-day deadline logic for OD form submission
- ✅ Events now show "X days left" in dropdown

### **Architecture Finalized (Nov 15, 2025)**
- ✅ Role responsibilities confirmed
- ✅ Approval flow defined (3-tier: EL → Faculty → HOD)
- ✅ Subject-level approval system designed
- ✅ Volunteer system planned
- ✅ Timetable integration planned
- ✅ UI/UX specifications defined

---

## 📁 File Structure (After Implementation)

```
od-forms-bvdu-dms/
├── views/
│   ├── event-leader/
│   │   ├── dashboard.html (UPDATED - add tabs)
│   │   ├── create-event.html (UPDATED - volunteer prep)
│   │   ├── review-od-participant.html (NEW)
│   │   └── review-od-volunteer.html (NEW)
│   ├── faculty/
│   │   ├── dashboard.html (UPDATED - add tabs)
│   │   ├── manage-timetables.html (NEW)
│   │   ├── review-od-participant.html (NEW)
│   │   └── review-od-volunteer.html (NEW)
│   ├── hod/
│   │   ├── dashboard.html (UPDATED - add tabs)
│   │   ├── review-od-participant.html (NEW)
│   │   └── review-od-volunteer.html (NEW)
│   └── student/
│       ├── submit-form.html (UPDATED - role selection)
│       └── profile.html (UPDATED - course/semester/division)
├── js/
│   ├── timetable-manager.js (NEW)
│   ├── subject-calculator.js (NEW)
│   ├── approval-engine.js (NEW)
│   └── config.js (EXISTING)
└── docs/
    ├── NEXT_STEPS.md (THIS FILE)
    ├── DESIGN_SYSTEM_ANALYSIS.md
    ├── CHANGELOG_UPDATE_20251114.md
    └── SESSION_LOG_20251114.md
```

---

## 🚀 Ready to Implement!

All clarifications confirmed. Implementation can begin when ready.

**Current Status:** 📋 Planning Complete, Ready for Development

**Next Action:** Implement Phase 1 (Timetable System)

---

**Document Version:** 1.0  
**Last Updated:** November 15, 2025  
**Maintained By:** GitHub Copilot  
**Review Status:** ✅ Approved for Implementation
