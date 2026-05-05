# Health Tracker System - System Testing Document

Complete the tiers in order. Every step includes an expected outcome.

---

## Credentials Quick Reference

| Role | Username | Password / PIN | Where |
|---|---|---|---|
| Super Admin (Django) | `superadmin` | `adminpassword123` | Admin panel (includes patient map) |
| Provider - Hypertension | `dr_hyper` | `password` | Web dashboard |
| Provider - Diabetes | `dr_diab` | `password` | Web dashboard |
| Provider - Asthma | `dr_asthma` | `password` | Web dashboard |
| Provider - Cardiology | `dr_cardio` | `password` | Web dashboard |
| Patient PT001 | `PT001` / `+263771000001` | `1234` | Mobile app |
| Patient PT002 | `PT002` / `+263771000002` | `2345` | Mobile app |
| Patient PT003 | `PT003` / `+263771000003` | `3456` | Mobile app |
| Patient PT015 | `PT015` / `+263771000015` | `5566` | Mobile app |

## System URLs

| System | URL |
|---|---|
| Django Admin Panel | https://health-tracker-api-blky.onrender.com/admin/ |
| Web Dashboard | https://health-tracker-zw.web.app/ |
| Mobile APK | `Vitalix.apk` in project root |

---

## TIER 1 - Super Admin

The super admin operates entirely through the Django admin panel at https://health-tracker-api-blky.onrender.com/admin/. This includes full database control, provider management, and the patient distribution map.

### 1.1 Django Admin Login

1. Open https://health-tracker-api-blky.onrender.com/admin/ in a browser.
2. Enter username `superadmin` and password `adminpassword123`. Click **Log In**.
   - **Expected:** The Django admin home page loads. The left sidebar lists tables including Users, Patients, Appointments, Check-ins, and Notifications.

### 1.2 View All Provider Accounts

1. Click **Users** in the left sidebar.
   - **Expected:** A list of all provider accounts is displayed: dr_hyper, dr_diab, dr_asthma, dr_cardio, admin, superadmin.
2. Click **dr_hyper** to open the record.
   - **Expected:** The user edit form opens showing username, email, permissions, and an Active checkbox.

### 1.3 Deactivate a Provider

1. On the dr_hyper user form, uncheck the **Active** checkbox and click **Save**.
   - **Expected:** The record saves. The user list shows dr_hyper without a green active indicator.
