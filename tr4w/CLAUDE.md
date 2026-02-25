# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TR4W is a Windows-based ham radio contest logging application written in Delphi/Pascal (Delphi 7). It supports multi-station networking, various radio interfaces, CW/digital modes, and integration with external applications like WSJT-X and DXKeeper.

**Current Version:** 4.143.2 (October 2025)
**License:** GPL v2+

## Building the Project

### Compilation
Use the provided batch script to compile:
```bash
BatchCompile.cmd
```

This script uses Delphi 7's command-line compiler (DCC32.EXE):
- Main project file: `tr4w.dpr`
- Output directory: `target/`
- Temp directory: `C:\Temp`
- Dependencies: Indy library components (networking)

**Note:** The BatchCompile.cmd script has hardcoded paths that may need adjustment for your environment.

### Language Variants
The project supports multiple languages controlled by the `LANG` compiler directive:
- ENG (English), RUS (Russian), SER (Serbian), ESP (Spanish), MNG (Mongolian), POL (Polish), CZE (Czech), ROM (Romanian), CHN (Chinese), GER (German), UKR (Ukrainian)

Language-specific resources are loaded from `res/tr4w_{lang}.res`

**Note:** To build for a different language, the `LANG` compiler directive must be set appropriately in the project options or build script.

## Architecture

### Directory Structure
- `src/` - Main source code
  - `src/trdos/` - Legacy TR-DOS code (original TR Log codebase from DOS era)
  - `src/utils/` - Utility modules (networking, text, file, math operations)
- `tr4wserver/` - Multi-station server component (separate .dpr file)
- `res/` - Resources (icons, language-specific .res files)
- `include/` - Third-party includes (WinSock2)
- `target/` - Build output (.exe files)
- `build/` - Build scripts
- `settings/` - Runtime configuration (tr4w.ini)

### Core Subsystems

#### 1. Radio Control (`src/trdos/LogRadio.pas`, `src/uRadio*.pas`)
- **Factory Pattern:** `uRadioFactory.pas` - Centralized radio instance creation
- **Base Class:** `uNetRadioBase.pas` - Abstract base for network-connected radios
- **Implementations:**
  - `uRadioElecraftK4.pas` - Elecraft K4 support (fully implemented)
  - `uRadioHamLib.pas` - HamLib generic radio support (fully implemented)
  - `uRadioIcomBase.pas` - Icom CI-V protocol base class
  - `uRadioIcom7300.pas`, `uRadioIcom7610.pas`, `uRadioIcom9700.pas` - Icom radios (implemented)
  - Planned: K3, Yaesu FTdx101, FT-991, FlexRadio 6000
- **Threading:** Each radio instance runs its own reading thread (`TReadingThread`)
- **Reconnection:** Implements exponential backoff reconnection logic (1s → 30s max)

#### 2. External Logger Integration (`src/uExternalLogger*.pas`)
- **Factory Pattern:** `uExternalLoggerFactory.pas` - Centralized logger instance creation
- **Base Class:** `uExternalLoggerBase.pas` - Abstract base for external loggers
- **Implementations:**
  - DXKeeper (fully implemented)
  - ACLog (partial)
  - Ham Radio Deluxe/HRD (partial)
- **Threading:** Each logger runs its own thread for communication

#### 3. Configuration System (`src/uCFG.pas`, `src/trdos/CfgCmd.pas`)
- Two-tier config: INI file (`settings/tr4w.ini`) + contest-specific CFG files
- Command processing through CFGRecord structures
- Configuration commands can be read-only, editable, or editable with restart
- Network synchronization support for multi-station setups

#### 4. Networking (`src/uNet.pas`, `src/trdos/LogNet.pas`)
- Multi-station contest support
- Network message utilities in `src/utils/NetworkMessageUtils.pas`
- Telnet support in `uTelnet.pas`
- Uses Indy components (IdTCPClient, IdUDPClient, etc.)

#### 5. Contest Logging & QSO Database (`src/trdos/Log*.pas`)
- Core contest logging: `LogStuff.pas`, `LogGrid.pas`, `LogEdit.pas`
- Contest-specific modules: `LogWAE.pas` (WAE), `LogDom.pas` (Domestic), `LogK1EA.pas`
- Dupe checking: `LogDupe.pas`
- SCP (Super Check Partial): `LogSCP.pas` - callsign database lookup
- Master database: `trmaster.dta` - Super Check Partial callsign database
- Country/zone data: `uCTYDAT.pas` (loads cty.dat file)
- SO2R support: Two-radio operations for advanced contesting

