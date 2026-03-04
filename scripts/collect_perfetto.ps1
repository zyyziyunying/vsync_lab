param(
  [int]$TraceSeconds = 15,
  [string]$TraceName = 'vsync_trace',
  [string]$OutputDir = 'artifacts/perfetto'
)

$ErrorActionPreference = 'Stop'

$targetDir = Join-Path $PSScriptRoot "../$OutputDir"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$remotePath = "/data/misc/perfetto-traces/${TraceName}_${timestamp}.pftrace"
$localPath = Join-Path $targetDir "${TraceName}_${timestamp}.pftrace"

$config = @"
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
      ftrace_events: "gfx/frame_timeline"
      ftrace_events: "view/view_vsync"
    }
  }
}

data_sources: {
  config {
    name: "android.surfaceflinger.frametimeline"
  }
}

data_sources: {
  config {
    name: "track_event"
  }
}
"@

$tmpConfigPath = Join-Path $env:TEMP "perfetto_${timestamp}.cfg"
$config | Set-Content -Path $tmpConfigPath -Encoding utf8

Write-Host "Recording Perfetto trace for ${TraceSeconds}s ..."
adb push $tmpConfigPath /data/local/tmp/perfetto_vsync.cfg | Out-Null
adb shell perfetto -o $remotePath -t "${TraceSeconds}s" -c /data/local/tmp/perfetto_vsync.cfg

Write-Host 'Pulling trace to host ...'
adb pull $remotePath $localPath | Out-Null

Remove-Item $tmpConfigPath -ErrorAction SilentlyContinue
adb shell rm /data/local/tmp/perfetto_vsync.cfg | Out-Null

Write-Host "Trace saved: $localPath"
Write-Host 'Open in https://ui.perfetto.dev'
