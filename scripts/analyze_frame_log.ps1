param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path,
  [int]$RecentWindow = 0,
  [int]$WarmupSkip = 30,
  [int]$ChunkSize = 60,
  [int]$TopCount = 10,
  [switch]$AsJson
)

$ErrorActionPreference = 'Stop'

function Get-Mean {
  param([double[]]$Values)

  if (-not $Values -or $Values.Count -eq 0) {
    return 0.0
  }

  $sum = 0.0
  foreach ($value in $Values) {
    $sum += $value
  }

  return $sum / $Values.Count
}

function Get-Percentile {
  param(
    [double[]]$Values,
    [double]$Percent
  )

  if (-not $Values -or $Values.Count -eq 0) {
    return $null
  }

  $sorted = @($Values | Sort-Object)
  if ($sorted.Count -eq 1) {
    return $sorted[0]
  }

  $position = ($sorted.Count - 1) * $Percent
  $lowerIndex = [Math]::Floor($position)
  $upperIndex = [Math]::Ceiling($position)
  if ($lowerIndex -eq $upperIndex) {
    return $sorted[$lowerIndex]
  }

  $lowerWeight = $upperIndex - $position
  $upperWeight = $position - $lowerIndex
  return ($sorted[$lowerIndex] * $lowerWeight) + ($sorted[$upperIndex] * $upperWeight)
}

function Get-Ratio {
  param(
    [int]$Count,
    [int]$Total
  )

  if ($Total -le 0) {
    return 0.0
  }

  return $Count / $Total
}

function ConvertTo-Milliseconds {
  param([object]$Microseconds)

  if ($null -eq $Microseconds) {
    return $null
  }

  return [double]$Microseconds / 1000.0
}

function Format-Number {
  param(
    [object]$Value,
    [int]$Digits = 3
  )

  if ($null -eq $Value) {
    return $null
  }

  return [Math]::Round([double]$Value, $Digits)
}

function Get-StatsSummary {
  param([double[]]$Values)

  if (-not $Values -or $Values.Count -eq 0) {
    return [pscustomobject]@{
      mean = $null
      p50 = $null
      p90 = $null
      p95 = $null
      p99 = $null
      max = $null
    }
  }

  return [pscustomobject]@{
    mean = Format-Number (Get-Mean $Values)
    p50 = Format-Number (Get-Percentile $Values 0.50)
    p90 = Format-Number (Get-Percentile $Values 0.90)
    p95 = Format-Number (Get-Percentile $Values 0.95)
    p99 = Format-Number (Get-Percentile $Values 0.99)
    max = Format-Number (($Values | Measure-Object -Maximum).Maximum)
  }
}

function Get-FrameSummary {
  param([object]$Record)

  return [pscustomobject]@{
    frameIndex = [int]$Record.frameIndex
    actualIntervalMs = Format-Number (ConvertTo-Milliseconds $Record.actualIntervalUs)
    deltaMs = Format-Number (ConvertTo-Milliseconds $Record.intervalDeltaUs)
    buildMs = Format-Number (ConvertTo-Milliseconds $Record.buildUs)
    rasterMs = Format-Number (ConvertTo-Milliseconds $Record.rasterUs)
    totalMs = Format-Number (ConvertTo-Milliseconds $Record.totalUs)
    isOverBudget = [bool]$Record.isOverBudget
    isVsyncMiss = [bool]$Record.isVsyncMiss
  }
}

