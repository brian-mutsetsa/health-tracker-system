"""
Test script for Phase 2 API endpoints (Appointments & Notifications)
Run: python test_phase2_api.py

Tests include:
- Appointment creation and management
- Notification retrieval and marking as read
- High-risk alert checking
"""

import urllib.request
import json
import os
from datetime import datetime, timedelta

BASE_URL = os.getenv('API_URL', 'http://localhost:8000/api')

def make_request(endpoint, method='GET', data=None):
    """Make HTTP request to API"""
    url = f"{BASE_URL}{endpoint}"
    headers = {'Content-Type': 'application/json'}
    
    if data:
        req = urllib.request.Request(
            url,
            json.dumps(data).encode('utf-8'),
            headers,
            method=method
        )
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    
    try:
        with urllib.request.urlopen(req) as response:
            body = response.read().decode('utf-8')
            return response.status, json.loads(body) if body else {}
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8')
        try:
            return e.code, json.loads(error_body)
        except:
            return e.code, {'error': error_body}

def test_appointments():
    """Test appointment endpoints"""
    print("\n" + "="*60)
    print("Testing Appointment Endpoints")
    print("="*60)
    
    # Get a test provider ID (assuming provider_id=1 exists from earlier tests)
    provider_id = 1
    
    # Create an appointment
    appointment_data = {
        "patient_id": 1,
        "provider_id": provider_id,
        "scheduled_date": (datetime.now() + timedelta(days=7)).date().isoformat(),
        "scheduled_time": "14:30",
        "appointment_type": "FOLLOW_UP",
        "reason": "Routine check-up for hypertension management",
        "status": "SCHEDULED"
    }
    
    print("\n✓ Creating appointment...")
    status, response = make_request('/appointments/create/', 'POST', appointment_data)
    print(f"  Status: {status}")
    if status == 201 or status == 200:
        appointment_id = response.get('id')
        print(f"  ✅ Appointment created successfully! ID: {appointment_id}")
        print(f"  Response: {json.dumps(response, indent=2, default=str)}")
    else:
        print(f"  ❌ Failed to create appointment: {response}")
        return
    
    # List appointments
    print("\n✓ Listing all appointments...")
    status, response = make_request('/appointments/', 'GET')
    print(f"  Status: {status}")
    if status == 200:
        print(f"  ✅ Found {response.get('count', 0)} appointments")
        print(f"  Sample: {json.dumps(response.get('results', [])[:1], indent=2, default=str)}")
    else:
        print(f"  ❌ Failed to list appointments: {response}")
    
    # Get specific appointment
    if appointment_id:
        print(f"\n✓ Getting appointment {appointment_id}...")
        status, response = make_request(f'/appointments/{appointment_id}/', 'GET')
        print(f"  Status: {status}")
        if status == 200:
            print(f"  ✅ Appointment retrieved: {response.get('appointment_type')}")
        else:
            print(f"  ❌ Failed: {response}")
    
    # Update appointment
    if appointment_id:
        print(f"\n✓ Updating appointment {appointment_id}...")
        update_data = {
            "reason": "Updated reason: Quarterly review for medication adjustment"
        }
        status, response = make_request(f'/appointments/{appointment_id}/update/', 'PUT', update_data)
        print(f"  Status: {status}")
        if status == 200:
            print(f"  ✅ Appointment updated")
        else:
            print(f"  ❌ Failed: {response}")
    
    # Complete appointment
    if appointment_id:
        print(f"\n✓ Completing appointment {appointment_id}...")
        status, response = make_request(f'/appointments/{appointment_id}/complete/', 'POST')
        print(f"  Status: {status}")
        if status == 200:
            print(f"  ✅ Appointment marked as completed")
            print(f"  Status: {response.get('status')}")
        else:
            print(f"  ❌ Failed: {response}")
    
    # List appointments with filters
    print(f"\n✓ Listing appointments (filter by COMPLETED status)...")
    status, response = make_request('/appointments/?status=COMPLETED', 'GET')
    print(f"  Status: {status}")
    if status == 200:
        print(f"  ✅ Found {response.get('count', 0)} completed appointments")
    else:
        print(f"  ❌ Failed: {response}")


def test_notifications():
    """Test notification endpoints"""
    print("\n" + "="*60)
    print("Testing Notification Endpoints")
    print("="*60)
    
    user_id = 1  # Assuming provider_id=1
    
    # Get notifications
    print(f"\n✓ Getting notifications for user {user_id}...")
    status, response = make_request(f'/notifications/?user_id={user_id}', 'GET')
    print(f"  Status: {status}")
    if status == 200:
        count = response.get('count', 0)
        print(f"  ✅ Found {count} notifications")
        if count > 0:
            first_notification = response.get('results', [{}])[0]
            notification_id = first_notification.get('id')
            print(f"  First notification: {first_notification.get('message')}")
            
            # Mark notification as read
            if notification_id:
                print(f"\n✓ Marking notification {notification_id} as read...")
                status, response = make_request(f'/notifications/{notification_id}/read/', 'PUT')
                print(f"  Status: {status}")
                if status == 200:
                    print(f"  ✅ Notification marked as read")
                    print(f"  read_at: {response.get('read_at')}")
                else:
                    print(f"  ❌ Failed: {response}")
    else:
        print(f"  ❌ Failed to get notifications: {response}")
    
    # Get only unread notifications
    print(f"\n✓ Getting unread notifications for user {user_id}...")
    status, response = make_request(f'/notifications/?user_id={user_id}&unread_only=true', 'GET')
    print(f"  Status: {status}")
    if status == 200:
        count = response.get('count', 0)
        print(f"  ✅ Found {count} unread notifications")
    else:
        print(f"  ❌ Failed: {response}")


def test_alerts():
    """Test high-risk alert checking"""
    print("\n" + "="*60)
    print("Testing High-Risk Alert Endpoints")
    print("="*60)
    
    print("\n✓ Checking for high-risk alerts...")
    status, response = make_request('/alerts/check-high-risk/', 'POST')
    print(f"  Status: {status}")
    if status == 200:
        alerts_created = response.get('alerts_created', 0)
        print(f"  ✅ Alert check completed")
        print(f"  Alerts created: {alerts_created}")
        if alerts_created > 0:
            print(f"  Details: {json.dumps(response.get('results', [])[:2], indent=2, default=str)}")
    else:
        print(f"  ❌ Failed: {response}")


def run_all_tests():
    """Run all Phase 2 API tests"""
    print("\n" + "="*70)
    print("PHASE 2 API ENDPOINT TEST SUITE")
    print("="*70)
    print(f"Base URL: {BASE_URL}")
    
    try:
        test_appointments()
        test_notifications()
        test_alerts()
        
        print("\n" + "="*70)
        print("✅ All tests completed!")
        print("="*70)
    except Exception as e:
        print(f"\n❌ Test error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == '__main__':
    run_all_tests()
