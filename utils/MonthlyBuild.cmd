@echo off
REM ===========================================================================
REM  MonthlyBuild.cmd  --  full monthly TR4W release.
REM
REM  A thin wrapper around tr4w\build\Invoke-Release.ps1 so you don't have to
REM  remember the PowerShell syntax.  The monthly build is the SUPERSET of an
REM  interim tag: it refreshes CTY.DAT + TRMASTER.DTA, bumps Version.pas
REM  (number + date), builds locally, commits, pushes master, and tags
REM  v<version>-all (all 8 languages), which triggers the CI installer build.
REM
REM  Usage:
REM     utils\MonthlyBuild.cmd 4.148.0               full monthly release
REM     utils\MonthlyBuild.cmd 4.148.0 -DryRun       rehearse: do everything
REM                                                  locally but do NOT commit,
REM                                                  push, or tag
REM     utils\MonthlyBuild.cmd 4.148.0 -EnglishOnly  tag v<version> (ENG only)
REM     utils\MonthlyBuild.cmd 4.148.0 -SkipCty -SkipTrmaster
REM                                                  no data refresh (the
REM                                                  interim subset, but via the
REM                                                  script with a local build)
REM
REM  For a plain interim CI tag (no data refresh, no rebuild), prefer
REM  utils\TagIt.cmd <version> instead.
REM
REM  Works from any clone location and any current directory: Invoke-Release.ps1
REM  derives the repo root from its own path.
REM ===========================================================================
powershell.exe -ExecutionPolicy Bypass -File "%~dp0..\tr4w\build\Invoke-Release.ps1" %*