function Get-WindowSummary {
  param(
    [object[]]$Records,
    [double]$BudgetMs,
    [string]$Name
  )

  $actualIntervals = New-Object System.Collections.Generic.List[double]
  $buildMsValues = New-Object System.Collections.Generic.List[double]
  $rasterMsValues = New-Object System.Collections.Generic.List[double]
  $totalMsValues = New-Object System.Collections.Generic.List[double]

  $overBudgetCount = 0
  $vsyncMissCount = 0
  $buildOverBudgetCount = 0
  $rasterOverBudgetCount = 0
  $bothOverBudgetCount = 0
  $rasterDominantCount = 0
  $maxConsecutiveVsyncMiss = 0
  $currentVsyncMissStreak = 0

  foreach ($record in $Records) {
    $buildMs = ConvertTo-Milliseconds $record.buildUs
    $rasterMs = ConvertTo-Milliseconds $record.rasterUs
    $totalMs = ConvertTo-Milliseconds $record.totalUs

    if ($null -ne $record.actualIntervalUs) {
      [void]$actualIntervals.Add((ConvertTo-Milliseconds $record.actualIntervalUs))
    }
    [void]$buildMsValues.Add($buildMs)
    [void]$rasterMsValues.Add($rasterMs)
    [void]$totalMsValues.Add($totalMs)

    if ([bool]$record.isOverBudget) {
      $overBudgetCount++
    }
    if ([bool]$record.isVsyncMiss) {
      $vsyncMissCount++
      $currentVsyncMissStreak++
      if ($currentVsyncMissStreak -gt $maxConsecutiveVsyncMiss) {
        $maxConsecutiveVsyncMiss = $currentVsyncMissStreak
      }
    }
    else {
      $currentVsyncMissStreak = 0
    }

    if ($buildMs -gt $BudgetMs) {
      $buildOverBudgetCount++
    }
    if ($rasterMs -gt $BudgetMs) {
      $rasterOverBudgetCount++
    }
    if ($buildMs -gt $BudgetMs -and $rasterMs -gt $BudgetMs) {
      $bothOverBudgetCount++
    }
    if ($rasterMs -gt $buildMs) {
      $rasterDominantCount++
    }
  }

  $averageIntervalMs = Get-Mean $actualIntervals.ToArray()
  $estimatedFps = if ($averageIntervalMs -le 0) { 0.0 } else { 1000.0 / $averageIntervalMs }

  return [pscustomobject]@{
    name = $Name
    count = $Records.Count
    avgFpsEst = Format-Number $estimatedFps
    overBudgetRatio = Format-Number (Get-Ratio $overBudgetCount $Records.Count)
    vsyncMissRatio = Format-Number (Get-Ratio $vsyncMissCount $Records.Count)
    buildOverBudgetRatio = Format-Number (Get-Ratio $buildOverBudgetCount $Records.Count)
    rasterOverBudgetRatio = Format-Number (Get-Ratio $rasterOverBudgetCount $Records.Count)
    bothOverBudgetRatio = Format-Number (Get-Ratio $bothOverBudgetCount $Records.Count)
    rasterDominantRatio = Format-Number (Get-Ratio $rasterDominantCount $Records.Count)
    maxConsecutiveVsyncMiss = $maxConsecutiveVsyncMiss
    interval = Get-StatsSummary $actualIntervals.ToArray()
    build = Get-StatsSummary $buildMsValues.ToArray()
    raster = Get-StatsSummary $rasterMsValues.ToArray()
    total = Get-StatsSummary $totalMsValues.ToArray()
  }
}

function Get-VsyncMissStreaks {
  param([object[]]$Records)

  $streaks = New-Object System.Collections.Generic.List[object]
  $current = New-Object System.Collections.Generic.List[object]

  foreach ($record in $Records) {
    if ([bool]$record.isVsyncMiss) {
      [void]$current.Add($record)
      continue
    }

    if ($current.Count -gt 0) {
      $streaks.Add(@($current.ToArray()))
      $current = New-Object System.Collections.Generic.List[object]
    }
  }

  if ($current.Count -gt 0) {
    $streaks.Add(@($current.ToArray()))
  }

  return @($streaks.ToArray())
}

function Get-StreakSummary {
  param([object[]]$Streak)

  $intervals = @($Streak | ForEach-Object { ConvertTo-Milliseconds $_.actualIntervalUs })
  $buildValues = @($Streak | ForEach-Object { ConvertTo-Milliseconds $_.buildUs })
  $rasterValues = @($Streak | ForEach-Object { ConvertTo-Milliseconds $_.rasterUs })

  return [pscustomobject]@{
    length = $Streak.Count
    startFrame = [int]$Streak[0].frameIndex
    endFrame = [int]$Streak[$Streak.Count - 1].frameIndex
    maxIntervalMs = Format-Number (($intervals | Measure-Object -Maximum).Maximum)
    avgIntervalMs = Format-Number (Get-Mean $intervals)
    avgBuildMs = Format-Number (Get-Mean $buildValues)
    avgRasterMs = Format-Number (Get-Mean $rasterValues)
  }
}

