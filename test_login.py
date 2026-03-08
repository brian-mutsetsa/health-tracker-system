import urllib.request
import json

def test_login():
    url = "https://health-tracker-api-blky.onrender.com/api/auth/login/"
    data = json.dumps({"username":"admin","password":"password"}).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            print("Status:", response.status)
            print("Response:", response.read().decode())
    except Exception as e:
        print("Error:", e)
        if hasattr(e, 'read'):
            print("Error Response:", e.read().decode())

def trigger_seed():
    url = "https://health-tracker-api-blky.onrender.com/api/seed/"
    req = urllib.request.Request(url, headers={'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(req) as response:
            print("Seed Status:", response.status)
            print("Seed Response:", response.read().decode())
    except Exception as e:
        print("Seed Error:", e)
        if hasattr(e, 'read'):
            print("Seed Error Response:", e.read().decode())

print("Pinging seed first...")
trigger_seed()
print("Trying login...")
test_login()
