# Health Tracker System - Client Verification & Testing Manual

This manual is designed for the client to systematically verify that their entire vision for the Health Tracker System has been successfully implemented. 

It is written to be executed entirely from the user interfaces (the Mobile App, the Web Dashboard, and the Admin Panel) with zero technical commands required. Every step is detailed exactly—down to the specific buttons to press—so that any stakeholder can verify the system's capabilities.

---

## 🌟 How We Met The Client's Vision
Before testing, here is exactly how your requested features were implemented:
1. **The 12-Question Expansion & Numeric Vitals:** We expanded the symptom tracker from 7 to 12 questions using a 0-3 severity scale, and added the ability to record precise numeric vitals (Blood Pressure & Blood Glucose) exactly as requested.
2. **Edge Computing (Offline Mode):** The mobile app houses a local database (Hive) and a localized Machine Learning model. Patients can calculate their risk and save their check-ins completely offline in resource-constrained environments.
3. **Dynamic Specialist Routing:** Patients are no longer grouped into one pool. The system dynamically routes Asthma patients *only* to Pulmonologists, and Diabetes patients *only* to Endocrinologists, securing data access.
4. **Real-Time Communication:** We built a dedicated, real-time polling chat system complete with "Provider is typing..." indicators to bridge the gap between patients and healthcare workers.

---

## 🔐 MASTER TEST CREDENTIALS
Please use these exact credentials when following the tests below.

### 1. Super Admin Panel (For IT Management)
- **Website:** `https://health-tracker-api-blky.onrender.com/admin/`
- **Username:** `superadmin`
- **Password:** `adminpassword123`

### 2. Provider Web Dashboard (For Doctors/Nurses)
- **Website:** `https://health-tracker-zw.web.app/`
- **Diabetes Specialist:** `dr_diab` / `password`
- **Asthma Specialist:** `dr_asthma` / `password`

### 3. Mobile App (For Patients)
- **App:** Open the installed Health Tracker application on your Android phone.
- **Patient 3 (Asthma):** `PT003` / `test123`
- **Patient 5 (Diabetes):** `PT005` / `test123`

---

## 🧪 TEST PHASE 1: Super Admin Security & Staff Management
**Objective:** Verify that system administrators can strictly control which nurses and doctors have access to the system — including creating accounts, deactivating them to block access, and reactivating them to restore it. The Web Dashboard will now display a clear popup message to the user explaining exactly why they cannot log in.

---

### PART A — Create a New Staff Account
1. Open your computer's web browser and go to `https://health-tracker-api-blky.onrender.com/admin/`.
2. Click on the **Username** box and type `superadmin`.
3. Click on the **Password** box and type `adminpassword123`.
4. Click the gray **Log in** button. You will be taken to the Minty Green dashboard.
5. Look at the left-hand menu panel. Click on the word **Users** (under the "Authentication and Authorization" section).
6. In the top right corner, click the green **ADD USER +** button.
7. In the **Username** box, type `test_nurse`. In both **Password** boxes, type `password123`. Click **Save and continue editing**.
8. Scroll down to the **Permissions** section. Check the box next to **Staff status** (this is required for dashboard access). Leave **Active** checked for now.
9. Click the blue **Save** button.

---

### PART B — Test Logging In with a Non-Existent Account
> **What this verifies:** If someone types a username that does not exist at all, the dashboard shows a clear "Account Not Found" popup instead of a confusing generic error.

1. Open a new browser tab and go to `https://health-tracker-zw.web.app/`.
2. In the **Provider ID / Name** box, type `nobody_here`.
3. In the **Password** box, type `anything`.
4. Click **Sign In**.
5. **The Verification:** A popup dialog will appear with the title **"Account Not Found"** and an orange warning icon. It will tell you that no account exists with that username and to contact your administrator. Click **OK** to dismiss it.

---

### PART C — Deactivate the Account (Simulate Firing or Suspending a Staff Member)
> **What this verifies:** An administrator can instantly block a staff member from accessing all patient data with a single click.

1. Go back to the Admin Panel tab (`https://health-tracker-api-blky.onrender.com/admin/`).
2. Click **Users** in the left-hand menu.
3. Click on **test_nurse** in the user list to open their profile.
4. Scroll down to the **Permissions** section.
5. **CRITICAL STEP:** Uncheck the box next to **Active**.
6. Click the blue **Save** button.
7. **The Verification:** You will be returned to the user list. Find `test_nurse`. The **Active** column will show a red ❌ icon, confirming the account is deactivated.