#### 6. CW/Keying & CAT Control
- **CW Keying:** `src/trdos/LogCW.pas`, `src/uWinKey.pas`
- WinKey support with dedicated thread
- DVP (Digital Voice Player) support: `src/trdos/LOGDVP.pas`
- Paddle input handling
- CW message memories and function keys
- **CAT Control:** `src/uCAT.pas` - Computer-aided transceiver control (legacy serial/CAT interface)
- **Distinction:** CAT control (`uCAT.pas`) handles legacy serial radios; network radios use the new factory pattern (`uRadioFactory.pas`)

#### 7. External Integrations
- **WSJT-X:** `uWSJTX.pas` - UDP protocol, colorization support
- **MMTTY:** `uMMTTY.pas` - RTTY mode support
- **MixW:** `uMixW.pas` - Digital mode integration

#### 8. Logging Framework
- Uses Log4D (`src/Log4D.pas`) for debug logging
- Logger instance: `TLogLogger` configured at startup
- Log levels: Trace, Debug, Info, Warn, Error, Fatal
- Configured via `DEBUG LOG LEVEL` in tr4w.ini
- Log file: `tr4w.log` (rolling file appender)

### Threading Model
Multiple background threads handle I/O operations:
- Radio polling/communication threads (per radio)
- External logger threads (per logger)
- WinKey keyer thread
- Network send/receive threads
- CW/DVP playback threads

Event synchronization uses Windows events created in inline assembly (see tr4w.dpr lines 555-575):
- `tCW_Event` - CW keying
- `tCWPaddle_Event` - Paddle input
- `tDVP_Event` - DVP playback
- `tNet_Event` - Network operations

### Main Window & UI (`src/MainUnit.pas`)
- Custom window class with manual Windows API calls (no VCL forms)
- Main message loop in `tr4w.dpr` (lines 658-856)
- Window manager: `uWinManager.pas`
- Dialog utilities: `uDialogs.pas`
- Bandmap: `uBandmap.pas`

### Key Global Variables (defined in MainUnit.pas)
- `wsjtx: TWSJTXServer` - WSJT-X integration instance
- `externalLogger: TExternalLogger` - External logger instance
- `logger: TLogLogger` - Log4D logger instance

## Configuration Files

### Runtime Configuration
- `settings/tr4w.ini` - Main configuration (DEBUG LOG LEVEL, LATEST CONFIG FILE, etc.)
- Contest CFG files - Contest-specific settings
- `cty.dat` - Country database (loaded from `TR4W_CTY_FILENAME`)

### Important Startup Sequence (tr4w.dpr)
1. Initialize logging (Log4D) - lines 324-341
2. Create mutex to prevent multiple instances - lines 346-356
3. Load configuration files (INI → CFG → common messages) - lines 443-447
4. Initialize WSJT-X if enabled - lines 448-451
5. Initialize external logger if enabled - lines 452-457
6. Load country database (cty.dat) - lines 431-436
7. Create main window and UI - line 521
8. Initialize WinKey thread if enabled - lines 589-594
9. Enter main message loop - line 658

## Common Patterns

### Factory Pattern Usage
When adding new radio or logger support:
1. Create new class inheriting from `TNetRadioBase` or `TExternalLoggerBase`
2. Add model/type to the enum in factory class
3. Implement factory creation method
4. Update `IsModelSupported` / `IsLoggerSupported`

### Thread Safety
- Radio/logger threads communicate via callbacks: `TProcessMsgRef`
- Use proper synchronization when accessing UI from threads
- Radio disconnection is handled gracefully with `radioWasDisconnected` flag

### Error Handling
- Extensive use of Log4D for debugging
- Custom exception types: `ERadioFactoryException`, `EExternalLoggerFactoryException`
- ShowMessage/MessageBox for user-facing errors

## Testing

Test files exist but are minimal:
- `src/TestRadioFactory.pas` - Radio factory tests
- `src/TestExternalLoggerFactory.pas` - External logger factory tests

No automated test framework is currently in place.

## Common Issues & Solutions

### Compilation Errors
- **Missing Indy exception types:** If you see `Undeclared identifier: 'EIdConnClosedGracefully'` or `'EIdSocketError'`, add `IdException, IdStack` to the uses clause
- **Missing Indy units:** Ensure the Indy library paths are correctly set in BatchCompile.cmd

## Important Notes

- This is a legacy Delphi 7 codebase with roots in the DOS-era TR Log
- `src/trdos/` contains the original TR-DOS Pascal code (heavy use of global variables and procedural programming)
- Modern OOP patterns (factories, base classes) are being introduced gradually (see recent commits on `feature/radio-factory` branch)
- The codebase uses inline assembly in a few places (thread event creation, low-level I/O)
- Heavy use of Windows API directly (no VCL forms, manual window creation)
- Configuration uses a custom command parser, not standard INI libraries for CFG files
- **Dual radio interfaces:** Legacy serial radios use `uCAT.pas`; modern network radios use the factory pattern (`uRadioFactory.pas`, `uNetRadioBase.pas`)

