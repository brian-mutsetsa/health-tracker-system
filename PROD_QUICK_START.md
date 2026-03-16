# Quick Start: Build, Deploy & Test (Production)

**Status:** Backend ✅ Running on Render | Dashboard ✅ Ready for Firebase | Mobile ⏳ Build & Test

**Render Backend URL:** `https://health-tracker-api-blky.onrender.com`

---

## ⚡ QUICK STEPS (30 minutes total)

### Step 1: Build Release APK (5 min)

```powershell
cd c:\dev\projects\health_tracker_system\mobile

# Clean and build
flutter clean
flutter pub get
flutter build apk --release

# APK ready at: build/app/outputs/flutter-app.apk
```

**Result:** `flutter-app.apk` (~60MB) ready to install

---

### Step 2: Push to GitHub (3 min)

```powershell
cd c:\dev\projects\health_tracker_system

git add .
git commit -m "Phase 1 & 2: Patient Auth, Daily Checkin, Appointments, Notifications"
git push -u origin main
```

**Result:** Code in GitHub, ready for production reference

---

### Step 3: Seed Test Data (1 min)

Visit this URL in your browser (or use curl):

```
https://health-tracker-api-blky.onrender.com/api/seed/
```

**Expected Response:**
```json
{
  "status": "success",
  "message": "Database seeded successfully"
}
```

**What's Created:**
- 5 test patients (PT001-PT005) with passwords
- Sample check-ins (varying risk levels: GREEN, YELLOW, ORANGE, RED)
- Example appointments
- High-risk alerts & notifications

---

### Step 4: Login & Test Mobile App (10 min)

#### 4.1 Install APK on Android Phone
```
1. Connect phone via USB or download APK file
2. Enable "Unknown Sources" in Settings > Security
3. Open file → Install
```

#### 4.2 Login as Patient
```
Patient ID: PT001
Password: test123
Condition: Hypertension (auto-detected)
```

**Expected:** Logged in, see dashboard with patient name "John Doe"

#### 4.3 Complete Daily Checkin
```
1. Tap "Daily Checkin"
2. Select Condition: Hypertension
3. Answer 12 questions:
   - Step 1 (Q1-3): Mix "None" and "Mild"
   - Step 2 (Q4-6): Mix "None" and "Mild"  
   - Step 3 (Q7-9): All "None"
   - Step 4 (Q10-12): All "None"
4. Tap "Submit"
```

**Expected:** 
- Risk level shows: **GREEN** (low score)
- Message: "Synced to Cloud"
- Checkin appears in history

---

### Step 5: Test Dashboard (5 min)

**Admin Login:**
```
URL: https://<your-firebase-domain>.web.app
Username: admin
Password: admin123
```

**Verify:**
1. ✅ Patient list shows PT001-PT005
2. ✅ Click PT001, see latest checkin (GREEN, today)
3. ✅ Click PT005, see RED risk alert
4. ✅ PT005 has notification: "RED risk level"
5. ✅ Can create appointment for patient
6. ✅ Can mark appointment complete

---

### Step 6: Test Different Risk Levels (5 min)

| Patient | Risk Level | What to See |
|---------|-----------|------------|
| PT001 | GREEN ✅ | Healthy, no alerts |
| PT002 | YELLOW ⚠️ | Moderate symptoms |
| PT003 | ORANGE 🔴 | High risk warning |
| PT005 | RED 🚨 | Critical alert for provider |

**Test on Mobile:**
```
1. Log out (PT001)
2. Login as PT005
3. Complete NEW checkin with all "Severe" answers
4. Should show RED risk
5. Check Dashboard → PT005 should have new alert
```

---

## 🔐 Test Credentials

### Mobile App (Patient Login)
```
PT001: John Doe (Hypertension) - GREEN
PT002: Jane Smith (Diabetes) - YELLOW
PT003: Robert Wilson (Cardiovascular) - ORANGE
PT004: Maria Garcia (Hypertension) - GREEN
PT005: James Brown (Diabetes) - RED ⚠️

All passwords: test123
```

### Dashboard (Web)
```
Username: admin
Password: admin123
```

---

## 📋 Expected Test Results By Screen

### Mobile - Patient Dashboard (After Login)
```
Shows:
- Patient name: "John Doe"
- Patient ID: "PT001"
- Condition: "Hypertension"
- Latest check-in: GREEN risk, today
- "Daily Checkin" button (tap to start)
- History of past check-ins
```

