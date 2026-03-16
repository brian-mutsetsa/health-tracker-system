# Phase 2 API Implementation Guide

## Overview

Phase 2 extends the Health Tracker API with appointment management and notification/alert functionality. This guide covers all new endpoints, their usage, request/response formats, and integration patterns.

---

## Table of Contents

1. [Appointment Management](#appointment-management)
2. [Notifications & Alerts](#notifications--alerts)
3. [Error Handling](#error-handling)
4. [Integration Examples](#integration-examples)
5. [Testing](#testing)

---

## Appointment Management

### Overview
Appointments enable providers to schedule, track, and manage patient consultations. Supports full CRUD operations with filtering and status tracking.

### Endpoints

#### Create Appointment
**POST** `/api/appointments/create/`

Creates a new appointment for a patient.

**Request Body:**
```json
{
  "patient_id": 1,
  "provider_id": 2,
  "scheduled_date": "2024-03-15",
  "scheduled_time": "14:30",
  "appointment_type": "FOLLOW_UP",
  "reason": "Routine check-up",
  "status": "SCHEDULED"
}
```

**Response (201 Created):**
```json
{
  "id": 5,
  "patient": {
    "id": 1,
    "patient_id": "PT001",
    "name": "John Doe"
  },
  "provider_id": 2,
  "scheduled_date": "2024-03-15",
  "scheduled_time": "14:30",
  "appointment_type": "FOLLOW_UP",
  "reason": "Routine check-up",
  "status": "SCHEDULED",
  "notes": null,
  "created_at": "2024-03-08T10:30:00Z",
  "updated_at": "2024-03-08T10:30:00Z"
}
```

**Error Cases:**
- `400 Bad Request`: Missing or invalid required fields
- `404 Not Found`: Patient or provider not found

---

#### List Appointments
**GET** `/api/appointments/`

Lists all appointments with optional filtering and pagination.

**Query Parameters:**
- `patient_id` (string): Filter by patient ID
- `provider_id` (int): Filter by provider ID
- `status` (string): Filter by status (SCHEDULED, COMPLETED, CANCELLED, NO_SHOW)
- `date_from` (string): Start date in YYYY-MM-DD format
- `date_to` (string): End date in YYYY-MM-DD format

**Example Request:**
```
GET /api/appointments/?status=SCHEDULED&provider_id=2&date_from=2024-03-01
```

**Response (200 OK):**
```json
{
  "count": 3,
  "results": [
    {
      "id": 5,
      "patient": {
        "id": 1,
        "patient_id": "PT001",
        "name": "John Doe"
      },
      "provider_id": 2,
      "scheduled_date": "2024-03-15",
      "scheduled_time": "14:30",
      "appointment_type": "FOLLOW_UP",
      "reason": "Routine check-up",
      "status": "SCHEDULED",
      "notes": null
    },
    // ... more appointments
  ]
}
```

---

#### Get Appointment Details
**GET** `/api/appointments/{appointment_id}/`

Retrieves details for a specific appointment.

**Response (200 OK):**
```json
{
  "id": 5,
  "patient": {
    "id": 1,
    "patient_id": "PT001",
    "name": "John Doe",
    "condition": "Hypertension"
  },
  "provider_id": 2,
  "scheduled_date": "2024-03-15",
  "scheduled_time": "14:30",
  "appointment_type": "FOLLOW_UP",
  "reason": "Routine check-up",
  "status": "SCHEDULED",
  "notes": null,
  "created_at": "2024-03-08T10:30:00Z",
  "updated_at": "2024-03-08T10:30:00Z"
}
```

---

#### Update Appointment
**PUT** `/api/appointments/{appointment_id}/update/`

Updates appointment details (reschedule, add notes, etc).

**Request Body (partial updates supported):**
```json
{
  "scheduled_date": "2024-03-20",
  "scheduled_time": "15:00",
  "reason": "Updated reason: Quarterly review",
  "notes": "Patient to bring recent lab results"
}
```

**Response (200 OK):**
```json
{
  "id": 5,
  "patient": { /* ... */ },
  "scheduled_date": "2024-03-20",
  "scheduled_time": "15:00",
  "reason": "Updated reason: Quarterly review",
  "notes": "Patient to bring recent lab results",
  "updated_at": "2024-03-08T11:20:00Z"
}
```

---

#### Complete Appointment
**POST** `/api/appointments/{appointment_id}/complete/`

Marks an appointment as completed.

**Response (200 OK):**
```json
{
  "id": 5,
  "status": "COMPLETED",
  "completed_at": "2024-03-15T14:45:00Z"
}
```

---

#### Cancel Appointment
**DELETE** `/api/appointments/{appointment_id}/cancel/`

Cancels an appointment.

**Response (200 OK):**
```json
{
  "status": "cancelled",
  "appointment_id": 5
}
```

---

## Notifications & Alerts

### Overview
The notification system enables real-time alerts for providers about patient status changes, high-risk conditions, and appointment reminders.

### Endpoints

#### Get Notifications
**GET** `/api/notifications/`

Retrieves user's notifications with optional filtering.

**Query Parameters:**
- `user_id` (required, int): The provider_id or patient_id
- `unread_only` (boolean): If true, only return unread notifications (default: false)

**Example Request:**
```
GET /api/notifications/?user_id=2&unread_only=true
```

**Response (200 OK):**
```json
{
  "count": 2,
  "results": [
    {
      "id": 1,
      "user_id": 2,
      "notification_type": "HIGH_RISK_ALERT",
      "message": "PT001 (John Doe) is at HIGH RISK - Immediate attention needed",
      "related_patient_id": "PT001",
      "is_read": false,
      "read_at": null,
      "created_at": "2024-03-08T09:15:00Z"
    },
    {
      "id": 2,
      "user_id": 2,
      "notification_type": "APPOINTMENT_REMINDER",
      "message": "Appointment reminder: John Doe at 14:30 tomorrow",
      "related_patient_id": "PT001",
      "is_read": false,
      "read_at": null,
      "created_at": "2024-03-08T08:00:00Z"
    }
  ]
}
```

---

#### Mark Notification as Read
**PUT** `/api/notifications/{notification_id}/read/`

Marks a single notification as read and records the read timestamp.

**Response (200 OK):**
```json
{
  "id": 1,
  "user_id": 2,
  "is_read": true,
  "read_at": "2024-03-08T10:30:00Z"
}
```

---

#### Delete Notification
**DELETE** `/api/notifications/{notification_id}/delete/`

Deletes a notification.

**Response (200 OK):**
```json
{
  "status": "deleted"
}
```

---

#### Check High-Risk Alerts
**POST** `/api/alerts/check-high-risk/`

Checks for patients at HIGH RISK (from the last 24 hours) and creates alert notifications for their providers.

**Use Case:** Call periodically (e.g., every hour) via scheduled task to keep providers informed.

**Response (200 OK):**
```json
{
  "alerts_created": 2,
  "results": [
    {
      "id": 3,
      "user_id": 2,
      "notification_type": "HIGH_RISK_ALERT",
      "message": "PT001 (John Doe) is at HIGH RISK - Immediate attention needed",
      "related_patient_id": "PT001",
      "created_at": "2024-03-08T11:00:00Z"
    },
    {
      "id": 4,
      "user_id": 3,
      "notification_type": "HIGH_RISK_ALERT",
      "message": "PT003 (Jane Smith) is at HIGH RISK - Immediate attention needed",
      "related_patient_id": "PT003",
      "created_at": "2024-03-08T11:00:00Z"
    }
  ]
}
```

---

## Error Handling

All endpoints follow standard HTTP status codes:

| Status Code | Meaning | Example |
|-------------|---------|---------|
| 200 | Success | Appointment retrieved |
| 201 | Created | New appointment created |
| 400 | Bad Request | Invalid data format or missing required fields |
| 404 | Not Found | Appointment or patient doesn't exist |
| 500 | Server Error | Database or unexpected error |

**Error Response Format:**
```json
{
  "error": "Patient not found"
}
```

---

## Integration Examples

### Example 1: Mobile App - Schedule Appointment
```javascript
async function scheduleAppointment(patientId, providerIdapointmentData) {
  const response = await fetch('http://api.health-tracker.com/api/appointments/create/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      patient_id: patientId,
      provider_id: providerId,
      scheduled_date: appointmentData.date,
      scheduled_time: appointmentData.time,
      appointment_type: 'FOLLOW_UP',
      reason: appointmentData.reason,
      status: 'SCHEDULED'
    })
  });
  
  const result = await response.json();
  if (response.ok) {
    showSuccessMessage(`Appointment scheduled for ${result.scheduled_date}`);
  } else {
    showError(result.error);
  }
}
```

### Example 2: Backend - Scheduled Task to Check High-Risk Patients
```python
from django_extensions.management.commands import BaseCommand
import schedule
import time
import requests
from django.conf import settings

class HighRiskChecker:
    def check_alerts(self):
        """Called every hour to check for high-risk patients"""
        response = requests.post(
            f'{settings.API_BASE_URL}/alerts/check-high-risk/'
        )
        if response.status_code == 200:
            data = response.json()
            print(f"Alerts created: {data['alerts_created']}")

# Schedule the check
checker = HighRiskChecker()
schedule.every(1).hour.do(checker.check_alerts)

while True:
    schedule.run_pending()
    time.sleep(60)
```

### Example 3: Dashboard - Get and Display Provider's Notifications
```javascript
async function loadProviderNotifications(providerId) {
  try {
    // Get unread notifications only
    const response = await fetch(
      `http://api.health-tracker.com/api/notifications/?user_id=${providerId}&unread_only=true`
    );
    const data = await response.json();
    
    // Display notifications
    displayNotifications(data.results);
    
    // Mark each as read when clicked
    data.results.forEach(notif => {
      const element = document.getElementById(`notif-${notif.id}`);
      if (element) {
        element.addEventListener('click', async () => {
          await fetch(
            `http://api.health-tracker.com/api/notifications/${notif.id}/read/`,
            { method: 'PUT' }
          );
          element.style.opacity = '0.6'; // Mark as read visually
        });
      }
    });
  } catch (error) {
    console.error('Failed to load notifications:', error);
  }
}
```

---

## Testing

### Local Testing
```bash
cd backend
python test_phase2_api.py
```

This runs comprehensive tests for:
- Appointment CRUD operations
- Notification retrieval and marking as read
- High-risk alert checking

### Using cURL
```bash
# Create appointment
curl -X POST http://localhost:8000/api/appointments/create/ \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "provider_id": 2,
    "scheduled_date": "2024-03-15",
    "scheduled_time": "14:30",
    "appointment_type": "FOLLOW_UP",
    "reason": "Follow up visit"
  }'

# Get notifications
curl "http://localhost:8000/api/notifications/?user_id=2&unread_only=true"

# Mark notification as read
curl -X PUT http://localhost:8000/api/notifications/1/read/
```

---

## Notes for Implementation

1. **Permissions**: Add permission checks to ensure providers can only see their own appointments and notifications
2. **Reminders**: Implement automated appointment reminder emails/SMS before scheduled time
3. **Webhooks**: Consider webhooks for real-time notification delivery to mobile apps
4. **Audit Trail**: Track appointment changes (who changed, when, what changed)
5. **Timezone Handling**: Store all times in UTC, convert to user timezone in frontend

---

## Phase 2 Models Reference

### Appointment Model
```python
class Appointment(models.Model):
    patient = ForeignKey(Patient)
    provider_id = IntegerField()
    scheduled_date = DateField()
    scheduled_time = TimeField()
    appointment_type = CharField(default='FOLLOW_UP')  # FOLLOW_UP, INITIAL, EMERGENCY, etc.
    reason = TextField()
    status = CharField(default='SCHEDULED')  # SCHEDULED, COMPLETED, CANCELLED, NO_SHOW
    notes = TextField(null=True, blank=True)
    created_at = DateTimeField(auto_now_add=True)
    updated_at = DateTimeField(auto_now=True)
```

### Notification Model
```python
class Notification(models.Model):
    user_id = IntegerField()  # provider_id or patient_id
    notification_type = CharField()  # HIGH_RISK_ALERT, APPOINTMENT_REMINDER, etc.
    message = TextField()
    related_patient_id = CharField(null=True)
    is_read = BooleanField(default=False)
    read_at = DateTimeField(null=True)
    created_at = DateTimeField(auto_now_add=True)
```

---

**Last Updated:** March 2024
**Status:** Implementation Complete
