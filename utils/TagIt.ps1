param([Parameter(Mandatory)][string]$Tag)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent          # ..\ from utils\

# Guard 1: refuse to tag with an uncommitted Version.pas.  The version guard
# below validates the COMMITTED file (what the tag actually captures), so an
# edit that is on disk but not committed would otherwise sail through and
# produce a tag on the pre-bump commit (CI then fails the tag/Version.pas
# match).  Check this BEFORE the pull so the message is clear.
$dirty = git -C $repo status --porcelain -- tr4w/src/Version.pas
if ($dirty) {
   throw "Version.pas has uncommitted changes. Commit and push your version bump before tagging."
}

git -C $repo pull --ff-only origin master
if ($LASTEXITCODE -ne 0) { throw "Local master is not fast-forwardable to origin/master. Resolve before tagging." }

# Guard 2: refuse to tag if local HEAD is not exactly origin/master.
# 'pull --ff-only' silently succeeds when local is AHEAD of origin, which would
# tag a commit that is not (yet) on the remote branch.  Require them to push
# their commits first so branch and tag agree.
$head   = (git -C $repo rev-parse HEAD).Trim()
$origin = (git -C $repo rev-parse origin/master).Trim()
if ($head -ne $origin) {
   throw "Local HEAD ($head) is not origin/master ($origin). Push your commits before tagging."
}

# Mirror the CI guard in .github/workflows/release.yml exactly:
#   strip leading 'v' and trailing '-all', then compare to Version.pas.
# Read the COMMITTED file via 'git show HEAD:...' -- NOT the working tree -- so
# this validates exactly the Version.pas the tag will capture.
$bare    = $Tag -replace '^v','' -replace '-all$',''
$verLine = git -C $repo show HEAD:tr4w/src/Version.pas | Select-String -Pattern "TR4W_CURRENTVERSION_NUMBER" | Select-Object -First 1
$version = [regex]::Match($verLine.Line, "'([^']+)'").Groups[1].Value
if ($bare -ne $version) {
   throw "Tag v$bare does not match committed Version.pas ($version). Bump one or the other before tagging."
}
Write-Host "Tag v$bare matches committed Version.pas $version - OK"

git -C $repo tag -a "v$Tag" -m "TR4W v$Tag (English)"
git -C $repo push origin "v$Tag"
