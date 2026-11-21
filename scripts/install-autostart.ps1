$ErrorActionPreference = 'Stop'

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$VbsPath = Join-Path $PSScriptRoot 'start-hidden.vbs'
$TaskName = 'BekaneBotAutoStart'
$StartupDir = [Environment]::GetFolderPath('Startup')
$StartupShortcut = Join-Path $StartupDir 'BekaneBot.lnk'

# Remove legacy startup shortcut if switching to Task Scheduler cleanly
if (Test-Path -LiteralPath $StartupShortcut) {
  Remove-Item -LiteralPath $StartupShortcut -Force
}

$registeredTask = $false
try {
  $action = New-ScheduledTaskAction -Execute 'wscript.exe' -Argument ('"' + $VbsPath + '"') -WorkingDirectory $ProjectDir
  $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
  $trigger.Delay = 'PT10S'
  $settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit ([TimeSpan]::Zero) `
    -MultipleInstances IgnoreNew

  Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Description 'Tu dong khoi dong Bekane Bot Telegram khi bat may Windows' `
    -Force | Out-Null

  $registeredTask = $true
  Write-Host "Da cai dat Task Scheduler '$TaskName' thanh cong!"
} catch {
  Write-Warning "Khong dang ky duoc Task Scheduler ($($_.Exception.Message)), chuyen sang Startup Folder..."
}

if (-not $registeredTask) {
  $wsh = New-Object -ComObject WScript.Shell
  $lnk = $wsh.CreateShortcut($StartupShortcut)
  $lnk.TargetPath = 'wscript.exe'
  $lnk.Arguments = '"' + $VbsPath + '"'
  $lnk.WorkingDirectory = $ProjectDir
  $lnk.Description = 'Tu dong khoi dong Bekane Bot Telegram'
  $lnk.Save()
  Write-Host "Da tao shortcut khoi dong cung Windows tai: $StartupShortcut"
}