function Get-ChunkSummaries {
  param(
    [object[]]$Records,
    [int]$ChunkSize,
    [double]$BudgetMs
  )

  $chunks = New-Object System.Collections.Generic.List[object]
  for ($index = 0; $index -lt $Records.Count; $index += $ChunkSize) {
    $endIndex = [Math]::Min($index + $ChunkSize - 1, $Records.Count - 1)
    $slice = @($Records[$index..$endIndex])
    $summary = Get-WindowSummary -Records $slice -BudgetMs $BudgetMs -Name "$($slice[0].frameIndex)-$($slice[$slice.Count - 1].frameIndex)"
    $chunks.Add([pscustomobject]@{
      frames = $summary.name
      avgFpsEst = $summary.avgFpsEst
      vsyncMissRatio = $summary.vsyncMissRatio
      avgBuildMs = $summary.build.mean
      avgRasterMs = $summary.raster.mean
      avgIntervalMs = $summary.interval.mean
      overBudgetRatio = $summary.overBudgetRatio
    })
  }

  return @($chunks.ToArray())
}

function Write-Section {
  param([string]$Title)

  Write-Host ""
  Write-Host $Title
  Write-Host ('-' * $Title.Length)
}

$resolvedPath = Resolve-Path $Path
$file = Get-Item $resolvedPath
$log = Get-Content $resolvedPath -Raw | ConvertFrom-Json

$records = @($log.records)
if (-not $records -or $records.Count -eq 0) {
  throw "No records found in $resolvedPath"
}

$snapshotSampleCount = 0
if ($null -ne $log.snapshot -and $null -ne $log.snapshot.sampleCount) {
  $snapshotSampleCount = [int]$log.snapshot.sampleCount
}

$effectiveRecentWindow = if ($RecentWindow -gt 0) {
  $RecentWindow
}
elseif ($snapshotSampleCount -gt 0) {
  $snapshotSampleCount
}
else {
  [Math]::Min(240, $records.Count)
}

$effectiveRecentWindow = [Math]::Min($effectiveRecentWindow, $records.Count)
$budgetMs = [double]$log.frameBudgetMs
$recentRecords = @($records | Select-Object -Last $effectiveRecentWindow)
$postWarmupRecords = if ($WarmupSkip -ge $records.Count) { @() } else { @($records | Select-Object -Skip $WarmupSkip) }

$allSummary = Get-WindowSummary -Records $records -BudgetMs $budgetMs -Name 'all'
$recentSummary = Get-WindowSummary -Records $recentRecords -BudgetMs $budgetMs -Name "last$effectiveRecentWindow"
$postWarmupSummary = if ($postWarmupRecords.Count -gt 0) {
  Get-WindowSummary -Records $postWarmupRecords -BudgetMs $budgetMs -Name "skip$WarmupSkip"
}
else {
  $null
}

$topTotalFrames = @($records |
  Sort-Object -Property @{ Expression = { [int]$_.totalUs }; Descending = $true } |
  Select-Object -First $TopCount |
  ForEach-Object { Get-FrameSummary $_ })

$topIntervalFrames = @($records |
  Where-Object { $null -ne $_.actualIntervalUs } |
  Sort-Object -Property @{ Expression = { [int]$_.actualIntervalUs }; Descending = $true } |
  Select-Object -First $TopCount |
  ForEach-Object { Get-FrameSummary $_ })

$topIntervalFramesAfterWarmup = if ($postWarmupRecords.Count -gt 0) {
  @($postWarmupRecords |
    Where-Object { $null -ne $_.actualIntervalUs } |
    Sort-Object -Property @{ Expression = { [int]$_.actualIntervalUs }; Descending = $true } |
    Select-Object -First $TopCount |
    ForEach-Object { Get-FrameSummary $_ })
}
else {
  @()
}

$streaks = @(
  Get-VsyncMissStreaks $records |
    Sort-Object -Property @{ Expression = { $_.Count }; Descending = $true } |
    Select-Object -First $TopCount |
    ForEach-Object { Get-StreakSummary $_ }
)

