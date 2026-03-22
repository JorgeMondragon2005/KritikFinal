import urllib.request
import json

base_url = "https://kritikfinal.onrender.com/api/users"
email_target = "jorgemoondragon595@gmail.com"

req = urllib.request.Request(base_url)
try:
    with urllib.request.urlopen(req) as response:
        users = json.loads(response.read().decode('utf-8'))
        
    user = next((u for u in users if u.get("email") == email_target or u.get("Email") == email_target), None)
    
    if user:
        user_id = user.get("id") or user.get("Id")
        print(f"Found user {email_target} with id {user_id}")
        
        # update role
        update_url = f"{base_url}/{user_id}/role"
        data = {"role": "Profesor"}
        update_req = urllib.request.Request(update_url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'}, method='PUT')
        
        with urllib.request.urlopen(update_req) as update_response:
            print(f"Role update status: {update_response.status}")
            print(f"User {email_target} is now a Profesor.")
    else:
        print(f"User {email_target} not found in the API list.")
except Exception as e:
    print(f"Error: {e}")
