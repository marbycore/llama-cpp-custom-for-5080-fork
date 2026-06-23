$MODEL = "C:\Users\marco\.lmstudio\models\bartowski\Qwen_Qwen3.5-4B-GGUF\Qwen_Qwen3.5-4B-Q4_K_S.gguf"
$BIN = "c:\data\llama-cpp-custom\build\bin\llama-server.exe"
Write-Host "🚀 Iniciando Motor en Modo LAN (0.0.0.0)..."
$p = Start-Process $BIN -ArgumentList "-m `"$MODEL`" --host 0.0.0.0 --port 5050 -ngl 99 -c 4096 --flash-attn on" -NoNewWindow -PassThru
Start-Sleep -Seconds 10
try {
    $res = Invoke-WebRequest -Uri "http://127.0.0.1:5050/health" -Method Head -ErrorAction Stop
    Write-Host "✅ MOTOR LAN OPERATIVO" -ForegroundColor Green
}
catch {
    Write-Host "❌ MOTOR LAN FALLIDO" -ForegroundColor Red
}
Stop-Process $p -Force
