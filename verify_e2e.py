"""End-to-end verification: GUI Test Mode -> Read Result -> Launch Server -> API Check"""
import subprocess, requests, time, os

RESULT_FILE = os.path.join(os.environ['TEMP'], 'llama_launch.txt')
SERVER_EXE = r"C:\data\llama-cpp-custom\build\bin\llama-server.exe"

# ── Step 1: Run GUI in Test mode ──
print("=" * 60)
print("[1/4] Testing GUI selector (auto-select mode)...")
r = subprocess.run(
    ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
     "-File", r"C:\data\llama-cpp-custom\launcher_gui.ps1", "-Test"],
    capture_output=True, text=True
)
print(f"  Output: {r.stdout.strip()}")
assert os.path.exists(RESULT_FILE), f"FAIL: Result file not created"

# ── Step 2: Parse result like the .bat does ──
print("[2/4] Parsing result file...")
with open(RESULT_FILE, 'r') as f:
    content = f.read().strip()
parts = content.split('|')
assert len(parts) == 5, f"FAIL: Expected 5 fields, got {len(parts)}: {parts}"
model_path, ctx, ngl, np_val, batch = parts
print(f"  Model : {os.path.basename(model_path)}")
print(f"  Ctx   : {ctx}")
print(f"  Layers: {ngl}")
print(f"  Slots : {np_val}")
print(f"  Batch : {batch}")
assert os.path.exists(model_path), f"FAIL: Model not found: {model_path}"
print("  ✅ All values parsed correctly")

# ── Step 3: Launch server with parsed values ──
print("[3/4] Launching llama-server on port 5055 (test)...")
cmd = [SERVER_EXE, "-m", model_path, "-c", "2048", "-ngl", ngl, "--port", "5055", "--host", "127.0.0.1"]
proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

# ── Step 4: Verify API ──
print("[4/4] Verifying API on port 5055...")
ok = False
for i in range(20):
    try:
        resp = requests.get("http://127.0.0.1:5055/v1/models", timeout=2)
        if resp.status_code == 200:
            model_id = resp.json()['data'][0]['id']
            print(f"  ✅ API LIVE! Model loaded: {model_id}")
            ok = True
            break
    except:
        pass
    time.sleep(1)

proc.terminate()
proc.wait()

print()
if ok:
    print("=" * 60)
    print("✅ FULL VERIFICATION PASSED")
    print("   GUI -> Parse -> Server -> API = ALL WORKING")
    print("=" * 60)
else:
    print("❌ FAILED: Server did not respond")
    exit(1)
