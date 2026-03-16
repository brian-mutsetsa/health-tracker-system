# Complete Testing Guide - Health Tracker System

## Quick Start - Test All Fixes

### Step 1: Seed Test Data (Backend)
**Goal:** Populate database with PT001-PT005 test patients

**Option A: Using Curl** (Easiest)
```bash
curl -X GET https://health-tracker-api-blky.onrender.com/api/seed/
```

**Option B: Using Postman**
1. Open Postman
2. New Request → GET
3. URL: `https://health-tracker-api-blky.onrender.com/api/seed/`
4. Send
5. Expected: JSON response showing created patients

**Expected Output:**
```json
{
  "status": "success",
  "message": "Test data seeded successfully",
  "patients_created": 5,
  "checkins_created": 5,
  ...
}
```

**Verification:** Check Render database shows 5 patients and 5+ check-in records

---

### Step 2: Verify Dashboard Loads Patient Data
**Goal:** Confirm PT001-PT005 appear in web dashboard

1. Open Firebase Dashboard: Open your deployed web dashboard
2. Login (your provider credentials)
3. Patient List should show:
   - PT001: John Doe (Hypertension) - GREEN risk
   - PT002: Jane Smith (Diabetes) - YELLOW risk
   - PT003: Robert Wilson (Cardiovascular) - ORANGE risk
   - PT004: Michael Davis (Hypertension) - GREEN risk
   - PT005: James Brown (Diabetes) - RED risk

**If patients don't appear:**
- Check browser console for errors
- Verify backend API is accessible: `https://health-tracker-api-blky.onrender.com/api/patients/`
- Check CORS settings in Django backend

---

### Step 3: Test Mobile App Login
**Goal:** Verify mobile authentication works

**Prerequisites:**
1. Build mobile app for iOS/Android (or use web version)
2. Test patients created from Step 1

**Test Cases:**

#### Test Case 3.1: Valid Login
1. Launch app
2. You should see splash screen with logo (2 second delay)
3. Then navigate to login screen
4. Enter:
   - Patient ID: `PT001`
   - Password: `test123`
5. Tap Login
6. **Expected:** Navigate to home screen showing "Patient: John Doe"

#### Test Case 3.2: Invalid Password
1. Login screen
2. Patient ID: `PT001`
3. Password: `wrongpassword`
4. Tap Login
5. **Expected:** Error message: "Invalid credentials"

#### Test Case 3.3: Splash Screen Behavior
**First Time Install:**
1. Clear app cache/reinstall
2. **Expected Flow:**
   - Splash screen (2 sec)
   - Tutorial screens (if implemented)
   - Then login screen

**Returning User:**
1. Login successfully once
2. Close and reopen app
3. **Expected Flow:**
   - Splash screen (2 sec)
   - Skip tutorial
   - Go directly to login or home (based on session)

---

### Step 4: Test Daily Checkin Questions
**Goal:** Verify each question renders with correct answer options

**Prerequisites:**
1. Login as PT001 (password: test123)
2. Navigate to daily checkin screen

**Verification for Each Condition:**

#### Hypertension (PT001) Questions
| Q# | Question | Expected Answer Type | Expected Buttons |
|----|----------|-------------------|------------------|
| 1-8 | Symptoms (headaches, dizziness, etc.) | Scale | None/Mild/Moderate/Severe |
| 9 | Medication adherence | Medication | Yes fully/Missed once/Missed more/Did not take |
| 10 | Salt intake | Intake | None/Small/Moderate/High |
| 11 | Stress levels | Scale | None/Low/Moderate/High |
| 12 | Blood pressure reading | Text Input | Text field with "e.g., 120/80" |

#### Diabetes (PT002) Questions
| Q# | Question | Expected Answer Type | Expected Buttons |
|----|----------|-------------------|------------------|
| 1-8 | Symptoms (thirst, fatigue, etc.) | Scale | None/Mild/Moderate/Severe |
| 9 | Medication adherence | Medication | Yes fully/Missed once/Missed more/Did not take |
| 10 | Diet adherence | Intake | Excellent/Good/Fair/Poor |
| 11 | Physical activity | Scale | None/Light/Moderate/Vigorous |
| 12 | Blood glucose reading | Text Input | Text field with "e.g., 120 mg/dL" |

