# Health Tracker System - System Testing Document

Complete the tiers in order. Every step includes an expected outcome.

---

## DEFENCE DEMONSTRATION SCRIPTS

These are five scripted walk-throughs designed for the project defence. Each one is self-contained, tells you exactly what to type, and points out what the examiner should see. Run them in order for the smoothest presentation.

> **All demonstrations use the live production system — no local setup required.**
>
> | System | Live URL |
> |---|---|
> | Web Dashboard | https://health-tracker-zw.web.app/ |
> | Backend / Admin | https://health-tracker-system-production.up.railway.app/admin/ |
> | Mobile | Install `Vitalix.apk` from the project root |

> **Provider credentials for the demos** — use the specialist whose patients are being demonstrated:
>
> | Demo | Provider Account | Reason |
> |---|---|---|
> | DEMO 1, 2, 3, 5 | `dr_hyper` / `password` | Ivan (PT002) is a Hypertension patient |
> | DEMO 4 | `dr_diab` / `password` | Heidi (PT003) is a Diabetes patient |

---

### DEMO 1 — Notification Bell Badge and Read-State Persistence

**What this shows:** The bell icon in the top bar shows a live unread count. Clicking it clears the badge. After a full browser reload the badge does not reappear for notifications already read.

**Steps:**

1. Open https://health-tracker-zw.web.app/ and log in as `dr_hyper` / `password`.
   - *Look at the top-right corner of the screen.* The bell icon should have a red badge showing a number (e.g. **3**). This is the count of unread notifications.

2. Without clicking the bell, note the number on the badge. Point it out to the examiner.

3. Click the bell icon directly.
   - *Expected:* The view switches to the **Notifications** tab automatically. The red badge on the bell icon disappears immediately.

4. In the Notifications list, find any card that still has a coloured background and a small **red dot** on its right edge. That is an unread notification.

5. Click anywhere on that notification card (not a button — just the card itself).
   - *Expected:* The card background turns white. The red dot changes to a faint grey tick. The notification is now marked as read without any page reload.

6. Now reload the entire browser page (press `F5` or `Ctrl+R`).
   - *Expected:* The bell badge does **not** come back for the notification just marked as read. The badge count reflects only any genuinely unread items remaining.

7. Point out to the examiner: "Read state is stored server-side so it survives any reload."

---

### DEMO 2 — Appointment Approval Auto-Creates a Draft Clinical Visit

**What this shows:** When a provider approves a pending appointment, the system automatically creates a draft clinical visit record linked to that appointment. An orange badge appears on the patient's card immediately.

**Log in as:** `dr_hyper` / `password` (Ivan is a Hypertension patient assigned to the Hypertension specialist.)

**What to prepare:** You need one pending appointment in the live system. If none exists, go to **Appointments → Book Appointment**, select patient **Ivan (PT002)**, pick any future date and time, and enter the reason `"Follow-up: Blood pressure monitoring and medication review"`. Submit it — it will appear with status Pending.

**Steps:**

1. Click **Appointments** in the left sidebar.
   - *Expected:* The Appointments tab opens. Ivan (PT002) appears in the pending list.

2. Find Ivan's pending appointment and click **Confirm** (or **Approve**).
   - *Expected:* The status changes to **Scheduled/Confirmed**. The pending badge on the sidebar decreases by one.

3. Click **All Patients** in the sidebar.
   - *Expected:* Find **Ivan** in the list. His patient card now has a small orange **"Visit Pending"** label next to his name and an orange border. This badge was not there before the approval.

4. Point this out to the examiner: "The system instantly flagged that Ivan needs a clinical visit record filled in."

5. Reload the browser.
   - *Expected:* The "Visit Pending" label is **still there**. It will only disappear after the visit record is completed (demonstrated in Demo 3).

---

### DEMO 3 — Filling In the Clinical Visit Record with Reference Comparison

**What this shows:** The provider opens the draft clinical visit, sees the patient's previous vitals for comparison, enters today's readings, and completes the record. The draft badge then clears.

**Continue directly from Demo 2 — still logged in as `dr_hyper` / `password`.**

**Steps:**

1. Click on **Ivan (PT002)** in the All Patients list to open his detail screen.
   - *Expected:* The Patient Detail screen opens on the Profile tab.

