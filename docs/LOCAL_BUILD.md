# Building TR4W Locally

Checklist-style guide for building TR4W on a Windows dev machine. Follow the prerequisites once, then pick one of the three build commands.

---

## 1. Prerequisites checklist

Install these once. Defaults match the assumed locations; if yours differ, see [section 2](#2-non-default-tool-locations).

- [ ] **Delphi 7** — `C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE`
- [ ] **Indy 10 library** — `C:\Indy\Indy\Lib\` (with `Core\`, `System\`, `Protocols\` subdirs)
- [ ] **PowerShell** — built into Windows; nothing to install
- [ ] **Git** — needed by the build script to read the current branch name for zip filenames
- [ ] **Git Bash / WSL** — optional but useful if you're following along with Unix-style commands

For `-BuildInstallers` mode only:

- [ ] **NSIS** — `C:\Program Files (x86)\NSIS\makensis.exe`
- [ ] **UPX** — `upx.exe` in `PATH` (any version that supports `--lzma`)

You DO NOT need any of these unless you're building installers. Plain `Build.cmd` and `BuildAll.cmd` only need Delphi 7 + Indy.

---

## 2. Non-default tool locations

Skip this section if you accepted the defaults during installation.

The build script reads three environment variables. Set them only if YOUR install differs from the defaults.

- [ ] `DELPHI7_BIN` — directory containing `DCC32.EXE` (default `C:\Program Files (x86)\Borland\Delphi7\Bin`)
- [ ] `INDY_ROOT` — Indy `Lib` directory containing `Core`/`System`/`Protocols` (default `C:\Indy\Indy\Lib`)
- [ ] `NSIS_BIN` — NSIS directory containing `makensis.exe` (default `C:\Program Files (x86)\NSIS`)

How to set permanently (one-time, per machine):

```
1. Win+R → sysdm.cpl → Enter
2. Advanced tab → Environment Variables...
3. Under "User variables" → New...
4. Variable name: DELPHI7_BIN  (or INDY_ROOT, or NSIS_BIN)
5. Variable value: <your path>
6. OK out of everything
7. Close any open terminal / IDE so they pick up the new value
```

Or, override per-invocation on the command line:

```
powershell -File tr4w\FullBuild.ps1 -Delphi7Bin "D:\Delphi7\Bin" -IndyRoot "E:\Indy\Lib"
```

You can also point the script at a checkout in a non-default location (anywhere on disk) with `-ProjectRoot`. The default is auto-detected from where `FullBuild.ps1` lives.

---

## 3. Pick a build mode

Run any of these from the **repo root** (e.g., `C:\TR4W\`):

| Wrapper | What it does | When to use | Typical duration |
|---|---|---|---|
| `Build.cmd` | Build English tr4w.exe + tr4wserver.exe + zip | Day-to-day dev iteration | ~30 sec (cached) to ~3 min (first build) |
| `BuildAll.cmd` | All the above + 7 per-language exes in `tr4w\target\dist\lang-test\` | Smoke-test that every language still compiles | ~25 min first time / ~1-2 min on re-run with no source changes |
| `BuildAllInstallers.cmd` | All the above + 8 installers in `tr4w\build\release\` (ENG + 7 langs) | Producing shippable installers | First-time same as BuildAll + ~10 sec per installer |

---

## 4. What lands where after a build

After `Build.cmd`:

- [ ] `tr4w\target\tr4w.exe` — English program. Double-click to run.
- [ ] `tr4w\tr4wserver\tr4wserver.exe` — Multi-op server. Optional.
- [ ] `tr4w\target\dist\tr4w-<version>-<branch>-<timestamp>.zip` — Zipped exe for emailing to testers.

After `BuildAll.cmd` (everything from `Build.cmd` plus):

- [ ] `tr4w\target\dist\lang-test\tr4w-RUS.exe` (also `-SER`, `-MNG`, `-CZE`, `-ROM`, `-GER`, `-UKR`) — Each non-English variant exe, for spot-checking that languages compile.

After `BuildAllInstallers.cmd` (everything from `BuildAll.cmd` plus):

- [ ] `tr4w\build\release\tr4w_setup_<version>.exe` — English installer (no language suffix).
- [ ] `tr4w\build\release\tr4w_setup_<version>_<lang>.exe` — Per-language installers (`_rus`, `_ser`, `_mng`, `_cze`, `_rom`, `_ger`, `_ukr`).

---

## 5. Verifying a build worked

- [ ] Did `=== BUILD SUCCESSFUL ===` print in green near the end? If not, scroll up for the first red error line.
- [ ] Does `tr4w\target\tr4w.exe` exist with today's timestamp? `dir tr4w\target\tr4w.exe`
- [ ] Does double-clicking it launch in English? (Title bar should say `TR4W v.<version> ...`, menus in English.)
- [ ] For installers, did `tr4w\build\release\` get the expected files? `dir tr4w\build\release\`

---

## 6. Things that go wrong + what to do

- [ ] **`DCC32.EXE not found at: <path>`** — Delphi 7 isn't installed at the default location. See [section 2](#2-non-default-tool-locations).
- [ ] **`Indy lib root not found at: <path>`** — same, but for Indy.
- [ ] **`makensis.exe not found`** — NSIS not installed or in non-default location. Only matters for `-BuildInstallers`.
- [ ] **`upx.exe not found in PATH`** — install UPX, add it to PATH. Only matters for `-BuildInstallers`.
- [ ] **Build fails with `Could not create output file 'tr4w.exe'`** — `tr4w.exe` is currently running. Close it.
- [ ] **`Could not compile used unit 'src\VC.pas'`** — almost always a missing language constant in `tr4w_consts_<lang>.pas`. See issue #925.
- [ ] **Build is in a weird state after Ctrl+C'ing a previous build** — delete `tr4w\target\.dcu-managed-by-fullbuild` and re-run. The script will defensively clear stale DCUs on the next run.

---

## 7. How the per-language build works (1 paragraph for the curious)

`tr4w.exe` is the same Delphi 7 project compiled with a different `-DLANG_xxx` flag per language. Each language's compiled `.dcu` files live in `tr4w\target\dcu-cache\<lang>\`. The canonical English DCUs live in `src\` (where the Delphi IDE puts them by default — so opening the project in the IDE after a script build doesn't trigger a phantom rebuild). The first time you build a given language, it does a full ~3-minute compile (`-B` flag to force DCC32 to ignore the ENG DCUs in `src\`). After that, the language's DCU cache is populated and subsequent builds of the same language are ~5-10 seconds.

---

## 8. CI builds (for reference)

If you tag a release (`git tag v4.x.y && git push --tags`), `.github/workflows/release.yml` runs the same `FullBuild.ps1` on a self-hosted Windows runner and uploads the installer as a GitHub Actions artifact. The runner uses the same three env vars (`DELPHI7_BIN`, `INDY_ROOT`, `NSIS_BIN`); they're set as repo Variables under Settings → Actions → Variables.
