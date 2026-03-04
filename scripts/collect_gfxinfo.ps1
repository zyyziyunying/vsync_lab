param(
  [string]$PackageName = 'com.harrypet.vsync_lab',
  [string]$OutputDir = 'artifacts/gfxinfo',
  [switch]$ClearBeforeCollect
)

$ErrorActionPreference = 'Stop'

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$targetDir = Join-Path $PSScriptRoot "../$OutputDir"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

if ($ClearBeforeCollect) {
  Write-Host "Clearing existing gfxinfo stats for $PackageName ..."
  adb shell dumpsys gfxinfo $PackageName reset | Out-Null
}

$deviceInfoPath = Join-Path $targetDir "device_$timestamp.txt"
$gfxInfoPath = Join-Path $targetDir "gfxinfo_$timestamp.txt"

Write-Host 'Collecting device model and refresh info ...'
adb shell getprop ro.product.model | Out-File -FilePath $deviceInfoPath -Encoding utf8
adb shell dumpsys display | Out-File -FilePath $deviceInfoPath -Append -Encoding utf8

Write-Host "Collecting gfxinfo for package: $PackageName"
adb shell dumpsys gfxinfo $PackageName framestats | Out-File -FilePath $gfxInfoPath -Encoding utf8

Write-Host "Saved files:"
Write-Host "- $deviceInfoPath"
Write-Host "- $gfxInfoPath"
