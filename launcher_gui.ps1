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
if (Test-Path $CONFIG_PATH) {
    try {
        $config = Get-Content $CONFIG_PATH | ConvertFrom-Json
        $MODEL_ROOT = $config.ModelRoot
        $HERMES_CFG = $config.HermesConfig
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
    $line = "$($m.FullName)|131072|99|1|Default|$HERMES_CFG"
    [System.IO.File]::WriteAllText($RESULT_FILE, $line)
    exit 0
}

# ── Formulario ──
$form = New-Object Windows.Forms.Form
$form.Text = "Llama.cpp Elite Orchestrator - RTX 5080 Blackwell"
$form.ClientSize = New-Object Drawing.Size(960, 800)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(25, 25, 25)
$form.ForeColor = [Drawing.Color]::White
$form.Font = New-Object Drawing.Font("Segoe UI", 10)
$form.FormBorderStyle = "Sizable"
$form.MinimumSize = New-Object Drawing.Size(800, 700)

# ── Selector de Carpeta de Modelos ──
$lblPath = New-Object Windows.Forms.Label
$lblPath.Text = "Carpeta de Modelos:"
$lblPath.Location = New-Object Drawing.Point(20, 15)
$lblPath.AutoSize = $true
$form.Controls.Add($lblPath)

$txtPath = New-Object Windows.Forms.TextBox
$txtPath.Text = $MODEL_ROOT
$txtPath.Location = New-Object Drawing.Point(160, 13)
$txtPath.Size = New-Object Drawing.Size(690, 28)
$txtPath.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$txtPath.ForeColor = [Drawing.Color]::LimeGreen
$form.Controls.Add($txtPath)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = "Folder"
$btnBrowse.Location = New-Object Drawing.Point(860, 12)
$btnBrowse.Size = New-Object Drawing.Size(80, 30)
$btnBrowse.BackColor = [Drawing.Color]::FromArgb(70, 70, 70)
$form.Controls.Add($btnBrowse)

# ── Selector de Hermes Config ──
$lblHermes = New-Object Windows.Forms.Label
$lblHermes.Text = "Hermes config.yaml:"
$lblHermes.Location = New-Object Drawing.Point(20, 55)
$lblHermes.AutoSize = $true
$form.Controls.Add($lblHermes)

$txtHermes = New-Object Windows.Forms.TextBox
$txtHermes.Text = $HERMES_CFG
$txtHermes.Location = New-Object Drawing.Point(160, 53)
$txtHermes.Size = New-Object Drawing.Size(690, 28)
$txtHermes.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$txtHermes.ForeColor = [Drawing.Color]::DeepSkyBlue
$form.Controls.Add($txtHermes)

$btnHermes = New-Object Windows.Forms.Button
$btnHermes.Text = "Config"
$btnHermes.Location = New-Object Drawing.Point(860, 52)
$btnHermes.Size = New-Object Drawing.Size(80, 30)
$btnHermes.BackColor = [Drawing.Color]::FromArgb(70, 70, 70)
$form.Controls.Add($btnHermes)

# ── Buscador ──
$lblS = New-Object Windows.Forms.Label
$lblS.Text = "Filtrar nombre:"
$lblS.Location = New-Object Drawing.Point(20, 95)
$lblS.AutoSize = $true
$form.Controls.Add($lblS)

$txtS = New-Object Windows.Forms.TextBox
$txtS.Location = New-Object Drawing.Point(160, 93)
$txtS.Size = New-Object Drawing.Size(780, 28)
$txtS.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$txtS.ForeColor = [Drawing.Color]::White
$form.Controls.Add($txtS)

# ── DataGridView ──
$dgv = New-Object Windows.Forms.DataGridView
$dgv.Location = New-Object Drawing.Point(20, 135)
$dgv.Size = New-Object Drawing.Size(920, 335)
$dgv.Anchor = "Top,Left,Right,Bottom"
$dgv.BackgroundColor = [Drawing.Color]::FromArgb(35, 35, 35)
$dgv.GridColor = [Drawing.Color]::FromArgb(60, 60, 60)
$dgv.BorderStyle = "None"
$dgv.CellBorderStyle = "SingleHorizontal"
$dgv.ColumnHeadersDefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$dgv.ColumnHeadersDefaultCellStyle.ForeColor = [Drawing.Color]::LimeGreen
$dgv.ColumnHeadersDefaultCellStyle.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$dgv.EnableHeadersVisualStyles = $false
$dgv.DefaultCellStyle.BackColor = [Drawing.Color]::FromArgb(40, 40, 40)
$dgv.DefaultCellStyle.ForeColor = [Drawing.Color]::White
$dgv.DefaultCellStyle.SelectionBackColor = [Drawing.Color]::FromArgb(0, 180, 0)
$dgv.DefaultCellStyle.SelectionForeColor = [Drawing.Color]::Black
$dgv.ColumnCount = 4
$dgv.Columns[0].Name = "Modelo"; $dgv.Columns[0].Width = 380
$dgv.Columns[1].Name = "GB"; $dgv.Columns[1].Width = 70
$dgv.Columns[2].Name = "Origen"; $dgv.Columns[2].Width = 250
$dgv.Columns[3].Name = "Ruta"; $dgv.Columns[3].Visible = $false
$dgv.AutoSizeColumnsMode = "None"
$dgv.SelectionMode = "FullRowSelect"
$dgv.MultiSelect = $false; $dgv.ReadOnly = $true
$dgv.RowHeadersVisible = $false; $dgv.AllowUserToAddRows = $false
$dgv.RowTemplate.Height = 32
$form.Controls.Add($dgv)

function Update-ModelGrid {
    param([string]$filter = "")
    $dgv.Rows.Clear()
    $script:allModels = Get-GGUFModels $txtPath.Text
    
    $confObj = @{ 
        ModelRoot    = $txtPath.Text
        HermesConfig = $txtHermes.Text
    }
    $confObj | ConvertTo-Json | Out-File $CONFIG_PATH -Force

    foreach ($m in $script:allModels) {
        if ($filter -eq "" -or $m.Name -like "*$filter*") {
            $origen = $m.Directory.Parent.Name + "/" + $m.Directory.Name
            $dgv.Rows.Add($m.Name, [math]::round($m.Length / 1GB, 2), $origen, $m.FullName) | Out-Null
        }
    }
    if ($dgv.Rows.Count -gt 0) { $dgv.Rows[0].Selected = $true }
}
Update-ModelGrid

$btnBrowse.Add_Click({
        $fbd = New-Object Windows.Forms.FolderBrowserDialog
        $fbd.SelectedPath = $txtPath.Text
        if ($fbd.ShowDialog() -eq "OK") {
            $txtPath.Text = $fbd.SelectedPath
            Update-ModelGrid $txtS.Text
        }
    })

$btnHermes.Add_Click({
        $ofd = New-Object Windows.Forms.OpenFileDialog
        $ofd.Filter = "YAML Files (*.yaml)|*.yaml"
        if ($ofd.ShowDialog() -eq "OK") {
            $txtHermes.Text = $ofd.FileName
            Update-ModelGrid $txtS.Text
        }
    })

$txtPath.Add_TextChanged({ Update-ModelGrid $txtS.Text })
$txtHermes.Add_TextChanged({ Update-ModelGrid $txtS.Text })
$txtS.Add_TextChanged({ Update-ModelGrid $txtS.Text })

$pnl = New-Object Windows.Forms.GroupBox
$pnl.Text = "  Configuracion Avanzada  "
$pnl.ForeColor = [Drawing.Color]::LimeGreen
$pnl.Location = New-Object Drawing.Point(20, 490)
$pnl.Size = New-Object Drawing.Size(920, 200)
$pnl.Anchor = "Bottom,Left,Right"
$form.Controls.Add($pnl)

function New-Setting {
    param($title, $x, $items, $def, $tip)
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $title; $lbl.ForeColor = "White"
    $lbl.Location = New-Object Drawing.Point($x, 30); $lbl.Width = 200
    $pnl.Controls.Add($lbl)

    $cb = New-Object Windows.Forms.ComboBox
    $cb.Location = New-Object Drawing.Point($x, 55); $cb.Width = 200
    $cb.DropDownStyle = "DropDownList"
    $cb.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
    $cb.ForeColor = [Drawing.Color]::White
    $cb.FlatStyle = "Flat"
    foreach ($i in $items) { $cb.Items.Add($i) | Out-Null }
    $cb.SelectedIndex = $def
    $pnl.Controls.Add($cb)

    $tipLbl = New-Object Windows.Forms.Label
    $tipLbl.Text = $tip
    $tipLbl.ForeColor = [Drawing.Color]::Gray
    $tipLbl.Location = New-Object Drawing.Point($x, 85); $tipLbl.Size = New-Object Drawing.Size(210, 80)
    $tipLbl.Font = New-Object Drawing.Font("Segoe UI", 8)
    $pnl.Controls.Add($tipLbl)
    return $cb
}

$cCtx = New-Setting "Contexto (Tokens)" 15 @(
    "32768 (32K) - Chats cortos",
    "65536 (64K) - Hermes Agent",
    "131072 (128K) - Max Qwen",
    "262144 (256K) - Experimental"
) 2 "Memoria de conversacion"

$cGpu = New-Setting "GPU Layers (-ngl)" 240 @(
    "99 - Todo en GPU",
    "60 - Hibrido GPU+CPU",
    "40 - Seguro (modelos >14GB)",
    "0 - Solo CPU (muy lento)"
) 0 "Capas cargadas en VRAM"

$cPar = New-Setting "Parallel Slots (-np)" 465 @(
    "1 - Velocidad maxima",
    "2 - Multi-tarea (Hermes)",
    "4 - Alta concurrencia"
) 0 "Sesiones simultaneas"

$cBat = New-Setting "uBatch Size" 690 @(
    "Default - Automatico",
    "1024 - Balanceado",
    "2048 - Rapido",
    "4096 - Maximo RTX 5080"
) 0 "Batch size Blackwell"

$btn = New-Object Windows.Forms.Button
$btn.Text = "LANZAR SERVIDOR RTX 5080"
$btn.Location = New-Object Drawing.Point(250, 700)
$btn.Size = New-Object Drawing.Size(460, 70)
$btn.Anchor = "Bottom"
$btn.BackColor = [Drawing.Color]::LimeGreen
$btn.ForeColor = [Drawing.Color]::Black
$btn.FlatStyle = "Flat"
$btn.Font = New-Object Drawing.Font("Segoe UI", 15, [Drawing.FontStyle]::Bold)
$btn.Cursor = [Windows.Forms.Cursors]::Hand

$btn.Add_Click({
        if ($dgv.SelectedRows.Count -eq 0) {
            [Windows.Forms.MessageBox]::Show("Selecciona un modelo de la tabla.", "Error", "OK", "Warning")
            return
        }
        $modelPath = $dgv.SelectedRows[0].Cells[3].Value
        $ctx = $cCtx.SelectedItem.Split(" ")[0]
        $ngl = $cGpu.SelectedItem.Split(" ")[0]
        $np = $cPar.SelectedItem.Split(" ")[0]
        $ub = $cBat.SelectedItem.Split(" ")[0]
        $hermesCfg = $txtHermes.Text
        [System.IO.File]::WriteAllText($RESULT_FILE, "$modelPath|$ctx|$ngl|$np|$ub|$hermesCfg")
        $form.DialogResult = [Windows.Forms.DialogResult]::OK
        $form.Close()
    })
$form.Controls.Add($btn)

$form.ShowDialog() | Out-Null