2. Look at the **Clinical** tab label at the top. It should have a small **orange badge showing "1"**.
   - Point this out: "One visit record is waiting to be filled in."

3. Click the **Clinical** tab.
   - *Expected:* A section labelled **"Pending Visit Records"** appears at the top in orange. Inside it is one card for the appointment just confirmed, showing the appointment reason and reference vitals from Ivan's last check-in.

4. Click the orange button **"Fill In & Complete Visit"** on the draft card.
   - *Expected:* A wide dialog opens. The **left panel** (orange background) shows Ivan's previous reference data — last check-in blood pressure, glucose, and risk level. The **right panel** has editable vital sign fields, already pre-filled with Ivan's baseline values.

5. In the right panel, enter the following values to simulate today's clinic readings:
   - **Systolic BP:** `148`
   - **Diastolic BP:** `94`
   - **Heart Rate:** `82`
   - **Blood Glucose:** `105`
   - **Weight:** `78`
   - **Temperature:** `36.8`
   - **SpO2:** `97`
   - **Medication Intake:** `Amlodipine 5mg — taken as prescribed`
   - **Comments:** `Patient reports occasional headaches in the morning. BP slightly elevated compared to last visit.`
   - **Changes Made:** `Increased amlodipine to 10mg. Scheduled follow-up in 4 weeks.`

6. Click **Complete & Save**.
   - *Expected:* The dialog closes. The "Pending Visit Records" section disappears. A new card appears in the **"Completed Visits"** section with all the values just entered. The orange badge on the Clinical tab label disappears.

7. Navigate back to **All Patients**.
   - *Expected:* Ivan's card no longer has the "Visit Pending" label or orange border.

---

### DEMO 4 — Second Patient: Diabetes Review (End-to-End in One Flow)

**What this shows:** The same full workflow for a different patient with a different condition, demonstrating the feature works generically across the system.

**Log in as:** `dr_diab` / `password` (Heidi is a Diabetes patient assigned to the Diabetes specialist.)

**What to prepare:** If no pending appointment exists for Heidi, go to **Appointments → Book Appointment**, select **Heidi (PT003)**, pick any future date and time, and enter the reason `"Diabetes review: glucose control and insulin dosage assessment"`. Submit it.

**Steps:**

1. Click **Appointments** in the sidebar. Find Heidi (PT003) and click **Confirm**.
   - *Expected:* Status changes to Confirmed. A draft clinical visit is auto-created for Heidi.

2. Click **All Patients**. Find **Heidi (PT003)**.
   - *Expected:* Her card shows the orange **"Visit Pending"** label.

3. Click Heidi's card. Go to the **Clinical** tab.
   - *Expected:* The tab badge shows **"1"**. The Pending Visit Records section has one card for the diabetes review appointment.

4. Click **"Fill In & Complete Visit"**. Enter the following values:
   - **Systolic BP:** `122`
   - **Diastolic BP:** `80`
   - **Heart Rate:** `76`
   - **Blood Glucose:** `210`
   - **Weight:** `65`
   - **Temperature:** `36.5`
   - **SpO2:** `99`
   - **Medication Intake:** `Metformin 500mg twice daily — patient reports compliance`
   - **Comments:** `Fasting glucose elevated at 210 mg/dL. Patient admitted to skipping evening dose twice this week. No symptoms of hypoglycaemia.`
   - **Changes Made:** `Reinforced medication adherence. Added dietary counselling referral. Repeat glucose check in 2 weeks.`

5. Click **Complete & Save**.
   - *Expected:* Visit moves to Completed. Tab badge clears. Heidi's patient card clears the pending label.

6. Point out to the examiner: "The completed visit now serves as a reference point. The next time a visit is created for Heidi, this data will appear in the reference panel."

---

### DEMO 5 — Badge Persistence: Reload Proves Badges Survive Correctly

**What this shows:** Appointment and high-risk badges use SharedPreferences to remember what the provider has already seen. New items badge correctly; already-seen items do not re-badge after a reload.

**Log in as:** `dr_hyper` / `password` (or whichever specialist account was used in Demos 2–3).

**Steps:**

