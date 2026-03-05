import urllib.request
import json

url = 'https://health-tracker-api-blky.onrender.com/api/patients/'
try:
    with urllib.request.urlopen(url) as response:
        print("Status:", response.status)
        data = response.read().decode('utf-8')
        print("Body:", data)
except Exception as e:
    print("Exception:", e)
