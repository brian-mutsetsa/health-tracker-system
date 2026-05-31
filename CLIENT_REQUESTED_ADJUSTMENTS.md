# Client Requested Adjustments & Implementation Guide

This document outlines the exact adjustments required based on the most recent client feedback, and explains how to implement them from scratch. It also covers the exact build and deployment steps to ensure these changes are published correctly.

## 1. Required Adjustments

### A. Security Enhancements
The client asked about what security measures are implemented since the system contains confidential patient information.
**What to do:**
1. **Environment Variables**: Modify `backend/health_tracker/settings.py` to use `os.getenv()` for sensitive values like `SECRET_KEY`, `DEBUG`, and database credentials. This ensures no secrets are hardcoded in the repository.
2. **CORS Restrictions**: Set `ALLOWED_HOSTS` and CORS settings to only allow the specific frontend domains.
3. **Password Validators**: Enable Django's default `AUTH_PASSWORD_VALIDATORS` in `settings.py` so that providers must use strong passwords.

### B. PDF Report Generation
The client requested the ability to download reports as PDFs for healthcare workers.
**What to do:**
1. **Backend**: Add `reportlab` to `requirements.txt`. Create a new endpoint in `backend/api/views.py` (e.g., `generate_patient_pdf_report`) that fetches a patient's demographics, baseline vitals, and all check-in history, and formats them into a downloadable PDF using `reportlab`.
2. **Dashboard**: Add `url_launcher: ^6.2.0` to `dashboard/pubspec.yaml`. In `dashboard/lib/screens/patient_detail_screen.dart`, add a PDF icon button to the `AppBar`. When clicked, it should launch the backend PDF endpoint URL.

### C. Mobile App Risk & Recommendation UI
The client asked for the home screen to show the current risk level of the patient, along with specific recommendations based on their risk (e.g., advising them to monitor closely, or contact their healthcare worker within 24 hours if critical).
**What to do:**
1. Open `mobile/lib/screens/home_screen.dart`.
2. Remove the inactive "Suggested Doctors" placeholder widget and header.
3. Create a dynamic Risk Recommendation Card that reads the patient's latest check-in risk level.
4. **Logic to implement**:
   - **CRITICAL / RED**: Display "Contact your Healthcare Worker within 24 hours." and show a red "Call Doctor" button.
   - **HIGH RISK / ORANGE**: Display "Please monitor yourself closely and maintain your daily check-ins."
   - **ELEVATED / YELLOW**: Display "Moderate risk detected."
   - **SAFE / GREEN**: Display "Maintain your current healthy habits."

### D. System Testing Document & ML Metrics
The client wants documentation explaining the security and ML classifications.
**What to do:**
1. Open `SYSTEM_TESTING_DOCUMENT.md`.
2. Add a section detailing the new security measures (Environment variables, CORS, Password Validators).
3. Add a section defining the Machine Learning metrics:
   - Backend Random Forest Model: ~94% Accuracy, 95% Recall for high-risk.
   - Mobile Offline TFLite Model: ~91% Accuracy.
4. Include a tutorial like there is a test for everything, have the client test for all cases for the mobile if the latest log is a green, yellow, red, or orange so that the user can etst and see the updates of the app in real tike as it changes the colour, but also the expected outcome just like how all other tests are done in the md file. Analyze it thoroughly, to get a really good jist of how you should be writing this stuff and doing it.

---

## 2. Build and Deployment Instructions

Once you have made the code adjustments above, follow these exact steps to build the frontend apps and deploy the system.

### Step 1: Build the Web Dashboard
Navigate into the dashboard directory, install dependencies, and build for web:
```bash
cd dashboard
flutter clean
flutter pub get
flutter build web --release
```

### Step 2: Build the Mobile APK
Navigate into the mobile directory and build the Android APK.
```bash
cd ../mobile
flutter clean
flutter pub get
flutter build apk --release
```
*Troubleshooting Note: If the APK build fails with an error that just says `25.0.2` (or similar), it means the Android NDK is missing. You can either install it via Android Studio's SDK manager, or simply open `mobile/android/app/build.gradle.kts` and comment out the line `ndkVersion = flutter.ndkVersion`.*

### Step 3: Copy and Rename the APK
Once the mobile build succeeds, copy the generated APK to the root directory and rename it to `Vitalix.apk` so it overrides the old version and is easily accessible.
```bash
cp build/app/outputs/flutter-apk/app-release.apk ../Vitalix.apk
```

### Step 4: Push to GitHub for Deployment
Navigate back to the root directory. Add all your changes, commit them, and push to GitHub.
```bash
cd ..
git add .
git commit -m "feat: implement security hardening, PDF reports, and dynamic risk UI"
git push origin main
```

Because your production environment (Railway) is linked to GitHub, pushing to the `main` branch will automatically trigger Railway to rebuild the backend and deploy the new features. Railway will inject the environment variables automatically.
