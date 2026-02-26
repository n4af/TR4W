# TR4W Windows Build Runner

## Overview

TR4W is a Delphi 7 project that must compile on Windows. Development happens on macOS, with compilation offloaded to a Windows 11 CI runner (`win-ci`) via SSH. Claude Code edits source files locally on macOS and uses `scp` + `ssh` to copy files to the runner and invoke the Delphi command-line compiler.

---

## Infrastructure

| Component | Details |
|-----------|---------|
| **Runner** | `win-ci` (Windows 11, Proxmox VM 104) |
| **IP** | 192.168.86.139 |
| **SSH** | `ssh win-ci` (key auth, configured in `~/.ssh/config`) |
| **Delphi 7** | `C:\Program Files (x86)\Borland\Delphi7` |
| **Compiler** | `dcc32.exe` (on system PATH) |
| **Repo clone** | `C:\projects\tr4w` |
| **Source root** | `C:\projects\tr4w\tr4w` (contains `tr4w.dpr`) |
| **Output** | `C:\projects\tr4w\tr4w\target\tr4w.exe` |

---

## Build Commands

### Full compile

```bash
ssh win-ci "cd C:\projects\tr4w\tr4w && dcc32.exe tr4w.dpr"
```

Exit code 0 = success. The compiler prints file progress and any hints/warnings/errors to stdout/stderr. The compiled binary lands in `target\tr4w.exe` (per the `-E"target"` directive in `tr4w.cfg`).

### Copy a file to the runner, then compile

```bash
# Single file
scp ~/projects/tr4w/tr4w/src/uMyUnit.pas win-ci:"C:/projects/tr4w/tr4w/src/uMyUnit.pas"

# Then build
ssh win-ci "cd C:\projects\tr4w\tr4w && dcc32.exe tr4w.dpr"
```

### Copy multiple files

```bash
scp ~/projects/tr4w/tr4w/src/uFoo.pas \
    ~/projects/tr4w/tr4w/src/uBar.pas \
    ~/projects/tr4w/tr4w/tr4w.cfg \
    win-ci:"C:/projects/tr4w/tr4w/src/"
```

Note: when copying to a directory, all files go into that directory. For files in different subdirectories, use separate `scp` commands or `rsync`.

### Sync entire source tree

```bash
rsync -avz --delete \
    ~/projects/tr4w/tr4w/ \
    win-ci:"C:/projects/tr4w/tr4w/" \
    --exclude='target/' \
    --exclude='build/' \
    --exclude='*.exe' \
    --exclude='*.obj' \
    --exclude='*.dcu'
```

### One-liner: copy + compile

```bash
scp ~/projects/tr4w/tr4w/src/uMyUnit.pas win-ci:"C:/projects/tr4w/tr4w/src/" && \
ssh win-ci "cd C:\projects\tr4w\tr4w && dcc32.exe tr4w.dpr"
```

---

## Compiler Configuration

All compiler settings are in `tr4w.cfg` (read automatically by `dcc32.exe` when compiling `tr4w.dpr`).

### Key settings

