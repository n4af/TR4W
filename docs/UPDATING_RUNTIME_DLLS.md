# Updating Bundled Runtime DLLs

TR4W ships several third-party DLLs in `tr4w/target/` so that the NSIS
installer can bundle them and so that the program works out-of-the-box on
machines without the libraries pre-installed. This document is for
maintainers who need to update those DLLs to a newer upstream version.

For most contributors this doc is irrelevant — a routine `git pull` brings
the current DLLs in automatically. Read on only if you intend to **replace**
a bundled DLL with a newer copy.

---

## Bundled runtime files at a glance

| File | Source | Bitness | Purpose |
|---|---|---|---|
| `libhamlib-4.dll` | [HamLib](https://hamlib.github.io/) Windows build | **32-bit** | Radio control via the HamLib library (used by `uRadioHamLibDirect.pas`) |
| `libgcc_s_dw2-1.dll` | Ships in the HamLib Windows zip | **32-bit** | MinGW runtime — required by `libhamlib-4.dll` |
| `libusb-1.0.dll` | Ships in the HamLib Windows zip | **32-bit** | USB transport — required by `libhamlib-4.dll` for USB-attached radios |
| `libwinpthread-1.dll` | Ships in the HamLib Windows zip | **32-bit** | POSIX-threads runtime — required by `libhamlib-4.dll` |
| `libeay32.dll` | OpenSSL 1.0.2 (legacy series) | **32-bit** | Used by Indy for HTTPS (HamScore RTC, TR4WSERVER TLS) |
| `ssleay32.dll` | OpenSSL 1.0.2 (legacy series) | **32-bit** | SSL/TLS layer — required by `libeay32.dll` |
| `inpout32.dll` | [InpOut32 by Phil Gibbons](https://www.highrez.co.uk/downloads/inpout32/) | **32-bit** | Direct parallel-port I/O for LPT CW keying (legacy stations) |
| `rigctld.exe` | HamLib Windows build | **32-bit** | **DEPRECATED.** Replaced by direct-DLL mode (`uRadioHamLibDirect.pas`). Tracked but not shipped by the installer; planned for removal. |

> ⚠️ **Everything is 32-bit.** TR4W is a Delphi 7 application and compiles
> exclusively for 32-bit Windows. The 64-bit builds of HamLib, OpenSSL, and
> inpout32 are **not compatible** and will cause crashes or load failures at
> runtime, even on a 64-bit Windows host.

---

## Why the gitignore actively blocks accidental updates

The repo root `.gitignore` contains:

```
*.dll
tr4w/target/*
```

Both rules would normally prevent any DLL from being committed. The bundled
DLLs are tracked anyway because they were `git add`'d **before** the rules
were added — once a file is tracked, gitignore stops applying to it.

The net effect is deliberately protective:

- ✅ `git pull` updates the tracked DLLs from upstream commits normally.
- ✅ `git status` shows tracked DLLs as modified if you replace them locally.
- ❌ `git add tr4w/target/libhamlib-4.dll` after replacing it silently does
  nothing — the file is ignored.
- ✅ `git add -f tr4w/target/libhamlib-4.dll` works.

This is intentional. The `-f` requirement is a speed bump against the most
common mistake: dropping a newer or wrong-bitness DLL into `tr4w/target/`
during local debugging and unintentionally committing it to the repo. If
you really mean to update the bundled copy, `-f` says so.

---

## Procedure: updating the HamLib DLLs

The four HamLib DLLs (`libhamlib-4.dll`, `libgcc_s_dw2-1.dll`,
`libusb-1.0.dll`, `libwinpthread-1.dll`) ship as a set in the upstream
HamLib Windows zip. Update them together so the runtime is internally
consistent.

1. **Download the upstream zip.** Go to
   <https://github.com/Hamlib/Hamlib/releases> and grab the latest
   **`hamlib-win32-X.Y.Z.zip`** — the file name explicitly contains
   `win32`. Do **not** download `hamlib-w64-X.Y.Z.zip`.
2. **Extract** to a scratch directory. The four DLLs live in
   `hamlib-win32-X.Y.Z/bin/`.
3. **Verify bitness** before copying. From a PowerShell prompt:
   ```
   $bytes = [System.IO.File]::ReadAllBytes("path\to\libhamlib-4.dll")
   $peOffset = [System.BitConverter]::ToInt32($bytes, 60)
   $machine  = [System.BitConverter]::ToUInt16($bytes, $peOffset + 4)
   # 0x14c = 32-bit (i386), 0x8664 = 64-bit (x64)
   "0x{0:x}" -f $machine
   ```
   Confirm the output is `0x14c` for all four DLLs.
4. **Replace** the four files in `tr4w/target/`.
5. **Test build** — run `Build.cmd` then launch `tr4w/target/tr4w.exe` and
   confirm a HamLib-controlled radio still connects. The dep check in
   `FullBuild.ps1` won't catch wrong-bitness DLLs (the file is present);
   only a runtime load failure will, so a smoke test matters.
6. **Stage with `-f`** and commit:
   ```
   git -C C:\TR4W add -f tr4w/target/libhamlib-4.dll
   git -C C:\TR4W add -f tr4w/target/libgcc_s_dw2-1.dll
   git -C C:\TR4W add -f tr4w/target/libusb-1.0.dll
   git -C C:\TR4W add -f tr4w/target/libwinpthread-1.dll
   git -C C:\TR4W commit -m "Bump bundled HamLib to X.Y.Z (32-bit)"
   ```
7. **Open a PR** even though it's an infra change — the upstream version
   bump is worth a review.

---

## Procedure: updating OpenSSL (libeay32 + ssleay32)

TR4W tracks the **legacy OpenSSL 1.0.2** series. Indy 10.6.3.3 (the version
TR4W bundles) does **not** support OpenSSL 1.1.x or 3.x — the DLL exports
and API shape changed incompatibly. Do not drop a 1.1.x or 3.x build of
`libeay32.dll`/`ssleay32.dll` into `tr4w/target/`; HTTPS connections will
fail at runtime with cryptic SSL handshake errors.

Indy-compatible 1.0.2 binaries are no longer published by OpenSSL itself
(end-of-life since 2019). Reliable mirrors used historically:

- <https://indy.fulgan.com/SSL/> — built specifically for Indy
- <https://wiki.openssl.org/index.php/Binaries> — pointers to community
  mirrors

Pick a 32-bit OpenSSL 1.0.2u (or latest 1.0.2-series) build, then follow
the same steps as HamLib above:

1. Download the 32-bit 1.0.2-series build.
2. Verify bitness (same PE-header check).
3. Replace `libeay32.dll` and `ssleay32.dll` in `tr4w/target/`.
4. Test — log a QSO into a HamScore-enabled contest and confirm HTTPS POST
   succeeds (check `tr4w.log` for `[HamScore] POST ... -> 200`).
5. `git add -f` both files, commit, PR.

> 🔒 **The right long-term fix is to refresh Indy** so we can use OpenSSL
> 3.x. Tracked under [Indy refresh with Delphi 12 port](../) in the
> maintainer memory; out of scope for a routine OpenSSL DLL refresh.

---

## Procedure: updating inpout32

`inpout32.dll` ships unchanged from
<https://www.highrez.co.uk/downloads/inpout32/>. It's an old, stable
component — releases are infrequent. The 32-bit variant is the only one
that works with TR4W.

Same procedure as the others: download, verify bitness, replace,
test (only matters if you can actually exercise LPT CW keying on a host
with a parallel port — increasingly rare), `git add -f`, commit, PR.

> 📋 **Long-term**: this DLL is on a deprecation track. It's the single
> true-positive VirusTotal flag on TR4W installers (DrWeb labels it
> `Tool.VulnDriver.32` — correctly, since inpout32 is a known userland →
> kernel I/O port primitive). LPT CW itself is candidate for removal during
> the Delphi 12/13 port. Don't invest heavily in refreshing this one.

---

## `rigctld.exe` (deprecated)

`tr4w/target/rigctld.exe` is tracked but **not** referenced by `full.nsi`
(so the installer doesn't ship it) and **not** invoked by TR4W's code
(replaced by direct-DLL mode in `uRadioHamLibDirect.pas` — see
`uRadioFactory.pas` line 214: `"Direct DLL mode - no rigctld process
needed"`).

**Don't update it.** The right move is to remove it entirely on a future
cleanup pass. Tracked separately as a TODO.

---

## Common pitfalls

| Pitfall | What goes wrong | How to spot |
|---|---|---|
| Dropping a 64-bit DLL | Runtime "wrong-architecture" load failure or silent skip | TR4W can't connect to the radio; `tr4w.log` shows DLL load error. Verify with the PE-header check above. |
| `git add` without `-f` | Update appears to succeed locally but the new bytes aren't staged | `git diff --cached` shows the file as unchanged. Always re-check with `git status` before committing. |
| OpenSSL 1.1.x / 3.x against Indy 10.6.3.3 | HTTPS POSTs fail with handshake errors | HamScore log shows network errors; works in browser but not from TR4W. |
| HamLib DLLs from mixed versions | Random radio-control failures, missing rig support | Update all 4 HamLib DLLs together from a single upstream zip. |
| Replacing a tracked DLL but forgetting to commit | Locally works, but the next CI build (or another developer's clone) uses the old version | Run `git status tr4w/target/` after replacement to confirm the diff is staged. |

---

## Verification after any DLL update

Before pushing:

1. `Build.cmd` — verifies the build still compiles.
2. `BuildAllInstallers.cmd` — exercises the new pre-flight dep check (the
   replaced DLL must still satisfy the `File` directives in `full.nsi`).
3. Launch the produced `tr4w.exe` and exercise the relevant feature
   (radio connect / HTTPS upload / LPT keying), depending on which DLL
   changed.
4. `git status` to confirm only the intended files are staged.

---

## Related files

- `tr4w/build/full.nsi` — installer manifest that bundles the DLLs into the
  setup.
- `tr4w/FullBuild.ps1` — build script with the `Test-InstallerDependencies`
  pre-flight that ensures every `File` directive in `full.nsi` resolves to
  an existing file before NSIS runs.
- `tr4w/src/uRadioHamLibDirect.pas` — direct-DLL HamLib client, supersedes
  the old `rigctld` daemon path.
- `.gitignore` (repo root) — the rules that block accidental DLL commits.
