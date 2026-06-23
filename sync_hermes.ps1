param(
    [string]$ConfigPath,
    [string]$ModelName,
    [string]$Context
)

if (Test-Path $ConfigPath) {
    try {
        $content = Get-Content $ConfigPath
        # Actualización quirúrgica de valores respetando la estructura YAML
        $content = $content -replace '^\s*default:.*', "  default: $ModelName"
        $content = $content -replace '^\s*context_length:.*', "  context_length: $Context"
        $content | Set-Content $ConfigPath -Force
        Write-Host "✅ Hermes sincronizado con: $ModelName" -ForegroundColor Green
    }
    catch {
        Write-Warning "No se pudo sincronizar Hermes: $($_.Exception.Message)"
    }
}