$chunkSummaries = Get-ChunkSummaries -Records $records -ChunkSize $ChunkSize -BudgetMs $budgetMs

$result = [pscustomobject]@{
  file = [pscustomobject]@{
    path = $file.FullName
    lastWriteTime = $file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')
    sizeBytes = $file.Length
  }
  metadata = [pscustomobject]@{
    schemaVersion = $log.schemaVersion
    logType = $log.logType
    generatedAt = $log.generatedAt
    targetRefreshRateHz = $log.targetRefreshRateHz
    frameBudgetMs = Format-Number $budgetMs 3
    scenario = $log.scenario
    recordCount = $records.Count
    maxRecords = $log.maxRecords
    scenarioSettings = $log.scenarioSettings
  }
  snapshot = $log.snapshot
  calculated = [pscustomobject]@{
    recentWindow = $effectiveRecentWindow
    warmupSkip = $WarmupSkip
    all = $allSummary
    recent = $recentSummary
    postWarmup = $postWarmupSummary
  }
  topFrames = [pscustomobject]@{
    byTotalMs = $topTotalFrames
    byIntervalMs = $topIntervalFrames
    byIntervalMsAfterWarmup = $topIntervalFramesAfterWarmup
  }
  vsyncMissStreaks = $streaks
  chunks = $chunkSummaries
}

if ($AsJson) {
  $result | ConvertTo-Json -Depth 10
  return
}

Write-Section 'File'
$result.file | Format-List | Out-String | Write-Host

Write-Section 'Metadata'
$result.metadata | Format-List | Out-String | Write-Host

if ($null -ne $result.snapshot) {
  Write-Section 'Snapshot'
  $result.snapshot | Format-List | Out-String | Write-Host
}

Write-Section 'Calculated Windows'
@($result.calculated.all, $result.calculated.recent, $result.calculated.postWarmup) |
  Where-Object { $null -ne $_ } |
  Select-Object -Property @(
    'name',
    'count',
    'avgFpsEst',
    'overBudgetRatio',
    'vsyncMissRatio',
    'buildOverBudgetRatio',
    'rasterOverBudgetRatio',
    'bothOverBudgetRatio',
    'rasterDominantRatio',
    'maxConsecutiveVsyncMiss'
  ) |
  Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Percentiles (ms)'
@($result.calculated.all, $result.calculated.recent, $result.calculated.postWarmup) |
  Where-Object { $null -ne $_ } |
  ForEach-Object {
    [pscustomobject]@{
      name = $_.name
      intervalP50 = $_.interval.p50
      intervalP90 = $_.interval.p90
      intervalP95 = $_.interval.p95
      buildP50 = $_.build.p50
      buildP95 = $_.build.p95
      rasterP50 = $_.raster.p50
      rasterP95 = $_.raster.p95
      totalP50 = $_.total.p50
      totalP95 = $_.total.p95
    }
  } | Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Top Frames By Total'
$result.topFrames.byTotalMs | Format-Table -AutoSize | Out-String | Write-Host

Write-Section 'Top Frames By Interval'
$result.topFrames.byIntervalMs | Format-Table -AutoSize | Out-String | Write-Host

if ($result.topFrames.byIntervalMsAfterWarmup.Count -gt 0) {
  Write-Section "Top Frames By Interval After Warmup (skip $WarmupSkip)"
  $result.topFrames.byIntervalMsAfterWarmup | Format-Table -AutoSize | Out-String | Write-Host
}

if ($result.vsyncMissStreaks.Count -gt 0) {
  Write-Section 'Longest Vsync-Miss Streaks'
  $result.vsyncMissStreaks | Format-Table -AutoSize | Out-String | Write-Host
}

Write-Section "Trend By $ChunkSize Frames"
$result.chunks | Format-Table -AutoSize | Out-String | Write-Host

if ($allSummary.overBudgetRatio -eq 1.0) {
  Write-Host 'Note: isOverBudget uses FrameTiming.totalSpan > frameBudget; compare vsyncMissRatio for visible frame pacing misses.'
}
