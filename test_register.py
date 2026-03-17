import urllib.request
import json
import random

url = 'https://kritikfinal.onrender.com/api/auth/register'
email = f'test{random.randint(1000,9999)}@test.com'
data = {'email': email, 'passwordHash': 'password123', 'fullName': 'Test Name'}
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
