<#
.SYNOPSIS
   Shared VirusTotal scan logic -- the SINGLE source of truth used by BOTH the
   CI release pipeline (.github/workflows/release.yml) and the local build
   pre-flight (tr4w/FullBuild.ps1). There is no second VT implementation.

.DESCRIPTION
   Two ways to use this file:

   1. DOT-SOURCE it (`. .\Invoke-VirusTotalScan.ps1`) to load the functions
      without running anything. FullBuild.ps1 does this for its informational
      local pre-flight: it calls Invoke-VirusTotalScan + ConvertTo-VtResult and
      prints verdicts, never failing the build.

   2. RUN it directly with -InstallerDir / -ReportPath to perform the CI
      authoritative scan: scan every installer in the directory, write a
      Markdown report, and exit non-zero if any installer meets/exceeds
      -Threshold malicious detections.

   The multipart upload uses curl.exe (ships with Windows 10 1803+), NOT
   Invoke-RestMethod -Form. That keeps the script identical under Windows
   PowerShell 5.1 (both FullBuild's local pre-flight and the CI step run under
   powershell.exe) and PowerShell 7 -- no -Form / no pwsh-7 dependency.

   The VirusTotal API key is read from the VT_API_KEY environment variable in
   CI mode (mapped from secrets.VIRUS_TOTAL_API_KEY); FullBuild passes its key
   to Invoke-VirusTotalScan explicitly.

.PARAMETER InstallerDir
   CI mode: directory (searched recursively) for tr4w_setup_*.exe to scan.
.PARAMETER ReportPath
   CI mode: path to write the Markdown report to (overwritten if it exists).
.PARAMETER Threshold
   Malicious-engine detections at or above which a file is BLOCKED (CI fails).
.PARAMETER RefName
   Git ref name for the report header. Informational only.
.PARAMETER CommitSha
   Full commit SHA for the report header; truncated to 7 chars. Informational.
.PARAMETER SelfTest
   Run the network-free logic against built-in sample data and assert
   invariants. No API key or network required.
