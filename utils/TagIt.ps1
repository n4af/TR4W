param([Parameter(Mandatory)][string]$Tag)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent          # ..\ from utils\

git -C $repo pull --ff-only origin master
if ($LASTEXITCODE -ne 0) { throw "Local master is not fast-forwardable to origin/master. Resolve before tagging." }

# Mirror the CI guard in .github/workflows/release.yml exactly:
#   strip leading 'v' and trailing '-all', then compare to Version.pas.
$bare    = $Tag -replace '^v','' -replace '-all$',''
$verLine = Select-String -Path "$repo\tr4w\src\Version.pas" -Pattern "TR4W_CURRENTVERSION_NUMBER" | Select-Object -First 1
$version = [regex]::Match($verLine.Line, "'([^']+)'").Groups[1].Value
if ($bare -ne $version) {
   throw "Tag v$bare does not match Version.pas ($version). Bump one or the other before tagging."
}
Write-Host "Tag v$bare matches Version.pas $version - OK"

git -C $repo tag -a "v$Tag" -m "TR4W v$Tag (English)"
git -C $repo push origin "v$Tag"
