# Refresca el dashboard "Centro Oriente Volumen" una vez al dia (via Windows Task Scheduler).
# Corre localmente porque las credenciales de Databricks (.env) y run_config.json solo existen
# en esta maquina -- ver detalle del flujo en daily_refresh_centro_oriente_prompt.txt.

$ErrorActionPreference = "Stop"
# El subproceso `claude` escribe stdout en UTF-8; sin esto, PowerShell 5.1 lo captura con el
# codepage de consola por defecto y los acentos/tildes salen corruptos en el log (mojibake).
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

$ProjectDir = "C:\Users\aldoz\OneDrive\Claudio"
$PromptFile = Join-Path $ProjectDir "scripts\daily_refresh_centro_oriente_prompt.txt"
$RunLog = Join-Path $ProjectDir "scripts\daily_refresh_run.log"

Set-Location $ProjectDir

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Add-Content -Path $RunLog -Encoding utf8 -Value "`n===== ${timestamp}: arrancando refresh ====="

$prompt = Get-Content -Raw -Path $PromptFile

try {
    & claude -p $prompt --dangerously-skip-permissions --output-format text | Out-File -FilePath $RunLog -Append -Encoding utf8
    $exitCode = $LASTEXITCODE
    Add-Content -Path $RunLog -Encoding utf8 -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): terminado, exit code $exitCode"
} catch {
    Add-Content -Path $RunLog -Encoding utf8 -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss'): ERROR ejecutando claude -- $($_.Exception.Message)"
}
