param(
  [string]$PackageName = 'com.harrypet.vsync_lab',
  [string]$OutputDir = 'artifacts',
  [string]$Scenario,
  [string]$DeviceId,
  [int]$RecentWindow = 0,
  [int]$WarmupSkip = 30,
  [int]$ChunkSize = 60,
  [int]$TopCount = 10,
  [switch]$AsJson,
  [string]$UseExistingFile
)

$ErrorActionPreference = 'Stop'

function Invoke-Adb {
  param(
    [string[]]$Arguments,
    [string]$ErrorMessage,
    [switch]$CaptureOutput
  )

  $adbArgs = @()
  if ($DeviceId) {
    $adbArgs += @('-s', $DeviceId)
  }
  $adbArgs += $Arguments

  if ($CaptureOutput) {
    $output = & adb @adbArgs
    if ($LASTEXITCODE -ne 0) {
      throw $ErrorMessage
    }

    return $output
  }

  & adb @adbArgs
  if ($LASTEXITCODE -ne 0) {
    throw $ErrorMessage
  }
}

function Get-RemoteLatestFileName {
  $remoteAppDataDir = Get-RemoteAppDataDir
  $listing = Invoke-Adb -Arguments @(
    'shell',
    'run-as',
    $PackageName,
    'ls',
    '-1t',
    "$remoteAppDataDir/cache"
  ) -ErrorMessage 'Failed to inspect app cache directory via adb.' -CaptureOutput

  $fileName = $listing |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -match '^frame_log_.*_latest\.json$' } |
    Select-Object -First 1

  if (-not $fileName) {
    throw 'No frame log found in app cache. Tap "Save frame log" in the app first.'
  }

  return $fileName
}

function Get-RemoteAppDataDir {
  $appDataDirOutput = Invoke-Adb -Arguments @(
    'shell',
    'run-as',
    $PackageName,
    'pwd'
  ) -ErrorMessage 'Failed to resolve app data directory via adb.' -CaptureOutput

  $appDataDir = (($appDataDirOutput -join "`n").Trim())
  if (-not $appDataDir) {
    throw 'Failed to resolve app data directory via adb.'
  }

  return $appDataDir
}

function Get-RemoteFileName {
  if ($Scenario) {
    return "frame_log_${Scenario}_latest.json"
  }

  return Get-RemoteLatestFileName
}

function Pull-RemoteFile {
  param(
    [string]$RemoteAbsolutePath,
    [string]$LocalPath
  )

  $adbPrefix = 'adb'
  if ($DeviceId) {
    $adbPrefix += " -s $DeviceId"
  }

  $escapedLocalPath = $LocalPath.Replace('"', '""')
  $command = "$adbPrefix exec-out run-as $PackageName cat $RemoteAbsolutePath > `"$escapedLocalPath`""
  cmd.exe /c $command | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to pull $RemoteAbsolutePath from $PackageName"
  }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$analyzerPath = Join-Path $scriptRoot 'analyze_frame_log.ps1'
if (-not (Test-Path $analyzerPath)) {
  throw "Analyzer script not found: $analyzerPath"
}

$localPath = $null
if ($UseExistingFile) {
  $resolvedExistingPath = Resolve-Path $UseExistingFile
  $localPath = $resolvedExistingPath.Path
  Write-Host "Using existing frame log: $localPath"
}
else {
  $targetDir = Join-Path $scriptRoot "../$OutputDir"
  New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

  $remoteAppDataDir = Get-RemoteAppDataDir
  $remoteFileName = Get-RemoteFileName
  $remoteAbsolutePath = "$remoteAppDataDir/cache/$remoteFileName"
  $localPath = Join-Path $targetDir $remoteFileName

  Write-Host "Pulling frame log from device: $remoteAbsolutePath"
  Pull-RemoteFile -RemoteAbsolutePath $remoteAbsolutePath -LocalPath $localPath
  Write-Host "Saved frame log to: $localPath"
}

$analysisArgs = @(
  '-ExecutionPolicy', 'Bypass',
  '-File', $analyzerPath,
  '-Path', $localPath,
  '-WarmupSkip', "$WarmupSkip",
  '-ChunkSize', "$ChunkSize",
  '-TopCount', "$TopCount"
)

if ($RecentWindow -gt 0) {
  $analysisArgs += @('-RecentWindow', "$RecentWindow")
}

if ($AsJson) {
  $analysisArgs += '-AsJson'
}

Write-Host 'Running frame log analysis ...'
& powershell.exe @analysisArgs
if ($LASTEXITCODE -ne 0) {
  throw 'Frame log analysis failed.'
}
