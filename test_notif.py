import urllib.request
import json
import random

url = 'https://kritikfinal.onrender.com/api/Notifications'
data = {
    'userId': '67d1dbf9f1b2c5c6d3e8a4a2', # Just a dummy fake ObjectId
    'title': 'Test Title', 
    'message': 'Test Message',
    'isRead': False,
    'createdAt': '2026-03-15T00:00:00Z'
}
req = urllib.request.Request(url, json.dumps(data).encode('utf-8'), {'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Error:", e)