### Mobile - Daily Checkin Screen
```
Step 1 (Questions 1-3):
  Q1: Headaches? / Excessive thirst? / Chest pain?
  Q2: Dizziness? / Frequent urination? / Shortness of breath?
  Q3: Blurred vision? / Unusual hunger? / Swelling in legs?

Step 2 (Questions 4-6):
  Q4: Chest discomfort? / Fatigue? / Unusual fatigue?
  Q5: Shortness of breath? / Blurred vision? / Shortness of breath?
  Q6: Unusual fatigue? / Numbness/tingling? / Dizziness?

Step 3 (Questions 7-9):
  Q7: Nosebleeds? / Slow healing? / Pain in arm/neck?
  Q8: Heart palpitations? / Dizziness? / Sudden sweating?
  Q9: Medication adherence / Medication adherence / Medication adherence

Step 4 (Questions 10-12):
  Q10: Salt intake / Diet adherence / Physical activity
  Q11: Stress levels / Physical activity / Alcohol/smoking
  Q12: Optional BP/Glucose readings

Review:
  All answers shown
  Risk level calculated: RED/ORANGE/YELLOW/GREEN
  Can go back to edit
  Submit button ready
```

### Mobile - Offline Test
```
1. Disable internet
2. Complete checkin
3. Should see: "Saved Locally" (not "Synced")
4. Enable internet
5. Should auto-sync and show "Synced to Cloud"
```

### Dashboard - Patient List
```
Shows all 5 patients with:
- Name
- ID  
- Condition
- Latest risk level (color-coded)
- Last check-in date
- Can search/filter
```

### Dashboard - Patient Detail
```
When you click a patient:
- Baseline clinical data (weight, BP, glucose)
- Full check-in history
- Risk trend (recent checks)
- Button to create appointment
- Button to generate PDF
- Can edit baseline data
```

### Dashboard - Appointments
```
Shows:
- Patient name
- Scheduled date/time
- Status (SCHEDULED/COMPLETED/CANCELLED)
- Can filter by status
- Can create new appointment
- Can mark as complete
```

### Dashboard - Notifications
```
Shows:
- Unread notifications first
- Alert type (HIGH_RISK_ALERT, etc)
- Patient name and risk level
- Date/time
- Mark as read
- Delete
```

---

## 🐛 Troubleshooting

### APK won't install
```
→ Unknown Sources not enabled
→ Not enough storage (need 100MB+)
→ Uninstall previous version first
```

### Can't login on mobile
```
→ Patient ID is case-sensitive (PT001, not pt001)
→ Password must be exactly: test123
→ Check internet connection (for first login)
```

### Dashboard won't load
```
→ Clear browser cache
→ Try incognito/private window
→ Check you're logged in as admin
→ Verify Firebase hosting is deployed
```

### Checkin won't sync
```
→ Check API URL in mobile/lib/services/api_service.dart
→ Must be: https://health-tracker-api-blky.onrender.com
→ Try wifi instead of mobile data
→ Wait 1-2 minutes if Render app is sleeping
```

### No data appears after seeding
```
→ Call: https://health-tracker-api-blky.onrender.com/api/seed/
→ Check response says "success"
→ Refresh dashboard page
→ Clear browser cache
→ Mobile app may need restart
```

---

## ✅ Success Checklist

Run through this in order:

1. **APK Built**
   - [ ] APK file exists at `mobile/build/app/outputs/flutter-app.apk`
   - [ ] File size ~60-80MB

2. **Data Seeded**
   - [ ] Call `/api/seed/` endpoint
   - [ ] Get success response
   - [ ] See data appears in dashboard

3. **Patient Login Works**
   - [ ] Install APK on phone
   - [ ] Login with PT001 / test123
   - [ ] See John Doe dashboard

4. **Checkin Works**
   - [ ] Complete daily checkin on mobile
   - [ ] See risk level calculated
   - [ ] See "Synced to Cloud" message
   - [ ] Checkin appears on dashboard for same patient

5. **Dashboard Works**
   - [ ] Login as admin / admin123
   - [ ] See all 5 patients in list
   - [ ] Click patient → see details
   - [ ] See latest check-in from mobile
   - [ ] Create new appointment

6. **Alerts Work**
   - [ ] PT005 shows RED risk
   - [ ] Notification created for provider
   - [ ] PT003 shows ORANGE risk
   - [ ] Appointments created correctly

7. **Full End-to-End**
   - [ ] Mobile complete checkin → Dashboard shows it immediately
   - [ ] High-risk score triggers alert on dashboard
   - [ ] Provider appointment appears for patient to see (optional)

---

## 🚀 Summary

| Component | Status | URL |
|-----------|--------|-----|
| Backend (Django) | ✅ Running | https://health-tracker-api-blky.onrender.com |
| Dashboard (Flutter Web) | ✅ Ready | https://<firebase-domain>.web.app |
| Mobile (APK) | ⏳ Built | `mobile/build/app/outputs/flutter-app.apk` |
| Test Data | ✅ Seeded | 5 patients + checkins + alerts |
| Patient Login | ✅ Ready | Patient ID + password |

**All systems ready for production testing! 🎉**
