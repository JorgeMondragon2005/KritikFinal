import urllib.request
import urllib.error
import json

api_key = "AIzaSyB6lv3tsf0773c-H7dXqw5-N9ZY9xqhQTQ"
url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"

try:
    with urllib.request.urlopen(url) as response:
        result = json.loads(response.read().decode('utf-8'))
        print("Modelos disponibles:")
        for model in result.get('models', []):
            if 'generateContent' in model.get('supportedGenerationMethods', []):
                print(model['name'])
except urllib.error.HTTPError as e:
    print(f"Error: {e.read().decode('utf-8')}")
except Exception as e:
    print(f"Error: {e}")