1. Click **Appointments** in the sidebar. Note the current badge count (even if it is 0 after completing Demos 2–4).
   - The act of visiting this tab marks the current count as "seen" and saves it.

2. Reload the browser (`F5`).
   - *Expected:* The Appointments badge does **not** reappear for the appointments confirmed in Demos 2 and 3. The badge remains at 0 (or shows only genuinely new pending items if any exist).

3. Click **High Risk Alerts** in the sidebar.
   - *Expected:* The badge count on this tab reflects the number of RED/ORANGE patients. Visiting the tab saves this count.

4. Reload again.
   - *Expected:* The High Risk badge does not reappear for the same patients. It will only badge again if a new high-risk check-in arrives.

5. Click the bell icon to open Notifications. Count the unread items.
   - Reload the browser.
   - *Expected:* The bell badge shows the same count as before (server-side `is_read` field drives this one — it survives reload by design).

6. Point out to the examiner: "Badge counts are persisted locally so providers are not interrupted by stale alerts they have already seen. Only genuinely new events trigger the badge."

---



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
| Django Admin Panel | https://health-tracker-system-production.up.railway.app/admin/ |
| Web Dashboard | https://health-tracker-zw.web.app/ |
| Mobile APK | `Vitalix.apk` in project root |

---

## Model Training and Clinical Decision Support Notes

The backend risk model was trained as a decision-support tool for patient triage, not as a replacement for a licensed clinician. Its purpose is to help surface patients who may need faster follow-up, especially when providers are reviewing large numbers of check-ins. It should not be treated as a final diagnosis, a fully sourced medical opinion, or a substitute for clinical examination. In practical terms, the model can be useful and still be wrong. A machine can be confidently wrong if the input is incomplete, self-reported answers are inaccurate, or the patient presents in a way that was underrepresented in the training data.

### Training Data Used

The project uses three clinical datasets because the app focuses on overlapping chronic-risk patterns rather than a single disease:

1. **Cardiovascular Disease Dataset** (`cardio_train.csv`, about 70,000 records)
   - Used for blood pressure, cardiovascular status, age, activity patterns, and broad heart-related risk signals.
   - This dataset is useful because it is large enough to expose the model to a wide range of low-risk and high-risk cardiovascular profiles.
2. **Pima Indians Diabetes Dataset** (`diabetes.csv`, 768 records)
   - Used for glucose-related risk patterns, age, blood pressure, and diabetes outcome signals.
   - This dataset was chosen because the system supports diabetic patients and needs a grounded source for glucose escalation logic instead of inventing thresholds from scratch.
3. **Stroke / Hypertension Dataset** (`healthcare-dataset-stroke-data.csv`, 5,110 records)
   - Used to strengthen hypertension, age-related risk, glucose patterns, and associated vascular risk indicators.
   - This dataset helps bridge the gap between raw vital signs and broader chronic-event risk, which is relevant for triaging hypertensive and cardiovascular patients.

These datasets were selected because together they cover the main conditions supported by the system and provide structured variables that can be mapped into the app's daily check-in flow: blood pressure, glucose status, age, activity level, medication adherence, and symptom severity.

### Why These Datasets Were Chosen

The model was not trained on one perfect end-to-end dataset from the exact deployed app workflow, because that kind of local longitudinal patient dataset was not available at project stage. Instead, the training process combined reputable structured datasets that contain clinically meaningful signals related to the target use case.

The reasoning was:

1. The app needs to assess **chronic condition deterioration risk**, especially for hypertension, diabetes, and cardio-related cases.
2. Real-world public datasets already capture the strongest measurable signals behind that deterioration, even if they were originally collected for different prediction tasks.
3. Combining them allows the system to learn patterns that are more clinically grounded than pure synthetic data, while still being adapted to the app's own 12-question check-in format.

This is a practical engineering compromise. It is stronger than training only on made-up examples, but it is still not the same as validating a hospital-grade model on a local, prospectively collected clinical cohort.

### How the Training Was Done

The backend training pipeline converts the source datasets into the same feature structure expected by the live application. The model ultimately learns from a vector containing:

- 12 symptom-question scores from the app's daily check-in flow
- systolic blood pressure deviation from baseline
- diastolic blood pressure deviation from baseline
- glucose deviation from baseline
- medication adherence indicator
- condition code
- normalized age

