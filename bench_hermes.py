"""Benchmark llama.cpp server — measures prompt eval + generation t/s."""
import requests, json, time

URL = "http://127.0.0.1:5050/v1/chat/completions"

# A realistic Hermes-like prompt
messages = [
    {"role": "system", "content": "You are Hermes, a helpful AI assistant. Respond concisely and in Spanish."},
    {"role": "user", "content": (
        "Explícame detalladamente cómo funciona el protocolo TCP/IP, "
        "incluyendo las 4 capas del modelo, el three-way handshake, "
        "el control de flujo con ventana deslizante, y cómo se diferencia de UDP. "
        "Dame ejemplos prácticos de cuándo usar cada uno."
    )}
]

payload = {
    "model": "Qwen3.6-35B-A3B-UD-IQ3_S.gguf",
    "messages": messages,
    "max_tokens": 1024,
    "temperature": 0.7,
    "stream": False
}

print("=" * 60)
print("  Benchmark: llama.cpp Custom Build (RTX 5080)")
print("  Model: Qwen3.6-35B-A3B (IQ3_S)")
print("  Context: 131072 tokens")
print("=" * 60)
print()

t0 = time.perf_counter()
resp = requests.post(URL, json=payload, timeout=120)
elapsed = time.perf_counter() - t0

data = resp.json()
if "error" in data:
    print(f"ERROR: {data['error']}")
    exit(1)

usage = data.get("usage", {})
prompt_tokens = usage.get("prompt_tokens", 0)
completion_tokens = usage.get("completion_tokens", 0)
total_tokens = prompt_tokens + completion_tokens

# llama.cpp includes timings in the response
choice = data["choices"][0]
content = choice["message"]["content"]

gen_tps = completion_tokens / elapsed if elapsed > 0 else 0

print(f"  Prompt tokens:     {prompt_tokens}")
print(f"  Completion tokens: {completion_tokens}")
print(f"  Total tokens:      {total_tokens}")
print(f"  Wall time:         {elapsed:.2f}s")
print(f"  Generation speed:  {gen_tps:.1f} t/s (wall clock)")
print()

# Try to get internal timings from llama.cpp
timings = data.get("timings", {})
if timings:
    pp_tps = timings.get("prompt_per_second", 0)
    gen_tps_internal = timings.get("predicted_per_second", 0)
    print(f"  [Internal metrics]")
    print(f"  Prompt eval:       {pp_tps:.1f} t/s")
    print(f"  Generation:        {gen_tps_internal:.1f} t/s")
    TARGET = 75
    if gen_tps_internal >= TARGET:
        print(f"\n  ✅ TARGET MET: {gen_tps_internal:.1f} t/s >= {TARGET} t/s")
    else:
        print(f"\n  ❌ BELOW TARGET: {gen_tps_internal:.1f} t/s < {TARGET} t/s")
else:
    print("  (No internal timings available from server)")

print()
print("  --- Response preview (first 300 chars) ---")
print(f"  {content[:300]}...")
print()
