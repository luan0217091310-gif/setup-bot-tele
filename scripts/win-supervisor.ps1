$ErrorActionPreference = 'Stop'

$ProjectDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$DataDir = Join-Path $ProjectDir 'data'
if (-not (Test-Path -LiteralPath $DataDir)) {
  New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

# Single-instance guard so two bots never poll the same Telegram token.
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\BekaneBotSupervisor', [ref]$createdNew)
if (-not $createdNew) {
  exit 0
}

try {
  $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
  if (-not $nodeCmd) {
    $fallbackNode = 'C:\Program Files\nodejs\node.exe'
    if (Test-Path -LiteralPath $fallbackNode) {
      $nodePath = $fallbackNode
    } else {
      throw 'Khong tim thay node.exe'
    }
  } else {
    $nodePath = $nodeCmd.Source
  }

  $supLog = Join-Path $DataDir 'supervisor.log'
  $outLog = Join-Path $DataDir 'bot.log'
  $errLog = Join-Path $DataDir 'bot.err.log'
  $pidFile = Join-Path $DataDir 'bot.pid'
  Set-Content -LiteralPath (Join-Path $DataDir 'supervisor.pid') -Value $PID -Encoding ascii

  Set-Location -LiteralPath $ProjectDir

  if (-not (Test-Path -LiteralPath (Join-Path $ProjectDir 'dist\index.js'))) {
    & npm.cmd run build | Out-Null
  }

  while ($true) {
    foreach ($log in @($supLog, $outLog, $errLog)) {
      if ((Test-Path -LiteralPath $log) -and ((Get-Item -LiteralPath $log).Length -gt 2MB)) {
        Move-Item -LiteralPath $log -Destination "$log.old" -Force
      }
    }

    Add-Content -LiteralPath $supLog -Value ("[{0}] Khoi dong Bekane Bot..." -f (Get-Date -Format 's'))
    $proc = Start-Process -FilePath $nodePath `
      -ArgumentList 'dist/index.js' `
      -WorkingDirectory $ProjectDir `
      -WindowStyle Hidden `
      -RedirectStandardOutput $outLog `
      -RedirectStandardError $errLog `
      -PassThru

    Set-Content -LiteralPath $pidFile -Value $proc.Id -Encoding ascii
    $proc.WaitForExit()
    Add-Content -LiteralPath $supLog -Value ("[{0}] Bot da dung (exit={1}), khoi dong lai sau 8 giay..." -f (Get-Date -Format 's'), $proc.ExitCode)
    Start-Sleep -Seconds 8
  }
} finally {
  if ($mutex) {
    try { $mutex.ReleaseMutex() } catch {}
    $mutex.Dispose()
  }
}