The key step is feature engineering. The original datasets do not naturally arrive in the same exact format as the app questionnaire, so the training script maps them into a common structure:

1. **Blood pressure risk** is derived using hypertension threshold bands.
2. **Glucose risk** is derived using diabetes threshold bands.
3. **Disease flags** from the source datasets add extra severity where appropriate.
4. **Symptom-question scores** are then generated to mimic the kind of variability a real patient would report in the app, rather than creating a perfectly deterministic mapping.
5. **Medication adherence**, **condition category**, and **age normalization** are added so the model sees both symptom burden and context.

This approach was used because the deployed mobile and web systems consume the standardized check-in structure, not the raw original columns from each public dataset. In other words, the training process translates heterogeneous medical datasets into one unified risk input format that matches the production app.

### Labels and Risk Logic

The model predicts four operational risk levels:

- **GREEN**: stable
- **YELLOW**: moderate concern
- **ORANGE**: elevated concern
- **RED**: high concern / urgent follow-up

Those labels are derived from threshold-based clinical logic during training. For example, higher blood pressure ranges, higher glucose ranges, and the presence of disease indicators increase the assigned risk class. This was done so the model does not learn arbitrary labels. Instead, it learns against labels rooted in medically sensible escalation rules.

### Class Balancing and Model Choices

After combining the datasets, the training pipeline balances the classes by upsampling minority risk categories to match the largest class. That decision matters because raw clinical data is usually imbalanced: there are often more mild cases than severe ones. Without balancing, the model could become biased toward predicting safer outcomes too often.

Two model paths are used in the project:

1. **Random Forest classifier** for the backend risk service.
   - Chosen because it is robust on tabular data, handles mixed feature types well, and is easier to inspect than more opaque architectures.
2. **Keras neural network exported to TFLite** for mobile offline inference.
   - Chosen because the mobile app needs compact on-device inference when the user is offline, and TFLite is a practical deployment format for that requirement.

This split lets the system keep a strong server-side model while also supporting fast offline predictions on the handset.

### Important Limitations

This section is critical for interpreting the system responsibly:

1. The model is a **triage aid**, not a doctor.
2. The model output depends on self-reported answers and derived features, so inaccurate patient input can lead to inaccurate risk predictions.
3. Public datasets do not perfectly represent the local patient population, local care pathways, or every co-morbidity combination.
4. Some features are engineered proxies rather than directly observed measurements from the original sources, which is acceptable for a prototype decision-support pipeline but not equivalent to a fully clinically validated diagnostic model.
5. High-risk predictions should trigger provider review, not automated medical conclusions.

The correct interpretation is therefore: the system helps providers decide who to look at first, who may need follow-up sooner, and which patients may be deteriorating. It does not produce a final medical truth. Clinical judgment remains the deciding authority.

---

## TIER 1 - Super Admin

The super admin operates entirely through the Django admin panel at https://health-tracker-system-production.up.railway.app/admin/. This includes full database control, provider management, and the patient distribution map.

### 1.1 Django Admin Login

1. Open https://health-tracker-system-production.up.railway.app/admin/ in a browser.
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

1. Open https://health-tracker-system-production.up.railway.app/api/patients/ in the browser (while still logged into the admin session, or open in a new tab).
   - **Expected:** A JSON array of 15 patient objects is returned. Each object contains a `district` field with a Zimbabwe district name (e.g. Goromonzi, Mazowe, Bindura, Hwange, Matobo).

### 1.9 Patient Distribution Map

The patient map lives inside the Django admin panel. It is accessible only to the superadmin.

1. While logged into the admin panel as `superadmin`, look at the admin home page.
   - **Expected:** A green banner at the top of the page reads **"Patient Distribution Map"** with an **Open Map** button.
