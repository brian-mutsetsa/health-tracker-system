# Health Tracker System — Testing Guide

> **Test order:** Complete each tier fully before moving to the next.
> **Credentials summary at the end of this document.**

---

## TIER 1 — Super Admin (Django Admin Panel)

**URL:** https://health-tracker-api-blky.onrender.com/admin/
**Login:** `superadmin` / `adminpassword123`

### 1.1 Login
1. Open the admin panel URL in a browser.
2. Enter credentials and click **Log In**.
3. **Expect:** Django admin home page with tables listed (Users, Patients, Appointments, Check-ins, Notifications, etc.).

### 1.2 Provider Management
1. Click **Users** in the left sidebar.
2. **Expect:** List of all provider accounts (dr_hyper, dr_diab, dr_asthma, dr_cardio, admin, superadmin).
3. Click **dr_hyper** to open the record.
4. **Expect:** Full user form with username, email, staff flags.
5. Scroll to **Active** checkbox — uncheck it and click **Save**.
6. **Expect:** User marked inactive. Confirm by logging into the web dashboard as dr_hyper — login should be rejected.
7. Return to admin panel, re-check **Active** and save to restore access.

### 1.3 Patient Records
1. Click **Patients** in the sidebar.
2. **Expect:** All 15 patients listed (PT001-PT015) with names, conditions, and district fields.
3. Click any patient (e.g. PT001 - Tinashe Moyo).
4. **Expect:** Full patient record with fields: patient_id, name, condition, district, phone, PIN, assigned provider, registration date.

### 1.4 Appointments
1. Click **Appointments** in the sidebar.
2. **Expect:** List of appointment records with patient, provider, date, status fields.
3. Note: Appointment data grows as providers and patients interact via the apps.

### 1.5 Check-ins
1. Click **Check-ins** (or **Patient Check-ins**) in the sidebar.
2. **Expect:** List of check-in records showing patient, timestamp, 12 health responses, and computed risk score/level.

### 1.6 Notifications
1. Click **Notifications** in the sidebar.
2. **Expect:** System-generated notifications (all plain text, no emoji or garbled characters).
3. Verify messages are readable - e.g. "New appointment request from Tinashe Moyo" (no garbled characters).

### 1.7 Seed Data Verification
1. Open a browser to: https://health-tracker-api-blky.onrender.com/api/patients/
2. **Expect:** JSON array of 15 patient objects. Each has `district` field populated with a Zimbabwe district name.

---

## TIER 2 — Web Dashboard (Provider Portal)

**URL:** https://health-tracker-zw.web.app/
**Test accounts:** dr_hyper / dr_diab / dr_asthma / dr_cardio / admin - all use password `password`

### 2.1 Login
1. Open the dashboard URL.
2. Enter `dr_hyper` and `password`, click **Sign In**.
3. **Expect:** Dashboard loads showing the Overview tab. Provider name shown in top bar. No garbled characters anywhere.

### 2.2 Overview Tab
1. **Expect:** Summary cards showing total patients, pending appointments, high-risk count, total check-ins.
2. High-risk cards should use labels like "High Risk - Action Required" (plain dash, not garbled).
3. Cards should be readable on both desktop and mobile viewport widths.

### 2.3 All Patients Tab - Desktop Row Navigation
1. Click **All Patients** in the sidebar.
2. **Expect:** Table of patients with columns: Patient Name, Condition, Risk Status, Logs, Last Update, Action.
3. Click anywhere on a patient row (not just the button).
4. **Expect:** Navigates to the patient detail page for that patient.
5. Hover over a row - **Expect:** Subtle teal highlight shows the row is interactive.
6. Click the **Open** button in the Action column of a different row.
7. **Expect:** Same navigation to patient detail.
8. Click the message icon in the Action column.
9. **Expect:** Message drawer opens for that patient.

