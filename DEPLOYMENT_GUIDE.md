# Health Tracker System - Deployment Guide

This document outlines the final deployment steps for the Health Tracker System, covering the backend (Render), the Web Dashboard (Firebase), and the Mobile App (APK).

## 1. Backend (Django on Render)
The backend is already configured to automatically deploy whenever changes are pushed to the GitHub repository.

**Recent Updates Pushed:**
- Removed emoji print statements causing UnicodeEncodeError in Windows environments.
- Added provider-based filtering to `list_all_patients` in `api/views.py`.
- Updated `JAZZMIN_UI_TWEAKS` in `settings.py` to use the `minty` theme (Teal/Green).
- Overrode `UserAdmin` in `admin.py` to display the `is_active` status in the Django Admin list view.
- Disabled `AUTH_PASSWORD_VALIDATORS` to allow simple passwords for testing.

**Deployment Steps:**
1. Commit all recent changes: `git add .` then `git commit -m "Phase 5 updates"`
2. Push to main: `git push origin main`
3. Render will automatically detect the push and begin building the environment using `requirements.txt` and `Procfile`.
4. *Optional:* Once deployed on Render, access the Render terminal and run `python manage.py seed_test_data` to ensure the live database has the correct doctors and test patients.

## 2. Mobile App (Flutter APK)
The mobile app's `api_service.dart` is currently pointing to `https://health-tracker-api-blky.onrender.com/api`.

**Deployment Steps:**
1. Open a terminal in the `mobile` directory.
2. Ensure you have the Flutter SDK installed.
3. Run the command: `flutter build apk --release`
4. This will compile the app and output an `.apk` file located at `mobile/build/app/outputs/flutter-apk/app-release.apk`.
5. You can copy this APK to any Android device and install it directly.

## 3. Web Dashboard (Flutter Web on Firebase)
The dashboard's `api_service.dart` is currently pointing to `https://health-tracker-api-blky.onrender.com/api`.

**Deployment Steps:**
1. Open a terminal in the `dashboard` directory.
2. Build the web files: `flutter build web`
3. Install the Firebase CLI if you haven't already: `npm install -g firebase-tools`
4. Login to Firebase: `firebase login`
5. Initialize hosting: `firebase init hosting`
   - Select your existing Firebase project.
   - For the public directory, type `build/web`.
   - Configure as a single-page app: `Yes`.
   - Overwrite `index.html`: `No`.
6. Deploy to Firebase: `firebase deploy --only hosting`

---
*Note for AI Assistants:* The system requires matching `baseUrl` strings across `mobile/lib/services/api_service.dart` and `dashboard/lib/services/api_service.dart`. Both currently point to the Render API endpoint.
