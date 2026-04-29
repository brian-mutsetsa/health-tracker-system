# Phase 3: Super Admin & Nurse Management

## Overview
This phase focuses on administrative control. We will establish a clear hierarchy between Super Admins (using the native Django Admin interface) and Nurses/Healthcare Workers (using the Flutter web dashboard). We will implement the ability to deactivate staff members and restrict what regular staff can do.

## Checklist

### 1. Django Backend: Super Admin & Admin Panel Frontend
- [ ] Ensure the default Django Admin panel (`/admin`) is fully configured and styled professionally (e.g., using `django-jazzmin` or custom CSS) to match the mobile/dashboard look and feel, and is mobile-responsive.
- [ ] Register all relevant models (`User`, `PatientProfile`, `MedicalProfessionalProfile`, `CheckIn`, `Message`, `Appointment`) in `backend/api/admin.py` so they are fully manageable via the web interface.
- [ ] Add custom list displays, filters, and search fields in `admin.py` to make the super admin experience clean and efficient.

### 2. Django Backend: Nurse Deactivation & Role Management
- [ ] Ensure the custom `User` model (or the logic handling it) fully respects the `is_active` flag. 
- [ ] Verify that if a nurse's `is_active` flag is set to `False` (by a super admin in the Django panel), they can no longer log in to the Flutter Web Dashboard.
- [ ] Update JWT authentication to reject tokens for deactivated users.

### 3. Flutter Web Dashboard: Permission Restrictions
- [ ] Review the Flutter dashboard routing and UI elements.
- [ ] Ensure that a logged-in nurse does not have access to super-admin level functions (e.g., they cannot create other healthcare workers, they cannot delete the entire system).
- [ ] (Optional but recommended) Hide UI elements that are not relevant to their specific role.

## How to Proceed if Stuck
- **Django Admin:** If the `/admin` page doesn't look right or is missing models, check `backend/api/admin.py`. Ensure you run `python manage.py createsuperuser` to get initial access.
- **Deactivation:** If a deactivated nurse can still log in, check `serializers.py` (login serializer) to ensure it validates `user.is_active == True`.
