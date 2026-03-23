# TR4W Reference Manual Update — Summary

**Date:** March 2026  
**Scope:** Gap analysis and full wiki port of the TR4W Reference Manual v4.01 (2014)  
**Performed by:** NY4I (Tom)

---

## Background

The TR4W Reference Manual v4.01 was written by Tod Olson (K0TO) and last edited in 2014. Over the following twelve years, TR4W grew substantially — new rig control protocols, digital mode integration, UDP broadcasting, external logger support, SO2R enhancements, and dozens of new configuration parameters — none of which appeared in the manual.

This effort compared the current codebase against the 2014 PDF to identify every gap, then ported the entire manual into the GitHub Wiki in updated Markdown form.

---

## Gap Analysis Findings

### Configuration Parameters

| | Count |
|--|--|
| Parameters documented in v4.01 manual | 335 |
| Parameters in current `commands_help_eng.ini` (v4.145.3) | 357 |
| **New parameters not in the manual** | **54** |

The 54 undocumented parameters span eleven functional areas:

| Area | New Params |
|------|-----------|
| UDP Broadcasts (N1MM-compatible) | 15 |
| HamLib Rig Control | 6 |
| CW by CAT / CW Speed Sync | 4 |
| Radio Startup Commands / Stop Bits | 5 |
| WSJT-X / Digital Integration | 3 |
| External Logger (DXKeeper TCP) | 4 |
| Band Map Enhancements | 5 |
| SO2R Enhancements | 3 |
| Initial Exchange / IE Switch | 2 |
| UI / Font / Mode | 2 |
| Radio TCP Server | 1 |
| Debug Logging | 1 |
| DVP → DVK rename | 3 |

### Major New Feature Areas (no manual coverage at all)

- **HamLib integration** (v4.125, 2023) — 200+ radios via statically-linked DLL
- **Icom network control** — IC-705, IC-7300, IC-7610, IC-9700, IC-905, and others via Ethernet/WiFi
- **Elecraft K4 Direct** — native TCP protocol, no HamLib required
- **WSJT-X / FT8/FT4 integration** — full UDP receive, QSO logging, MULT/DUPE colorization
- **N1MM-compatible UDP broadcasts** — works with qsorder, ClubPi, 2Tone, Palstar HF-Auto, PSTRotator, WRTC scoring
- **DXKeeper TCP integration** — real-time QSO forwarding
- **Radio TCP server** — DXLab Commander protocol for WSJT-X radio control
- **Contest Online ScoreBoard (COSB)** support
- **ADIF enhancements** — SUBMODE, OPERATOR, POTA fields

### Contests Added Since 2014

POTA, Arizona QSO Party, LABRE, LABRE-DX, YO-DX-HF, PA QSO Party, WAG IE, 9A DX, OKOM, Indiana QSO Party (INQP), Missouri QSO Party, and others.

### Codebase Issues Noted

Two defects were found in `commands_help_eng.ini` that should be corrected:

1. **`RADIO TWO STARTUP COMAND`** — misspelling (missing 'M'). Both spellings exist as section headers. One should be removed.
2. **`RADIO ONE SCORE`** — the `DESCRIPTION` field contains the text for `RADIO ONE STARTUP COMMAND` (copy/paste error).

---

## Wiki Pages Published

All content was published to the [TR4W GitHub Wiki](https://github.com/n4af/TR4W/wiki) in a single commit on March 20, 2026. The original v4.01 PDF remains available at https://tr4w.net/TR4W_Reference_Manual_4.01.pdf for historical reference.

| Wiki Page | Status | Notes |
|-----------|--------|-------|
| [Home](https://github.com/n4af/TR4W/wiki) | Updated | Added Reference Manual TOC |
| [System Requirements](https://github.com/n4af/TR4W/wiki/System-Requirements) | New | Updated OS list to Win 7/10/11 |
| [Program Installation](https://github.com/n4af/TR4W/wiki/Program-Installation) | New | Updated URLs and version refs |
| [Supported Transceivers](https://github.com/n4af/TR4W/wiki/Supported-Transceivers) | New | Merged with existing wiki table; added Icom network, K4 Direct, HamLib |
| [Supported Contests](https://github.com/n4af/TR4W/wiki/Supported-Contests) | New | All original + new contests since 2014 |
| [Program Windows and Hot Keys](https://github.com/n4af/TR4W/wiki/Program-Windows-and-Hot-Keys) | New | All keyboard shortcut tables |
| [Interface Circuits](https://github.com/n4af/TR4W/wiki/Interface-Circuits) | New | Serial/parallel port pinouts; circuit diagrams reference original PDF |
| [Configuration Statements Overview](https://github.com/n4af/TR4W/wiki/Configuration-Statements-Overview) | New | Statements added/dropped vs TR Log |
| [Configuration Statements](https://github.com/n4af/TR4W/wiki/Configuration-Statements) | New | All 357 parameters; 54 new ones marked `[NEW]` |
| [Using Saved Configuration Statements](https://github.com/n4af/TR4W/wiki/Using-Saved-Configuration-Statements) | New | Step-by-step config file management |
| [HamLib Rig Control](https://github.com/n4af/TR4W/wiki/HamLib-Rig-Control) | New | Full setup guide and all HamLib parameters |
| [WSJT-X Integration](https://github.com/n4af/TR4W/wiki/WSJT-X-Integration) | New | FT8/FT4 setup, radio TCP server, JT-Alert compatibility |
| [UDP Broadcasts](https://github.com/n4af/TR4W/wiki/UDP-Broadcasts) | New | All 15 UDP parameters, compatible apps, multi-computer example |
| [External Logger Integration](https://github.com/n4af/TR4W/wiki/External-Logger-Integration) | New | DXKeeper TCP setup; ACLog/HRD noted as planned |
| `_Sidebar.md` | New | Persistent navigation sidebar on every wiki page |

**Total:** 15 files, ~5,200 lines of Markdown added.

---

## Source Files

The following files were used as primary sources during this analysis and are preserved in the workspace:

| File | Description |
|------|-------------|
| `commands_help_eng.ini` | Authoritative source for all current parameter definitions |
| `CHANGES.md` | Full TR4W change history since 2014, authored by NY4I |
| https://tr4w.net/TR4W_Reference_Manual_4.01.pdf | Original 2014 reference manual (83 pages) |

---

## Recommended Follow-Up

- [ ] Fix the `RADIO TWO STARTUP COMAND` typo in `commands_help_eng.ini`
- [ ] Fix the `RADIO ONE SCORE` description in `commands_help_eng.ini`
- [ ] Add DVK (voice keyer) usage guide to the wiki — the DVP → DVK rename is documented but there is no setup walkthrough
- [ ] Document the Contest Online ScoreBoard (COSB) configuration
- [ ] Keep the [Supported Contests](https://github.com/n4af/TR4W/wiki/Supported-Contests) wiki page updated as new contests are added
- [ ] Consider adding `commands_help_eng.ini` `DESCRIPTION` fields for any parameters that currently have blank descriptions (e.g., `DVK PATH`, `DVK RECORDER`)
