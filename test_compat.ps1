$MODEL = "C:\Users\marco\.lmstudio\models\bartowski\Qwen_Qwen3.5-4B-GGUF\Qwen_Qwen3.5-4B-Q4_K_S.gguf"
$BIN = "c:\data\llama-cpp-custom\build\bin\llama-server.exe"

Write-Host "Iniciando Motor Blackwell en Puerto 1234..."
$p = Start-Process $BIN -ArgumentList "-m `"$MODEL`" --host 127.0.0.1 --port 1234 -ngl 99" -NoNewWindow -PassThru
Start-Sleep -Seconds 10

Write-Host "Probando Ruta Estandar (/v1/models)..."
$res1 = curl.exe -s http://127.0.0.1:1234/v1/models
if ($res1) { 
    Write-Host "EXITO: El servidor esta respondiendo."
    $res1 | Out-Host
}
else { 
    Write-Host "ERROR: Sin respuesta del servidor."
}

Stop-Process $p -Force
Write-Host "Prueba finalizada."
