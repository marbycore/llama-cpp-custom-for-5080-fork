# ═══════════════════════════════════════════════════════════════
# Llama.cpp Elite Orchestrator — RTX 5080 Blackwell
# GUI Unificada: Modelo + Settings en una sola ventana
# ═══════════════════════════════════════════════════════════════
param(
    [switch]$Test
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$CONFIG_PATH = Join-Path $PSScriptRoot "config_server.json"
$DEFAULT_MODEL_ROOT = "$env:USERPROFILE\.lmstudio\models"
$DEFAULT_HERMES_CFG = "C:\data\hermes\hermes-tui\data\config.yaml"

# ── Cargar Configuración ──
$EXPOSE_LAN = $false
if (Test-Path $CONFIG_PATH) {
    try {
        $config = Get-Content $CONFIG_PATH | ConvertFrom-Json
        $MODEL_ROOT = $config.ModelRoot
        $HERMES_CFG = $config.HermesConfig
        $EXPOSE_LAN = [bool]$config.ExposeLan
    }
    catch {
        $MODEL_ROOT = $DEFAULT_MODEL_ROOT
        $HERMES_CFG = $DEFAULT_HERMES_CFG
    }
}
else {
    $MODEL_ROOT = $DEFAULT_MODEL_ROOT
    $HERMES_CFG = $DEFAULT_HERMES_CFG
}

if (-not $MODEL_ROOT) { $MODEL_ROOT = $DEFAULT_MODEL_ROOT }
if (-not $HERMES_CFG) { $HERMES_CFG = $DEFAULT_HERMES_CFG }

$RESULT_FILE = "$env:TEMP\llama_launch.txt"

# ── Función de Escaneo ──
function Get-GGUFModels {
    param([string]$path)
    if (-not (Test-Path $path)) { return @() }
    return @(Get-ChildItem -Path $path -Filter "*.gguf" -Recurse | Where-Object { $_.Name -notmatch "mmproj" })
}

$script:allModels = Get-GGUFModels $MODEL_ROOT

# Exportar lista para Hermes
$modelListPath = Join-Path $PSScriptRoot "model_list.txt"
if ($script:allModels.Count -gt 0) {
    $script:allModels.Name | Out-File -FilePath $modelListPath -Encoding ascii
}

# ── Modo Test ──
if ($Test) {
    if ($script:allModels.Count -eq 0) { Write-Error "No se encontraron modelos"; exit 1 }
    $m = $script:allModels[0]
    $lanStr = if ($EXPOSE_LAN) { "1" }else { "0" }
    $line = "$($m.FullName)|131072|99|1|Default|$HERMES_CFG|$lanStr"
    [System.IO.File]::WriteAllText($RESULT_FILE, $line)
    exit 0
}

# ── Formulario ──
$form = New-Object Windows.Forms.Form
$form.Text = "Llama.cpp Elite Orchestrator - RTX 5080 Blackwell"
$form.ClientSize = New-Object Drawing.Size(960, 840)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(25, 25, 25)
$form.ForeColor = [Drawing.Color]::White
$form.Font = New-Object Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = "Sizable"

# ── Selectores de Rutas (Compactos) ──
function New-PathSelector {
    param($title, $y, $val, $isFolder)
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $title; $lbl.Location = New-Object Drawing.Point(20, $y); $lbl.AutoSize = $true
    $form.Controls.Add($lbl)

    $txt = New-Object Windows.Forms.TextBox
    $txt.Text = $val; $txt.Location = New-Object Drawing.Point(160, $y - 2); $txt.Size = New-Object Drawing.Size(690, 28)
    $txt.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $txt.ForeColor = [Drawing.Color]::White
    $form.Controls.Add($txt)

    $btn = New-Object Windows.Forms.Button
    $btn.Text = "..."; $btn.Location = New-Object Drawing.Point(860, $y - 3); $btn.Size = New-Object Drawing.Size(80, 30)
    $btn.BackColor = [Drawing.Color]::FromArgb(70, 70, 70)
    $btn.Add_Click({
            if ($isFolder) {
                $fbd = New-Object Windows.Forms.FolderBrowserDialog; $fbd.SelectedPath = $txt.Text
                if ($fbd.ShowDialog() -eq "OK") { $txt.Text = $fbd.SelectedPath }
            }
            else {
                $ofd = New-Object Windows.Forms.OpenFileDialog; $ofd.Filter = "YAML|*.yaml"
                if ($ofd.ShowDialog() -eq "OK") { $txt.Text = $ofd.FileName }
            }
        })
    $form.Controls.Add($btn)
    return $txt
}

$txtPath = New-PathSelector "Carpeta Modelos:" 15 $MODEL_ROOT $true
$txtHermes = New-PathSelector "Hermes Config:" 55 $HERMES_CFG $false

# ── Buscador ──
$lblS = New-Object Windows.Forms.Label
$lblS.Text = "Filtrar por nombre:"
$lblS.Location = New-Object Drawing.Point(20, 95); $lblS.AutoSize = $true
$form.Controls.Add($lblS)

$txtS = New-Object Windows.Forms.TextBox
$txtS.Location = New-Object Drawing.Point(160, 93); $txtS.Size = New-Object Drawing.Size(780, 28)
$txtS.BackColor = [Drawing.Color]::FromArgb(50, 50, 50); $txtS.ForeColor = [Drawing.Color]::White
$form.Controls.Add($txtS)

# ── DataGridView ──
$dgv = New-Object Windows.Forms.DataGridView
$dgv.Location = New-Object Drawing.Point(20, 135); $dgv.Size = New-Object Drawing.Size(920, 320)
$dgv.Anchor = "Top,Left,Right,Bottom"
$dgv.BackgroundColor = [Drawing.Color]::FromArgb(35, 35, 35)
$dgv.DefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(40, 40, 40); $dgv.DefaultCellStyle.ForeColor = [Drawing.Color]::White
$dgv.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::LimeGreen; $dgv.DefaultCellStyle.SelectionForeColor = [Drawing.Color]::Black
$dgv.ColumnCount = 4; $dgv.Columns[0].Name = "Modelo"; $dgv.Columns[0].Width = 380; $dgv.Columns[1].Name = "GB"; $dgv.Columns[2].Name = "Origen"
$dgv.Columns[3].Visible = $false; $dgv.SelectionMode = "FullRowSelect"; $dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false
$form.Controls.Add($dgv)

function Update-ModelGrid {
    if (-not (Test-Path $txtPath.Text)) { return }
    $dgv.Rows.Clear()
    $models = Get-GGUFModels $txtPath.Text
    foreach ($m in $models) {
        if ($m.Name -like "*$($txtS.Text)*") {
            $dgv.Rows.Add($m.Name, [math]::round($m.Length / 1GB, 2), ($m.Directory.Parent.Name + "/" + $m.Directory.Name), $m.FullName) | Out-Null
        }
    }
    if ($dgv.Rows.Count -gt 0) { $dgv.Rows[0].Selected = $true }
}
$txtPath.Add_TextChanged({ Update-ModelGrid }); $txtS.Add_TextChanged({ Update-ModelGrid }); Update-ModelGrid

# ── Toggle Red (LAN) ──
$pnlNet = New-Object Windows.Forms.Panel
$pnlNet.Location = New-Object Drawing.Point(20, 465); $pnlNet.Size = New-Object Drawing.Size(920, 40)
$pnlNet.Anchor = "Bottom,Left"
$form.Controls.Add($pnlNet)

$chkLan = New-Object Windows.Forms.CheckBox
$chkLan.Text = "Habilitar Acceso LAN (Red Local) - Permite que otros dispositivos se conecten"
$chkLan.Checked = $EXPOSE_LAN
$chkLan.AutoSize = $true; $chkLan.ForeColor = [Drawing.Color]::DeepSkyBlue
$chkLan.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$pnlNet.Controls.Add($chkLan)

# ── Panel de Settings ──
$pnl = New-Object Windows.Forms.GroupBox
$pnl.Text = "  Optimizacion Blackwell RTX 5080  "
$pnl.ForeColor = [Drawing.Color]::LimeGreen
$pnl.Location = New-Object Drawing.Point(20, 510); $pnl.Size = New-Object Drawing.Size(920, 180)
$pnl.Anchor = "Bottom,Left,Right"
$form.Controls.Add($pnl)

function New-Setting {
    param($title, $x, $items, $def)
    $lbl = New-Object Windows.Forms.Label; $lbl.Text = $title; $lbl.Location = New-Object Drawing.Point($x, 30); $lbl.Width = 200
    $pnl.Controls.Add($lbl)
    $cb = New-Object Windows.Forms.ComboBox; $cb.Location = New-Object Drawing.Point($x, 55); $cb.Width = 200; $cb.DropDownStyle = "DropDownList"
    foreach ($i in $items) { $cb.Items.Add($i) | Out-Null }; $cb.SelectedIndex = $def; $pnl.Controls.Add($cb)
    return $cb
}

$cCtx = New-Setting "Contexto" 15 @("32768 (32K)", "65536 (64K)", "131072 (128K)", "262144 (256K)") 2
$cGpu = New-Setting "GPU Layers" 240 @("99 - Max FPS", "60 - Balanced", "40 - Safe") 0
$cPar = New-Setting "Parallel Slots" 465 @("1 - Solo Yo", "2 - Con Hermes", "4 - Multi") 0
$cBat = New-Setting "uBatch Size" 690 @("Default", "1024", "2048", "4096") 0

# ── Botón Lanzar ──
$btn = New-Object Windows.Forms.Button
$btn.Text = "LANZAR LABORATORIO BLACKWELL"
$btn.Location = New-Object Drawing.Point(250, 710); $btn.Size = New-Object Drawing.Size(460, 70); $btn.Anchor = "Bottom"
$btn.BackColor = [Drawing.Color]::LimeGreen; $btn.Font = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
$btn.FlatStyle = "Flat"; $btn.ForeColor = [Drawing.Color]::Black

$btn.Add_Click({
        if ($dgv.SelectedRows.Count -eq 0) { return }
    
        # Persistencia total
        $conf = @{ ModelRoot = $txtPath.Text; HermesConfig = $txtHermes.Text; ExposeLan = $chkLan.Checked }
        $conf | ConvertTo-Json | Out-File $CONFIG_PATH -Force

        $modelPath = $dgv.SelectedRows[0].Cells[3].Value
        $ctx = $cCtx.SelectedItem.Split(" ")[0]
        $ngl = $cGpu.SelectedItem.Split(" ")[0]
        $np = $cPar.SelectedItem.Split(" ")[0]
        $ub = $cBat.SelectedItem.Split(" ")[0]
        $lan = if ($chkLan.Checked) { "1" }else { "0" }
    
        [System.IO.File]::WriteAllText($RESULT_FILE, "$modelPath|$ctx|$ngl|$np|$ub|$($txtHermes.Text)|$lan")
        $form.DialogResult = [Windows.Forms.DialogResult]::OK
        $form.Close()
    })
$form.Controls.Add($btn)
$form.ShowDialog() | Out-Null
