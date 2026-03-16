# Health Tracker System - Phase 1 & 2 Implementation Plan

## Goal Description

The overall goal is to fully complete, fix, and wire up **Phase 1 (12-question symptom check-in)** and **Phase 2 (Optional numeric inputs for BP and glucose)** so the project can be handed off to the client today. 

**What the Previous AI Failed to Do:**
The previous attempt added the 12 questions to the UI but **failed to wire up the data flow**. The mobile app captures the Blood Pressure and Glucose values on the screen, but it never actually saves them to the local database, nor does it send them to the Django backend. Furthermore, text-input questions fail to record the string the user types. The dashboard also lacks a way to deeply view a patient's 12-question check-in data.

This implementation plan corrects the data flow from the Mobile UI -> Local Hive DB -> API Service -> Django Backend -> Provider Dashboard.

## Stock Take: Phase 1 & 2 Gaps
I have reviewed the [PROJECT_HANDOFF.md](file:///c:/dev/projects/health_tracker_system/PROJECT_HANDOFF.md) and compared it against the actual codebase. The previous AI claimed Phase 1 & 2 were 87% complete, but it entirely hallucinated the frontends. Here is the reality of what is **missing** and will be built in this plan:

**Phase 1 Gaps:**
- ❌ **Patient Registration System:** The dashboard has no way for a provider to register a new patient or enter their baseline clinical data (age, weight, BP, glucose). The **Mobile App** also lacks a registration flow for patients to sign themselves up.
- ❌ **Baseline Data Integration:** Because there is no registration, the ML model is not using a patient's baseline to calculate risk, rendering the risk scores clinically inaccurate.
- ❌ **Data Flow for 12 Questions:** The UI exists, but it doesn't send the data to the backend. Also, the answer options for questions like medication adherence incorrectly use "None/Mild/Severe" instead of the accurate categorical answers specified in the client requirements (e.g., "Yes fully", "Missed once").

**Phase 2 Gaps:**
- ❌ **Clinical Visits / Appointment Management:** The backend API exists, but the Mobile App has no screen to view/schedule appointments, and the Dashboard has no calendar or list to manage them. (Requirement: Two-way scheduling where provider booking auto-accepts, but patient booking requires provider approval with push notifications).
- ❌ **Automated Notifications & Alerts:** The mobile app has no local device notifications configured to wake the user for appointments (like approvals) or high-risk alerts.

---

## User Review Required

> [!CAUTION]
> **Mobile App Hive Database Migration:** Because we are modifying the [CheckinModel](file:///c:/dev/projects/health_tracker_system/mobile/lib/models/checkin_model.dart#5-30) to include new fields (`bpSystolic`, `bpDiastolic`, `bloodGlucose`), we will need to re-run the Flutter build_runner to regenerate the Hive adapters. Existing local check-ins on testing devices might be wiped or cause a mismatch during the update.

Please review the proposed changes below. If you approve, I will execute these immediately so you can send the project to your client today.

---

## Proposed Changes

### 1. Mobile App: Data Model Updates
We need the local database model to actually store the optional numeric vital fields.

#### [MODIFY] [checkin_model.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/models/checkin_model.dart)
- **Add Fields:** Add `bpSystolic`, `bpDiastolic`, and `bloodGlucose` as double nullable fields with `@HiveField` annotations.
- **Run build_runner:** Execute `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `checkin_model.g.dart`.

### 2. Mobile App: UI Data Capture Fix
We need to ensure the variables collected on the screen are actually passed to the Checkin Model during submission.

#### [MODIFY] [daily_checkin_screen.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/screens/daily_checkin_screen.dart)
- **Fix Categorical Answers:** Redefine the questions according to the EXACT client specifications. Some questions will use the standard (0=None, 1=Mild, 2=Moderate, 3=Severe), while others use custom scales (e.g., Medication: 0=Yes fully, 1=Missed once, 2=Missed more than once, 3=Did not take), and some will simply be **Yes/No** (mapped to 1 and 0 for the backend).
- **Fix Text Inputs:** In [_buildAnswerOptions](file:///c:/dev/projects/health_tracker_system/mobile/lib/screens/daily_checkin_screen.dart#509-541), capture the actual full text string the user types instead of hardcoding `0`.
- **Wire up Submission:** In [_submitCheckin()](file:///c:/dev/projects/health_tracker_system/mobile/lib/screens/daily_checkin_screen.dart#727-829), pass `bpSystolic`, `bpDiastolic`, and `bloodGlucose` to the [CheckinModel](file:///c:/dev/projects/health_tracker_system/mobile/lib/models/checkin_model.dart#5-30) constructor.

### 3. Mobile App: API Serialization Fix
We must transmit the captured vitals to the Django backend so the ML model can use them for accuracy and the Provider Dashboard can display them.

#### [MODIFY] [api_service.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/services/api_service.dart)
- **Update [uploadCheckin()](file:///c:/dev/projects/health_tracker_system/mobile/lib/services/api_service.dart#65-120):** Modify the JSON payload being sent to `POST /checkin/submit/`. Include [blood_pressure_systolic](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#94-98), [blood_pressure_diastolic](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#99-103), and [blood_glucose_reading](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#46-50) mapped from the [CheckinModel](file:///c:/dev/projects/health_tracker_system/mobile/lib/models/checkin_model.dart#5-30).

### 4. Provider Dashboard: Data Visualization
The client requires the healthcare worker to review patient logs thoroughly. We need to display the new 12 questions and vitals on the dashboard.

#### [MODIFY] [dashboard_screen.dart](file:///c:/dev/projects/health_tracker_system/dashboard/lib/screens/dashboard_screen.dart)
- **Add Patient Detail Modal:** Implement a click handler on the Patient table/cards that opens a detailed Dialog.
- **Display Check-in Details:** The modal will fetch the patient's latest check-in and display the 12 answers along with the Blood Pressure and Glucose readings cleanly.

### 5. Backend: Fix Login Endpoint Crash (ALREADY COMPLETED)
The login endpoint was returning a 500 error because of an `IndentationError` in [backend/api/serializers.py](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py) inside the [CheckInCreateSerializer](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#131-175) which crashed the Django app upon boot. 
- **Fixed:** Removed the trailing/duplicate code block and fixed the syntax error locally. Tested via `curl` and confirmed it works. I will deploy this to Render immediately so you can test it.

### 6. Phase 2 Completeness: Mobile App Appointments & Notifications
The previous AI built the backend for Phase 2 but failed to build the UI for the actual mobile app. We will implement these missing pieces:
- **[NEW] [mobile/pubspec.yaml](file:///c:/dev/projects/health_tracker_system/mobile/pubspec.yaml)**: Add `flutter_local_notifications` for on-device push notifications.
- **[NEW] `mobile/lib/services/notification_service.dart`**: Implement logic to trigger local push notifications for High-Risk alerts and whenever a provider approves an appointment.
- **[NEW] `mobile/lib/screens/appointments_screen.dart`**: Implement a new screen allowing the patient to view, schedule, and cancel appointments with their provider. Ensure scheduling sets status to "Pending".
- **[MODIFY] [mobile/lib/screens/home_screen.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/screens/home_screen.dart)**: Add navigation buttons to access the Appointments screen.

### 7. Phase 2 Completeness: Provider Dashboard Appointments
The provider needs to see and manage the scheduled appointments on the web dashboard.
- **[NEW] `dashboard/lib/screens/appointments_screen.dart`**: Build a calendar or list view on the web dashboard showing all upcoming and past appointments for all patients. Ensure providers can book appointments (auto-accepts) and approve patient-requested appointments (triggers notification).
- **[MODIFY] [dashboard/lib/screens/dashboard_screen.dart](file:///c:/dev/projects/health_tracker_system/dashboard/lib/screens/dashboard_screen.dart)**: Add a new tab/drawer item to navigate to the new appointment management center.

### 8. Phase 1 Completeness: Mobile Patient Registration
The mobile application must allow patients to register themselves and record baseline data.
- **[NEW] `mobile/lib/screens/registration_screen.dart`**: Create a registration flow collecting Name, Condition, Password, Age, baseline BP, baseline weight, and baseline glucose.
- **[MODIFY] [mobile/lib/screens/login_screen.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/screens/login_screen.dart)**: Add a 'Register' button to navigate to the new screen.
- **[MODIFY] [mobile/lib/services/api_service.dart](file:///c:/dev/projects/health_tracker_system/mobile/lib/services/api_service.dart)**: Implement `registerPatient` to send the new patient profile to the Django backend.

---

## Verification Plan

### Automated / Build Verification
- Run `flutter pub run build_runner build --delete-conflicting-outputs` in the `mobile` directory to ensure Hive decorators compile cleanly.
- Verify Flutter web builds successfully for the dashboard: `flutter build web`.

### Manual End-to-End Verification
1. **Launch Mobile App:** Start the Flutter app locally.
2. **Submit 12-Question Check-in:** Fill out all 12 questions, and critically, fill out the optional numeric fields for Blood Pressure and Glucose on the last step.
3. **Verify API Payload:** Check the debug console logs to ensure [blood_pressure_systolic](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#94-98), [blood_pressure_diastolic](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#99-103), and [blood_glucose_reading](file:///c:/dev/projects/health_tracker_system/backend/api/serializers.py#46-50) are present in the JSON payload sent to Render.
4. **Launch Dashboard:** Open the Flutter Web Dashboard.
5. **Verify Dashboard Display:** Click on the specific patient and verify that the detailed modal pops up, showing exactly the BP, Glucose, and all 12 questions submitted in step 2.