2. Click **Open Map** (or navigate directly to https://health-tracker-system-production.up.railway.app/admin/patient-map/).
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
   - **Expected:** The tab label shows a small orange badge with a number if the patient has any visit records that have not yet been filled in by the provider. If there are no pending records the badge is absent.
2. Approve a pending appointment for this patient (see section 2.9) if one has not already been approved.
   - **Expected:** The Clinical Visits tab now shows a highlighted orange section at the top labelled **"Pending Visit Records"**. Inside that section there is a card for the appointment that was just approved. The card displays the appointment reason, a **"DRAFT – Awaiting Completion"** status badge, and a reference row showing the patient's last recorded blood pressure and blood glucose from their most recent check-in (or baseline values if no check-in exists yet).
3. Click **Fill In & Complete Visit** on the draft visit card.
   - **Expected:** A wide dialog opens. The left panel is read-only and shows the reference snapshot: previous BP and glucose readings, risk level, and the baseline values stored for this patient. The right panel has editable fields for today's vital readings (systolic BP, diastolic BP, heart rate, blood glucose, weight, temperature, oxygen saturation), medication intake, general comments, and any changes made to the care plan.
4. Enter values in the vital sign fields and click **Complete & Save**.
   - **Expected:** The dialog closes. The draft card disappears from the Pending section. A new card appears in the **"Completed Visits"** section showing the filled-in values. The orange badge on the Clinical tab label decreases or disappears.

### 2.8 Risk Banner

1. Open a patient who has a RED or ORANGE risk level.
   - **Expected:** A coloured risk banner appears on the profile tab. The text uses a plain hyphen, e.g. "High Risk - Immediate Attention Needed". No em-dashes or garbled characters.

### 2.9 Appointments Tab

1. Click **Appointments** in the sidebar.
   - **Expected:** A list of appointment requests appears, grouped or labelled by status (Pending, Confirmed, Completed). The badge count on the sidebar item matches the number of pending items shown.
2. Click **Confirm** on a pending appointment.
   - **Expected:** The appointment status changes to Confirmed. The pending badge count on the sidebar decreases by one. A draft clinical visit record is automatically created for this patient linked to the appointment (visible in the patient's Clinical Visits tab as described in section 2.7).
3. Reload the browser and navigate back to the Appointments tab.
   - **Expected:** The sidebar badge count for Appointments does **not** reappear for appointments that were already visible before the reload. Only new appointments arriving after the last visit to this tab will increment the badge.

### 2.10 High Risk Alerts Tab

1. Click **High Risk Alerts** in the sidebar.
   - **Expected:** A list of patients with RED or ORANGE risk levels appears. Each entry shows the patient name, condition, risk level, and last check-in date. The badge count on the sidebar item matches the number of patients listed.
2. Click on a patient entry in the list.
   - **Expected:** The patient detail screen opens for that patient.

### 2.11 Analytics Tab

1. Click **Analytics** in the sidebar.
   - **Expected:** Charts and graphs appear showing check-in trends over time, risk level distribution (e.g. pie or bar chart), and condition breakdown. All axis labels and legends are plain text with no special characters.

### 2.12 Notifications Tab

1. Before opening the Notifications tab, look at the **bell icon** in the top navigation bar on desktop.
   - **Expected:** If there are any unread notifications, a red badge with the unread count is visible on the bell icon. If all notifications are already read the badge is absent.
2. Click the bell icon.
   - **Expected:** The view switches to the Notifications tab. The badge on the bell icon disappears immediately.
3. With the Notifications tab open, look at the notification feed.
   - **Expected:** A feed of system notifications appears (appointment requests, high-risk alerts, new check-ins). All message text is plain readable English with no emoji and no garbled characters.
4. Find any notification card that has not been read yet (it will have a slightly coloured background and a small red dot on the right side).
5. Click anywhere on that notification card.
   - **Expected:** The card background becomes white and the red dot changes to a faint grey check icon, indicating the notification has been marked as read. This happens instantly without a full page reload.
6. Reload the browser and navigate back to the Notifications tab.
   - **Expected:** The notification that was just read remains shown as read. The red dot does not reappear.
7. Reload the browser and look at the bell icon.
   - **Expected:** The bell badge reflects only the remaining unread notifications, not the one that was marked as read.

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

### 2.16 Patient Card - Pending Visit Badge

1. Open the **All Patients** list.
   - **Expected:** Any patient that has at least one draft clinical visit record (not yet filled in by the provider) shows a small orange **"Visit Pending"** label next to their name. The card border is a faint orange instead of the standard grey. Patients with no pending visits show a plain grey border and no label.
2. Click on a patient with the "Visit Pending" label to open their detail screen.
   - **Expected:** The Clinical Visits tab badge (orange dot with a number) is visible on the tab label, matching the number of pending draft records.
3. Complete the draft visit (see section 2.7 steps 3–4).
4. Return to the **All Patients** list.
   - **Expected:** The "Visit Pending" label and orange border are gone from that patient's card.

### 2.17 Badge Persistence Across Reloads

This section verifies that notification and count badges correctly survive a browser refresh.

1. Log in as a provider. Note the badge count on the **Appointments** sidebar item.
2. Click **Appointments** to view the list (this marks the current count as "seen").
3. Reload the entire browser page.
   - **Expected:** The Appointments sidebar badge does **not** reappear. The count resets only when new pending appointments arrive after the last visit to that tab.
4. Repeat steps 1–3 for the **High Risk Alerts** tab.
   - **Expected:** Same behaviour — the high-risk badge does not reappear after reload if no new high-risk patients have appeared since the last visit to that tab.
5. Note the unread count on the bell icon. Click the bell icon to open Notifications. Reload the browser.
   - **Expected:** The bell badge count reflects only notifications that remain unread server-side, not ones already marked read. Previously-read notifications do not increment the badge count after a reload.

### 2.18 End-to-End Appointment to Clinical Visit Flow

This section tests the complete workflow from appointment approval to a completed clinical visit record.

1. Log in as `dr_hyper`. Go to **Appointments** and approve a pending appointment for any patient.
   - **Expected:** The appointment status changes to Confirmed. The Appointments badge decreases.
2. Open the patient whose appointment was just approved. Go to the **Clinical Visits** tab.
   - **Expected:** The tab label shows an orange badge with **"1"**. The Pending Visit Records section contains exactly one draft card showing the appointment reason and reference vitals.
3. Click **Fill In & Complete Visit** on the draft card. In the dialog, enter realistic values for all vital fields. Click **Complete & Save**.
   - **Expected:** The dialog closes. The pending section disappears (or shows zero items). The Completed Visits section now shows the visit with the values just entered. The orange tab badge disappears.
4. Return to the **All Patients** list.
   - **Expected:** The "Visit Pending" orange label and border are gone from that patient's card.
5. Reload the browser and reopen the same patient's Clinical Visits tab.
   - **Expected:** The completed visit record is still present with all saved values. The tab label has no badge.

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

### CT-4: Appointment approval triggers clinical visit, badge appears, mark complete clears badge

1. **(Tier 3)** Log in on the mobile app as PT001 and request a new appointment for a future date.
   - **Expected:** The appointment appears in the PT001 Appointments tab with status Pending.
2. **(Tier 2)** Log in to the web dashboard as `dr_hyper`. Go to the Appointments tab. An Appointments sidebar badge or an increased badge count should be visible.
   - **Expected:** The pending appointment from PT001 appears in the Appointments list.
3. **(Tier 2)** Confirm the appointment by clicking **Confirm** on that row.
   - **Expected:** The status changes to Confirmed. The sidebar badge decreases.
4. **(Tier 2)** Go to the **All Patients** list and find PT001.
   - **Expected:** The PT001 card shows a small orange **"Visit Pending"** label next to the patient name and an orange border.
5. **(Tier 2)** Click the PT001 card to open their detail. Go to the **Clinical Visits** tab.
   - **Expected:** The tab label has an orange badge showing **"1"**. The Pending Visit Records section contains a draft card showing the appointment reason and a reference row of PT001's last known vitals (blood pressure, glucose, risk level).
6. **(Tier 2)** Click **Fill In & Complete Visit** on the draft card. Enter valid vitals in the dialog. Click **Complete & Save**.
   - **Expected:** The dialog closes. The Pending section disappears. A completed visit card appears in the Completed Visits section with the values just entered. The orange tab badge disappears.
7. **(Tier 3)** On the mobile app, check PT001's Appointments tab.
   - **Expected:** The appointment status has changed to Completed.
8. **(Tier 2)** Reload the browser and reopen the PT001 patient detail Clinical Visits tab.
   - **Expected:** The completed visit record is still present with all saved values. The tab label has no badge. The PT001 card on the All Patients list no longer shows the "Visit Pending" label or orange border.