| Flag | Meaning |
|------|---------|
| `-E"target"` | Output exe to `target\` subdirectory |
| `-U"..."` | Unit search paths |
| `-O"..."` | Object file search paths |
| `-I"..."` | Include file search paths |
| `-R"..."` | Resource file search paths |
| `-$M16384,1048576` | Stack size (16KB min, 1MB max) |
| `-K$00400000` | Image base address |
| `-M` | Generate .map file |

### Unit search paths

```
src;src\lang;src\trdos;src\utils;include;include\Core;include\Protocols;include\System;C:\Program Files (x86)\Borland\Delphi7\lib
```

- `src`, `src\lang`, `src\trdos`, `src\utils` — Application source
- `include` — WinSock2, pcre, PerlRegEx
- `include\Core`, `include\Protocols`, `include\System` — Indy 10 TCP/networking library (source in repo)
- `Delphi7\lib` — Delphi RTL/VCL compiled units

### Historical note

The original `.cfg` referenced `include\Indy\Lib\Core`, `include\Indy\Lib\Protocols`, etc. — paths from the original developer's machine. These were updated to match the actual repo layout (`include\Core`, `include\Protocols`, `include\System`).

---

## Build Output

### Success

```
402233 lines, 237.67 seconds, 1345832 bytes code, 406073 bytes data.
```

Exit code: 0

### Failure

The compiler prints the file and line number where it failed:

```
Fatal: File not found: 'SomeUnit.dcu'
```
or
```
src\uMyUnit.pas(42) Error: Undeclared identifier: 'FooBar'
```

Exit code: 1

### Hints and warnings

The compiler emits hints (unused variables, etc.) that do NOT prevent compilation:

```
src\uFoo.pas(123) Hint: Variable 'x' is declared but never used in 'DoSomething'
```

These are informational only.

---

## Project Structure

```
tr4w/
├── tr4w.dpr              # Main project file (program entry point)
├── tr4w.cfg              # Compiler configuration (search paths, flags)
├── tr4w.dof              # Delphi IDE options (not used by dcc32)
├── Win11.rc / Win11.RES  # Windows manifest resource
├── src/
│   ├── MainUnit.pas      # Main application unit
│   ├── Version.pas       # Version constants
│   ├── VC.pas            # Visual constants and language strings
│   ├── uCAT.pas          # CAT radio control
│   ├── uRadioFactory.pas # Radio factory (serial/network)
│   ├── uNetRadioBase.pas # Network radio base class
│   ├── uRadioIcom*.pas   # Icom network radio implementations
│   ├── uRadioElecraftK4.pas
│   ├── uRadioHamLib.pas  # Hamlib integration
│   ├── trdos/            # Legacy TRLog-derived code
│   ├── lang/             # Language string files
│   └── utils/            # Utility units
├── include/
│   ├── Core/             # Indy 10 core (IdTCPClient, etc.)
│   ├── Protocols/        # Indy 10 protocols (IdHTTP, etc.)
│   ├── System/           # Indy 10 system (IdGlobal, IdStack, etc.)
│   └── WinSock2.pas      # Winsock2 API bindings
├── res/                  # Resource files (.res) per language
├── target/               # Compiled output (tr4w.exe)
└── build/                # Intermediate build files (.dcu, .obj)
```

---

## Workflow for Claude Code

### Standard development cycle

1. **Edit** `.pas` files locally in `~/projects/tr4w/tr4w/`
2. **Copy** changed files to runner: `scp <file> win-ci:"C:/projects/tr4w/tr4w/<path>/"`
3. **Compile**: `ssh win-ci "cd C:\projects\tr4w\tr4w && dcc32.exe tr4w.dpr"`
4. **Read output** — fix errors, repeat

### Adding a new unit

1. Create the `.pas` file locally
2. Add the unit to the `uses` clause in `tr4w.dpr` with path: `uNewUnit in 'src\uNewUnit.pas'`
3. Copy both `tr4w.dpr` and the new `.pas` file to the runner
4. Compile

### Keeping runner in sync

The runner has a full git clone. To reset to upstream state:

```bash
ssh win-ci "cd C:\projects\tr4w && git checkout -- . && git pull"
```

Then copy the local `.cfg` fix back (since the repo's `.cfg` has the old Indy paths):

```bash
scp ~/projects/tr4w/tr4w/tr4w.cfg win-ci:"C:/projects/tr4w/tr4w/tr4w.cfg"
```

---

## Troubleshooting

### "File not found: 'SomeUnit.dcu'"

The compiler can't find a unit. Check:
1. Is the `.pas` file present on the runner? (`ssh win-ci "dir /s /b C:\projects\tr4w\tr4w\*SomeUnit*"`)
2. Is the directory in the `-U` search path in `tr4w.cfg`?

### Build takes too long

Full compile is ~4 minutes (402K lines). Delphi 7 does incremental compilation automatically — only changed units and their dependents are recompiled. If you only changed one `.pas` file, subsequent builds are much faster.

### Runner is offline

```bash
# Check status
ssh win-ci "echo online" 2>/dev/null || echo "OFFLINE"

# Start the VM from Proxmox
ssh proxmox 'qm start 104'
```

### File encoding issues

Delphi 7 expects ANSI (Windows-1252) encoded source files. If editing on macOS introduces UTF-8 BOM or non-ANSI characters, the compiler may fail with unexpected errors. Most ASCII source will be fine.

---

## Performance

| Metric | Value |
|--------|-------|
| Full compile | ~4 minutes (402K lines) |
| Incremental (1 unit changed) | ~10-30 seconds |
| scp single file | <1 second |
| Output binary | ~1.6 MB |
