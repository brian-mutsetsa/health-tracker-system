# Phase 4: Authentication, Signup & Doctor Routing

## Overview
This phase refines how users enter the system and how patients are matched with doctors. The mobile app needs a patient signup flow where they select their condition, and the system needs to automatically assign them to a specialized doctor for that condition. Additionally, the login systems will be refined so users can define their own passwords.

## Checklist

### 1. Refine Login Systems (Mobile & Web)
- [ ] **Mobile App:** Review `mobile/lib/screens/login_screen.dart`. Ensure the UI is clean and users can type their own username/ID and password.
- [ ] **Web Dashboard:** Review `dashboard/lib/screens/login_screen.dart`. Ensure nurses can log in using their ID/email and a password they define (or were assigned by the Super Admin).

### 2. Specialized Doctor Setup (Django)
- [ ] **Backend Seed/Creation:** Create specialized "Medical Professional" accounts in the Django backend representing different conditions (e.g., a Cardiologist for Hypertension, an Endocrinologist for Diabetes). 
- [ ] Note: The Super Admin can create these via the Django Admin panel. We need to ensure the backend data model has a way to associate a doctor with a `specialty` or `condition`.

### 3. Patient Signup & Auto-Assignment (Mobile & Django)
- [ ] **Mobile App:** Build `mobile/lib/screens/signup_screen.dart`. This screen must capture: Name, condition/disease they are seeking help for, and allow them to set their own password.
- [ ] **Mobile App:** Add a "Create Account / Sign Up" button to the mobile login screen.
- [ ] **Django Backend:** Create a new registration endpoint (e.g., `POST /api/register/patient/`).
- [ ] **Django Backend Logic:** When a patient registers, the backend logic must automatically assign them to a default "General Practice" doctor. It must also examine their chosen `condition`, query the database for a doctor with a matching `specialty`, and automatically link the patient's profile to that specific specialist (updating the database schema to support a primary and specialist provider if necessary).

### 4. Routing Validation
- [ ] **Backend:** Ensure that when the mobile app fetches messages (`GET /api/messages/`), it automatically pulls messages between the patient and their *assigned* doctor.
- [ ] **Backend:** Ensure check-ins and appointments submitted by the patient are linked to their *assigned* doctor.
- [ ] **Web Dashboard:** Verify that when a specialized doctor logs in, they *only* see patients assigned to them for their specific condition.

## How to Proceed if Stuck
- **Auto-Assignment Logic:** If patients aren't being assigned correctly, check the view handling the registration endpoint in `backend/api/views.py`. Ensure the query for `MedicalProfessionalProfile.objects.filter(specialty=...)` is working and assigning the `provider` field on the `PatientProfile`.
- **Specialties:** If doctors don't have specialties, you may need to add a `specialty` field to the `MedicalProfessionalProfile` model in `models.py` and run `makemigrations` and `migrate`.
