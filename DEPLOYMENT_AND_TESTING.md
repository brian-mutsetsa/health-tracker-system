# 🚀 DEPLOYMENT & TESTING CHECKLIST - Phase 1 & 2

**Status:** ✅ ALL CODE READY - Awaiting Render Deployment  
**Mobile APK:** ✅ Built (50.9MB)  
**Dashboard Web:** ✅ Built  
**GitHub:** ✅ Committed and Pushed  

---

## 📋 STEP 1: WAIT FOR RENDER DEPLOYMENT (CRITICAL)

After you pushed the code, Render should automatically redeploy. You need to **wait 2-5 minutes** for:

1. Render to detect the new commit
2. Render to start the deployment process
3. The `release: python manage.py migrate` line in Procfile to execute
4. The database migrations to create the missing `name` column
5. The app to come back online

**Check Render Dashboard:**
- Go to https://dashboard.render.com/
- Click your "health-tracker-api-blky" service
- Look at the **Logs** tab
- You should see:
  ```
  Running release command: python manage.py migrate
  Operations to perform:
    Apply all migrations: ... api, ...
  Running migrations:
    Applying api.0001_initial... OK
  
  Starting web service...
  ```

If you see errors in the logs, come back and we'll debug them.

---

## 📋 STEP 2: TEST SEED ENDPOINT (After Render redeploys)

Once deployment completes (you'll see "Service deployed" in logs), test:

```bash
curl https://health-tracker-api-blky.onrender.com/api/seed/
```

**Expected Response:**
```json
{
  "status": "success",
  "message": "Database seeded successfully"
}
```

If this works, you'll have 5 test patients:
- PT001 (Judy) - Hypertension
- PT002 (Ivan) - Hypertension
- PT003 (Heidi) - Asthma
- PT004 (Grace) - Heart Disease
- PT005 (Frank) - Diabetes

**Password for all:** `test123`

---

## 📋 STEP 3: TEST MOBILE APP LOGIN

1. **Open Flutter mobile app** (or APK on a device)
2. **Click "Sign Up"** to test new registration screen
3. **Fill registration form:**
   - Patient ID: `PT006-TestUser`
   - Name: Your name
   - Condition: Select one
   - Date of Birth: Any valid date
   - Password: `test123pass`
   - Optional: Add baseline vitals (weight, BP, glucose)
   - Click "Create Account"

4. **Expected result:** Success message, redirect to login

5. **Login with new credentials:**
   - Patient ID: `PT006-TestUser`
   - Password: `test123pass`
   - Should show home screen

---

## 📋 STEP 4: TEST DAILY CHECK-IN

1. **After login**, select your condition
2. **Complete 12-question check-in:**
   - Questions 1-11: Scale of 0-3
   - Question 12: Optional BP or Glucose reading
3. **Submit check-in**
4. **Verify:**
   - Success message appears
   - Risk level shown (GREEN/YELLOW/ORANGE/RED)
   - Data saved locally

---

## 📋 STEP 5: TEST PROVIDER DASHBOARD

1. **Open Flutter web dashboard**
2. **Provider login:** (use test credentials from backend, or create new)
3. **View patients list** - Should show PT001-PT005 and your new patient
4. **Click on a patient** → Detail modal opens
5. **Verify modal shows:**
   - All 12 question answers (q1-q12)
   - Blood pressure readings
   - Blood glucose readings
   - Risk assessment & color
   - Check-in history

---

## 📋 FULL END-TO-END FLOW TEST

```
Mobile App (Patient Side)
  ├─ Sign Up → Register new patient
  ├─ Login → Use registered credentials
  ├─ Select Condition → Choose from list
  ├─ Daily Check-in → Answer 12 questions
  ├─ Enter Vitals → Fill BP and/or glucose (optional)
  ├─ Submit → Upload to backend
  └─ View History → See past check-ins

Dashboard (Provider Side)
  ├─ Login → Provider credentials
  ├─ Patient List → View all patients
  ├─ Click Patient → Open detail modal
  ├─ View Answers → See all 12 questions & answers
  ├─ View Vitals → See BP & glucose
  ├─ Risk Assessment → See score and color
  └─ Check History → View past check-ins
```

---

## ⚠️ TROUBLESHOOTING

### "column api_patient.name does not exist"
**Problem:** Migrations didn't run  
**Solution:**
- Check Render logs for migration output
- Ensure Procfile has `release:` line (it should - we fixed it)
- Manually run Render deployment:
  - Go to Dashboard → Your Service → Settings
  - Find "Deploy Hooks" or just push a new commit
  - Wait for deployment to complete

### "Invalid Patient ID or password"
**Problem:** Seed hasn't run or test patients don't exist  
**Solution:**
- Call `/api/seed/` endpoint first
- Wait a few seconds
- Try login again

### Registration returns error
**Problem:** Validation error on backend  
**Check:**
- Patient ID might already exist (use a unique ID)
- Date of birth might be invalid (use realistic date)
- All required fields filled
- Check mobile app logs for full error message

### Dashboard doesn't show patient details
**Problem:** Patient or check-in data missing  
**Solution:**
- Ensure patient was registered successfully
- Ensure check-in was submitted (check mobile console logs)
- Manually test API: `https://health-tracker-api-blky.onrender.com/api/patients/PT001/`
- Should return patient data with all fields

---

## 📊 BUILD VERIFICATION (✅ ALREADY DONE)

✅ Mobile APK built successfully
- No icon errors
- 50.9MB file created
- Ready for App Store / Play Store

✅ Dashboard web built successfully
- Flutter web release build complete
- Ready for web deployment
- Includes all patient detail features

✅ All code pushed to GitHub
- main branch updated
- Both app and dashboard commits included

---

## 🎯 CURRENT STATE

| Component | Status | Location |
|-----------|--------|----------|
| Backend Procfile | ✅ Fixed | [backend/Procfile](backend/Procfile) |
| Mobile APK | ✅ Built | `mobile/build/app/outputs/flutter-apk/app-release.apk` |
| Dashboard Web | ✅ Built | `dashboard/build/web/` |
| Registration Screen | ✅ Fixed | [mobile/lib/screens/registration_screen.dart](mobile/lib/screens/registration_screen.dart) |
| GitHub | ✅ Pushed | `brian-mutsetsa/health-tracker-system` main branch |

---

## 🔄 NEXT STEPS

**Immediate (Now):**
1. Check Render dashboard for deployment completion
2. Run `curl https://health-tracker-api-blky.onrender.com/api/seed/`
3. Verify success response

**Short-term (Next 30 min):**
1. Test patient registration on mobile
2. Test login with new credentials
3. Complete a 12-question check-in
4. Verify data appears on dashboard

**Before Client Demo:**
1. Create fresh test patient with realistic data
2. Complete full check-in with all optional fields
3. Show dashboard detail modal to client
4. Highlight the 12 questions + vital signs features

---

## 📞 IF SOMETHING BREAKS

**Check in this order:**
1. Render dashboard logs → Look for migration errors
2. Mobile app console → Print statements for API calls
3. API direct test → Use curl/Postman to test endpoints
4. Database → Check if tables exist (if you have SSH access)

Let me know what you find in the Render logs and I'll help debug! 🚀
