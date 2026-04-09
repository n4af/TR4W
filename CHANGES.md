# TR4W Change Log

> TRLOG 4 Windows — Free Amateur Radio Contest Logging Application  
> Repository: [github.com/n4af/TR4W](https://github.com/n4af/TR4W)  
> Generated: 2026-03-19

## Contributors

| Handle | GitHub | Commits |
|--------|--------|---------|
| N4AF — Howie Hoyt | [@n4af](https://github.com/n4af) | 318 |
| NY4I — Tom Schaefer | [@ny4i](https://github.com/ny4i) | 362 |
| GM0GAV — Gavin Taylor | [@gm0gav](https://github.com/gm0gav) | 12 |
| K0TI — Dan | [@Dan-K0TI](https://github.com/Dan-K0TI) | 10 |
| Vojtěch Šádek | [@vksadek](https://github.com/vksadek) | 1 |

---

## 4.146.x — April 2026

### 4.146.4 (pending) — NY4I

#### Band Map — CTRL-END Focus Fix (`src/uBandmap.pas`, `src/MainUnit.pas`, `src/uMenu.pas`) — Issue #861

- **Fixed CTRL-END not moving cursor to band map on the second press.** Root cause: when the band map dialog is re-activated after losing focus, Win32's `DefDlgProc` fires a nested `SetFocus(BandMapListBox)` synchronously *inside* the outer `SetFocus` call from the CTRL-END handler. The outer `SetFocus` then sends `WM_KILLFOCUS` to the now-focused listbox, triggering `LBN_KILLFOCUS` → `KillFocus()` → `SetFocus(wh[mweCall])`, leaving focus on the call window. Fixed with a `BandMapSettingFocus` flag that causes `KillFocus` to exit early while CTRL-END is directing focus to the band map.
- **Restored Ctrl+End shortcut to move cursor to band map.** The `RC_CURSORINBM_HK` hotkey and its `menu_ctrl_cursorinbandmap` menu entry had been commented out since at least the initial 2014 commit with no documented reason. Re-enabled both. `T_MENU_ARRAY_SIZE` bumped from 175 to 176 to match.

#### POTA — Default CW Memories (`src/trdos/FCONTEST.PAS`)

- Added default F1 (`CQ POTA \ \`) and F2 (`CQ POTA CQ POTA \ \ FD`) CW memories and a default QSL message (`73 \ EE`) for the POTA contest type.

---

### 4.146.3 (2026-04-08) — N4AF

#### Michigan QSO Party — DC Added as Multiplier (`target/dom/michigan.dom`, `target/dom/dc.dom`, `target/dom/s51.dom`) — Issue #862

- **Added District of Columbia (DC) as a multiplier for Michigan stations** in the Michigan QSO Party, effective for the April 18, 2026 event. `michigan.dom` updated to reference `S51.DOM`; `dc.dom` and `s51.dom` added to the installer.

#### YCCC SO2R — CW Speed (`src/trdos/LogCW.pas`)

- Disabled `YCCCSetSpeed` call in the CW speed change handler to prevent speed commands from being sent to the YCCC SO2R box during keyer operation.

---

### 4.146.2 (2026-04-07) — NY4I

#### YCCC SO2R Box — OTRSP RX Control and Overlapped I/O (`src/uYCCCSO2R.pas`, `src/trdos/LOGSUBS2.PAS`, `src/uProcessCommand.pas`) — Issue #61

- **Rewrote serial I/O to use overlapped (`FILE_FLAG_OVERLAPPED`) mode** so `WriteFile` never blocks the main UI thread. A dedicated write thread drains the command queue via `WaitForMultipleObjects`.
- **Added `YCCCSetStereo()` and `YCCCSetRxMode()`** for independent RX antenna control per the OTRSP protocol.
- **Hooked `ToggleStereoPin`** to call `YCCCSetStereo` for stereo/mono RX switching.
- **Added `OTRSPCommand` procedure** in `LOGSUBS2.PAS` handling the `OTRSP=RX1`, `RX2`, `RXA`, `RXI`, and `STEREO` function key messages.
- **Registered `OTRSP` command** and five display-only help entries in `uProcessCommand.pas` commands list.

---

### 4.146.1 (2026-04-06) — NY4I

#### FlexRadio 6000 — Split, Alert Color, and UI Fixes (`uFlexRadio6000.pas`, `uNetRadioBase.pas`, `uRadioPolling.pas`, `MainUnit.pas`, `VC.pas`, `uCFG.pas`, `uOption.pas`, `LOGRADIO.PAS`, `tr4w.dpr`) — Issue #855

- **Fixed split indicator not clearing when SmartSDR closes slice 1.** Root cause: `in_use=0` push for slice 1 was not handled. Now clears split state and zeros VFO B frequency/band when slice 1 is deallocated.
- **Fixed VFO B showing VFO A's frequency when split is disabled.** When split was enabled externally from SmartSDR (`slice 0 tx=0` push), `FSlice0TX` was set to False. On subsequent split disable (`slice 1 tx=0`), only `FSlice1TX` was updated — leaving `FSlice0TX` stale and routing the `transmit freq=` push to VFO B. Fixed: when slice 1 loses TX, `FSlice0TX` is forced True (TX must be returning to slice 0).
- **Fixed VFO B frequency not preserved across split enable/disable.** `SetFrequency` for VFO B now always updates the internal VFO object first; if slice 1 doesn't exist yet, it exits early without sending. `Split(True)` applies the stored VFO B frequency when creating the new slice.
- **Added alert color when radio is disconnected or not operational.** The frequency and radio name windows change to the alert color when the radio is disconnected or when TCP is connected but no slices exist (SmartSDR running but no RX slice). `IsOperational` virtual property on `TNetRadioBase` allows `TFlexRadio6000` to distinguish these states. `RadioDisconnected` flag on `RadioObject` is set/cleared by the polling thread on state transitions only, avoiding redundant repaints.
- **Added ALERT COLOR to the colors configuration dialog** (`uOption.pas`, `uCFG.pas`, `VC.pas`). Defaults to red. Configurable via `ALERT COLOR = <color name>` in the `.cfg` file.
- **Fixed `-` key leaving a `-` in the call window after toggling split.** The `-` handler in `CallWindowKeyDownProc` fires on `WM_CHAR`. After the handler clears the call window, the same `WM_CHAR` event delivered the `-` to `KeyboardCallsignChar` which re-inserted it. Fixed with a `CallWindowCharConsumed` flag that causes `tr4w.dpr` to skip `KeyboardCallsignChar` for that message.
- **Fixed split warning (QuickDisplay) showing/hiding based on stale polling value.** `CallWindowChange` fired before `CurrentStatus.Split` was updated by the polling thread, causing the split warning to appear when turning split off and not appear when turning split on. Moved split warning display to `DisplayCurrentStatus` (`uRadioPolling.pas`), driven by confirmed state transitions (`PreviousStatus.Split` → `CurrentStatus.Split`). Removed the racy QD calls from `CallWindowChange`.

---

## 4.145.x — March 2026

### 4.145.5 (2026-03-22) — NY4I

#### Icom Network — VFO A/B Independent Display (`uRadioIcomBase.pas`, `uRadioPolling.pas`, `uNetRadioBase.pas`) — Issue #849

- **Fixed both VFOs showing wrong mode (DATA when plain USB/LSB was set).** Root cause: the `$26` (VFO B mode-only) response handler was reading `data[4]` (the filter byte, FIL1 = `$01`) as the data-mode flag instead of `data[3]` (the actual data-mode byte). The IC-7760 `$26` frame layout is `subCmd + mode + dataMode + filter`, not `subCmd + mode + filter + dataMode`. A filter value of FIL1 (`$01`) was being treated as "data mode D1 active", causing every mode on VFO B to display as DATA.
- **Fixed inactive VFO always queried as VFO B.** The `$01` (mode push) and `$04` (mode query) handlers always called `QueryVFOBMode` for the inactive VFO. When VFO B is the active/main VFO, the *inactive* VFO is A — the handler now picks `QueryVFOAMode` or `QueryVFOBMode` based on `FActiveVFO`.
- **Fixed `dataMode` field never updated in `$26` handler.** Handler set `vfo.Mode` but left `vfo.dataMode` stale, causing data-mode state to diverge from display mode. Now both fields are always updated together.
- **Added `FSupportsActiveVFOQuery` flag** to gate all `$07 $D2` (Main/Sub band selection) logic. Set `True` for IC-7600, IC-7610, IC-7760, IC-7850 (confirmed Main/Sub support); left `False` for IC-7300, IC-7300MK2, IC-705, IC-905, IC-7100 (VFO A/B only — no `$07 $D2`). IC-9700 deferred pending firmware polling workaround (issue #850).
- **`QueryVFOAMode` / `QueryVFOBMode` / `QueryActiveVFO`** virtual stubs added to `TNetRadioBase` (`uNetRadioBase.pas`) so the polling thread can call them without a concrete type reference.
- **Startup query order** in `uRadioPolling.pas`: `QueryActiveVFO` is now called first so `FActiveVFO` is known before VFO freq/mode queries begin.

#### Bug Fix — Obsolete HAMLIB Config Commands No Longer Show Blocking Dialog (`src/trdos/LogCfg.pas`)

Users who had `HAMLIB RIGCTLD PORT`, `HAMLIB RIGCTLD IP ADDRESS`, or `HAMLIB RIGCTLD RUN AT STARTUP` in their `.cfg` file (left over from when those parameters existed) were shown a blocking warning dialog at startup after those commands were removed in 4.145.4. These three commands are now silently ignored with a `WARN`-level log entry instead of a dialog.

---

### 4.145.4 (2026-03-21) — NY4I

#### Icom Network — Initial Frequency Display (`uRadioPolling.pas`, `uRadioIcomBase.pas`, `uIcomNetworkTransport.pas`, `uIcomNetworkTypes.pas`)

- Fixed frequency/mode display staying blank after connect. Root cause: the `OnInitialPollSeeding` WM_TIMER callback was registered on a thread that never pumps a Win32 message queue (the polling thread uses `Sleep()`), so it never fired. Replaced with direct queries (`QueryVFOAFrequency`, `QueryVFOBFrequency`, `QueryMode`, `PollRadioState`) issued by the polling thread the moment `IsConnected` first becomes true. The timer mechanism (`ICOM_TIMER_INITIAL_POLL`, `OnInitialPollSeeding`, `FOnInitialPoll`/`OnInitialPoll`) has been removed entirely.
- Frequency display is now blanked when the radio disconnects, so stale data is never shown.

#### HamLib — Remove Obsolete rigctld Configuration (`uCFG.pas`, `VC.pas`, `CFGDEF.PAS`, `tr4w.dpr`) — Issue #846

- Deleted `uRadioHamLib.pas` (the old rigctld-based `THamLib` class). All HamLib radio control now goes through `uRadioHamLibDirect.pas` (`THamLibDirect`) which links directly to `libhamlib-4.dll`. The file was already unreferenced — no factory, no polling thread, no `uses` clause pointed to it.
- Removed four obsolete config parameters: `HAMLIB PATH`, `HAMLIB RIGCTLD PORT`, `HAMLIB RIGCTLD IP ADDRESS`, `HAMLIB RIGCTLD RUN AT STARTUP`, along with their backing variables (`TR4W_HAMLIBPATH`, `TR4W_HAMLIBPORT`, `TR4W_HAMLIBIPADDRESS`, `TR4W_HAMLIBRUNRIGCTLD`) and defaults. `HAMLIB DEBUG` is retained as it applies to the DLL-based path.

---

### 4.145.3 (2026-03-19) — NY4I

#### Icom Network — CI-V Send Queue (`uRadioIcomBase.pas`)

- Introduced `TCIVSendThread` to serialize all outbound CI-V commands through a single thread with a 25 ms minimum inter-command delay. Prevents poll bursts and user actions from flooding the radio's CI-V input buffer (dropped commands, response corruption under load).
- Urgent queue (PTT, CW stop) is drained before normal queue entries.
- Normal queue depth capped at 50 entries as a safety backstop.

#### Icom Network — Dead-Radio Detection (`uIcomNetworkTransport.pas`, `uIcomNetworkTypes.pas`)

- Track timestamp of last inbound ping from the radio (`FLastPingReceived`).
- If fully connected and no ping received for 15 seconds, log a warning and disconnect; the polling thread then attempts to reconnect. This is the only reliable signal that a WiFi/network link has gone away (UDP is connectionless).

#### Bug Fixes

- **CW stop command for Icom network** — Was sending `$17 $01`; corrected to `$17 $FF` (closes issue on CWByCAT-ESC-fix branch). Updated in `uRadioIcomBase.pas` and all three Icom protocol docs.
- **GridFields multiplier tracking** (`uMults.pas`, `LOGDUPE.PAS`, `LOGSTUFF.PAS`) — `IsDmMult` now accepts a `DomMultType` parameter. For GridFields contests the comparison truncates the query to the 2-char field prefix and prefix-matches against stored 4-char grid keys, so any grid in the same field is correctly recognized as already worked. Full 4-char key retained in storage for Cabrillo export.
- **WSJT-X band/freq logging** (`uWSJTX.pas`, `MainUnit.pas`, `VC.pas`) — Use band and frequency from the WSJT-X ADIF record when TR4W has no radio connected; fall back to radio frequency only when WSJT-X omits them (closes issue #822). `GENERALQSO` now uses grid square from any ADIF source (WSJT-X does not always include `PROGRAMID`). `ExchString` falls back to `QTHString` when ADIF leaves it empty. MO QSO Party: fixed `ciMM` multi-mode flag.
- **Missouri QSO Party dom files** — `missouri.dom` and `missouri_cty.dom` were on disk but excluded by a `.gitignore` rule for `tr4w/target/`; fixed rule so `dom/` negation takes effect.

#### Repository / Build

- Added missing `arizona.dom`, `arizona_cty.dom`, and `brazil.dom` to `target/dom/` (were present in installer but not in git; exposed by prior `.gitignore` fix for `target/dom`).
- Added `PerlRegEx.pas`, `pcre.pas`, and precompiled `pcre/*.obj` files to `include/` so the build is fully self-contained.
- Moved `RadioFactoryTester.dpr` and compile scripts into `tr4w/test/` alongside the unit-test sources.
- Suppressed `.claude/` dirs and `*.pcap`/`*.pcapng` captures from git status noise.

---

### 4.145.2 (2026-03-16) — IcomNetwork branch — NY4I

#### Icom Network Radio Control (Ethernet / WiFi)

Full CI-V over Ethernet/WiFi support for Icom radios using the Icom Remote Utility protocol. This replaces the previous HamLib/rigctld approach for network-connected Icom radios with a native Delphi implementation that matches the wfview reference.

**Supported radios:** IC-705, IC-7100, IC-7300, IC-7300 MK2, IC-7600, IC-7610, IC-7760, IC-7850, IC-905, IC-9700

**Protocol implementation (`uIcomNetworkTransport.pas`):**
- 7-state machine: Disconnected → WaitingForHere → WaitingForReady → WaitingForLogin → Authenticated → StreamRequested → Connected
- Authenticated session management with login retry on stale sessions
- TX buffer + retransmit response (responds to radio's retransmit requests)
- Idle keepalive on control socket every 100 ms (matches wfview)
- Local IP auto-detection via WinSock UDP connect + getsockname
- Auth failure detection with immediate feedback (red "AUTH FAILED" on radio status line, beep)
- Shutdown hang fix: `SafeFreeSocket` runs Indy `.Free` on background thread with 500 ms timeout to avoid Indy destructor deadlock

**CI-V state management (`uRadioIcomBase.pas`):**
- Startup query sequence after `$19` response: frequency, mode, TX status, RIT, XIT, split, VFO B
- Transceive push handling: `$00` (VFO A freq), `$01` (mode), `$1A $06` (data mode queried after mode push)
- Polling only for states the radio does not push: RIT/XIT (`$21`), split (`$0F`), TX status (`$1C $00`) — 1 s interval
- CW speed encode/decode: 6–48 WPM ↔ 0–255 linear ↔ 2-byte BCD
- CW watchdog: 2 s timeout triggers CivOpen re-handshake

**IC-7760 specifics (`uRadioIcom7760.pas`):**
- CI-V address `$B2`, controller address `$E1`
- VFO B via extended `$25`/`$26` commands with sub-command byte `$01`
- Shared RIT/XIT offset; `$21 $01`/`$21 $02` sub-commands for RIT/XIT on/off

**SO2R fixes:**
- Per-instance timer dispatch via `GWL_USERDATA` (replaced dangerous `GTransportInstance` global)
- Radio label (`"Rig 1 IC-7760"`) in all transport log messages

#### Bug Fixes

- **IC-705 BandUp skips 4m band** — IC-705 has no 70 MHz band; sending that frequency causes the radio to reject it and revert to 6m. `TIcom705Radio.ToggleBand` now cycles 6m → 2m directly.
- **Radio/CAT dialog (ID 66) — HamLib checkbox hidden** — When TCP/IP + Icom is selected, USERNAME/PASSWORD fields were dynamically inserted over the "Use HamLib" checkbox, making it impossible to disable HamLib. Fix: expand the CAT group box height and shift the HamLib checkbox, CW/PTT group box, and all controls below down 56 px at `WM_INITDIALOG`.
- **Data mode flicker** — Polling `$04` (mode) every second was overwriting the DIGI sub-mode state. Fix: mode arrives via `$01` transceive push only; `$1A $06` is queried after each `$01` push.
- **Log4D level inheritance** — Removed explicit `logger.Level := All` from all 12 Icom units; debug level now flows from root logger via `UpdateDebugLogLevel` in `uCFG.pas`.

#### New Units & Tests

- `uIcomCIV.pas` — BCD encode/decode helpers for CI-V frequency/value conversion
- `uRadioBand.pas` — `TRadioBand` enumeration and band-edge frequency constants
- `uRadioIcom7100.pas` — IC-7100 implementation (CI-V address `$88`)
- `test/unit/uTestIcomCIV.pas` — 32 CI-V BCD unit tests
- `test/unit/uTestRadioBand.pas` — band/frequency mapping tests
- `test/unit/uTR4WTestFramework.pas` — lightweight DUnit-compatible test framework

#### Documentation

- `docs/ICOM_NETWORK_PROTOCOL_GUIDE.md` — Icom remote utility protocol internals
- `docs/ICOM_NEW_RADIO_IMPLEMENTATION.md` — how to add a new Icom network radio
- `docs/tr4w-migration-strategy.md` — phased Delphi 7 → Delphi 12 migration plan with testing strategy and dialog migration tracks

---

### 4.145.1 (2026-03-04)
- **UI:** Main window rounded corners (issue #834) — N4AF

### Contest Support
- **Colorado QSO Party** rules and scoring (issue #831) — N4AF
- **Indiana QSO Party (INQP)** support (issue #832) — N4AF

### Build & Installer
- **Fix missing `libgcc_s_dw2-1.dll` runtime error** on clean Windows installs — NY4I  
  HamLib 4.7.0 was built with MinGW DWARF-2 exception handling but the installer shipped the SJLJ variant from an older HamLib version. Replaced `libgcc_s_sjlj-1.dll` with `libgcc_s_dw2-1.dll` from official HamLib 4.7.0 w32 release.
- **Add NSIS installer script** with HamLib DLLs included — NY4I

### Bug Fixes (issues #827, #828, #830)
- Various fixes merged by N4AF

---

## Radio Factory & Icom Support — January–February 2026

This was a major development effort (primarily NY4I) introducing a modern factory pattern for radio control, Icom CI-V support, HamLib Direct DLL integration, and comprehensive reconnection logic.

### Radio Factory Pattern (PR #827, December 2025 – February 2026)

**Architecture — Factory Pattern for Radio Creation**
- New `uRadioFactory.pas` — centralized factory class for creating radio instances by model type
- New `uRadioManager.pas` — manager class for multiple simultaneous radio instances (SO2R / multi-op)
- New `TestRadioFactory.pas` — test/demo program
- Support for Elecraft K4 (network and serial), Icom (CI-V), HamLib Generic, and HamLib Direct
- Documentation: `NETWORK_RADIO_FACTORY_ANALYSIS.md`, `RADIO_FACTORY_README.md`

**Icom Radio Support — IC-7300, IC-7610, IC-9700 (2026-01-05 through 2026-01-08)**
- New `TIcomRadioBase` with full CI-V protocol implementation
- Radio-specific classes for IC-7300, IC-7610, and IC-9700 with correct CI-V addresses
- Icom radios enabled in factory pattern for both network and serial connections
- **IC-9700 startup optimization:** reduced frequency display delay from 17 seconds to ~1.6 seconds (38400 baud) or essentially immediate (115200 baud) by sending an immediate poll on connection
- **Serial reconnection after power cycle:** keeps serial port open during reconnection, polls during disconnected state to wake Icom radios. IC-9700 reconnects ~16 seconds after power cycle

**HamLib Direct DLL Integration (2025-12-29 through 2026-02-23)**
- New `uHamLibDirect.pas` — complete HamLib 4.x DLL wrapper with direct `GetProcAddress` calls
- New `uRadioHamLibDirect.pas` — `THamLibDirect` radio class using direct DLL communication
- Replaces rigctld-based HamLib approach for better performance and reliability
- Supports 200+ radio models via direct DLL without requiring rigctld daemon
- HamLib version logged at startup
- **HamLib updated from 4.6.5 to 4.7.0** (32-bit DLLs for Delphi 7 compatibility)

**Serial Port Support for K4 via Factory (2026-01-05)**
- New `uSerialPort.pas` — Win32 serial port wrapper (`CreateFile`/`ReadFile`/`WriteFile`)
- Configurable baud rate, data bits, parity, stop bits; non-blocking 10ms timeouts
- `TNetRadioBase` extended with dual-mode (serial + network) support
- K4 serial connections now use the same modern code path as network connections

**Radio Class Refactoring (2026-01-05)**
- Eliminated K4-suffixed methods (`SetModeK4` → `SetMode`) by adding default VFO parameters to base class
- New `uRadioInterfaces.pas` with interface definitions (`IRadioBasic`, `IRadioFrequency`, `IRadioMode`, `IRadioDualVFO`, etc.) for future capability-based architecture
- Fixed `EAbstractError` crashes when connecting K4 via native TCP

**Crash Fix & Automatic Reconnection (2025-12-29 through 2026-02-23)**
- Prevent crash when radio disconnects by removing blocking locks from I/O operations
- Exponential backoff reconnection (1s initial → 30s max, 2x multiplier)
- Connection state tracking (`wasConnected`, `consecutiveFailures`)
- Exception handling for `EIdNotConnected`, `EIdConnClosedGracefully`, `EIdConnectTimeout`, `EIdSocketError`
- Threads persist through failures, auto-reconnect when radio/logger returns
- **Reset Radio Ports fix:** clean thread teardown and K4 reconnect state — serial disconnect now terminates reading thread before `Free`, releasing COM port

### External Logger Factory (2025-12-29)
- New `uExternalLoggerFactory.pas` — factory class for logger creation (DXKeeper, ACLog, HRD)
- New `uExternalLoggerManager.pas` — manages multiple logger instances with `ConnectAll`, `LogQSOToAll`, `DeleteQSOFromAll`
- Same reconnection logic applied to external loggers for consistency

### Repository Cleanup (February 2026)
- Moved documentation to `docs/` folder
- Removed tracked `.dcu` build artifacts from `bin/` and `res/bin/`
- Updated `.gitignore` for build logs, rotated log files, and build output
- Added missing `uDXLabPathfinder.pas` source file (was causing build failures)
- Removed duplicate HamLib DLLs from `lib/hamlib` (already tracked in `target/`)
- Untracked `tr4wserver.dsk`
- Updated `CLAUDE.md` project documentation

---

## 4.141.x — January–October 2025

### 4.141.1 (2025-02-04)
- Added `uSuperCheckPartial` source to the project (PR #812) — NY4I

### 4.141.0 (2025-01-03)
- Master release — N4AF

### Contest Online Scoreboard (COSB)
- **Fix COSB integration** — local `tr4w.ini` configuration per COSB docs (issue #825) — N4AF
- **Online scoreboard** support (issue #823) — N4AF

### Radio Info Fix (2025-03-11)
- Fixed `EntryWindow` handle in RadioInfo UDP message — was not set to a number, causing downstream issues for external programs (PR #815) — NY4I

### Bug Fixes
- **Ensure at least one space after MyCall** for consistent output formatting (issue #813, PR #814) — Vojtěch Šádek
- Radio polling improvements (issue #815) — N4AF

---

## 4.140.x — December 2024

### 4.140.7 (2024-12-30)
- Bug fixes (issue #811) — N4AF

### 4.140.6 (2024-12-26)
- Bug fix (issue #809) — N4AF

### 4.140.5 (2024-12-23)
- Fixes (minus issue #800) — N4AF

### 4.140.1 (2024-12-21)
- **9A DX** contest support (issue #805) — N4AF

### 4.140.0 (2024-12-04)
- December build — N4AF

### Changes
- **Added IC-7760** radio support, based on IC-7610 (PR #809) — NY4I
- **Changed DI mode to DG** for Winter Field Day — WFD team changed their parser to conform to standard Cabrillo mode for digital contacts (PR #811) — NY4I
- **Fixed CW speed** following Kenwoods and Elecraft (PR #804) — NY4I
- **Added IC-7760 code** and RegEx maintenance — moved code into includes to ensure TPerlRegEx compiles with same version as pcre library (PR #796) — NY4I

---

## 4.139.x — November 2024

### 4.139.1 (2024-11-25)
- **Removed autofill of zones via `cty.dat`** — N4AF
- QSY now properly deletes call + exchange windows (issue #795) — N4AF
- Entered frequency fails to clear on QSY — fix — N4AF

---

## 4.138.x — October–November 2024

### 4.138.5 (2024-11-01)
- New `trmaster` and `cty.dat` data files — N4AF

### 4.138.4 (2024-10-31)
- Fixes for issues #786, #787, #788 — N4AF

### Contest Support
- **WAG IE** (issue #785) — N4AF

---

## 4.137.x — August 2024

### 4.137.2 (2024-08-29)
- Updated `uSuperCheckPartialFileUpload.dcu` compiled with new Indy version (PR #782) — NY4I
- Added Indy10 library — NY4I

### 4.137.1 (2024-08-15)
- **Arizona QSO Party** Cabrillo name update — N4AF

### 4.137 (2024-08-11)
- August 2024 release — N4AF

---

## 4.136.x — June–August 2024

### 4.136.3 (2024-08-06)
- Fix for issue #458 — N4AF

### 4.136.2 (2024-07-23)
- **LABRE-DX** contest support — N4AF
- **Arizona QSO Party** updates — N4AF

### 4.136.1 (2024-07-23)
- **LABRE** contest support — N4AF

### 4.136.0 (2024-06-05)
- June release — N4AF

---

## 4.135.x — April–May 2024

### 4.135.4 (2024-05-16)
- Fix for issue #765 — N4AF
- **Fix ADIF SUBMODE** — `SUBMODE` could incorrectly be set where not applicable due to stale temporary strings in `PostUnit` `ExportADIF` (PR #764) — NY4I
- `uSpots.pas` update (PR #765) — NY4I

### 4.135.3 (2024-05-10)
- ADIF submode fix (issue #763) — N4AF

### 4.135.2 (2024-05-05)
- Update `IN7QPNE_CTY` — N4AF

### 4.135.1 (2024-05-02–03)
- Fix for issue #762 — N4AF

### 4.134.2 (2024-04-29)
- Fix for issue #761 — N4AF
- **Updates for FQP and other QSO Parties** — DX multipliers for FQP, added Cabrillo names where different from string name, fixed `PostScore` bug (PR #761) — NY4I

---

## 4.133.x — April 2024

### 4.133.2 (2024-04-09)
- Fix for issue #757 — N4AF

### 4.133.1 (2024-04-07)
- **SO2R display** fix (issue #754) — N4AF

---

## 4.132.x — March–April 2024

### 4.132.4 (2024-04-03)
- New `trmaster` + `cty.dat` — N4AF

### 4.132.3 (2024-04-03)
- Fix for issue #753 — N4AF
- **Properly filled out `ismultiplier` fields** — were previously set to 0 (PR #753) — NY4I

### 4.132.2 (2024-03-30)
- Fix for issue #746 — N4AF

### 4.132.1 (2024-03-13)
- **Allow two-letter POTA codes** (issue #744) — N4AF
- Updated RegEx to support two-letter park codes (PR #744) — NY4I

---

## 4.131.x — January–March 2024

### 4.131.13 (2024-03-06)
- Fix for issue #742 — N4AF
- **Fixed Reset Ports** for networked K4 — also other items (PR #742) — NY4I

### 4.131.11 (2024-02-26)
- **Implemented commands to delete a contact** — sends `DeleteQSO` record on delete, delete-then-re-add on change (issue #738, PR #738) — NY4I

### 4.131.10 (2024-02-24)
- **Make external logger selectable** — framework for DXKeeper, ACLog, HRD; DXKeeper working, others stubbed (issue #734, PR #734) — NY4I

### 4.131.9 (2024-02-21)
- Fix for issue #733 — N4AF

### 4.131.5 (2024-02-06)
- **DARC-10M** contest changes (issue #712) — N4AF
- **OKOM** contest changes (issue #711) — N4AF

### 4.131.4 (2024-02-06)
- **ADIF export of myexchange** — code was missing in `PostUnit` (issue #725, PR #725) — NY4I

### 4.131.3 (2024-02-05)
- Fix for issue #702 — N4AF
- **Fix score posted to online scoreboard and UDP** (PR #724) — NY4I

### 4.131.1 (2024-02-03)
- FOC Marathon import `foc_num` fails — fix — N4AF

### Bug Fixes
- **Fix UDP port binding conflicts** — port was bound even when `WSJTXEnabled` was `false`, conflicting with JTAlert (PR #729) — NY4I
- **Fix VFOBumpUp/Down for Flex** — Flex doesn't support `UP;`/`DN;` commands; now adds/subtracts 20 Hz directly (issue #727, PR #728) — NY4I
- **FOC and WFL N1MM import** fix (PR #723) — NY4I
- **Added X-EXCHANGE for Winter Field Day** (closes #698, PR #721) — NY4I
- **Fix UDP contact port** — copy-paste error where `BroadcastPortLookup` was overwriting `ContactPort` (fixes #715, PR #720) — NY4I
- **External logger start and UDP fix for Node-RED dashboard** (closes #707, PR #714) — NY4I
- **SO2R BM only loads ALT-D** (issue #733) — N4AF

---

## 4.130.x — January 2024

### 4.130.1 (2024-01-06)
- `uSpots` — stop dupe check on match — N4AF

### 4.130 (2024-01-03)
- January 2024 master release — N4AF

---

## 4.129.x — December 2023

### 4.129.2 (2023-12-17)
- **9ADX** multipliers set wrong — fix — N4AF

### 4.129.1 (2023-12-12)
- Added `croat.dom` to build — N4AF

---

## 4.127.x — September–October 2023

### 4.127.5 (2023-10-28)
- Fix for issue #704 — N4AF

### 4.127.3 (2023-10-15)
- Fix for issue #688 — N4AF
- **Fixed UDP band issue** — NY4I

### 4.127.2 (2023-10-09)
- **PA QSO Party** rules added — N4AF

### 4.127.1 (2023-10-08)
- Fix for issue #700 — N4AF

---

## 4.126.x — August–September 2023

### 4.126.8 (2023-09-23–29)
- Fix `uSpots` (issue #697) — N4AF
- Fix hesitation calling station — N4AF

### 4.126.7 (2023-09-21)
- Fix for issue #696 — N4AF

### 4.126.6 (2023-09-16)
- Fix for issue #695 — N4AF

### 4.126.5 (2023-09-15)
- Fix for issue #694 — N4AF

### 4.126.4 (2023-09-14)
- Fix for issue #693 — N4AF
- **Add Icom address to rigctld parameters** — CIV address was missing (PR #693) — NY4I

### 4.126.3 (2023-09-12)
- Fix for issue #690 — N4AF

### 4.126.2 (2023-09-08–12)
- Fix BWQP — N4AF
- Fix for issue #690 — N4AF

### 4.126.1 (2023-09-06)
- Fix for issue #689 — N4AF

---

## 4.125.x — August 2023

### HamLib Support (PR #684 — Major Feature)

This was a significant upgrade adding HamLib support to TR4W. HamLib is the ham radio control library used by WSJT-X and many other programs, enabling automatic support for radios that HamLib supports.

### 4.125.4 (2023-08-26)
- Fix for issue #259 — N4AF

### 4.125.3 (2023-08-25)
- HamLib pass 3 — handle debug log level better (PR #686) — NY4I
- Add required HamLib DLLs — NY4I

### 4.125.2 (2023-08-23)
- HamLib pass 2 — fixed radio enumeration, rigctld starts minimized (PR #684) — NY4I
- Add Ctrl-J HamLib English helps — N4AF

### 4.125.1 (2023-08-22)
- **HamLib support initial release** — N4AF, NY4I
- Install HamLib files in target directory — NY4I
- Added 5 HamLib-related CFG parameters — NY4I
- Full HamLib commands and `get_vfo_info` processing — NY4I
- Changes to close rigctld at shutdown — NY4I
- Fix Orion frequency and mode — NY4I
- Fix exception in `SendToRadio` — NY4I

### Bug Fix
- **Fix ALT-M on Yaesu radios** (PR #682) — NY4I
- **Fix Yaesu serial CW** (issue #678, PR #679) — NY4I

### 4.125 (2023-08) — YO-DX-HF
- **YO-DX-HF** contest support (issue #687) — N4AF

---

## 4.124.x — July 2023

### Fixes after Field Day
- Fix WSJT-X mode logged as Data/RTTY instead of FT8/FT4 (issue #658) — NY4I
- Fix PlayMessage issue — NY4I
- Network parameter send safeguards — prevent disrupting remote config (PR #672) — NY4I
- Added OPERATOR field to edit dialog — all language resource files updated (closes #601, PR #669) — NY4I
- Fixed format statement `%` → `%s` in `ExchangeWindowChange` (fixes #657, PR #665) — NY4I
- TCP server for WSJT-X radio control can be turned off — NY4I
- NAQP-RTTY import now sets STATE properly — NY4I
- Importing N1MM logs for various contest types — NY4I

---

## 4.123.x — May 2023

### POTA Support (PR #647)
- Fixed ADIF file for POTA — NY4I
- New `TF` format for 5 `PChar` parameters — NY4I
- Allow blank exchange for POTA (default RST, no park) — NY4I
- Changed directory name for POTA log — NY4I

### Czech Dialog Fix
- Restored missing TCP/IP options in Czech radio dialog (PR #650) — NY4I

---

## 4.122.x — March 2023

- Added Kenwood and Yaesu radio commands — NY4I
- Added commands to stop playing message on ESC (closes #640, #639, PR #642) — NY4I
- **Fixed WFD import** and SRS commands for network (closes #635, #637, PR #638) — NY4I

---

## 4.121.x — January 2023

- **Fix:** Close logfile after UDP command — was preventing subsequent contacts from saving (PR #634) — NY4I

---

## 4.120.x — December 2022

- Added M class and MX section for Mexico (PR #630) — NY4I
- Changed ADIF name to WFD — NY4I
- Fixed `LooksLikeAGrid` in TREE — NY4I

---

## 4.114.x — August 2022

- Fix for issue #614 (PR #615) — N4AF

---

## 4.111.x — May–June 2022

### UDP Port Improvements (PR #591)
- **Separate UDP ports** for App, Contact, Radio, and Score — NY4I

### Bug Fixes
- **Added grid-locator to Cabrillo header** (closes #599, PR #600) — NY4I
- Cleared Cabrillo exchange fields before each contact write — random data was appearing — NY4I
- Fixed ADIF parser for gridsquare in `MainUnit` (PR #598) — NY4I
- Added confirmation dialog after Cabrillo upload or on error (fixes #592, PR #593) — NY4I
- June `cty.dat` and `trmaster` update — N4AF

---

## Earlier History (2014–2022)

The repository was first committed on April 25, 2014 at version 4.30.3 by Howard Hoyt (N4AF). The project has been continuously developed since then, with NY4I (Tom Schaefer) joining as a major contributor. Over the project's life, it has grown from a basic contest logger to a full-featured application supporting dozens of contests, multiple radio protocols, HamLib integration, external loggers, WSJT-X digital mode integration, online scoreboards, and POTA/QSO Party support.

---

*This changelog was generated from the Git commit history of the [n4af/TR4W](https://github.com/n4af/TR4W) repository on March 19, 2026.*
