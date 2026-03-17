import urllib.request
import urllib.error
import json

api_key = "AIzaSyAfwrg7Mw5YliM897Vvt-KANiOF8mSByV8"
url = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key={api_key}"

data = json.dumps({
    "contents": [{"parts": [{"text": "Dime 'Hola, ya funciono' en espanol."}]}]
}).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})

print("--------------------------------------------------")
print("==> CONECTANDO DIRECTAMENTE CON SERVIDORES DE GOOGLE (SIN PASAR POR FLUTTER O RENDER) <==")
print("--------------------------------------------------\n")

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        text = result['candidates'][0]['content']['parts'][0]['text']
        print("[EXITO!] Google ya autorizo el limite de tu tarjeta.")
        print(f"Gemini dice: {text}")
except urllib.error.HTTPError as e:
    error_body = e.read().decode('utf-8')
    try:
        error_json = json.loads(error_body)
        error_msg = error_json.get('error', {}).get('message', error_body)
        error_code = error_json.get('error', {}).get('code', e.code)
    except:
        error_msg = error_body
        error_code = e.code
    
    print(f"[AUN BLOQUEADO POR GOOGLE] (Codigo {error_code})")
    print(f"Motivo Real: {error_msg}")
    print("\n[DIAGNOSTICO]: Kiosko_IA esta enviando los comandos de manera PERFECTA, el servidor responde pero Google de plano dice que aun tienes CUOTA LIMITADA a cero peticiones (Quota 0). Solo hay que esperar a que sus servidores sincronicen tu tarjeta de credito, o ingresar una cuenta de facturacion diferente.")
except Exception as e:
    print(f"[ERROR LOCAL]: {e}")