#### Cardiovascular (PT003) Questions
| Q# | Question | Expected Answer Type | Expected Buttons |
|----|----------|-------------------|------------------|
| 1-8 | Symptoms (chest pain, SOB, etc.) | Scale | None/Mild/Moderate/Severe |
| 9 | Medication adherence | Medication | Yes fully/Missed once/Missed more/Did not take |
| 10 | Physical activity | Scale | None/Light/Moderate/Vigorous |
| 11 | Alcohol/smoking | Intake | None/Minimal/Moderate/High |
| 12 | Stress/anxiety | Scale | None/Low/Moderate/High |

**Test Procedure:**
1. For each condition (test with PT001, PT002, PT003):
   - Complete all 12 questions
   - Verify Q12 shows text input field (not buttons)
   - Verify Q9 shows medication-specific options
   - Verify Q10 shows intake-specific options

---

### Step 5: Test Check-in Submission
**Goal:** Verify answers upload to backend correctly

1. Complete daily checkin with various answer selections
2. Tap "Submit Check-in"
3. **Expected:**
   - Loading indicator appears
   - Success message: "Check-in submitted successfully"
   - Data sent to: `POST /api/checkins/create/`

**Verify in Backend:**
```bash
curl https://health-tracker-api-blky.onrender.com/api/checkins/?patient_id=PT001
```
Should return today's check-in with all answered questions

---

### Step 6: Test Risk Level Calculation
**Goal:** Verify risk scoring and color coding

**Test Cases:**

#### Green Risk (Score 0-8)
- Example: PT001 with mostly "None" and "Mild" answers
- **Expected:** GREEN badge, green progress bar

#### Yellow Risk (Score 9-16)
- Example: PT002 with mixed "Mild" and "Moderate" answers
- **Expected:** YELLOW badge, yellow progress bar

#### Orange Risk (Score 17-24)
- Example: PT003 with mostly "Moderate" and some "Severe" answers
- **Expected:** ORANGE badge, orange progress bar

#### Red Risk (Score 25-36)
- Example: PT005 with mostly "Severe" answers
- **Expected:** RED badge, red progress bar + alert notification

---

## Troubleshooting

### Issue: Seeding Returns 500 Error
**Possible Causes:**
1. Database constraint violation
2. Missing fields in seed data
3. Model mismatch

**Solution:**
1. Check Render logs: Dashboard → Service → Logs
2. Look for Django error traceback
3. Contact support if database corrupted

---

### Issue: Login Returns "Invalid Credentials"
**Possible Causes:**
1. Seeding didn't run (PT001 doesn't exist)
2. Password mismatch
3. API endpoint not responding

**Solution:**
1. Verify seeding successful (Step 1)
2. Verify patient exists: `curl https://health-tracker-api-blky.onrender.com/api/patients/`
3. Try password: exactly `test123`

---

### Issue: Daily Checkin Shows Wrong Buttons for Q9/Q10
**Cause:** Question rendering fix not deployed

**Solution:**
1. If mobile app: Rebuild/redeploy from latest code
2. If dashboard: Clear browser cache
3. Check git history: Should see commits for dynamic rendering fix

---

### Issue: Dashboard Doesn't Show Patient Data
**Possible Causes:**
1. Seeding didn't run
2. CORS not configured
3. Firebase authentication issue

**Solution:**
1. Check browser console for errors
2. Verify `/api/patients/` endpoint accessible
3. Check Firebase permissions in settings.json

---

## Success Criteria

✅ **Seeding Works:** PT001-PT005 appear in database
✅ **Dashboard Works:** Patient list loads with correct risk levels
✅ **Login Works:** Can authenticate as any test patient
✅ **Questions Work:** Each question shows correct answer options
✅ **Submission Works:** Check-ins save to backend
✅ **Risk Scoring:** Colors match expected ranges

---

## Quick Test Checklist

- [ ] Seeding endpoint returns success
- [ ] Dashboard shows 5 test patients
- [ ] Can login as PT001 with password test123
- [ ] Daily checkin Q9 shows medication options
- [ ] Daily checkin Q10 shows intake/diet options
- [ ] Daily checkin Q12 shows text input field
- [ ] Successfully submit checkin
- [ ] Backend shows new check-in record

---

## For debugging locally (if needed):

```bash
# Start Flask backend
cd backend
python manage.py runserver

# In another terminal, test seed endpoint
curl http://localhost:8000/api/seed/

# Check if patients created
curl http://localhost:8000/api/patients/
```

---

## Next Steps After Testing

1. If all tests pass: ✅ Feature complete, ready for production
2. If issues found: Report specific test case and error message
3. Consider: Load testing, security testing, performance optimization