2. Open the web dashboard (https://health-tracker-zw.web.app/) in a new tab and attempt to log in as `dr_hyper` / `password`.
   - **Expected:** Login is rejected with an error message. Access is denied.
3. Return to the admin panel and re-check **Active** on dr_hyper. Click **Save**.
   - **Expected:** dr_hyper can now log in to the web dashboard again.

### 1.4 View Patient Records

1. Click **Patients** in the left sidebar.
   - **Expected:** All 15 patients are listed (PT001-PT015) with their names, conditions, and district fields visible.
2. Click any patient (e.g. PT001 - Tinashe Moyo).
   - **Expected:** The patient detail form opens showing: patient_id, full name, condition, district (Zimbabwe district name), phone number, PIN, assigned provider, and registration date.

### 1.5 View Appointments

1. Click **Appointments** in the left sidebar.
   - **Expected:** A list of appointment records is shown with columns for patient, provider, requested date/time, and status (Pending / Confirmed / Completed).

### 1.6 View Check-ins

1. Click **Check-ins** (or **Patient Check-ins**) in the left sidebar.
   - **Expected:** A list of check-in submissions is shown. Each record includes the patient name, submission timestamp, the 12 health response values, and a computed risk level (GREEN / YELLOW / ORANGE / RED).

### 1.7 View Notifications

1. Click **Notifications** in the left sidebar.
   - **Expected:** A list of system-generated notification messages is shown. All messages are plain readable English with no emoji, no garbled characters (no sequences like "â€"" or "â€¢").
2. Open several records and read the message text.
   - **Expected:** Messages are clean, e.g. "New appointment request from Tinashe Moyo" or "High risk alert for PT003".

### 1.8 Verify Seed Data via API

1. Open https://health-tracker-api-blky.onrender.com/api/patients/ in the browser (while still logged into the admin session, or open in a new tab).
   - **Expected:** A JSON array of 15 patient objects is returned. Each object contains a `district` field with a Zimbabwe district name (e.g. Goromonzi, Mazowe, Bindura, Hwange, Matobo).

### 1.9 Patient Distribution Map

The patient map lives inside the Django admin panel. It is accessible only to the superadmin.

1. While logged into the admin panel as `superadmin`, look at the admin home page.
   - **Expected:** A green banner at the top of the page reads **"Patient Distribution Map"** with an **Open Map** button.
2. Click **Open Map** (or navigate directly to https://health-tracker-api-blky.onrender.com/admin/patient-map/).
   - **Expected:** A full-page map of Zimbabwe loads using OpenStreetMap tiles. Coloured pin markers are scattered across the country at district locations. Pins are colour-coded: RED = high risk, ORANGE = elevated, YELLOW = moderate, GREEN = stable.
3. Read the summary bar above the map.
   - **Expected:** Four counters are shown: High Risk, Elevated, Moderate, Stable — each with the correct patient count for that risk level.
4. Click any pin on the map.
   - **Expected:** A popup appears showing: patient name, patient ID, condition, district, risk level (in the risk colour), total check-ins, last check-in date, and assigned provider. A **View in Admin Panel** button is visible at the bottom of the popup.
5. Click **View in Admin Panel** inside the popup.
   - **Expected:** The browser navigates to the Patients list in the admin panel, pre-filtered to that patient's ID.
6. Use the browser back button to return to the map. Click the **High Risk** filter button above the map.
   - **Expected:** Only RED pins remain visible. All other pins are hidden. The High Risk button is highlighted.
7. Click **Elevated**, then **Moderate**, then **Stable** in turn.
   - **Expected:** Each click filters the map to show only that risk category.
8. Click **All** to reset.
   - **Expected:** All 15 patient pins are visible again across the map.

---

## TIER 2 - Web Dashboard (Provider Portal)

Test with a regular provider account. The patient map is not part of the web dashboard — it is in the Django admin panel (Tier 1, section 1.9).

### 2.1 Login

1. Open https://health-tracker-zw.web.app/ and log in as `dr_hyper` / `password`.
   - **Expected:** The dashboard loads on the Overview tab. The provider name is shown in the top bar. No garbled characters, emoji, or encoding errors anywhere on the screen.

### 2.2 Overview Tab

1. Review the summary cards on the Overview tab.
   - **Expected:** Cards display: total patients assigned to this provider, number of pending appointments, number of high-risk patients, and total check-ins. All numbers are visible and formatted correctly.
2. Check any risk-level label text.
   - **Expected:** Labels read "High Risk - Action Required" with a plain hyphen, not a garbled em-dash character.

### 2.3 All Patients - Desktop Table Navigation

1. Click **All Patients** in the sidebar.
   - **Expected:** A table loads with columns: Patient Name, Condition, Risk Status, Logs, Last Update, Action.
2. Move the mouse cursor over a patient row without clicking.
   - **Expected:** The row highlights with a subtle teal background, indicating the entire row is clickable.
3. Click anywhere on a patient row (not on the button).
   - **Expected:** The patient detail screen opens for that patient.
4. Press the browser back button to return to the patient list. Click the **Open** button in the Action column of a different row.
   - **Expected:** The same patient detail screen opens for that patient.
5. Click the message icon (envelope/chat icon) in the Action column of any row.
   - **Expected:** A message drawer or dialog opens addressed to that patient.

### 2.4 All Patients - Mobile Card View

1. Resize the browser window to below 768 px wide, or open DevTools and select a mobile device preset.
   - **Expected:** The patient table disappears and is replaced by a vertical list of patient cards. Each card shows the patient's name, condition, risk badge, last check-in date, and total check-in count.
2. Tap or click anywhere on a patient card.
   - **Expected:** The patient detail screen opens for that patient.

### 2.5 Patient Detail - Profile Tab

1. Open any patient from the All Patients list.
   - **Expected:** The AppBar shows "Patient Detail" with a subtitle in the format "ID: PT001 | Hypertension" showing the patient ID and condition.
2. Read the blue information banner at the top of the profile tab.
   - **Expected:** A banner explains how to use the tabs to navigate between Profile, Check-ins, and Clinical Visits.
3. Review all fields on the profile tab.
   - **Expected:** Fields display: Full Name, Date of Birth, Gender, District, Phone, Condition, Assigned Provider, Registration Date. No degree symbols (°), no em-dashes (—), no garbled characters anywhere.

### 2.6 Patient Detail - Check-ins Tab

1. Click the **Check-ins** tab on the patient detail screen.
   - **Expected:** A list of check-in submissions for this patient appears. Each entry shows the date, a coloured risk level badge (GREEN/YELLOW/ORANGE/RED), and a summary of the health responses.
2. Check the date format on any check-in entry.
   - **Expected:** Dates use commas as separators, e.g. "May 5, 2:30 PM". There are no middle dots or garbled separator characters.

### 2.7 Patient Detail - Clinical Visits Tab

1. Click the **Clinical Visits** tab on the patient detail screen.
   - **Expected:** A list of appointments for this patient appears, showing the date, status (Pending / Confirmed / Completed), and any notes.

### 2.8 Risk Banner

1. Open a patient who has a RED or ORANGE risk level.
   - **Expected:** A coloured risk banner appears on the profile tab. The text uses a plain hyphen, e.g. "High Risk - Immediate Attention Needed". No em-dashes or garbled characters.

### 2.9 Appointments Tab

1. Click **Appointments** in the sidebar.
   - **Expected:** A list of appointment requests appears, grouped or labelled by status (Pending, Confirmed, Completed). The badge count on the sidebar item matches the number of pending items shown.
2. Click **Confirm** on a pending appointment.
   - **Expected:** The appointment status changes to Confirmed. The pending badge count on the sidebar decreases by one.

### 2.10 High Risk Alerts Tab

1. Click **High Risk Alerts** in the sidebar.
   - **Expected:** A list of patients with RED or ORANGE risk levels appears. Each entry shows the patient name, condition, risk level, and last check-in date. The badge count on the sidebar item matches the number of patients listed.
2. Click on a patient entry in the list.
   - **Expected:** The patient detail screen opens for that patient.

### 2.11 Analytics Tab

1. Click **Analytics** in the sidebar.
   - **Expected:** Charts and graphs appear showing check-in trends over time, risk level distribution (e.g. pie or bar chart), and condition breakdown. All axis labels and legends are plain text with no special characters.

### 2.12 Notifications Tab

1. Click **Notifications** in the sidebar.
   - **Expected:** A feed of system notifications appears (appointment requests, high-risk alerts, new check-ins). All message text is plain readable English with no emoji and no garbled characters.
2. Click on a notification.
   - **Expected:** The app navigates to the relevant patient or appointment that the notification refers to.

### 2.13 Register a New Patient

1. Find and click the **Register Patient** button (on the Overview tab or the All Patients tab header).
   - **Expected:** A registration form opens with fields for: Full Name, Date of Birth, Gender, Condition, District, Phone (+263 format), and PIN (4-6 digits).
2. Fill in all fields with valid data and click **Register** (or **Submit**).
   - **Expected:** A success message appears. The new patient appears in the All Patients list.

### 2.14 Book an Appointment

1. From the All Patients list, open a patient and go to the Clinical Visits tab. Click **Book Appointment** (or use the Appointments tab to create one for a patient).
   - **Expected:** An appointment creation form opens.
2. Select a date, time, and reason. Submit the form.
   - **Expected:** The appointment is created and visible in the Appointments list with status Pending.
3. Try booking a second appointment at the exact same date and time for any patient.
   - **Expected:** An error message appears reading "That time slot is already booked. Please choose another time." There are no emoji in this message.

### 2.15 Message a Patient

1. From the patient list, click the message icon on any patient row.
   - **Expected:** A message composer opens (drawer or dialog) showing the patient's name.
2. Type a short message and click **Send**.
   - **Expected:** The message appears in the conversation thread. No error is shown.

---

## TIER 3 - Mobile App (Vitalix)

Install `Vitalix.apk` on an Android device. Enable "Install from unknown sources" in device settings if required.

### 3.1 Phone + PIN Login

1. Open the Vitalix app. On the login screen, select the **Phone** tab.
2. Enter phone number `+263771000001` and PIN `1234`. Tap **Login**.
   - **Expected:** The home screen loads for patient PT001 (Tinashe Moyo). The patient's name and condition are displayed. No garbled characters on any part of the home screen.

### 3.2 Patient ID Login

1. Log out and return to the login screen. Select the **ID** tab.
2. Read the hint text below the patient ID field.
   - **Expected:** The hint reads "ID login - Patient ID: PT001-PT015" using plain hyphens. No em-dashes, no garbled characters.
3. Enter patient ID `PT002` and PIN `2345`. Tap **Login**.
   - **Expected:** The home screen loads for PT002.

### 3.3 New Patient Registration

1. Tap **Register** or **Create Account** on the login screen.
   - **Expected:** A multi-field registration form appears.
2. Fill in: Name, Date of Birth, Gender, Condition, District, Phone number, and PIN. Tap **Register**.
   - **Expected:** A loading message appears reading "Connecting to server - this may take up to 30 seconds on first use." using a plain hyphen with no garbled characters.
3. After registration completes, a confirmation screen appears.
   - **Expected:** A button reads "I have saved my details - Go to Login" with a plain hyphen. Tapping it returns to the login screen.

### 3.4 Daily Check-in (12 Questions)

1. Log in as PT001. Tap **Daily Check-in** or the check-in prompt on the home screen.
   - **Expected:** A questionnaire begins with 12 health questions presented one at a time (e.g. blood pressure reading, heart rate, headache severity, shortness of breath, chest pain level, etc.).
2. Answer all 12 questions and submit.
   - **Expected:** A risk result screen appears showing a colour-coded risk level (GREEN / YELLOW / ORANGE / RED) and a plain-text label. No special characters or emoji in the result.

### 3.5 Check-in History

1. Navigate to the **History** or **Check-in History** tab.
   - **Expected:** A list of previous check-ins appears, each showing a date and risk level badge.
2. Check the date format on any entry.
   - **Expected:** Dates use a comma, e.g. "May 5, 2:30 PM". No middle dots or garbled separators.
3. Tap any check-in entry.
   - **Expected:** A detail screen opens showing all 12 question responses and the computed risk score for that submission.

### 3.6 Appointments

1. Navigate to the **Appointments** tab.
   - **Expected:** A list of the patient's appointments appears showing status (Pending / Confirmed / Completed).
2. Tap **Request Appointment** or **Book Appointment**.
   - **Expected:** A form appears to select a date, time, and reason.
3. Fill in the form and submit.
   - **Expected:** A success message appears reading "Request sent - awaiting provider approval" with a plain hyphen and no garbled characters.
4. Try requesting a slot that is already taken.
   - **Expected:** An error message appears reading "That time slot is already booked. Please choose another time." No emoji in this message.

### 3.7 Messages

1. Navigate to the **Messages** tab.
   - **Expected:** Any existing message threads with the assigned provider are displayed.
2. Type a message and tap **Send**.
   - **Expected:** The message appears in the thread immediately. No error is shown.

### 3.8 Notifications

1. Navigate to the **Notifications** tab.
   - **Expected:** A list of notifications appears (appointment updates, risk alerts, reminders). All text is plain English with no emoji and no garbled characters.
2. Note the badge count on the Notifications tab icon before opening any notification.
3. Tap a notification to open it.
   - **Expected:** The badge count decreases. The notification is marked as read.

### 3.9 Offline Mode

1. Enable Airplane Mode on the device.
2. Open the Vitalix app (already logged in from a prior session).
   - **Expected:** The home screen loads using locally cached data. The app does not crash and does not show a blank screen.
3. Navigate to Check-in History.
   - **Expected:** Previous check-in records are visible from the local Hive cache, without any network request.
4. Start a new daily check-in and complete all 12 questions.
   - **Expected:** The risk result is computed instantly on-device using the TFLite model. No network request is made. The result appears without delay.
5. Re-enable mobile data or Wi-Fi.
   - **Expected:** Any locally saved check-in data syncs to the server. No data is lost.

---

## Cross-Tier Tests

### CT-1: Provider books appointment, patient sees it

1. **(Tier 2)** Log in as `dr_hyper`. Book an appointment for PT001 on a specific future date.
   - **Expected:** The appointment appears in the Appointments tab with status Pending.
2. **(Tier 3)** Log in on the mobile app as PT001.
   - **Expected:** The same appointment is visible in the PT001 Appointments tab showing the correct date and Pending status.

### CT-2: Patient check-in triggers high-risk alert on dashboard

1. **(Tier 3)** Log in as PT001 and submit a daily check-in with all maximum-severity answers (highest blood pressure, heart rate, etc.).
   - **Expected:** The result screen shows a RED risk level.
2. **(Tier 2)** Log in to the web dashboard as `dr_hyper` (PT001's assigned provider).
   - **Expected:** PT001 appears in the High Risk Alerts tab. The Notifications tab shows a new high-risk alert for PT001. Badge counts reflect the new alert.

### CT-3: Admin deactivates provider, provider is blocked

1. **(Tier 1)** In the Django admin panel, deactivate `dr_diab` (uncheck Active, save).
   - **Expected:** The admin panel shows the change saved successfully.
2. **(Tier 2)** Attempt to log in to the web dashboard as `dr_diab` / `password`.
   - **Expected:** Login is rejected. An error message is displayed. The dashboard does not load.
3. **(Tier 1)** Re-activate `dr_diab` in the admin panel.
4. **(Tier 2)** Log in as `dr_diab` again.
   - **Expected:** Login succeeds. The dashboard loads normally.

