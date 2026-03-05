import urllib.request
import json

url = 'https://health-tracker-api-blky.onrender.com/api/checkin/submit/'
data = {
    "patient_id": "test_patient_123",
    "condition": "Hypertension",
    "date": "2026-03-05T00:00:00Z",
    "answers": {"q1": "None", "q2": "Mild", "q7": "Yes"},
    "risk_level": "GREEN",
    "risk_color": "green"
}
req = urllib.request.Request(url, json.dumps(data).encode('utf-8'), {'Content-Type': 'application/json'})
try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Exception:", e)