#>
[CmdletBinding()]
param(
   [string]$InstallerDir,
   [string]$ReportPath,
   [int]$Threshold = 8,
   [string]$RefName = '',
   [string]$CommitSha = '',
   [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'

# VirusTotal API v3 endpoints + the 32 MiB large-file upload boundary.
$script:VtFilesUrl       = 'https://www.virustotal.com/api/v3/files'
$script:VtUploadUrlUrl   = 'https://www.virustotal.com/api/v3/files/upload_url'
$script:VtAnalysesUrl    = 'https://www.virustotal.com/api/v3/analyses'
$script:VtGuiFileUrl     = 'https://www.virustotal.com/gui/file'
$script:VtLargeFileBytes = 33554432

# ---------------------------------------------------------------------------
# Network primitive -- upload one file and poll for the analysis result.
# Returns the parsed analysis response object, or $null on upload/poll
# failure (callers decide whether that is fatal). Uses curl.exe so it runs
# unchanged on PowerShell 5.1 and 7.
# ---------------------------------------------------------------------------
function Invoke-VirusTotalScan {
   param(
      [Parameter(Mandatory = $true)][string]$FilePath,
      [Parameter(Mandatory = $true)][string]$ApiKey
   )

   $filesize  = (Get-Item -LiteralPath $FilePath).Length
   $uploadUrl = $script:VtFilesUrl

   # Files >32MB need a one-shot large-file upload URL.
   if ($filesize -gt $script:VtLargeFileBytes) {
      try {
         $ulResp = Invoke-RestMethod -Uri $script:VtUploadUrlUrl -Method Get -Headers @{ 'x-apikey' = $ApiKey }
         $uploadUrl = $ulResp.data
      }
      catch {
         Write-Host "    Failed to get large-file upload URL: $_" -ForegroundColor Red
         return $null
      }
   }

   $curlOut = & curl.exe --silent --request POST `
                         --url $uploadUrl `
                         --header "x-apikey: $ApiKey" `
                         --form "file=@$FilePath"
   if ($LASTEXITCODE -ne 0) {
      Write-Host "    curl upload failed (exit $LASTEXITCODE)" -ForegroundColor Red
      return $null
   }
   try {
      $upResp = $curlOut | ConvertFrom-Json
   }
   catch {
      Write-Host "    Upload response not JSON: $curlOut" -ForegroundColor Red
      return $null
   }
   $analysisId = $upResp.data.id
   if (-not $analysisId) {
      Write-Host "    No analysis id in upload response" -ForegroundColor Red
      return $null
   }

   # Poll /analyses/{id} every 15s up to 10 minutes total.
   for ($i = 1; $i -le 40; $i++) {
      Start-Sleep -Seconds 15
      try {
         $poll = Invoke-RestMethod -Uri "$($script:VtAnalysesUrl)/$analysisId" -Method Get -Headers @{ 'x-apikey' = $ApiKey }
      }
      catch {
         Write-Host "    Poll $i/40 error: $_" -ForegroundColor DarkYellow
         continue
      }
      if ($poll.data.attributes.status -eq 'completed') {
         return $poll
      }
      Write-Host "    Poll $i/40: status=$($poll.data.attributes.status)" -ForegroundColor DarkGray
   }
   Write-Host "    Poll timed out after 10 minutes" -ForegroundColor Red
   return $null
}

# ---------------------------------------------------------------------------
# Pure (network-free) helpers -- shared verdict + result shaping + report.
# ---------------------------------------------------------------------------

# Single definition of the threshold verdict, used by both callers.
function Get-VtVerdict {
   param([int]$Malicious, [int]$Suspicious, [int]$Threshold)

   if ($Malicious -ge $Threshold) { return 'BLOCKED' }
   if ($Malicious -gt 0 -or $Suspicious -gt 0) { return 'WARN' }
   return 'CLEAN'
}

# Shape a completed VT analysis response into a flat result record (used by
# the CI report AND FullBuild's console pre-flight, so stats parsing lives in
# exactly one place).
function ConvertTo-VtResult {
   param([string]$FileName, $Analysis, [int]$Threshold)

   $stats     = $Analysis.data.attributes.stats
   $malicious = [int]$stats.malicious
   $suspicious= [int]$stats.suspicious
   $undetected= [int]$stats.undetected
   $harmless  = [int]$stats.harmless
   $failure   = [int]$stats.failure
   $sha       = [string]$Analysis.meta.file_info.sha256

   $details = @()
   if ($malicious -gt 0 -or $suspicious -gt 0) {
      $details = @(
         foreach ($engine in $Analysis.data.attributes.results.PSObject.Properties) {
            if ($engine.Value.category -in @('malicious', 'suspicious')) {
               [pscustomobject]@{
                  Engine   = $engine.Name
                  Category = $engine.Value.category
                  Result   = $engine.Value.result
               }
            }
         }
      )
   }

   [pscustomobject]@{
      File       = $FileName
      Status     = 'OK'
      Malicious  = $malicious
      Suspicious = $suspicious
      Undetected = $undetected
      Harmless   = $harmless
      Total      = $malicious + $suspicious + $undetected + $harmless + $failure
      Sha        = $sha
      Permalink  = "$($script:VtGuiFileUrl)/$sha"
      Details    = $details
      Verdict    = Get-VtVerdict -Malicious $malicious -Suspicious $suspicious -Threshold $Threshold
   }
}

function Get-VtFailure {
   param([object[]]$Results, [int]$Threshold)

   @(
      foreach ($r in $Results) {
         if ($r.Status -ne 'OK') {
            "$($r.File) (scan incomplete)"
         }
         elseif ($r.Verdict -eq 'BLOCKED') {
            "$($r.File) ($($r.Malicious) malicious detections >= threshold $Threshold)"
         }
      }
   )
}

function New-VtMarkdownReport {
   param(
      [object[]]$Results,
      [int]$Threshold,
      [string]$RefName,
      [string]$ShortSha,
      [string]$ScanDate
   )

   $md = [System.Collections.Generic.List[string]]::new()
   $md.Add('# VirusTotal Scan Report')
   $md.Add('')
   $md.Add("**Build**: $RefName | **Date**: $ScanDate | **Commit**: $ShortSha")
   $md.Add("**Detection threshold**: $Threshold malicious engines")
   $md.Add('')
   $md.Add('## Results Summary')
   $md.Add('')
   $md.Add('| File | Malicious | Suspicious | Clean | Total | Result | Link |')
   $md.Add('|------|-----------|------------|-------|-------|--------|------|')
   foreach ($r in $Results) {
      if ($r.Status -ne 'OK') {
         $md.Add("| $($r.File) | - | - | - | - | SCAN INCOMPLETE | - |")
      }
      elseif ($r.Verdict -eq 'BLOCKED') {
         $md.Add("| $($r.File) | **$($r.Malicious)** | $($r.Suspicious) | $($r.Undetected) | $($r.Total) | BLOCKED | [View]($($r.Permalink)) |")
      }
      elseif ($r.Verdict -eq 'WARN') {
         $md.Add("| $($r.File) | $($r.Malicious) | $($r.Suspicious) | $($r.Undetected) | $($r.Total) | WARN (below threshold) | [View]($($r.Permalink)) |")
      }
      else {
         $clean = $r.Undetected + $r.Harmless
         $md.Add("| $($r.File) | $($r.Malicious) | $($r.Suspicious) | $clean | $($r.Total) | CLEAN | [View]($($r.Permalink)) |")
      }
   }

   if ($Results | Where-Object { $_.Details.Count -gt 0 }) {
      $md.Add('')
      $md.Add('## Detection Details')
      $md.Add('')
      foreach ($r in $Results) {
         if ($r.Details.Count -gt 0) {
            $md.Add("### $($r.File)")
            $md.Add('')
            $md.Add('| Engine | Category | Detection |')
            $md.Add('|--------|----------|-----------|')
            foreach ($d in $r.Details) {
               $md.Add("| $($d.Engine) | $($d.Category) | $($d.Result) |")
            }
            $md.Add('')
         }
      }
   }

   $md.Add('')
   $md.Add('## File Hashes (SHA-256)')
   $md.Add('')
   $md.Add('```')
   foreach ($r in $Results) {
      if ($r.Sha) {
         $md.Add("$($r.Sha)  $($r.File)")
      }
   }
   $md.Add('```')
   $md.Add('')
   $md.Add('---')
   $md.Add("*Scanned by [VirusTotal](https://www.virustotal.com) via GitHub Actions | Threshold: $Threshold malicious detections*")

   return ($md -join "`n")
}

# ---------------------------------------------------------------------------
# Self-test: exercise the network-free logic against built-in sample data.
# ---------------------------------------------------------------------------
function Invoke-SelfTest {
   Write-Host '=== SELF-TEST: Get-VtVerdict / ConvertTo-VtResult / Get-VtFailure / New-VtMarkdownReport ==='

   # Sample VT analysis shaped like the real TR4W case (a handful of heuristic
   # detections on an unsigned, packed PE).
   $sample = [pscustomobject]@{
      data = [pscustomobject]@{
         attributes = [pscustomobject]@{
            status = 'completed'
            stats  = [pscustomobject]@{ malicious = 7; suspicious = 1; undetected = 60; harmless = 0; failure = 2 }
            results = [pscustomobject]@{
               'DrWeb'   = [pscustomobject]@{ category = 'malicious';  result = 'Tool.VulnDriver.32' }
               'Wacatac' = [pscustomobject]@{ category = 'malicious';  result = 'Wacatac.B!ml' }
               'VBA32'   = [pscustomobject]@{ category = 'suspicious'; result = 'BScope.Trojan' }
               'CleanAV' = [pscustomobject]@{ category = 'undetected'; result = $null }
            }
         }
      }
      meta = [pscustomobject]@{ file_info = [pscustomobject]@{ sha256 = 'abc123def456' } }
   }

   $errors = @()

   # Verdict boundaries.
   if ((Get-VtVerdict -Malicious 7 -Suspicious 0 -Threshold 8) -ne 'WARN')    { $errors += 'verdict 7<8 should be WARN' }
   if ((Get-VtVerdict -Malicious 8 -Suspicious 0 -Threshold 8) -ne 'BLOCKED') { $errors += 'verdict 8>=8 should be BLOCKED' }
   if ((Get-VtVerdict -Malicious 0 -Suspicious 0 -Threshold 8) -ne 'CLEAN')   { $errors += 'verdict 0/0 should be CLEAN' }

   $blocked = ConvertTo-VtResult -FileName 'tr4w_setup_eng.exe' -Analysis $sample -Threshold 7
   if ($blocked.Malicious -ne 7)        { $errors += "expected Malicious=7, got $($blocked.Malicious)" }
   if ($blocked.Total -ne 70)           { $errors += "expected Total=70, got $($blocked.Total)" }
   if ($blocked.Details.Count -ne 3)    { $errors += "expected 3 detail rows, got $($blocked.Details.Count)" }
   if ($blocked.Verdict -ne 'BLOCKED')  { $errors += "expected BLOCKED at threshold 7, got $($blocked.Verdict)" }
   if ($blocked.Sha -ne 'abc123def456') { $errors += "sha mismatch: $($blocked.Sha)" }

   $warn = ConvertTo-VtResult -FileName 'tr4w_setup_rus.exe' -Analysis $sample -Threshold 8
   if ($warn.Verdict -ne 'WARN')        { $errors += "expected WARN at threshold 8, got $($warn.Verdict)" }

   $incomplete = [pscustomobject]@{
      File = 'tr4w_setup_ger.exe'; Status = 'SCAN_INCOMPLETE'; Malicious = 0; Suspicious = 0
      Undetected = 0; Harmless = 0; Total = 0; Sha = ''; Permalink = ''; Details = @(); Verdict = 'CLEAN'
   }

   $results = @($warn, $incomplete)
   $failuresAt8 = Get-VtFailure -Results $results -Threshold 8
   if ($failuresAt8.Count -ne 1)        { $errors += "threshold 8: expected 1 failure (incomplete only), got $($failuresAt8.Count)" }

   $report = New-VtMarkdownReport -Results @($warn, $incomplete) -Threshold 8 -RefName 'v4.147.22' -ShortSha 'deadbee' -ScanDate '2026-05-29 12:00 UTC'
   if ($report -notmatch 'WARN \(below threshold\)') { $errors += 'report missing WARN row' }
   if ($report -notmatch 'SCAN INCOMPLETE')          { $errors += 'report missing SCAN INCOMPLETE row' }
   if ($report -notmatch 'Tool\.VulnDriver\.32')     { $errors += 'report missing detection detail' }

   Write-Host ''
   Write-Host '--- Sample report ---'
   Write-Host $report
   Write-Host ''

   if ($errors.Count -gt 0) {
      Write-Host 'SELF-TEST FAILED:'
      $errors | ForEach-Object { Write-Host "  - $_" }
      exit 1
   }
   Write-Host 'SELF-TEST PASSED.'
}

# ---------------------------------------------------------------------------
# Entry point. When dot-sourced (FullBuild loading the functions), do nothing.
# ---------------------------------------------------------------------------
if ($MyInvocation.InvocationName -eq '.') {
   return
}

if ($SelfTest) {
   Invoke-SelfTest
   return
}

# --- CI authoritative scan ---
if ([string]::IsNullOrWhiteSpace($InstallerDir) -or [string]::IsNullOrWhiteSpace($ReportPath)) {
   throw 'InstallerDir and ReportPath are required unless -SelfTest is specified.'
}

$apiKey = $env:VT_API_KEY
if ([string]::IsNullOrWhiteSpace($apiKey)) {
   Write-Error 'VT_API_KEY environment variable is empty -- cannot scan.'
   exit 1
}

$scanFiles = @(Get-ChildItem -LiteralPath $InstallerDir -Recurse -Filter 'tr4w_setup_*.exe' -File -ErrorAction SilentlyContinue)
if ($scanFiles.Count -eq 0) {
   Write-Error "No installers (tr4w_setup_*.exe) found under '$InstallerDir'."
   exit 1
}
Write-Host "Found $($scanFiles.Count) installer(s) to scan:"
$scanFiles | ForEach-Object { Write-Host "  $($_.FullName)" }

$results = @(
   foreach ($file in $scanFiles) {
      Write-Host ''
      Write-Host "Scanning: $($file.Name)"
      $analysis = Invoke-VirusTotalScan -FilePath $file.FullName -ApiKey $apiKey
      if ($null -eq $analysis) {
         Write-Host '  Result: SCAN INCOMPLETE (upload or poll failed)'
         [pscustomobject]@{
            File = $file.Name; Status = 'SCAN_INCOMPLETE'; Malicious = 0; Suspicious = 0
            Undetected = 0; Harmless = 0; Total = 0; Sha = ''; Permalink = ''; Details = @(); Verdict = 'CLEAN'
         }
      }
      else {
         $r = ConvertTo-VtResult -FileName $file.Name -Analysis $analysis -Threshold $Threshold
         Write-Host "  Result: $($r.Verdict) -- $($r.Malicious) malicious / $($r.Suspicious) suspicious of $($r.Total) engines"
         $r
      }
   }
)

$failures = Get-VtFailure -Results $results -Threshold $Threshold

$scanDate = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm') + ' UTC'
$shortSha = if ($CommitSha.Length -ge 7) { $CommitSha.Substring(0, 7) } else { $CommitSha }
$report   = New-VtMarkdownReport -Results $results -Threshold $Threshold -RefName $RefName -ShortSha $shortSha -ScanDate $scanDate

# Write UTF-8 WITHOUT a BOM so the Markdown renders cleanly on the release
# page. Windows PowerShell 5.1's `Set-Content -Encoding utf8` would add a BOM,
# so write via .NET with a BOM-less UTF8Encoding. Resolve the (possibly
# relative) path against PowerShell's current location -- [IO.File] uses the
# process working dir, which is not kept in sync with Get-Location.
$reportFull = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ReportPath)
[System.IO.File]::WriteAllText($reportFull, $report, (New-Object System.Text.UTF8Encoding($false)))
Write-Host ''
Write-Host '=== Scan Report ==='
Write-Host $report

if ($failures.Count -gt 0) {
   Write-Host ''
   Write-Host 'SCAN FAILED -- release will be blocked:'
   $failures | ForEach-Object { Write-Host "  $_" }
   exit 1
}
Write-Host ''
Write-Host "All installer(s) passed VirusTotal scan (threshold: $Threshold)"