---

### PART D — Test Logging In with a Deactivated Account
> **What this verifies:** A deactivated staff member is shown a clear, informative message — not a confusing error — so they know exactly what happened and who to call.

1. Go back to the Web Dashboard tab (`https://health-tracker-zw.web.app/`).
2. In the **Provider ID / Name** box, type `test_nurse`.
3. In the **Password** box, type `password123`.
4. Click **Sign In**.
5. **The Verification:** A popup dialog will appear with the title **"Account Deactivated"** and a red block icon. It will display the message: *"Your account has been deactivated. Please contact your administrator to reactivate it."* Click **OK** to dismiss it.

---

### PART E — Reactivate the Account (Restore a Staff Member's Access)
> **What this verifies:** An administrator can restore access just as easily as they removed it.

1. Go back to the Admin Panel tab.
2. Click **Users** → click on **test_nurse**.
3. Scroll to the **Permissions** section.
4. **Re-check** the box next to **Active**.
5. Click the blue **Save** button.
6. **The Verification:** The **Active** column for `test_nurse` now shows a green ✔ icon.
7. Go back to the Web Dashboard. Log in as `test_nurse` / `password123`.
8. **The Final Verification:** Login succeeds. The account is fully restored with no additional steps required.

---

## 🧪 TEST PHASE 2: Mobile App 12-Question Check-in & Edge ML
**Objective:** Verify the client's request to track 12 specific symptoms on a 0-3 scale, capture numeric vitals, and calculate risk on the device.

**Step-by-Step Instructions:**
1. Open the **Health Tracker** app on your Android phone.
2. Tap the **Username** field and type `PT005` (This is Frank, our Diabetes test patient).
3. Tap the **Password** field and type `test123`. Tap **Login**.
4. At the bottom of the screen, tap the **Daily Check-in** tab (it looks like a clipboard).
5. **The Verification:** Scroll through the questions. You will see exactly 12 questions tailored to Diabetes.
6. Answer questions 1 through 10 by tapping the sliders or dropdowns (pick random severity levels).
7. Scroll down to Questions 11 and 12. Tap the text box for **Blood Pressure Systolic** and type `140`. Tap the box for **Diastolic** and type `90`. 
8. Tap the green **Submit Check-in** button at the very bottom.
9. **The Verification:** The screen will instantly display a color-coded Risk Level (e.g., YELLOW or ORANGE). This calculation was done *instantly by the Machine Learning model residing directly on the phone*, fulfilling the Edge Computing requirement.

---

## 🧪 TEST PHASE 3: Provider Dashboard & Dynamic Routing
**Objective:** Verify that specialists ONLY see the patients assigned to their specific medical condition, and verify they can see the 12-question clinical data.

**Step-by-Step Instructions:**
1. Open your computer's web browser and go to `https://health-tracker-zw.web.app/`.
2. Click the **Username** box and type `dr_diab` (The Diabetes Specialist).
3. Click the **Password** box and type `password`. Click the green **Log in** button.
4. **The Routing Verification:** Look at the list of patient cards on the screen. You will ONLY see patients who have Diabetes (including Frank, `PT005`). You will absolutely not see any Hypertension or Asthma patients. This fulfills the Dynamic Routing requirement.
5. Find the patient card for **Frank Mutasa (PT005)**. Click the **Details** button on his card.
6. **The Clinical Verification:** A large window will pop up titled *"Frank Mutasa (PT005)"*. Look at the top of the window. You will see his exact Blood Pressure reading (`140/90`) that you entered in Test Phase 2. Scroll down the window. You will see a list of all 12 questions with their **full question text** (e.g., "Excessive thirst", "Took diabetes medication") and the exact answer labels (e.g., "None", "Mild", "Moderate", "Severe") — not just numbers like "Q1: 2".

---

## 🧪 TEST PHASE 4: Real-Time Communication & Typing Indicators
**Objective:** Verify that patients and doctors can chat seamlessly, and verify that the routing works for messages too.

