# Phase 2 API - Quick Reference Card

## 📌 All Endpoints at a Glance

### Appointments Management

| Method | Endpoint | Purpose | Status Codes |
|--------|----------|---------|--------------|
| POST | `/api/appointments/create/` | Create appointment | 201, 400 |
| GET | `/api/appointments/` | List appointments | 200 |
| GET | `/api/appointments/<id>/` | Get details | 200, 404 |
| PUT | `/api/appointments/<id>/update/` | Update details | 200, 400, 404 |
| POST | `/api/appointments/<id>/complete/` | Mark complete | 200, 404 |
| DELETE | `/api/appointments/<id>/cancel/` | Cancel appointment | 200, 404 |

### Notifications & Alerts

| Method | Endpoint | Purpose | Status Codes |
|--------|----------|---------|--------------|
| GET | `/api/notifications/` | Get notifications | 200 |
| PUT | `/api/notifications/<id>/read/` | Mark as read | 200, 404 |
| DELETE | `/api/notifications/<id>/delete/` | Delete notification | 200, 404 |
| POST | `/api/alerts/check-high-risk/` | Create risk alerts | 200 |

---

## 🔧 Common Request Examples

### Create Appointment
```bash
POST /api/appointments/create/

{
  "patient_id": 1,
  "provider_id": 2,
  "scheduled_date": "2024-03-20",
  "scheduled_time": "14:30",
  "appointment_type": "FOLLOW_UP",
  "reason": "Routine check-up",
  "status": "SCHEDULED"
}

Response: 201
{
  "id": 5,
  "patient": {...},
  "provider_id": 2,
  "scheduled_date": "2024-03-20",
  "scheduled_time": "14:30",
  "appointment_type": "FOLLOW_UP",
  "reason": "Routine check-up",
  "status": "SCHEDULED",
  "notes": null
}
```

### List Appointments with Filters
```bash
GET /api/appointments/?provider_id=2&status=SCHEDULED&date_from=2024-03-01

Query Parameters:
- patient_id=<value>    → Filter by patient
- provider_id=<value>   → Filter by provider
- status=<status>       → SCHEDULED|COMPLETED|CANCELLED|NO_SHOW
- date_from=YYYY-MM-DD  → Start date
- date_to=YYYY-MM-DD    → End date

Response: 200
{
  "count": 3,
  "results": [...]
}
```

### Get User's Notifications
```bash
GET /api/notifications/?user_id=2&unread_only=true

Query Parameters:
- user_id=<value>       → Required: provider_id or patient_id
- unread_only=true      → Optional: only unread (default: false)

Response: 200
{
  "count": 2,
  "results": [
    {
      "id": 1,
      "user_id": 2,
      "notification_type": "HIGH_RISK_ALERT",
      "message": "...",
      "is_read": false,
      "read_at": null
    }
  ]
}
```

### Mark Notification as Read
```bash
PUT /api/notifications/1/read/

Response: 200
{
  "id": 1,
  "is_read": true,
  "read_at": "2024-03-08T10:30:00Z"
}
```

### Check for High-Risk Alerts
```bash
POST /api/alerts/check-high-risk/

Response: 200
{
  "alerts_created": 2,
  "results": [
    {
      "id": 3,
      "user_id": 2,
      "notification_type": "HIGH_RISK_ALERT",
      "message": "PT001 is at HIGH RISK - Immediate attention needed"
    }
  ]
}
```

---

## 📋 Query Parameter Reference

### Appointment Filters
```
/api/appointments/
  ?patient_id=PT001
  &provider_id=2
  &status=SCHEDULED
  &date_from=2024-03-01
  &date_to=2024-03-31
```

### Notification Filters
```
/api/notifications/
  ?user_id=2
  &unread_only=true
```

---

## 🔄 Status & Type Values

### Appointment Status
- `SCHEDULED` - Appointment scheduled
- `COMPLETED` - Appointment completed
- `CANCELLED` - Appointment cancelled
- `NO_SHOW` - Patient didn't show up

### Appointment Type
- `INITIAL` - Initial consultation
- `FOLLOW_UP` - Follow-up visit
- `CHECKUP` - Routine checkup
- `EMERGENCY` - Emergency appointment
- `ROUTINE` - Routine visit

### Notification Types
- `HIGH_RISK_ALERT` - Patient at high risk
- `APPOINTMENT_REMINDER` - Appointment reminder
- `MEDICATION_REMINDER` - Medication reminder
- `CHECKIN_SCHEDULED` - Check-in scheduled
- `RESULT_AVAILABLE` - Lab result available
- `GENERAL_NOTIFICATION` - General notification

---

## 🚨 Error Responses

### 400 Bad Request
```json
{
  "error": "Missing required field: patient_id"
}
```

### 404 Not Found
```json
{
  "error": "Patient not found"
}
```

### 500 Server Error
```json
{
  "error": "Database error occurred"
}
```

---

## 💡 Tips & Tricks

### Filter Appointments by Provider & Status
```javascript
const response = await fetch(
  '/api/appointments/?provider_id=2&status=SCHEDULED'
);
const data = await response.json();
console.log(`${data.count} scheduled appointments`);
```

### Get Only Unread Notifications
```javascript
const response = await fetch(
  '/api/notifications/?user_id=2&unread_only=true'
);
const { count } = await response.json();
console.log(`${count} unread notifications`);
```

### Mark All User Notifications as Read (Python)
```python
import requests

user_id = 2
response = requests.get(f'/api/notifications/?user_id={user_id}')
notifications = response.json()['results']

for notif in notifications:
    if not notif['is_read']:
        requests.put(f"/api/notifications/{notif['id']}/read/")
```

### Create Appointment & Link to Patient
```javascript
const appointmentData = {
  patient_id: patientObj.id,
  provider_id: currentProviderId,
  scheduled_date: form.dateInput.value,
  scheduled_time: form.timeInput.value,
  appointment_type: 'FOLLOW_UP',
  reason: form.reasonInput.value,
  status: 'SCHEDULED'
};

const created = await fetch('/api/appointments/create/', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(appointmentData)
});
```

---

## 🔐 Authentication (To Be Added)

Once authentication is implemented, add to all requests:

```javascript
const headers = {
  'Content-Type': 'application/json',
  'Authorization': `Bearer ${authToken}`
};

const response = await fetch('/api/appointments/', {
  headers: headers
});
```

---

## 📱 Frontend Integration Template

### React Example
```javascript
import { useEffect, useState } from 'react';

function AppointmentsList() {
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch('/api/appointments/?provider_id=2&status=SCHEDULED')
      .then(res => res.json())
      .then(data => {
        setAppointments(data.results);
        setLoading(false);
      });
  }, []);

  if (loading) return <div>Loading...</div>;

  return (
    <ul>
      {appointments.map(apt => (
        <li key={apt.id}>
          {apt.patient.name} - {apt.scheduled_date} {apt.scheduled_time}
        </li>
      ))}
    </ul>
  );
}
```

### Flutter Example
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<List<Appointment>> getAppointments(int providerId) async {
  final response = await http.get(
    Uri.parse('/api/appointments/?provider_id=$providerId&status=SCHEDULED'),
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body)['results'];
    return data.map((json) => Appointment.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load appointments');
  }
}
```

---

## 🔗 Related Documentation

- **Full API Guide**: See `PHASE2_API_GUIDE.md`
- **Implementation Details**: See `PHASE2_IMPLEMENTATION_SUMMARY.md`
- **Getting Started**: See `PHASE2_README.md`
- **Test Suite**: Run `python test_phase2_api.py`

---

**Last Updated:** March 2024  
**Version:** Phase 2 Complete
