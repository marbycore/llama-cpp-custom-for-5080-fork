"""End-to-End Verification: Launcher Logic -> Llama Server -> API Response."""
import subprocess
import requests
import time
import os

# 1. Get model path from selector (using -AutoSelect to simulate GUI selection)
print("[1/3] Testing Model Selector CLI...")
ps_cmd = [
    "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
    "-File", r"C:\data\llama-cpp-custom\model_selector.ps1", "-AutoSelect"
]
result = subprocess.run(ps_cmd, capture_output=True, text=True)
model_path = result.stdout.strip()

if not model_path or not os.path.exists(model_path):
    print(f"FAILED: Selector returned invalid path: '{model_path}'")
    exit(1)
print(f"SUCCESS: Selector returned: {model_path}")

# 2. Start server in background
print("[2/3] Starting Llama Server...")
server_cmd = [
    r"C:\data\llama-cpp-custom\build\bin\llama-server.exe",
    "-m", model_path,
    "-c", "2048",  # Small context for fast test
    "-ngl", "99",
    "--port", "5055"  # Use different port to not clash
]

# Using Popen to keep it running
server_proc = subprocess.Popen(server_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# 3. Poll API
print("[3/3] Verifying API Connectivity on port 5055...")
max_retries = 30
connected = False
for i in range(max_retries):
    try:
        resp = requests.get("http://127.0.0.1:5055/v1/models", timeout=2)
        if resp.status_code == 200:
            print(f"SUCCESS: API is LIVE! Response: {resp.json()['data'][0]['id']}")
            connected = True
            break
    except:
        pass
    time.sleep(1)
    if i % 5 == 0: print(f"  Waiting for server ({i}/{max_retries})...")

# Cleanup
server_proc.terminate()
if connected:
    print("\n✅ VERIFICATION COMPLETE: The entire chain (Selector -> Server -> API) is working perfectly.")
else:
    print("\n❌ FAILED: API did not respond in time.")
    exit(1)
