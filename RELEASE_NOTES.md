# TR4W Release Notes

**TR4W (TRLOG 4 Windows)** is a free, open-source contest logging application for amateur radio operators running Windows. It supports CW, SSB, and digital modes; dozens of contests from ARRL events to QSO Parties and DX contests; rig control for a wide range of transceivers; POTA (Parks on the Air) activations; DX cluster/band map; WSJT-X/FT8 integration; SO2R; networked multi-op; and much more.

This is the user-facing changelog — it covers what changed, what was fixed, and what's new in each release. Technical implementation details have been trimmed so you can quickly find what matters to you on the air.

---

## Contributors

| Call | GitHub | Commits |
|--------|--------|---------|
| N4AF — Howie Hoyt | [@n4af](https://github.com/n4af) | 734 |
| NY4I — Tom Schaefer | [@ny4i](https://github.com/ny4i) | 394 |
| GM0GAV — Gavin Taylor | [@gm0gav](https://github.com/gm0gav) | 12 |
| K0TI — Dan | [@Dan-K0TI](https://github.com/Dan-K0TI) | 8 |
| Vojtěch Šádek | [@vksadek](https://github.com/vksadek) | 1 |
| Dmitriy Gulyaev UA4WLI | | (Original Author of Win32 Port / Pre-GitHub)|
| N6TR - Tree | [@n6tr](https://github.com/n6tr) | (Original TRLOG (DOS) Author) |

Various contributors along the way

---

## 4.147.x — May 2026

### 4.147.07 (2026-05-14) — NY4I / N4AF

#### New Contest

- **RTC — Real-Time Contest**: a 4-hour mixed-mode (CW + SSB) HF event sponsored by contestonlinescore.com. Exchange is serial number + 4-character Maidenhead grid; scoring is distance-based between grid centers with tiers of 1, 2, 3, or 4 points. TR4W prompts for your 4-character grid when you start a new RTC contest, fills your function-key messages with the rules-spec format, and disables the WARC bands automatically. Note: 160 m, 80 m, and digital modes still let you tune and log, but score 0 and don't count as multipliers per RTC rules.

#### UDP Broadcasts (N1MM-compatible)

- **WARC bands now report the correct MHz label**: prior versions sent meter-band labels (`30` / `17` / `12`) for QSOs on 30 m, 17 m, and 12 m, while every other band reported MHz (`14`, `21`, `28`, etc.). Spotting and scoring tools (N1MM, DXLog, COS) that key off the MHz value were silently dropping every WARC QSO. WARC bands now correctly report `10`, `18`, `24`.
- **X-QSO tag is well-formed XML**: the `<IsClaimedQso>` UDP field's closing tag was case-mismatched in 4.147.06, which strict XML consumers reject. The tag is now correctly closed.

#### Cabrillo / ADIF Export

- **No more garbage characters after short grids**: when your `MY GRID` was 4 characters (e.g. `EL88`), the Cabrillo file and the ADIF `<MyGrid>` field could include random non-printable characters after the grid (uninitialized memory leaking into the output). Affects RTC and any other contest using a 4-character grid. Now correctly terminated; re-export an affected log after upgrading to clean it up.

---

### 4.147.06 (2026-05-13) — NY4I / N4AF

#### Logging — X-QSO Support

- **Mark a QSO as X-QSO**: an X-QSO record stays in your log for NIL-protection purposes (so the other station gets credit if their log is checked against yours) but contributes nothing to YOUR score — no QSO count, no multipliers, no points, no presence in the dupe sheet.
- **How to use**: open the QSO in the edit dialog, tick the X-QSO checkbox after the S&P checkbox. The row is grayed out in the log view so you can see at a glance which contacts are excluded.
- **What it does to exports**:
  - **Cabrillo**: emits `X-QSO:` instead of `QSO:` for that record (per Cabrillo spec).
  - **ADIF**: tags the record so other software knows it's not claimed. TR4W's ADIF import also recognizes the equivalent fields from N1MM+ and DXLog.net, so X-QSO survives round-trips between loggers.
- **Toggle off and rescore** restores the QSO's points based on the normal contest rules.
- **All 11 languages supported**.

#### Log View

- **Column auto-fit on double-click survives restart**: when you double-click the right edge of a column header in the editable log to auto-fit, TR4W now adds a small padding so the content stays fully visible across restarts. Previously, columns auto-fit just barely wide enough would lose a character or two on restart (e.g. `14046.00` becoming `14046...`).
- Manual drag is unchanged — whatever width you drag to is what gets saved.

#### WSJT-X / FT8

- **Cleaner debug log for no-multiplier contests**: ARRL Digital, CQ WPX Digital, and similar QSO-count-only contests no longer generate misleading "Checking if grid X is a multiplier" log lines in `tr4w.log`. No functional change; only the spurious log noise is gone.

---

### 4.147.05 (2026-05-12) — NY4I / N4AF

#### Radio Control

- **K4 over network — connection no longer drops during idle periods**: K4 radios in remote/host mode drops a client that sends nothing for 10 seconds. TR4W's K4 network mode used to sit silent during operator idle periods and would silently lose the connection. TR4W now sends a `PING;` once per second over the network connection to keep it alive. Serial mode is unchanged.

#### ADIF Import/Export

- **Field Day, Sweepstakes, and similar no-RST contests no longer get a bogus `59` in `<SRX_STRING>`**: an earlier fix to add implied RST to state QSO party exchanges was incorrectly applied to contests whose exchanges have no RST. Field Day export was emitting `<SRX_STRING:9>59 1D WCF` with a bogus leading `59`. Each contest now picks the right shape — RST contests still get the implied `599`, non-RST contests get just the exchange.
- **No more `<SRX:5>000-1` garbage in ADIF**: for contests where the received-serial field is unused (e.g. Field Day), the ADIF export was emitting `<SRX:5>000-1` — a malformed numeric field. Export now correctly skips SRX (and symmetrically STX) when no serial was received.

---

### 4.147.04 (2026-05-12) — NY4I / N4AF

#### ADIF Import/Export

- **CQ zone now imported correctly**: importing an ADIF that contained a `<CQZ>` field used to silently drop the CQ zone on every QSO. The CQ zone is now read correctly on import — fixes silent data loss for CQ WW and similar zone-based contests when round-tripping through ADIF.
- **Records without a mode are no longer marked as CW**: importing an ADIF whose records did not include a `<MODE>` field used to silently set every such record to CW. Those records are now imported with no mode set, so incomplete records show up as incomplete and can be reviewed and corrected rather than being misclassified.

---

### 4.147.02 (2026-05-10) — NY4I / N4AF

#### State QSO Party Rover Operations

- **Rover calls (e.g. `KG1S/MON`)**: when a rover sends their call with a `/county` suffix, TR4W now preserves the full callsign in the log and Cabrillo. The county is automatically pre-filled into the exchange when you press Enter so you don't have to retype it.
- **Country lookup**: rover calls like `AF4O/MON` are no longer mislabeled as Great Britain (the `/M` was being read as a GB prefix). This is fixed for entry, import, and rescore.
- **County-line QSOs**: when you log a county-line station (e.g. `PIN/HIL`), the second county is no longer flagged as a duplicate and no longer scores zero points. Both records also share the single transmitted serial number, matching CQ Magazine guidance for the California QSO Party.

#### ADIF Import/Export

- **ADIF STATE field**: for state QSO parties, the STATE field now correctly reports the contest's host state (e.g. `FL` for FQP) when the QTHString is a county code instead of incorrectly emitting the county as the state. Supported for CA, FL, MI, MN, MO, NC, OH, TX, WI, TN, CO, PA, IN.
- **ADIF CNTY field**: state-and-county is now emitted as `<state>,<long-name>` (e.g. `CA,Alameda`) when the long county name is available in the dom file. Currently emitted for CA, MO, OH, PA, WI, IL, TX, MI. FL and TN ship `_cty.dom` files without long names, so CNTY is skipped for those states.
- **Rover call round-trip**: ADIF export records the bare call (`KG1S`) in the standard `<CALL>` field plus the full rover form (`KG1S/MON`) in a TR4W-specific `<APP_TR4W_ROVERCALL>` field. ADIF import recognizes that field and restores the full call.
- **SRX_STRING consistency**: the received-exchange field now always includes the implied RST (e.g. `599 HIL`) regardless of whether you typed it, so it matches the sent-exchange field in CW contests where 599 is implied.
- **Import for state QPs**: importing an ADIF now correctly repopulates county multipliers — verified with California QSO Party and Florida QSO Party.

#### Multi-County / Multi-Park Entry

- **One Enter, N QSOs**: a single Enter press logs one QSO per ref for multi-county and multi-park exchanges.
- **Per-QSO exchange string**: each follow-up record in a multi-county or multi-park entry carries its own SRX_STRING with only its own ref, not the combined operator input.

#### WinKeyer

- **WK3 hardware**: the WinKeyer status field at the bottom of the screen now shows `WK3` for K1EL WinKeyer3 hardware (previously showed `WK2`).
- **COM port error message**: when the COM port for your WinKeyer can't be opened, the error dialog now shows a readable Windows error message instead of garbage characters.

#### Multi-Op / Networking

- **Operator visible in network window**: the network window now shows the active operator's name for each connected station.
- **Score posting over HTTPS**: TR4W can now post scores to score-tracking sites that require HTTPS (Issue #26).
- **Cleaner connect-retry log**: repeated connection retry messages are now logged once per state change instead of once per retry, making the log easier to read when a remote is briefly unavailable.

#### Programmable Messages

- **Double-click to insert at cursor**: in the message editor, double-clicking a command in the command list now inserts the command at the cursor position rather than replacing the whole field.

#### New Contest Setup

- **Clean overwrite**: creating a new contest with the same name as an existing one now removes the old log file as part of the overwrite, so stale records don't bleed into the new log.

---

## 4.146.x — April 2026

### 4.146.14 (2026-04-17) — NY4I

#### POTA Support

- POTA exchanges are now fully free-form — you can type a state, ARRL section, operator name, or any combination and TR4W will figure it out. Exchanges that previously couldn't be saved will now log correctly.
- TR4W now correctly identifies park references (e.g. US-1234 or K-0001), so RST values and other non-park text are no longer mistaken for park numbers.
- Operator name recognition now uses a database of about 1,300 known ham names, giving much more reliable name detection than before.
- Grid squares typed in a POTA exchange are now recognized correctly.

#### POTA ADIF Import/Export

- ADIF export now writes the standard POTA_REF field (in addition to SIG/SIG_INFO), improving compatibility with POTA upload tools and other logging software.
- ADIF import now reads POTA_REF, SIG/SIG_INFO, and several other POTA-related fields from files generated by N1MM+ and other loggers.
- Each QSO is now assigned a unique identifier in the ADIF, which helps with duplicate checking when importing logs from multiple sources.

---

### 4.146.13 (2026-04-17) — NY4I

#### Radio Control

- Added native support for the **Yaesu FTX-1F** transceiver, including C4FM voice modes.

#### Usability

- If you try to open a log file that was saved by a newer version of TR4W, you'll now get a clear error message explaining the situation, rather than a confusing offer to downgrade the log.

---

### 4.146.12 (2026-04-16) — NY4I

#### Log Format

- Each QSO now has a unique ID stored in the log. This improves duplicate detection when editing QSOs in networked or multi-op setups, and makes ADIF exports more compatible with tools like LOTW and Club Log.
- When editing a QSO in a networked session, the corrected QSO is now properly broadcast to other stations on the network.

#### Windows Compatibility

- TR4W now correctly identifies Windows 11 versions (including 24H2/25H2) in its debug log, which helps when reporting problems.

#### Network Logging

- Debug log now shows the server address and thread activity when connecting in multi-op mode, making it easier to diagnose connection issues.

---

### 4.146.11 (2026-04-14) — NY4I

#### CTY.DAT Auto-Update

- TR4W now checks for a newer version of the country data file (CTY.DAT) in the background when it starts up, and shows a hint if an update is available.
- Press **Alt+O** to download and install the latest CTY.DAT without restarting the program.
- You can disable the startup check by adding `CTY UPDATE CHECK ON STARTUP = FALSE` to your config file.

---

### 4.146.10 (2026-04-14) — NY4I

#### Bug Fixes

- Fixed a band map display bug where double-clicking a spot with "QSY Inactive Radio" enabled could show a garbled or combined callsign (e.g. DF9II appearing as DF9IIA3CNO). The callsign buffer is now properly cleared before loading the new call.
- Added detailed CW trace logging to help diagnose an intermittent extra space appearing in sent CW messages. (If you've been seeing this, enable trace logging and send the log to the developers.)

---

### 4.146.7 / 4.146.8 (2026-04-13) — NY4I

#### Band Map Improvements

- Eliminated the flickering/flashing that occurred in the band map when spots arrived rapidly or when tuning the VFO. The band map now redraws smoothly.
- Deleting a spot now removes it from the band map immediately, instead of leaving it visible until the next spot arrival.

#### Radio Control

- **Elecraft K4:** VFO frequency now updates at the configured poll rate (default 10 ms) instead of once per second — the display is now as responsive as the K3.
- **Elecraft K3/K4:** TR4W now shuts down the radio polling thread quickly on exit, instead of waiting up to 3 seconds.
- **Icom IC-7760 (and similar):** VFO B mode/frequency commands now use the correct extended command, matching the behavior of serial-connected radios.
- **DX Cluster:** Fixed a false "split" detection that was triggered by spot comments containing the word "up" as part of another word (e.g. "Pup Emma"). Split detection is now more precise.

---

### 4.146.6 (2026-04-12) — NY4I

#### UI Improvements

- Fixed the QTH/exchange column in the log view being too narrow at startup — columns now auto-size to fit the data, not just the column header.
- Column widths you manually adjust are now remembered across sessions.

#### HamLib / Radio Control

- Improved the HamLib polling cycle to match the approach used by WSJT-X: fewer commands are sent in the fast heartbeat, which prevents menu interference on Icom IC-7610 and IC-7760.
- RIT/XIT on/off state is now read accurately — TR4W no longer shows RIT as active when the IC-7610 has a stored offset but RIT is actually off.
- Added a `HAMLIB TRACE = TRUE` config option that redirects HamLib's internal debug output to `hamlib_trace.log` — useful for diagnosing rig control issues.
- The CAT setup dialog now warns you if you select HamLib for a radio that has native TR4W support, noting the RIT/XIT limitation.
- Added native **Elecraft KX3** support (Kenwood protocol, 38400 baud).

---

### 4.146.5 (2026-04-11) — NY4I

#### POTA — Full Feature Set

- Park names are now automatically fetched from the POTA API and displayed alongside the park reference as you log QSOs.
- Park references are normalized to standard format (e.g. K-1234) before saving and ADIF export.
- **Multi-park (2fer/3fer/Nfer) support:** enter multiple park references in one exchange and TR4W automatically logs a separate QSO for each park. The status display now correctly shows "3fer", "4fer", etc. based on the actual number of parks.
- **Ctrl+T (Repeat Parks):** new shortcut pre-fills the exchange with your last-logged park references, so a second operator can work the same activation without re-typing anything.
- The POTA menu is now hidden entirely when you're not in a POTA contest (no more grayed-out POTA items cluttering other contests).
- Fixed the QTH field incorrectly showing an RST value.
- Fixed exchange acceptance issues in certain conditions.

#### Radio Control

- Fixed SO2R RIT Up/Down commands — they now correctly go to the active radio instead of always going to Radio 1.
- Fixed FlexRadio RIT getting stuck after the first bump.

---

### 4.146.4 (2026-04-09) — NY4I

#### Bug Fixes

- Fixed **Ctrl+End** not reliably moving the cursor to the band map on the second press. You can now use Ctrl+End consistently to jump to the band map.
- Added default CW memories for POTA: F1 sends a CQ POTA call, F2 sends a full CQ message, and a default QSL message is included.

---

### 4.146.3 (2026-04-08) — N4AF

#### New Contests / Contest Updates

- **Michigan QSO Party:** the District of Columbia (DC) is now a valid multiplier for Michigan stations, effective for the April 2026 event.

#### Bug Fix

- Fixed a YCCC SO2R box issue where CW speed change commands were incorrectly being sent to the SO2R box.

---

### 4.146.2 (2026-04-07) — NY4I

#### YCCC SO2R Box

- Rewrote the serial communication with the YCCC SO2R box so commands no longer block the UI. Commands are now sent on a background thread.
- Added OTRSP support for independent RX antenna control: you can now control RX1/RX2/stereo switching via OTRSP function key commands.

---

### 4.146.1 (2026-04-06) — NY4I

#### FlexRadio 6000 / SmartSDR Improvements

- Fixed the split indicator not clearing when SmartSDR closes a slice.
- Fixed VFO B showing VFO A's frequency when split is disabled.
- Fixed VFO B frequency not being preserved when toggling split on and off.
- The frequency display and radio name now turn an alert color (red by default) when the radio is disconnected or when SmartSDR is running but no receive slice exists. The alert color is configurable via `ALERT COLOR` in your config file.
- Fixed the minus key leaving a stray dash in the call window after toggling split.
- Fixed the split warning in the status display appearing/disappearing at the wrong times.

---

## 4.145.x — March 2026

### 4.145.5 (2026-03-22) — NY4I

#### Icom Network Radio Control

- Fixed both VFOs displaying the wrong mode (showing DATA when plain USB/LSB was set) on the IC-7760 and similar radios.
- Fixed the inactive VFO always being queried as VFO B — now TR4W correctly determines which VFO is active and queries the right one.
- Added the IC-7600, IC-7610, IC-7760, and IC-7850 to the list of radios that support independent Main/Sub band selection queries. IC-7300, IC-705, IC-7100, IC-905 use standard VFO A/B queries only.

#### Bug Fix

- Fixed a blocking startup warning dialog that appeared for users who had old, now-removed HamLib config parameters left in their config file. These old settings are now silently ignored.

---

### 4.145.4 (2026-03-21) — NY4I

#### Icom Network Radio Control

- Fixed the frequency and mode display staying blank after connecting to an Icom radio over the network. Frequency and mode are now queried immediately on connection.
- The frequency display is now blanked when the radio disconnects, so you no longer see stale data.

#### HamLib

- Removed the old rigctld-based HamLib option. All HamLib radio control now goes through the direct DLL interface introduced in the January–February 2026 update, which is faster and more reliable.
- Removed four obsolete config parameters related to the old rigctld path.

---

### 4.145.3 (2026-03-19) — NY4I

#### Icom Network Radio Control

- Outbound CI-V commands are now sent through a queued thread with a minimum delay between commands. This prevents TR4W from flooding the radio's input buffer when polling and user actions overlap — eliminating dropped commands and garbled responses.
- PTT and CW-stop commands are prioritized in the queue so they always go out first.
- TR4W now detects when the network link to an Icom radio has gone silent (no ping for 15 seconds) and automatically disconnects and reconnects. This catches WiFi/network dropouts that UDP connections can't otherwise detect.
- Fixed the CW stop command sent over CI-V network — the wrong value was being sent.

#### Contest Support

- **GridFields contests:** multiplier tracking now correctly recognizes any grid in the same field as already worked, while still storing the full 4-character grid for Cabrillo export.

#### WSJT-X Integration

- When TR4W has no radio connected, it now uses the band and frequency from the WSJT-X ADIF record for logging, instead of leaving it blank. Falls back to the radio frequency only when WSJT-X omits it.
- Missouri QSO Party multi-mode flag fixed.

---

### 4.145.2 (2026-03-16) — NY4I

#### Icom Network Radio Control (Ethernet / WiFi)

This is a major new feature: full native CI-V over Ethernet/WiFi for Icom radios, replacing the previous HamLib/rigctld approach. TR4W now speaks the Icom Remote Utility protocol directly, giving you faster and more reliable rig control without needing any third-party software.

**Supported radios:** IC-705, IC-7100, IC-7300, IC-7300 MK2, IC-7600, IC-7610, IC-7760, IC-7850, IC-905, IC-9700

- Full authentication and session management with the radio.
- Automatic reconnection if the network link drops.
- Frequency, mode, TX, RIT/XIT, and split state are all tracked and displayed correctly.
- CW keying over the network, including speed control (6–48 WPM).
- SO2R supported with separate instances for Radio 1 and Radio 2.
- Alert shown immediately if authentication fails (wrong password, etc.).

**Bug fixes in this release:**
- IC-705: Band Up no longer incorrectly tries to step to 4 meters (not supported on IC-705) — it now steps directly from 6m to 2m.
- Fixed data-mode display flickering caused by polling overwriting the DIGI sub-mode state.
- Fixed the HamLib checkbox being hidden in the CAT dialog when Icom TCP/IP is selected.

---

### 4.145.1 (2026-03-04) — N4AF / NY4I

#### New Contests

- **Colorado QSO Party** — full rules and scoring added.
- **Indiana QSO Party (INQP)** — added.

#### Bug Fix

- Fixed a startup crash on clean Windows installs caused by a missing HamLib runtime file. The correct DLL is now included in the installer.

---

## Radio Factory & Icom Support — January–February 2026

This was a major development period (primarily NY4I) that laid the groundwork for the Icom network support above and made radio control significantly more robust overall.

**What changed for users:**

- **HamLib Direct:** TR4W now links directly to the HamLib DLL (updated to version 4.7.0), giving you access to 200+ radio models without needing to run the rigctld daemon separately. Just select your radio model in the CAT dialog and TR4W handles the rest.
- **Automatic reconnection:** If your radio or network logger disconnects, TR4W now automatically tries to reconnect with exponential backoff (starting at 1 second, up to 30 seconds maximum). You no longer need to restart TR4W after a radio power cycle.
- **Elecraft K4 serial support** uses the same modern code path as the network connection.
- **External logger support (DXKeeper, ACLog, HRD):** the same automatic reconnection logic now applies to external loggers.
- **HamLib updated from 4.6.5 to 4.7.0.**

---

## 4.141.x — January–October 2025

### Contest Online Scoreboard (COSB)

- Fixed COSB integration — TR4W now correctly reads the local `tr4w.ini` configuration for online scoreboard posting.
- Online scoreboard support added.

### Bug Fixes

- Fixed the RadioInfo UDP message so external programs (dashboards, network monitors) receive the correct entry window handle.
- Fixed a spacing issue in sent callsigns — at least one space now always follows your callsign in formatted output.
- Radio polling improvements.

---

## 4.140.x — December 2024

### New Contests

- **9A DX** contest support added.

### Radio Control

- Added native **IC-7760** support (based on IC-7610).
- Fixed CW speed tracking for Kenwood and Elecraft radios.

### Contest Updates

- **Winter Field Day:** changed digital mode logging from DI to DG in Cabrillo export, matching the WFD organizers' updated parser.

---

## 4.139.x — November 2024

### Bug Fixes

- Removed the automatic zone fill from callsign lookup via CTY.DAT (was causing incorrect zone entries in some exchanges).
- Fixed QSY not properly clearing the callsign and exchange windows.
- Fixed a manually entered frequency not clearing after a QSY.

---

## 4.138.x — October–November 2024

### New Contests

- **WAG IE** added.

### Data Updates

- Updated TRMASTER and CTY.DAT data files.

### Bug Fixes

- Several fixes for reported issues.

---

## 4.137.x — August 2024

- **Arizona QSO Party:** updated Cabrillo contest name.
- Updated Indy10 networking library used for SCP file uploads.

---

## 4.136.x — June–August 2024

### New Contests

- **LABRE-DX** contest support added.
- **LABRE** contest support added.
- **Arizona QSO Party** rules updated.

---

## 4.135.x — April–May 2024

### Bug Fixes

- Fixed ADIF export incorrectly setting the SUBMODE field in cases where it doesn't apply.
- Fixed QSO party DX multiplier handling for the Florida QSO Party (FQP) and others.
- Fixed a Cabrillo score posting bug affecting QSO parties.
- Various other reported fixes.

---

## 4.133.x — April 2024

### Bug Fixes

- Fixed the SO2R dual display.

---

## 4.132.x — March–April 2024

### POTA

- Added support for **two-letter POTA park code prefixes** (e.g. US-, VE-, DL-), previously only one-letter prefixes were accepted.

### Bug Fixes

- Fixed multiplier fields that were incorrectly set to zero in contest scoring.
- Fixed "Reset Radio Ports" for networked K4 connections.

---

## 4.131.x — January–March 2024

### New Features

- **Delete QSO over UDP:** TR4W now sends a proper delete notification when you remove a QSO, and a delete-then-re-add when you edit one — keeping external loggers and network partners in sync.
- **External logger selection:** you can now choose your external logger (DXKeeper, ACLog, HRD) from a menu. DXKeeper is fully working; others are in progress.

### Contest Updates

- **DARC-10M** and **OKOM** contest rule updates.

### Bug Fixes

- Fixed ADIF export missing the "my exchange" field.
- Fixed the online scoreboard and UDP score posting.
- Fixed UDP port binding conflict with JTAlert (the UDP port was bound even when WSJT-X integration was turned off).
- Fixed VFO bump up/down for FlexRadio (Flex doesn't support the standard UP/DN commands).
- Fixed UDP contact port — a copy-paste error was overwriting the contact port with the lookup port.
- Fixed FOC Marathon import of FOC number.
- Fixed various N1MM log import issues.

---

## 4.130.x — January 2024

- Band map: stopped dupe checking after a match is found (performance improvement for large spot lists).

---

## 4.129.x — December 2023

- Fixed **9ADX** contest multipliers being set incorrectly.
- Added Croatian DOM file to the installer.

---

## 4.127.x — September–October 2023

### New Contests

- **Pennsylvania QSO Party** rules added.

### Bug Fixes

- Fixed a UDP band reporting issue.
- Various other reported fixes.

---

## 4.126.x — August–September 2023

### Bug Fixes

- Fixed the Icom CI-V address missing from rigctld parameters (was preventing rigctld from connecting to Icom radios).
- Fixed a hesitation when calling a spotted station.
- Various spot display and band map fixes.

---

## 4.125.x — August 2023

### HamLib Support (Major New Feature)

TR4W gained initial HamLib support in this release. HamLib is the same radio control library used by WSJT-X and dozens of other ham radio programs, giving TR4W automatic support for a huge range of transceivers.

- HamLib radio selection added to the CAT dialog, with five new config parameters.
- rigctld launches minimized and closes automatically when TR4W exits.
- Added Ctrl+J help entries for HamLib configuration.

### New Contests

- **YO-DX-HF** contest support added.

### Bug Fixes

- Fixed Alt+M on Yaesu radios.
- Fixed Yaesu serial CW keying.

---

## 4.124.x — July 2023

### Bug Fixes

- Fixed WSJT-X contacts being logged with the wrong mode (showing Data/RTTY instead of FT8/FT4).
- Added an OPERATOR field to the QSO edit dialog (all language versions).
- Fixed a format error in the exchange window change handler.
- The TCP server for WSJT-X radio control can now be turned off in settings.
- Fixed NAQP-RTTY import not setting the STATE field correctly.
- Improved N1MM log import for various contest types.
- Network parameter send safeguards: TR4W won't accidentally overwrite a remote station's configuration.

---

## 4.123.x — May 2023

### POTA Support

- Fixed ADIF file generation for POTA activations.
- Allowed a blank exchange for POTA (uses default RST when no park reference is given).

### Bug Fix

- Restored missing TCP/IP options in the Czech-language radio dialog.

---

## 4.122.x — March 2023

- Added Kenwood and Yaesu radio commands for mode and frequency control.
- Fixed the ESC key to properly stop a playing CW or voice message.
- Fixed Winter Field Day log import and network sync commands.

---

## 4.121.x — January 2023

- Fixed a critical bug where the log file was not closed properly after a UDP command, causing subsequent QSOs not to be saved.

---

## 4.120.x — December 2022

- Added Mexico class M and section MX for contests with Mexican domestic exchanges.
- Fixed Winter Field Day ADIF file naming.
- Fixed grid square detection in certain exchange types.

---

## 4.114.x — August 2022

- Bug fix release.

---

## 4.111.x — May–June 2022

### Improvements

- **Separate UDP ports** for app, contact, radio, and score data — makes integration with Node-RED, dashboards, and external loggers much more flexible.
- Added grid locator to the Cabrillo header.
- Fixed random data appearing in Cabrillo exchange fields.
- Fixed ADIF grid square parsing.
- Added a confirmation dialog after Cabrillo upload (or on error), so you know whether the upload succeeded.
- Updated CTY.DAT and TRMASTER data files.

---

## Earlier History (2014–2022)

TR4W was first committed to GitHub on April 25, 2014 at version 4.30.3 by Howard Hoyt (N4AF). Over the following eight years, N4AF continuously expanded the application with new contests, radio support, and bug fixes. Tom Schaefer (NY4I) joined as a major contributor, bringing significant improvements to radio control, UDP/network integration, WSJT-X support, POTA, external logger connectivity, and code reliability. By 2022, TR4W had grown from a straightforward contest logger into a full-featured application supporting dozens of contests, CW/SSB/digital modes, HamLib, multiple radio protocols, online scoreboards, and POTA activations.

---

## Pre-GitHub History (2009–2012) — UA4WLI

> The following release history predates the GitHub repository. It was recorded by
> Dmitriy Gulyaev (UA4WLI), the original author of TR4W, in a history file bundled with the application.
> Versions span 4.162 through 4.247, covering September 2009 through December 2012.

This era established the foundation of TR4W as a Windows application. UA4WLI developed a rich set of features during these years, including:

- **Contest support** for dozens of events: ARRL Sweepstakes, ARRL RTTY, CQ WPX RTTY, NAQP RTTY, WAE DX, DARC-10M, LZ DX, Black Sea Cup, CW Ops, CWOPEN, YO-DX-HF, NA Sprint RTTY, and many others.
- **Radio control** for a wide range of transceivers: Icom IC-705, IC-781, IC-7200, IC-7410, IC-910H, IC-9700 (predecessor models); Yaesu FT-450, FT-857, FT-897, FT-1000MP, FTDX3000; Elecraft K3; Ten-Tec Orion; and more.
- **Winkeyer** support for CW keying, including speed control, PTT, and all major WK2 commands.
- **Band map and DX cluster**: telnet cluster, skimmer spot support, colored spots (new mult = red, dupe = gray), and a band map popup for tuning the inactive radio.
- **ADIF import/export** with support for many standard fields.
- **EDI format export.**
- **Cabrillo export** for all supported contests.
- **Auto-CQ** in both CW and phone modes.
- **SO2R** with a dual dupe sheet window.
- **Network/multi-op** logging with serial number lockout and operator login.
- **DVK (Digital Voice Keyer)** support.
- **MP3 recording** of audio.
- **PC time synchronization.**
- **Rotator control** via the call window (type a bearing and press Ctrl+P).
- Many UI improvements including custom window colors, grid locator prompting, and S&P counter display.

Key individual releases in this period include version 4.195 (February 2010), which introduced Elecraft K3 support and moved Winkeyer settings into the config file; version 4.229 (August 2010), which added "Possible Calls" lookup using TRMASTER.DTA; version 4.231 (December 2010), which added rotator control and ARRL-10 multipliers; and version 4.245 (May 2012), which renamed the DVP function to DVK and added IC-7410 support.

---

*This changelog was generated from the Git commit history of the [n4af/TR4W](https://github.com/n4af/TR4W) repository. Repository: [github.com/n4af/TR4W](https://github.com/n4af/TR4W)*