### 2.4 All Patients Tab - Mobile View
1. Resize browser below 768 px width (or use browser DevTools mobile mode).
2. **Expect:** Patient list switches to card layout. Each card shows name, condition, risk badge, last check-in date, total check-ins.
3. Tap/click anywhere on a patient card.
4. **Expect:** Navigates to patient detail page.

### 2.5 Patient Detail - Profile Tab
1. Open any patient from the All Patients list.
2. **Expect:** AppBar shows "Patient Detail" with subtitle "ID: PT001 | Hypertension" (patient's ID and condition).
3. A blue information banner at the top of the profile tab explains how to navigate the tabs.
4. **Expect:** Fields show: Full Name, Date of Birth, Gender, District, Phone, Condition, Assigned Provider, Registration Date.
5. **Expect:** No degree symbols, no em-dashes, no garbled characters anywhere in the form.

### 2.6 Patient Detail - Check-ins Tab
1. Click the **Check-ins** tab.
2. **Expect:** List of check-in records for this patient. Each shows date, risk level badge, and summary of responses.
3. Risk level badge colour: GREEN = green, YELLOW = amber, ORANGE = orange, RED = red.
4. Check-in dates use commas not middle dots (e.g. "May 5, 2:30 PM" not garbled separator).

### 2.7 Patient Detail - Clinical Visits Tab
1. Click the **Clinical Visits** tab.
2. **Expect:** Appointment history for this patient. Each appointment shows date, status, and notes.

### 2.8 Risk Banner Labels
1. Return to the patient detail profile.
2. If a high-risk patient, a risk banner is shown.
3. **Expect:** Banner text uses plain " - " (hyphen), not an em-dash or garbled character.

### 2.9 Appointments Tab
1. Click **Appointments** in the sidebar.
2. **Expect:** List of pending and confirmed appointment requests.
3. Pending count badge on the sidebar/bottom nav should match the number shown in the list.
4. Click **Confirm** on a pending appointment.
5. **Expect:** Status changes to Confirmed. Badge count decreases.

### 2.10 High Risk Alerts Tab
1. Click **High Risk Alerts**.
2. **Expect:** List of patients flagged RED or ORANGE. Each entry shows patient name, condition, risk level, last check-in date.
3. Badge on sidebar tab should match the number of high-risk patients shown.
4. Click a patient name or row.
5. **Expect:** Opens that patient's detail page.

### 2.11 Analytics Tab
1. Click **Analytics**.
2. **Expect:** Charts showing check-in trends, risk distribution, condition breakdown. Labels are plain text, no special characters.

### 2.12 Notifications Tab
1. Click **Notifications**.
2. **Expect:** Feed of system notifications - appointment requests, high-risk alerts, new check-ins.
3. **Expect:** All messages are readable plain text. No emoji, no garbled characters.
4. Click a notification.
5. **Expect:** Navigates to the relevant patient or appointment (if applicable).

### 2.13 Register Patient (Provider Workflow)
1. Look for a **Register Patient** button (on the Overview or Patients tab).
2. Fill in: Full Name, Date of Birth, Gender, Condition, District, Phone number (+263 format), PIN (4-6 digits).
3. Click **Register**.
4. **Expect:** Success message. New patient appears in the All Patients list.

### 2.14 Book Appointment for Patient
1. From the All Patients list, open a patient.
2. Navigate to the Clinical Visits tab and book an appointment.
3. **Expect:** Appointment created and visible in the Appointments list.
4. If the slot is already taken, **Expect:** Error message: "That time slot is already booked. Please choose another time." (no emoji).

### 2.15 Message Patient
1. From the patient list, click the message icon on any row.
2. **Expect:** A message drawer or dialog opens.
3. Type a message and send.
4. **Expect:** Message is sent and visible in the conversation thread.

### 2.16 Super Admin - Patient Map (admin account only)
1. Log out and log back in as `admin` / `password`.
2. **Expect:** An extra **Patient Map** item appears in the sidebar (not visible when logged in as other providers).
3. Click **Patient Map**.
4. **Expect:** A Zimbabwe map loads showing coloured dot markers for all 15 patients.
   - RED dots = high risk patients
   - ORANGE dots = elevated risk
   - YELLOW dots = moderate risk
   - GREEN dots = stable patients
5. Click any dot on the map.
6. **Expect:** A popup card appears showing the patient's name, ID, condition, district, risk level, check-in count, and an **Open Patient Record** button.
7. Click **Open Patient Record**.
8. **Expect:** Navigates to that patient's detail page.
9. Test the filter chips at the top (High Risk, Elevated, Moderate, Stable, All).
10. **Expect:** Selecting a chip filters the visible dots on the map to only that risk category.

---

## TIER 3 — Mobile App (Vitalix APK)

**APK file:** `Vitalix.apk` (in project root)
**Install:** Transfer to Android device and install (enable "Install from unknown sources" in device settings if needed).

### 3.1 Phone + PIN Login
1. Open the Vitalix app.
2. On the login screen, select the **Phone Login** tab.
3. Enter phone `+263771000001` and PIN `1234`.
4. Tap **Login**.
5. **Expect:** Home screen loads for patient PT001 (Tinashe Moyo). No garbled text on home screen.

### 3.2 Patient ID Login
1. Log out and return to login screen.
2. Select the **ID Login** tab.
3. Enter patient ID `PT002` and PIN `2345`.
4. **Expect:** Login hint below the field reads: "ID login - Patient ID: PT001-PT015" (plain dashes, no garbled characters).
5. Tap **Login**.
6. **Expect:** Home screen loads for PT002.

### 3.3 Registration (New Patient)
1. Tap **Register** / **Create Account** on the login screen.
2. Fill in all required fields: Name, DOB, Gender, Condition, District, Phone, PIN.
3. Tap **Register**.
4. **Expect:** Loading message: "Connecting to server - this may take up to 30 seconds on first use." (plain dash, no garbled characters).
5. On success: confirmation screen with "I have saved my details - Go to Login" button.
6. Tap that button - **Expect:** Returns to login screen.

### 3.4 Daily Check-in (12 Questions)
1. Log in as PT001.
2. Tap **Daily Check-in** or the check-in card on the home screen.
3. **Expect:** 12 health questions presented one at a time (blood pressure, heart rate, headache severity, shortness of breath, etc.).
4. Answer all 12 questions.
5. **Expect:** Risk score calculated and displayed (colour-coded: GREEN/YELLOW/ORANGE/RED).
6. **Expect:** Risk label uses plain text, no special characters.

### 3.5 Check-in History
1. Navigate to **History** or **Check-in History** tab.
2. **Expect:** List of previous check-ins, each showing date and risk level.
3. Dates should use commas: "May 5, 2:30 PM" (not a garbled separator).
4. Tap any check-in.
5. **Expect:** Detail view showing all 12 responses and the computed risk score.

### 3.6 Appointments
1. Navigate to **Appointments** tab.
2. **Expect:** List of existing appointments (pending / confirmed / completed).
3. Tap **Request Appointment** or **Book Appointment**.
4. Select a date, time, and reason.
5. Tap **Submit**.
6. **Expect:** Success message: "Request sent - awaiting provider approval" (plain dash, no garbled characters).
7. If the slot is taken, **Expect:** "That time slot is already booked. Please choose another time." (no emoji).

### 3.7 Messages
1. Navigate to **Messages** tab.
2. **Expect:** Conversation thread with the assigned provider (if any messages exist).
3. Type a message and tap **Send**.
4. **Expect:** Message appears in the thread.

### 3.8 Notifications
1. Navigate to **Notifications** tab.
2. **Expect:** List of notifications (appointment confirmations, reminders, risk alerts).
3. **Expect:** All notification text is plain ASCII - no emoji, no garbled characters.
4. Badge on the tab should show count of unread notifications.
5. Open a notification - **Expect:** Badge count decreases.

### 3.9 Offline Mode
1. Enable Airplane Mode on the device.
2. Open the app (already logged in from a previous session).
3. **Expect:** Home screen loads using cached data (no crash, no blank screen).
4. Navigate to Check-in History - **Expect:** Previous check-ins visible from local cache.
5. Attempt a new check-in while offline.
6. **Expect:** Check-in saved locally, or an appropriate "No internet connection" message.
7. Re-enable network - **Expect:** Any queued data syncs to the server.

### 3.10 Risk Model (Offline TFLite)
1. With Airplane Mode still ON, complete a fresh daily check-in (all 12 questions).
2. **Expect:** Risk score is computed locally using the on-device TFLite model (not a server call).
3. Result should appear immediately without network delay.
4. Reconnect and check the backend admin panel (Tier 1) - **Expect:** The offline check-in record eventually syncs and appears in the admin panel check-ins list.

---

## Cross-Tier Verification Scenarios

These tests span multiple tiers to confirm end-to-end data flow.

### CT-1: Provider creates appointment -> Patient sees it
1. **(Tier 2)** Log in to dashboard as dr_hyper, book an appointment for PT001 on a specific date.
2. **(Tier 3)** Log in to mobile as PT001.
3. **Expect:** The appointment appears in the PT001 Appointments tab.

### CT-2: Patient check-in triggers high-risk alert
1. **(Tier 3)** Log in as a patient and complete a check-in with all high-risk answers.
2. **(Tier 2)** Log in to dashboard as the patient's assigned provider.
3. **Expect:** The patient appears in the High Risk Alerts tab. Notification badge increments.

### CT-3: Admin creates provider -> Provider can log in
1. **(Tier 1)** In the Django admin panel, create a new User with a provider role.
2. **(Tier 2)** Attempt to log in to the web dashboard with the new credentials.
3. **Expect:** Login succeeds and the provider dashboard loads.

### CT-4: Deactivate provider -> Login blocked
1. **(Tier 1)** Deactivate dr_diab in the admin panel (uncheck Active, save).
2. **(Tier 2)** Attempt to log in as dr_diab.
3. **Expect:** Login fails with an appropriate error message.
4. **(Tier 1)** Re-activate the account.
5. **(Tier 2)** Log in again - **Expect:** Login succeeds.

---

## Test Credentials Reference

| Account | Username / ID | Password / PIN | Platform |
|---|---|---|---|
| Super Admin | `superadmin` | `adminpassword123` | Admin panel (Tier 1) |
| Provider - Hypertension | `dr_hyper` | `password` | Web dashboard (Tier 2) |
| Provider - Diabetes | `dr_diab` | `password` | Web dashboard (Tier 2) |
| Provider - Asthma | `dr_asthma` | `password` | Web dashboard (Tier 2) |
| Provider - Cardiology | `dr_cardio` | `password` | Web dashboard (Tier 2) |
| Super Admin Provider | `admin` | `password` | Web dashboard (Tier 2) - sees Patient Map |
| Patient PT001 | `PT001` / `+263771000001` | `1234` | Mobile app (Tier 3) |
| Patient PT002 | `PT002` / `+263771000002` | `2345` | Mobile app (Tier 3) |
| Patient PT003 | `PT003` / `+263771000003` | `3456` | Mobile app (Tier 3) |
| Patient PT004-PT015 | `PT004`-`PT015` | incremental PINs | Mobile app (Tier 3) |
| Patient PT015 | `PT015` / `+263771000015` | `5566` | Mobile app (Tier 3) |

---

## System URLs

| Resource | URL |
|---|---|
| Backend API | https://health-tracker-api-blky.onrender.com |
| Django Admin | https://health-tracker-api-blky.onrender.com/admin/ |
| Web Dashboard | https://health-tracker-zw.web.app/ |
| Mobile APK | `Vitalix.apk` (project root) |

