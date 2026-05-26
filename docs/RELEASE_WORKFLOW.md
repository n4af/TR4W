# TR4W Build & Release Workflow

End-to-end guide covering: reviewing a PR, building locally, smoke-testing, tagging
for the English CI build, promoting to a full English installer release, and (for
major releases) producing the multi-language installers.

If you only want to compile the source on your dev box and never publish anything,
sections 1-4 are all you need. Sections 5-7 cover tagging and the GitHub-side
release flow.

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
- [ ] **Indy 10 library** -- `C:\Indy\Indy\Lib\` (with `Core\`, `System\`,
  `Protocols\` subdirs)
- [ ] **PowerShell** -- built into Windows; nothing to install
- [ ] **Git** -- used by the build script to read the current branch name for zip
  filenames

For `-BuildInstallers` mode (anything that produces `tr4w_setup_*.exe`):

- [ ] **NSIS** -- `C:\Program Files (x86)\NSIS\makensis.exe`
- [ ] **UPX** -- `upx.exe` in `PATH` (any version that supports `--lzma`)

Plain `Build.cmd` and `BuildAll.cmd` only need Delphi 7 + Indy.

### 1a. Non-default tool locations

Skip this if you accepted the installer defaults.

The build script reads three environment variables. Set them only if YOUR install
differs from the defaults.

- [ ] `DELPHI7_BIN` -- directory containing `DCC32.EXE`
  (default `C:\Program Files (x86)\Borland\Delphi7\Bin`)
- [ ] `INDY_ROOT` -- Indy `Lib` directory containing `Core`/`System`/`Protocols`
  (default `C:\Indy\Indy\Lib`)
- [ ] `NSIS_BIN` -- NSIS directory containing `makensis.exe`
  (default `C:\Program Files (x86)\NSIS`)

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
- **`Indy lib root not found`** -- same for Indy.
- **`makensis.exe not found`** -- NSIS not installed. Only matters for
  `-BuildInstallers`.
- **`upx.exe not found in PATH`** -- install UPX and add to PATH. Only matters for
  `-BuildInstallers`.
- **`Could not create output file 'tr4w.exe'`** -- `tr4w.exe` is currently
  running. Close it.
- **`Could not compile used unit 'src\VC.pas'`** -- almost always a missing
  language constant in `tr4w_consts_<lang>.pas`. See issue #925.
- **Weird state after Ctrl+C'ing a previous build** -- delete
  `tr4w\target\.dcu-managed-by-fullbuild` and re-run. Script defensively clears
  stale DCUs on the next run.

### 3c. How the per-language build works (one paragraph)

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

## 5. Tagging for an English-only release

This is the **normal** release path. Use it for the vast majority of releases.

1. **Make sure master is clean and you're on it.**
   ```
   git checkout master
   git pull
   git status   # should be clean
   ```

2. **Bump the version in `src/Version.pas`.**
   - Edit `TR4W_CURRENTVERSION_NUMBER`, e.g. `'4.147.18'`.
   - Update `TR4W_CURRENTVERSIONDATE`, e.g. `'May, 2026'`.
   - Optional one-line comment after the version literal describing what's in this
     release.
   - **Version.pas-only diffs go direct to master** -- no branch, no PR. Larger
     changes that include the bump went through their own PR earlier.

3. **Commit and push.**
   ```
   git add tr4w\src\Version.pas
   git commit -m "Bump Version.pas to 4.147.18"
   git push origin master
   ```

4. **Tag and push the tag.**
   ```
   git tag v4.147.18
   git push origin v4.147.18
   ```

5. **CI fires.** `.github/workflows/release.yml` matches `v4.*.*`, builds English
   only, UPX-compresses, runs `makensis`, and:
   - Uploads `tr4w_setup_4.147.18.exe` as a workflow artifact.
   - Creates a **draft** GitHub Release with auto-generated changelog + the
     installer attached.

6. **Watch the run.** GitHub Actions tab, or:
   ```
   gh run watch
   ```
   English-only build is ~3-5 min.

7. **Review and publish the draft release.**
   - Open the draft on GitHub.
   - Edit the auto-generated notes -- highlight headline changes, call out radio
     additions, breaking changes, contest additions.
   - Verify the installer is attached.
   - **Publish.** This emails watchers and makes the release public.

If the build fails: CI tells you why. Common causes -- tag doesn't match
`Version.pas` (you tagged before bumping, or vice versa), or a missing language
constant (won't happen for English-only).

---

## 6. Tagging for an all-languages release (major releases only)

Use this for major releases where you want shippable installers for every
language. It's slower (~25 min) and the per-language installers are mostly
appreciated by international contesters who don't want to muddle through English
menus.

Same as section 5 except:

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

## 7. Ad-hoc full builds without a release

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

## 8. Quick reference

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

## 9. Related files

- `.github/workflows/release.yml` -- the CI workflow itself
- `tr4w/FullBuild.ps1` -- the build script
- `tr4w/build/full.nsi` -- NSIS installer script
- `tr4w/src/Version.pas` -- single source of truth for the version string
- `Build.cmd`, `BuildAll.cmd`, `BuildAllInstallers.cmd` -- thin wrappers around
  `FullBuild.ps1`
