import requests
import json

url = "http://127.0.0.1:5050/v1/chat/completions"
headers = {"Content-Type": "application/json"}
data = {
    "model": "Qwen3.6-35B-A3B-UD-IQ3_S.gguf",
    "messages": [{"role": "user", "content": "Hola, responde brevemente"}],
    "max_tokens": 10
}

try:
    response = requests.post(url, headers=headers, data=json.dumps(data))
    print(response.status_code)
    print(response.json())
except Exception as e:
    print(f"Error: {e}")
