# TR4W Build & Release Workflow

End-to-end guide covering: reviewing a PR, building locally, smoke-testing, tagging
for the English CI build, promoting to a full English installer release, and (for
major releases) producing the multi-language installers.

If you only want to compile the source on your dev box and never publish anything,
sections 1-4 are all you need. Section 5 covers the version-bump policy.
Sections 6-8 cover tagging and the GitHub-side release flow.

---

## 0. Audience and assumptions

- You have **write access** to `n4af/TR4W` on GitHub.
- You're on Windows with the toolchain installed (Delphi 7, Indy, NSIS, UPX -- see
  section 1).
- You're working from a clone of the repo (default `C:\TR4W`; Howie uses
  `D:\newsrc\TR4W`; either works).
- You have `gh` (GitHub CLI) authenticated, or you'll use the GitHub web UI for PR
  review and tagging.

---

## 1. Prerequisites (one-time setup)

Install once. Defaults match the assumed locations; if yours differ, see
[section 1a](#1a-non-default-tool-locations).

- [ ] **Delphi 7** -- `C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE`
- [ ] **Indy 10 library** -- **already bundled in `tr4w\include`** (Indy 10.6.3.3).
  No external install required. If you happen to have your own Indy install
  (e.g. `C:\Indy\Indy\Lib\`) and prefer to use it, see
  [section 1a](#1a-non-default-tool-locations).
- [ ] **PowerShell** -- built into Windows; nothing to install
- [ ] **Git** -- used by the build script to read the current branch name for zip
  filenames

For `-BuildInstallers` mode (anything that produces `tr4w_setup_*.exe`):

- [ ] **NSIS** -- `C:\Program Files (x86)\NSIS\makensis.exe`
- [ ] **UPX** -- `upx.exe` discoverable via one of: `PATH`, the `UPX_BIN`
  environment variable (directory containing `upx.exe`), or the `-UpxBin`
  parameter to `FullBuild.ps1`. Any version that supports `--lzma`.
  Download: https://upx.github.io/

Plain `Build.cmd` and `BuildAll.cmd` only need Delphi 7 + Indy.

### 1a. Non-default tool locations

Skip this if you accepted the installer defaults.

The build script reads three environment variables. Set them only if YOUR install
differs from the defaults.

- [ ] `DELPHI7_BIN` -- directory containing `DCC32.EXE`
  (default `C:\Program Files (x86)\Borland\Delphi7\Bin`)
- [ ] `INDY_ROOT` -- Indy `Lib` directory containing `Core`/`System`/`Protocols`.
  **Optional** -- if unset, the script uses the bundled Indy at
  `tr4w\include`. Set this if you want to point at your own external Indy
  install (e.g. `C:\Indy\Indy\Lib`).
- [ ] `NSIS_BIN` -- NSIS directory containing `makensis.exe`
  (default `C:\Program Files (x86)\NSIS`)
- [ ] `UPX_BIN` -- directory containing `upx.exe`. **Optional** -- if unset,
  the script falls back to `PATH` lookup. Set this if you have UPX installed
  somewhere odd (e.g., `C:\Tools\upx-4.2.4-win64\`) and don't want to modify
  `PATH`.
- [ ] `VIRUS_TOTAL_API_KEY` -- VirusTotal public API key. **Optional** -- if
  unset, the local build prints a "skipping scan" note and continues. When set,
  `BuildAllInstallers.cmd` (and CI) upload each installer to VT and print a
  CLEAN/WARN/BLOCKED summary. Local scans are informational only; CI is the
  authoritative gate. Get a free key at https://www.virustotal.com/gui/my-apikey
  (4 requests/min, 500/day -- plenty for a 1-8-installer release).

Set permanently:

```
Win+R -> sysdm.cpl -> Advanced -> Environment Variables -> User variables -> New
Variable name:  DELPHI7_BIN (or INDY_ROOT, or NSIS_BIN)
Variable value: <your path>
```

Close any open terminal so it picks up the new value.

Or, override per-invocation:

```
powershell -File tr4w\FullBuild.ps1 -Delphi7Bin "D:\Delphi7\Bin" -IndyRoot "E:\Indy\Lib"
```

You can also point the script at a checkout in a non-default location anywhere on
disk with `-ProjectRoot`. Default is auto-detected from where `FullBuild.ps1` lives.

---

## 2. Reviewing an incoming PR

Day-to-day flow when someone opens a PR (or you opened one from a branch and want
to verify before merging).

1. **Read the PR on GitHub first.**
   - Skim the description, the file list, and the diff.
   - If the PR touches `Version.pas` AND other files, that's the normal case (one
     PR bundles the feature change + version bump).
   - If the PR is `Version.pas`-only, it's the narrow carve-out for version bumps;
     those can also land direct to master without a PR -- but if it arrived as a
     PR anyway, just merge it.

2. **Check out the branch locally.**
   ```
   git fetch origin
   git checkout <branch-name>
   git pull
   ```
   Or with `gh`:
   ```
   gh pr checkout <PR-number>
   ```

3. **Build locally** (see [section 3](#3-building-locally)).

4. **Smoke test** (see [section 4](#4-smoke-testing)).

5. **Approve / request changes** via the GitHub UI.

6. **Merge.** Use the GitHub merge UI. Default is "Create a merge commit" for TR4W.

7. **Back to master.**
   ```
   git checkout master
   git pull
   ```

---

## 3. Building locally

Run from the **repo root** (e.g., `C:\TR4W\`):

| Wrapper                 | What it does                                                                    | When to use                                | Typical duration                                       |
|-------------------------|---------------------------------------------------------------------------------|--------------------------------------------|--------------------------------------------------------|
| `Build.cmd`             | English `tr4w.exe` + `tr4wserver.exe` + zip                                     | PR review, day-to-day dev iteration        | ~30 sec (cached) to ~3 min (first build)               |
| `BuildAll.cmd`          | The above + 7 per-language exes in `tr4w\target\dist\lang-test\`                | Verify every language still compiles       | ~25 min first time / ~1-2 min on re-run unchanged      |
| `BuildAllInstallers.cmd`| All the above + 8 installers in `tr4w\build\release\` (ENG + 7 langs)           | Producing shippable installers locally     | First time same as `BuildAll` + ~10 sec per installer  |

**For PR review, `Build.cmd` is almost always enough.** Only use `BuildAll.cmd`
when the PR touches `src\lang\` or `tr4w_consts_*.pas`. Only use
`BuildAllInstallers.cmd` if you're producing release-candidate installers locally
(rare -- CI does this on a tag push).

### `Build.cmd` is incremental after the first run

Despite the script being named `FullBuild.ps1`, plain `Build.cmd` does **not**
clear DCUs or force a full recompile every time. The name is historical -- it
refers to the full chain (tests -> main build -> server -> zip -> optional
installers), not a clean build.

What actually happens:

- **First-ever run** (`tr4w\target\.dcu-managed-by-fullbuild` marker file missing):
  the script clears `src\*.dcu` to migrate cleanly from the pre-DCU-cache version
  of the script, then DCC32 does a full ~3-minute compile and drops the marker.
- **Every subsequent run**: marker exists, `src\*.dcu` is left alone, DCC32 runs
  **without `-B`** and recompiles only units whose `.pas` files changed. Typical
  incremental main-build time: ~30 sec, often less.

Per-language DCUs (`tr4w\target\dcu-cache\<lang>\`) are never read or written by
plain `Build.cmd` -- only by `BuildAll.cmd` / `BuildAllInstallers.cmd` and only
for non-ENG languages. ENG DCUs always live in `src\` (where Delphi 7 IDE
expects them, so opening the project in the IDE after a script build doesn't
trigger a phantom rebuild).

To force a full rebuild manually:

```
del tr4w\target\.dcu-managed-by-fullbuild
Build.cmd
```

Next run will be a full ~3 minute compile and the marker gets recreated.

### 3a. What lands where

After `Build.cmd`:

- `tr4w\target\tr4w.exe` -- English program. Double-click to run.
- `tr4w\tr4wserver\tr4wserver.exe` -- Multi-op server.
- `tr4w\target\dist\tr4w-<version>-<branch>-<timestamp>.zip` -- Zipped exe for
  emailing to testers.

After `BuildAll.cmd` (everything above plus):

- `tr4w\target\dist\lang-test\tr4w-RUS.exe` (also `-SER`, `-MNG`, `-CZE`, `-ROM`,
  `-GER`, `-UKR`).

After `BuildAllInstallers.cmd` (everything above plus):

- `tr4w\build\release\tr4w_setup_<version>.exe` -- English installer.
- `tr4w\build\release\tr4w_setup_<version>_<lang>.exe` -- Per-language installers.

### 3b. Things that go wrong

- **`DCC32.EXE not found at: <path>`** -- Delphi 7 not at default location. See
  [section 1a](#1a-non-default-tool-locations).
- **`Indy lib root not found`** -- only happens if you've set `INDY_ROOT` or
  passed `-IndyRoot` to a non-existent path. With both unset the script falls
  back to the bundled `tr4w\include`, which is always present in the repo.
- **`makensis.exe not found`** -- NSIS not installed. Only matters for
  `-BuildInstallers`.
- **`upx.exe not found`** -- only matters for `-BuildInstallers`. The script
  tries three resolution paths in order:
  1. `-UpxBin <dir>` command-line parameter, OR
  2. `UPX_BIN` environment variable (directory containing `upx.exe`), OR
  3. `PATH` lookup.

  Pick whichever is least disruptive for your machine. Download UPX from
  https://upx.github.io/ if you don't have it.
- **`Could not create output file 'tr4w.exe'`** -- `tr4w.exe` is currently
  running. Close it.
- **`Could not compile used unit 'src\VC.pas'`** -- almost always a missing
  language constant in `tr4w_consts_<lang>.pas`. See issue #925.
- **Weird state after Ctrl+C'ing a previous build** -- delete
  `tr4w\target\.dcu-managed-by-fullbuild` and re-run. Script defensively clears
  stale DCUs on the next run.

### 3c. Why clone location doesn't matter

You can clone TR4W to **any path** -- `C:\TR4W`, `D:\newsrc\TR4W`,
`E:\projects\contesting\tr4w`, whatever -- and the build script Just Works with
zero config. The mechanism:

- `tr4w\FullBuild.ps1` derives `$ProjectRoot` from `$PSScriptRoot` (the directory
  it lives in) by going one level up. Every other path in the script
  (`$SRC_DIR`, `$EXE_DIR`, `$BUILD_DIR`, `$VERSION_PAS`, etc.) is built from
  `$ProjectRoot` via `Join-Path`. So wherever the script lives, the script
  finds its own repo.
- The three `.cmd` wrappers (`Build.cmd`, `BuildAll.cmd`,
  `BuildAllInstallers.cmd`) invoke `tr4w\FullBuild.ps1` with a **relative** path,
  so they also work from any clone location -- just run them from the repo root.
- Toolchain locations (`DELPHI7_BIN`, `INDY_ROOT`, `NSIS_BIN`) are about your dev
  machine, not the repo. They don't move when you change clone location, so
  defaults apply and you only override if your toolchain install is non-standard
  ([section 1a](#1a-non-default-tool-locations)).
- The CI runner uses the same script with an explicit
  `-ProjectRoot $env:GITHUB_WORKSPACE` because GitHub's checkout path varies
  per-runner -- documented in `.github/workflows/release.yml`.

**No symlinks, no junctions, no `C:\TR4W` hardcoding anywhere.** If you find code
or docs that assume a specific clone path, that's a bug -- file it.

### 3d. Local VirusTotal scan (optional)

When `BuildAllInstallers.cmd` (or any `-BuildInstallers` invocation) finishes
successfully and the env var `VIRUS_TOTAL_API_KEY` is set, `FullBuild.ps1`
uploads each `tr4w_setup_*.exe` to VirusTotal, polls for analysis completion,
and prints a one-line verdict per file:

```
tr4w_setup_4.147.18.exe
    CLEAN -- 0 malicious / 0 suspicious / 73 clean of 73 engines
    https://www.virustotal.com/gui/file/<sha256>
```

Or, if engines flag the file:

```
    WARN (below CI threshold) -- 2 malicious / 0 suspicious / 71 clean of 73 engines
    BLOCKED (>= CI threshold of 8) -- 9 malicious / 1 suspicious / 63 clean of 73 engines
```

**Local scan is informational only** -- it never fails the build. The CI VT-scan
on tag push (see [section 6](#6-tagging-for-an-english-only-release)) is the
authoritative gate. Local exists for catching surprises before you tag and
trigger a release that gets blocked at the CI gate.

When the env var is unset, the script prints a "skipping scan" note and
continues. Set it once per machine:

```
[Environment]::SetEnvironmentVariable('VIRUS_TOTAL_API_KEY', '<your-key>', 'User')
```

(reopen the terminal afterward). Or per-session:

```
$env:VIRUS_TOTAL_API_KEY = '<your-key>'
```

Each VT scan takes 30 sec to ~3 min depending on queue depth -- typically
~1 min. Upload + 10-min poll cap per installer; if VT is slow or down, the
script logs the failure and moves on.

### 3e. How the per-language build works (one paragraph)

`tr4w.exe` is the same Delphi 7 project compiled with a different `-DLANG_xxx`
flag per language. Each language's compiled `.dcu` files live in
`tr4w\target\dcu-cache\<lang>\`. The canonical English DCUs live in `src\` (where
Delphi IDE puts them by default -- so opening the project in the IDE after a
script build doesn't trigger a phantom rebuild). The first time you build a given
language, it does a full ~3-minute compile (`-B` flag to force DCC32 to ignore the
ENG DCUs in `src\`). After that, the language's DCU cache is populated and
subsequent builds of the same language are ~5-10 seconds.

---

## 4. Smoke testing

After a local build, before approving the PR or tagging a release, run the
program and at least verify:

- [ ] **Launches.** Double-click `tr4w\target\tr4w.exe`. Title bar shows
  `TR4W v.<version>`.
- [ ] **Language is right.** Default English build: menus in English. Per-language
  build: spot-check the title / menus are in the expected language.
- [ ] **The feature in the PR works.** Read the PR description and exercise the
  code path it touches.
- [ ] **Nothing obvious regressed.** Open a contest, log a test QSO, verify the
  basics.
- [ ] **For radio-touching PRs:** connect to whatever hardware you have on hand
  and confirm the radio still polls (band/freq/mode display updates).

If the change is hardware- or contest-specific and you can't test it (e.g., a
TS-890 fix when you don't have a TS-890), say so explicitly in your PR review
rather than approving on faith. Hand the build to whoever does have the hardware.

---

## 5. When to update `Version.pas`

`src/Version.pas` is the single source of truth for the version string. The CI
release workflow extracts `TR4W_CURRENTVERSION_NUMBER` and refuses to build if it
doesn't match the tag (with the `-all` suffix stripped). So getting the timing
right matters.

There are two patterns. Pick the one that fits the situation:

### Pattern A: Bundled with the feature PR (preferred when possible)

Use this when the feature PR is intended to be the next release.

1. On the feature branch, as part of the PR's commits, bump
   `TR4W_CURRENTVERSION_NUMBER` and `TR4W_CURRENTVERSIONDATE`.
2. PR gets reviewed + merged to master normally.
3. After merge, **immediately** tag master (see [section 6](#6-tagging-for-an-english-only-release)).
   The bumped version is already on master; no separate bump step.

Pro: one PR, atomic. The version-bump diff and the changes that justify it travel
together; reviewer sees both.

Con: requires deciding the version number when the PR opens. If multiple PRs are
in flight, only one of them can carry the bump -- the others need rebasing or
will conflict.

### Pattern B: Standalone bump on master, no PR

Use this when:

- Several PRs have already merged since the last release and none of them carried
  a bump, OR
- You're cutting a release at a point not aligned with any single PR (e.g.,
  monthly cadence), OR
- A `-all` tag follows an English `vX.Y.Z` release: bump version, push, tag.

Steps -- runs **directly on master**, no branch, no PR:

```
git checkout master
git pull
# edit tr4w\src\Version.pas: bump TR4W_CURRENTVERSION_NUMBER and _DATE
git add tr4w\src\Version.pas
git commit -m "Bump Version.pas to 4.147.18"
git push origin master
```

This is the narrow exception to the "no direct commits on master" rule. It
applies **only** to `Version.pas`-only diffs whose review value is essentially
zero. Comment-only changes, typo fixes, and everything else still go through a
branch + PR.

### What NOT to do

- **Don't tag without bumping first.** The CI's tag-vs-`Version.pas` validation
  will fail, the build won't run, and you'll have to delete the tag and re-push.
- **Don't bump and then forget to tag.** A bumped `Version.pas` on master with no
  matching tag means the EXE built locally claims version N+1 but there's no
  corresponding release artifact anywhere.
- **Don't reuse a version.** Once `v4.147.18` is tagged and published, the next
  release is `v4.147.19` or `v4.148.0` -- not a re-tag of `v4.147.18`. Bump it
  again.

### Version-number conventions

- **Patch bumps** (`4.147.17` -> `4.147.18`): bug fixes, small features, the
  default for most releases.
- **Minor bumps** (`4.147.x` -> `4.148.0`): notable feature additions, new radio
  support, new contest additions.
- **Major bumps** (`4.x.y` -> `5.0.0`): reserved; not currently planned.
- **Date** (`TR4W_CURRENTVERSIONDATE`): update to the current "Month, Year" of the
  release.

---

## 6. Tagging for an English-only release

This is the **normal** release path. Use it for the vast majority of releases.

**Precondition:** `Version.pas` on master reflects the version you're about to
tag. If not, do [section 5](#5-when-to-update-versionpas) first.

1. **Make sure master is clean and you're on it.**
   ```
   git checkout master
   git pull
   git status   # should be clean
   ```

2. **Confirm the version.**
   ```
   git -C . show HEAD:tr4w/src/Version.pas | findstr CURRENTVERSION_NUMBER
   ```
   You should see exactly the version you're about to tag, e.g.
   `TR4W_CURRENTVERSION_NUMBER = '4.147.18'`.

3. **Create the tag and push it.**

   Annotated tag (recommended -- carries a message and a tagger date):
   ```
   git tag -a v4.147.18 -m "TR4W v4.147.18"
   git push origin v4.147.18
   ```

   Lightweight tag (also works, no message):
   ```
   git tag v4.147.18
   git push origin v4.147.18
   ```

   To push **all** local tags at once (rarely needed):
   ```
   git push origin --tags
   ```

4. **CI fires.** `.github/workflows/release.yml` matches `v4.*.*` and runs three
   jobs in sequence:
   - **build** (Windows runner): compiles, UPX-compresses, runs `makensis`,
     uploads `tr4w_setup_4.147.18.exe` as a workflow artifact.
   - **virustotal-scan** (Linux runner): downloads the installer, uploads it to
     VirusTotal, polls for completion, generates `virustotal-report.md`. Fails
     the pipeline if any installer hits the threshold
     (`VT_MALICIOUS_THRESHOLD = 8`), which blocks the release job. An emergency
     `skip_virustotal` input is available on the `workflow_dispatch` trigger.
   - **release** (Linux runner): only runs on tag push. Downloads both
     artifacts, creates a **draft** GitHub Release with auto-generated
     changelog, the installer, AND the VT report attached.

5. **Watch the run.** GitHub Actions tab, or:
   ```
   gh run watch
   ```
   English-only build is ~3-5 min.

6. **Review and publish the draft release.**
   - Open the draft on GitHub.
   - Edit the auto-generated notes -- highlight headline changes, call out radio
     additions, breaking changes, contest additions.
   - Verify the installer is attached.
   - **Publish.** This emails watchers and makes the release public.

### Fixing a mis-tag

If you tagged the wrong commit (or tagged before bumping `Version.pas`):

```
git push --delete origin v4.147.18    # remove tag from remote
git tag -d v4.147.18                  # remove tag locally
# fix the underlying issue (bump Version.pas, push, etc.)
git tag v4.147.18
git push origin v4.147.18
```

This is safe as long as the draft release hasn't been published yet. Once
published, prefer cutting a new version instead of force-retagging.

---

## 7. Tagging for an all-languages release (major releases only)

Use this for major releases where you want shippable installers for every
language. It's slower (~25 min) and the per-language installers are mostly
appreciated by international contesters who don't want to muddle through English
menus.

Same as [section 6](#6-tagging-for-an-english-only-release) except:

- **Tag with `-all` suffix:** `v4.147.18-all` instead of `v4.147.18`.
- CI detects the `-all` suffix and runs `FullBuild.ps1 -AllLanguages
  -BuildInstallers`.
- The draft release gets all 8 installers attached (`tr4w_setup_4.147.18.exe`
  plus 7 per-language `_rus`, `_ser`, `_mng`, `_cze`, `_rom`, `_ger`, `_ukr`).
- Release title in the draft includes "(all languages)".

The tag matching strips `-all` before comparing to `Version.pas`, so both
`v4.147.18` and `v4.147.18-all` validate against `Version.pas = 4.147.18`. You
can use either on the same version; you cannot use both with two separate tag
events without an intermediate version bump.

**Typical cadence:** ship English-only on point releases; ship all-languages on
the first release of a quarter, or whenever language files have meaningfully
changed.

---

## 8. Ad-hoc full builds without a release

If you want to produce all-language installers for testing without creating a
GitHub Release (e.g., to give Howie a build of the current master to validate
language files):

- GitHub Actions tab -> "Release Build" workflow -> **Run workflow** button.
- Check "Build all language installers".
- Pick the branch (usually `master`).
- Run.

This runs the same `FullBuild.ps1 -AllLanguages -BuildInstallers` chain and
uploads the installers as a workflow artifact, but **does not** create a draft
release. The artifact lives for 90 days; download it from the run's summary page.

---

## 9. Quick reference

| Goal                                  | Command / action                                                  |
|---------------------------------------|-------------------------------------------------------------------|
| Build English locally                 | `Build.cmd`                                                       |
| Build every language locally          | `BuildAll.cmd`                                                    |
| Build every language + installers     | `BuildAllInstallers.cmd`                                          |
| Ship English release                  | Bump `Version.pas` on master, push, tag `vX.Y.Z`, push tag        |
| Ship all-languages release            | Same as above with tag `vX.Y.Z-all`                               |
| Ad-hoc all-langs build, no release    | Actions tab -> Release Build -> Run workflow -> check the box     |
| Check the CI runner has the right tools | Repo Settings -> Variables -> Actions: `DELPHI7_BIN`, `NSIS_BIN`, `INDY_ROOT` |

---

## 10. Related files

- `.github/workflows/release.yml` -- the CI workflow itself
- `tr4w/FullBuild.ps1` -- the build script
- `tr4w/build/full.nsi` -- NSIS installer script
- `tr4w/src/Version.pas` -- single source of truth for the version string
- `Build.cmd`, `BuildAll.cmd`, `BuildAllInstallers.cmd` -- thin wrappers around
  `FullBuild.ps1`