**Step-by-Step Instructions:**
1. Keep the Web Dashboard open on your computer (still logged in as `dr_diab`).
2. Pick up your Android phone (still logged in as `PT005`). Tap the **Messages** tab at the bottom of the screen.
3. Tap the message box at the bottom, type "Hello Doctor, my blood sugar is high today.", and press the Send arrow.
4. Look at your computer screen. **The Verification:** Without you needing to refresh the page, the message will automatically pop up in the Web Dashboard's messaging drawer within a few seconds.
5. On your computer, click the "Type a message" box in the Web Dashboard. Type "I am reviewing your file right now." **DO NOT press send yet.**
6. Look at your phone screen. **The Verification:** A small banner will appear on the phone saying *"Care Provider is typing..."*. This fulfills the real-time feedback requirement.
7. Press Send on your computer. The message will immediately pop up on the phone's chat bubble.

---

## 🧪 TEST PHASE 6: New Patient Registration with Auto-Generated Credentials
**Objective:** Verify that a brand-new patient can register through the mobile app and receive an automatically generated Patient ID and password.

**Step-by-Step Instructions:**
1. Open the **Health Tracker** app on your Android phone.
2. On the login screen, tap **Create Account / Register**.
3. Fill in your name (e.g., `Alice Mwangi`), date of birth, and select your condition (e.g., `Diabetes`). **Leave the Password fields blank** — they have been removed; the system generates credentials for you.
4. Tap the **Register** button.
5. **The Verification:** A success dialog will appear showing:
   - Your automatically assigned **Patient ID** (e.g., `PT-A1B2C3D4`)
   - Your auto-generated **temporary password** (8-character alphanumeric)
   - A **Copy** button for each value
   - A prompt asking you to **take a screenshot** to save these credentials
6. Take the screenshot. Tap **Continue to Login**.
7. Use the generated Patient ID and password to log in. Login should succeed.
8. (Optional) Go to **Profile** → **Change Password** to set a personal password. Note that the Patient ID cannot be changed — it is permanent.

---

## 🧪 TEST PHASE 7: Notifications System
**Objective:** Verify that health events automatically create notifications visible on both the provider dashboard and the patient mobile app.

### PART A — Check-in Triggers a Provider Notification
1. Log in to the mobile app as `PT005` / `test123` (Frank Mutasa, Diabetes patient).
2. Submit a check-in with all **Severe** answers to generate a high-risk result.
3. On your computer, open `https://health-tracker-zw.web.app/` and log in as `dr_diab` / `password`.
4. **The Verification:** In the sidebar (or bottom nav on mobile), tap the 🔔 **Notifications** tab. You will see a new alert: *"🚨 Frank Mutasa submitted a check-in — Risk level: RED"*. The badge counter on the tab will show the count of unread notifications.

### PART B — Appointment Triggers a Notification
1. Log in to the mobile app as `PT005` / `test123`.
2. Navigate to the **Appointments** tab and request a new appointment.
3. On the provider dashboard, go to the **Notifications** tab.
4. **The Verification:** A new notification will appear: *"📅 New appointment request from Frank Mutasa..."*

### PART C — Patient Sees Their Own Notifications
1. On the mobile app (logged in as any patient), tap the 🔔 **Notifications** tab at the bottom of the screen (the 5th icon).
2. **The Verification:** Any notifications sent to that patient's user ID will appear in the list with timestamps.
3. Tap **Mark read** on an unread notification. The notification will be marked as read and the badge count will decrease.

### PART D — Super Admin Sees All Alerts
1. Log in to the provider dashboard as `admin` / `password` (or as superadmin through the web).
2. Go to the **Notifications** tab.
3. **The Verification:** The superadmin account receives copies of ALL high-risk alerts and ALL appointment creations across the entire system, giving full visibility.

---

## 🧪 TEST PHASE 8: Patient Names Display Everywhere
**Objective:** Verify that patient names (not patient IDs) are shown throughout the provider dashboard.

**Step-by-Step Instructions:**
1. Log in to the provider dashboard as `dr_diab` / `password`.
2. Look at the patient list on the **All Patients** tab.
3. **The Verification:** Each row shows the patient's full name (e.g., "Frank Mutasa") in bold with the Patient ID in small text below it. No raw "PT005" labels as headings.
4. Click **Details** on any patient card.
5. **The Verification:** The modal title shows *"Frank Mutasa (PT005)"* — name first, ID in parentheses.
6. Open the chat drawer for a patient (click the message icon).
7. **The Verification:** The chat header shows *"Chat: Frank Mutasa"*, not *"Chat: PT005"*.
