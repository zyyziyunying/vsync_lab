param(
  [int]$TraceSeconds = 15,
  [string]$TraceName = 'vsync_trace',
  [string]$OutputDir = 'artifacts/perfetto',
  [string]$PackageName = 'com.harrypet.vsync_lab'
)

$ErrorActionPreference = 'Stop'

$targetDir = Join-Path $PSScriptRoot "../$OutputDir"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$baseName = "${TraceName}_${timestamp}"
$traceDurationMs = $TraceSeconds * 1000

$remoteConfigPath = '/data/local/tmp/perfetto_vsync.cfg'
$remotePerfettoPath = "/data/local/tmp/${baseName}.pftrace"
$localPerfettoPath = Join-Path $targetDir "${baseName}.pftrace"
$remoteAtracePath = "/data/local/tmp/${baseName}.trace"
$localAtracePath = Join-Path $targetDir "${baseName}.trace"

$config = @"
duration_ms: $traceDurationMs

buffers: {
  size_kb: 16384
  fill_policy: RING_BUFFER
}

data_sources: {
  config {
    name: "linux.ftrace"
    ftrace_config {
      ftrace_events: "sched/sched_switch"
      ftrace_events: "sched/sched_wakeup"
      ftrace_events: "sched/sched_waking"
      atrace_categories: "gfx"
      atrace_categories: "view"
      atrace_categories: "wm"
      atrace_categories: "sched"
      atrace_categories: "freq"
      atrace_categories: "idle"
      atrace_apps: "$PackageName"
    }
  }
}
"@

function Invoke-Adb {
  param(
    [string[]]$Arguments,
    [string]$ErrorMessage
  )

  & adb @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw $ErrorMessage
  }
}

function Test-LocalTraceFile {
  param([string]$Path)

  return (Test-Path $Path) -and ((Get-Item $Path).Length -gt 0)
}

$tmpConfigPath = Join-Path $env:TEMP "perfetto_${timestamp}.cfg"
[System.IO.File]::WriteAllText(
  $tmpConfigPath,
  $config,
  (New-Object System.Text.UTF8Encoding($false))
)

$traceSavedPath = $null
$captureMode = $null

try {
  Write-Host "Recording Perfetto trace for ${TraceSeconds}s ..."

  try {
    Invoke-Adb -Arguments @('push', $tmpConfigPath, $remoteConfigPath) -ErrorMessage 'Failed to push Perfetto config to device.'

    & adb shell perfetto --txt -c $remoteConfigPath -o $remotePerfettoPath
    if ($LASTEXITCODE -eq 0) {
      Invoke-Adb -Arguments @('pull', $remotePerfettoPath, $localPerfettoPath) -ErrorMessage 'Failed to pull Perfetto trace to host.'

      if (Test-LocalTraceFile -Path $localPerfettoPath) {
        $traceSavedPath = $localPerfettoPath
        $captureMode = 'perfetto'
      }
      else {
        Remove-Item $localPerfettoPath -ErrorAction SilentlyContinue
      }
    }
  }
  catch {
    Write-Warning $_
  }

  if (-not $traceSavedPath) {
    Write-Warning 'Perfetto capture failed or produced an empty trace. Falling back to atrace for Android 10 compatibility.'
    Write-Host "Recording atrace fallback for ${TraceSeconds}s ..."

    Invoke-Adb -Arguments @(
      'shell',
      'atrace',
      '-z',
      '-b', '16384',
      '-t', "$TraceSeconds",
      '-a', $PackageName,
      'gfx',
      'view',
      'wm',
      'sched',
      'freq',
      'idle',
      '-o', $remoteAtracePath
    ) -ErrorMessage 'Atrace fallback recording failed.'

    Invoke-Adb -Arguments @('pull', $remoteAtracePath, $localAtracePath) -ErrorMessage 'Failed to pull atrace fallback to host.'

    if (-not (Test-LocalTraceFile -Path $localAtracePath)) {
      throw 'Atrace fallback completed but produced an empty trace.'
    }

    $traceSavedPath = $localAtracePath
    $captureMode = 'atrace'
  }

  Write-Host "Trace saved: $traceSavedPath"
  if ($captureMode -eq 'perfetto') {
    Write-Host 'Format: Perfetto (.pftrace)'
    Write-Host 'Open in https://ui.perfetto.dev'
  }
  else {
    Write-Host 'Format: atrace fallback (.trace, gzip-compressed)'
    Write-Host 'Open in https://ui.perfetto.dev or legacy systrace tooling'
  }
}
finally {
  Remove-Item $tmpConfigPath -ErrorAction SilentlyContinue
  adb shell rm -f $remoteConfigPath | Out-Null
  adb shell rm -f $remotePerfettoPath | Out-Null
  adb shell rm -f $remoteAtracePath | Out-Null
}
