$ErrorActionPreference = 'SilentlyContinue'
$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DataDir = Join-Path $ProjectDir 'data'

# Stop supervisor first so it doesn't respawn node
$supPidFile = Join-Path $DataDir 'supervisor.pid'
if (Test-Path -LiteralPath $supPidFile) {
  $supPid = (Get-Content -LiteralPath $supPidFile -Raw).Trim()
  if ($supPid -match '^\d+$') {
    Stop-Process -Id ([int]$supPid) -Force
  }
  Remove-Item -LiteralPath $supPidFile -Force
}

$procs = Get-CimInstance Win32_Process | Where-Object {
  ($_.Name -match '^powershell' -and $_.CommandLine -like "*$ProjectDir*win-supervisor.ps1*") -or
  ($_.Name -eq 'node.exe' -and $_.CommandLine -like "*$ProjectDir*")
}
foreach ($p in $procs) {
  Stop-Process -Id $p.ProcessId -Force
}

$pidFile = Join-Path $DataDir 'bot.pid'
if (Test-Path -LiteralPath $pidFile) {
  $botPid = (Get-Content -LiteralPath $pidFile -Raw).Trim()
  if ($botPid -match '^\d+$') {
    Stop-Process -Id ([int]$botPid) -Force
  }
  Remove-Item -LiteralPath $pidFile -Force
}

Write-Host 'Da dung Bekane Bot.'
