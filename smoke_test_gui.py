"""Quick GUI smoke test: Opens the real GUI, checks for errors, auto-closes after 3 seconds."""
import subprocess, threading, time

def kill_after(proc, seconds):
    time.sleep(seconds)
    proc.terminate()

print("Opening GUI for 4 seconds to check for errors...")
proc = subprocess.Popen(
    ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
     "-File", r"C:\data\llama-cpp-custom\launcher_gui.ps1"],
    stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
)

# Auto-close after 4 seconds
t = threading.Thread(target=kill_after, args=(proc, 4))
t.start()
stdout, stderr = proc.communicate()

if stderr.strip():
    print(f"ERRORS FOUND:\n{stderr}")
else:
    print("NO ERRORS - GUI opened cleanly!")

if stdout.strip():
    print(f"Stdout: {stdout.strip()}")
