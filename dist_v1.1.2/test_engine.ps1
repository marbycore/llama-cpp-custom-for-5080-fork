# Suite de Diagnóstico Llama-Server RTX 5080
$MODEL = "C:\Users\marco\.lmstudio\models\bartowski\Qwen_Qwen3.5-4B-GGUF\Qwen_Qwen3.5-4B-Q4_K_S.gguf"
$BIN = "c:\data\llama-cpp-custom\build\bin\llama-server.exe"

function Test-Launch {
    param([string]$host_ip, [string]$label)
    Write-Host "🧪 Probando Despliegue: $label ($host_ip)..." -ForegroundColor Cyan
    
    $proc = Start-Process $BIN -ArgumentList "-m `"$MODEL`" --host $host_ip --port 5050 -ngl 99 -c 4096 --flash-attn on" -NoNewWindow -PassThru
    Start-Sleep -Seconds 8
    
    $url = "http://$($host_ip):5050/health"
    if ($host_ip -eq "0.0.0.0") { $url = "http://127.0.0.1:5050/health" }
    
    try {
        $res = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 2 -ErrorAction Stop
        Write-Host "✅ EXITO: Servidor respondiendo en $url" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ ERROR: Servidor NO responde en $url" -ForegroundColor Red
    }
    
    Stop-Process $proc -Force
}

# Ejecutar Pruebas
Test-Launch "127.0.0.1" "MODO PRIVADO"
Test-Launch "0.0.0.0" "MODO LAN (0.0.0.0)"
