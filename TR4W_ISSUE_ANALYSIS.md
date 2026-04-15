# TR4W: Open Issues Analysis & Work Planning

> Cross-reference of open GitHub issues against commits, PRs, and triage status  
> Repository: [github.com/n4af/TR4W](https://github.com/n4af/TR4W)  
> Original analysis: 2026-03-14 | **Last updated: 2026-04-15**

---

## Status Since Original Analysis

| Item | Finding |
|------|---------|
| Tier 1 issues flagged for closure | 8 of 10 are now **closed** ✓ |
| Tier 2 issues (partial/superseded) | #713 and #826 **closed** ✓; #415, #446 still open |
| Tier 3 (Radio Factory work) | #826 **closed** ✓; others still open and need verification |
| Tier 4 (test-against-new-arch) | #803 **closed** ✓; #703, #121, #315, #685 still open |
| New issues since analysis (861–877) | 15 new issues, 13 closed in rapid succession; #871 and #877 still open |
| **Triage pass (2026-04-15)** | Labels incorrectly bulk-applied and reverted. `Triaged` means analysis + recommendations in comments — only issues #853, #854, #856, #850, #871, #866 carry it legitimately. Remaining issues need proper per-issue triage. |

---

## Still Open From Original Analysis

### Issues That Should Now Be Verified/Closed

These were flagged in the original analysis but remain open. They need a human verification pass to confirm resolution and close.

| Issue | Title | Status | Notes |
|-------|-------|--------|-------|
| [#688](https://github.com/n4af/TR4W/issues/688) | Lock bandmap window while updating to prevent flashing | **Open — likely resolved** | PR #869 (merged 2026-04-13) specifically addressed this: 250ms coalesced refresh timer, `WS_EX_COMPOSITED`, `RDW_NOERASE`. Band map flicker greatly reduced per PR description. Close after confirming in a build. |
| [#87](https://github.com/n4af/TR4W/issues/87) | SCP-like behavior for Section names | Open | Commit said "getting ready for" — still unverified. |
| [#800](https://github.com/n4af/TR4W/issues/800) | CW Speed Sync not following K4 | Open | Commit `ad86674b` said "minus issue 800" — K4 CW sync still unresolved. Issue #871 (WinKeyer extra space) is related but distinct. |
| [#383](https://github.com/n4af/TR4W/issues/383) | Status line message when radio connection lost | Open | Reconnection work added detection infrastructure; verify if status bar actually shows disconnect message. |
| [#735](https://github.com/n4af/TR4W/issues/735) | Direct log via TCP to ACLog | Open | Factory framework has `lt_ACLog` stub — check `uExternalLogger.pas` for actual send logic. |
| [#736](https://github.com/n4af/TR4W/issues/736) | HRD support for external logger | Open | Same as #735 — factory has `lt_HRD`, verify implementation vs. stub. |
| [#766](https://github.com/n4af/TR4W/issues/766) | Exception when editing contact with external logger | Open | Exception handling was added broadly — test by editing a contact with logger connected. |
| [#703](https://github.com/n4af/TR4W/issues/703) | K4 network doesn't reset split on bandmap click | Open | Split handling rewritten in factory pattern. Test on current build. |
| [#121](https://github.com/n4af/TR4W/issues/121) | S&P mode entered on Icom in split mode | Open | New `TIcomRadioBase` CI-V implementation is completely new. Test on IC-7300/7610/9700. |
| [#415](https://github.com/n4af/TR4W/issues/415) | Translation updates 2020-July | Open | WAGWarn item was done; verify remaining 3 (`TC_CANNOTOPENLOG`, `TC_LOGNOTPRESENT`, `TC_IMPORTFILENOTFOUND`). |
| [#396](https://github.com/n4af/TR4W/issues/396) | Applied merge by mistake | Open | This was a 2020 incident, not an active bug. **Close as resolved.** |

---

## Current Open Issues — Full List (as of 2026-04-15)

Count: **~95 open issues**. The `Triaged` label should only be applied after a developer has analyzed the issue and left recommendations in the comments. Issues below that already carry `Triaged`: #853, #854, #856, #850, #871. The remainder need per-issue analysis before being marked triaged.

### Active / Recently Worked (High Priority)

| Issue | Title | Labels |
|-------|-------|--------|
| [#877](https://github.com/n4af/TR4W/issues/877) | POTA parser does not accept free-form info like state or name | enhancement, POTA, Triaged |
| [#871](https://github.com/n4af/TR4W/issues/871) | Extra Space Inserted Between Callsign and Report (AUTO SEND CHARACTER COUNT) | Triaged |

### Bugs

| Issue | Title | Labels |
|-------|-------|--------|
| [#818](https://github.com/n4af/TR4W/issues/818) | NewContest dialog asks for MY STATE on non-state contests | bug, Triaged |
| [#807](https://github.com/n4af/TR4W/issues/807) | 9A (Croatian) DX awarding zero points | bug, Triaged |
| [#800](https://github.com/n4af/TR4W/issues/800) | CW Speed Sync not following K4 | bug, Radio Control, Triaged |
| [#788](https://github.com/n4af/TR4W/issues/788) | NextBandMap still displays deleted spot | bug, Triaged |
| [#784](https://github.com/n4af/TR4W/issues/784) | Next Bandmap fails to clear Initial Exchange field | bug, Triaged |
| [#766](https://github.com/n4af/TR4W/issues/766) | Exception when editing contact with external logger | bug, External Logger, Triaged |
| [#740](https://github.com/n4af/TR4W/issues/740) | BAND MAP CALL WINDOW feature does not seem to work | bug, Triaged |
| [#726](https://github.com/n4af/TR4W/issues/726) | PostUnit: remaining MyExchange handlers in GenerateMyExchange | bug, Triaged |
| [#716](https://github.com/n4af/TR4W/issues/716) | Random access violation using multi-network | bug, Multi-network, Triaged |
| [#709](https://github.com/n4af/TR4W/issues/709) | Croatian DX counting multipliers wrong | bug, Triaged |
| [#683](https://github.com/n4af/TR4W/issues/683) | Orion and Omni mode change ALT-M does not work | bug, Radio Control, Triaged |
| [#680](https://github.com/n4af/TR4W/issues/680) | CW port already open after APPLY/OK in Radio setup | bug, Triaged |
| [#505](https://github.com/n4af/TR4W/issues/505) | In S&P, after sending call via ENTER, F1 does not send call again | bug, Radio Control, Triaged |
| [#459](https://github.com/n4af/TR4W/issues/459) | Extra characters show up after save backup log | bug, Triaged |
| [#435](https://github.com/n4af/TR4W/issues/435) | Implement Kenwood TS990/TS890 Mode properly | bug, Radio Control, Triaged |
| [#426](https://github.com/n4af/TR4W/issues/426) | DVK recording and volume fail to function | bug, Triaged |
| [#417](https://github.com/n4af/TR4W/issues/417) | NA SPRINT: QTHString not cleared when exchange in State/name/# order | bug, ADIF, Triaged |
| [#121](https://github.com/n4af/TR4W/issues/121) | S&P mode entered on Icom in split mode | bug, Triaged |

### Bandmap

| Issue | Title | Labels |
|-------|-------|--------|
| [#835](https://github.com/n4af/TR4W/issues/835) | When clicking spot in band map, send UDP lookup message | Band Map, External Logger, Triaged |
| [#747](https://github.com/n4af/TR4W/issues/747) | After selecting bandmap, auto tab to exchange window | Band Map, Triaged |
| [#705](https://github.com/n4af/TR4W/issues/705) | Copy spot from bandmap to clipboard in pasteable format | enhancement, Band Map, Triaged |
| [#699](https://github.com/n4af/TR4W/issues/699) | In QSO Party, flag county in spot as mult in band map | enhancement, DX Cluster, Triaged |
| [#688](https://github.com/n4af/TR4W/issues/688) | Lock bandmap window while updating to prevent flashing | Band Map, Triaged — **likely resolved by PR #869, needs close** |

### Radio Control

| Issue | Title | Labels |
|-------|-------|--------|
| [#856](https://github.com/n4af/TR4W/issues/856) | Implement polymorphic KeepAlive for factory radio objects | enhancement, Triaged |
| [#854](https://github.com/n4af/TR4W/issues/854) | Rename tNetObject to FactoryRadio throughout codebase | enhancement, Triaged |
| [#853](https://github.com/n4af/TR4W/issues/853) | Implement radio discovery dialog for network radios | Radio Control, Triaged |
| [#852](https://github.com/n4af/TR4W/issues/852) | Add Icom 7700 to network radio implementation | Radio Control, Triaged |
| [#850](https://github.com/n4af/TR4W/issues/850) | Selective Use of 07 D2 Logic for Icom 9700 | Radio Control, Triaged |
| [#781](https://github.com/n4af/TR4W/issues/781) | Add SPAN commands for PAN adapter function key | enhancement, Radio Control, Triaged |
| [#703](https://github.com/n4af/TR4W/issues/703) | K4 network doesn't reset split on bandmap click | Radio Control, Triaged |
| [#683](https://github.com/n4af/TR4W/issues/683) | Orion and Omni ALT-M mode change does not work | bug, Radio Control, Triaged |
| [#623](https://github.com/n4af/TR4W/issues/623) | Fix Ten Tec Omni VI (564) breaking change | Radio Control, Triaged |
| [#449](https://github.com/n4af/TR4W/issues/449) | Make Flex its own radio type in uRadioPolling | enhancement, Radio Control, Triaged |
| [#448](https://github.com/n4af/TR4W/issues/448) | Implement TCP and UDP protocol for Flex radios | enhancement, Networking, Radio Control, Triaged |
| [#436](https://github.com/n4af/TR4W/issues/436) | Add rig control for TS890 | enhancement, New Radio Request, Triaged |
| [#383](https://github.com/n4af/TR4W/issues/383) | Status line message when radio connection is lost | Radio Control, Triaged |
| [#315](https://github.com/n4af/TR4W/issues/315) | Detect data mode on IC-9100 | Radio Control, Triaged |

### New Radio Requests

| Issue | Title |
|-------|-------|
| [#844](https://github.com/n4af/TR4W/issues/844) | Add Support for RigSelect Pro Switching Box |
| [#817](https://github.com/n4af/TR4W/issues/817) | Add support for Yaesu FTX-1F |
| [#778](https://github.com/n4af/TR4W/issues/778) | Add support for Yaesu FTX-1F (duplicate of #817) |
| [#767](https://github.com/n4af/TR4W/issues/767) | Add discovery protocol for network-connected K4 radios |
| [#446](https://github.com/n4af/TR4W/issues/446) | Add support for Expert Electronics TCI interface |
| [#436](https://github.com/n4af/TR4W/issues/436) | Add rig control for TS890 |
| [#431](https://github.com/n4af/TR4W/issues/431) | Add support for DXLab Suite Commander as radio |

> **Note:** #817 and #778 are duplicates — one should be closed.

### Contest Exchange / Scoring

| Issue | Title | Labels |
|-------|-------|--------|
| [#820](https://github.com/n4af/TR4W/issues/820) | Add new YUK Canadian section | Contest Exchange, Triaged |
| [#810](https://github.com/n4af/TR4W/issues/810) | WSJT-X: convert grid to state when contest requires it | enhancement, WSJT-X, Triaged |
| [#808](https://github.com/n4af/TR4W/issues/808) | 9A (Croatian) double points enhancement | enhancement, Triaged |
| [#802](https://github.com/n4af/TR4W/issues/802) | Score display not showing all info for ARRL 10 Meter | Triaged |
| [#799](https://github.com/n4af/TR4W/issues/799) | ARRL 10m: Mult needs for AZ show all bands | enhancement, Triaged |
| [#797](https://github.com/n4af/TR4W/issues/797) | Scoring change Russian 160 (RU3AX Memorial) | enhancement, Triaged |
| [#416](https://github.com/n4af/TR4W/issues/416) | NAQP: accept state and name in either order | enhancement, Triaged |
| [#460](https://github.com/n4af/TR4W/issues/460) | Allow entry of Precedence then number | enhancement, Triaged |
| [#461](https://github.com/n4af/TR4W/issues/461) | Sweepstakes: prefill spot comment with section | enhancement, good first issue, Triaged |

### New Contest / DOM Requests

| Issue | Title |
|-------|-------|
| [#829](https://github.com/n4af/TR4W/issues/829) | Updated DOM file of UBA DX Contest |
| [#789](https://github.com/n4af/TR4W/issues/789) | Add changes to 2025 RSGB Contests |
| [#776](https://github.com/n4af/TR4W/issues/776) | Add URC DX RTTY contest |
| [#745](https://github.com/n4af/TR4W/issues/745) | Contest name change: TESLA → HF-TESLA |
| [#692](https://github.com/n4af/TR4W/issues/692) | DARC-WAE: Add total QTCs to Summary.txt |
| [#602](https://github.com/n4af/TR4W/issues/602) | Contest score board fails to accept overlay category |
| [#434](https://github.com/n4af/TR4W/issues/434) | Grids.dom does not include all locators in WWDIGI |
| [#386](https://github.com/n4af/TR4W/issues/386) | TAC rule change |

### ADIF / Cabrillo / Logging

| Issue | Title | Labels |
|-------|-------|--------|
| [#819](https://github.com/n4af/TR4W/issues/819) | Export TR4W-specific fields and import from N1MM | enhancement, ADIF, Triaged |
| [#774](https://github.com/n4af/TR4W/issues/774) | Make ADIF and Cabrillo contest name configurable in CFG | ADIF, Cabrillo, Triaged |
| [#750](https://github.com/n4af/TR4W/issues/750) | Add ability to mark a QSO as X-QSO | enhancement, Cabrillo, UDP Broadcast, Triaged |
| [#473](https://github.com/n4af/TR4W/issues/473) | Cabrillo CATEGORY mismatch — ask to update | enhancement, Cabrillo, Triaged |
| [#483](https://github.com/n4af/TR4W/issues/483) | Check if MyGrid is put in Contact Record | question, Cabrillo, Triaged |

### External Logger / UDP

| Issue | Title | Labels |
|-------|-------|--------|
| [#836](https://github.com/n4af/TR4W/issues/836) | PathFinder DDE: exchange not cleared on message receipt | Triaged |
| [#835](https://github.com/n4af/TR4W/issues/835) | Clicking bandmap spot should send UDP lookup message | Band Map, External Logger, Triaged |
| [#768](https://github.com/n4af/TR4W/issues/768) | Add SentExchange to Contact UDP broadcast | enhancement, Modern Delphi, UDP Broadcast, Triaged |
| [#736](https://github.com/n4af/TR4W/issues/736) | Add HRD support to external logger via TCP/IP | enhancement, External Logger, Triaged |
| [#735](https://github.com/n4af/TR4W/issues/735) | Direct log via TCP to ACLog | enhancement, External Logger, Triaged |
| [#718](https://github.com/n4af/TR4W/issues/718) | Receive UDP Contact messages from non-TR4W programs | enhancement, UDP Broadcast, Triaged |

### Multi-network / Server

| Issue | Title | Labels |
|-------|-------|--------|
| [#770](https://github.com/n4af/TR4W/issues/770) | Add operator to Network window display | Multi-network, Triaged |
| [#717](https://github.com/n4af/TR4W/issues/717) | Display QSOs by each operator | enhancement, Triaged |
| [#716](https://github.com/n4af/TR4W/issues/716) | Random access violation using multi-network | bug, Multi-network, Triaged |
| [#574](https://github.com/n4af/TR4W/issues/574) | Investigate peer network (no TR4WSERVER) | Multi-network, Triaged |
| [#532](https://github.com/n4af/TR4W/issues/532) | Add discovery protocol for TR4W/TR4WSERVER | enhancement, Multi-network, Triaged |

### WSJT-X / Digital

| Issue | Title | Labels |
|-------|-------|--------|
| [#810](https://github.com/n4af/TR4W/issues/810) | Convert grid to state for WSJT-X when contest requires | enhancement, WSJT-X, Triaged |
| [#769](https://github.com/n4af/TR4W/issues/769) | WSJT-X log: station ID letter not put in log | WSJT-X, Triaged |
| [#465](https://github.com/n4af/TR4W/issues/465) | Implement TinyFSK Protocol for Mortty FSK interface | enhancement, RTTY, Triaged |
| [#444](https://github.com/n4af/TR4W/issues/444) | Add extendedMode of FST4 | enhancement, WSJT-X, Triaged |

### UI / General Enhancements

| Issue | Title | Labels |
|-------|-------|--------|
| [#783](https://github.com/n4af/TR4W/issues/783) | Real-time contest logging support for hamscore.com | enhancement, Triaged |
| [#780](https://github.com/n4af/TR4W/issues/780) | Option to download latest TRMASTER file | enhancement, Triaged |
| [#772](https://github.com/n4af/TR4W/issues/772) | Send real-time messages to ClubLog | enhancement, Online Scorebook, Triaged |
| [#758](https://github.com/n4af/TR4W/issues/758) | Date-aware contest selection dropdown | enhancement, Triaged |
| [#756](https://github.com/n4af/TR4W/issues/756) | Output a webpage with contest info | Triaged |
| [#755](https://github.com/n4af/TR4W/issues/755) | Add support for automatic self-spotting | Triaged |
| [#749](https://github.com/n4af/TR4W/issues/749) | Indicate if frequency is out of band for station call | Triaged |
| [#748](https://github.com/n4af/TR4W/issues/748) | Add beam heading to bandmap status bar for spot | Triaged |
| [#739](https://github.com/n4af/TR4W/issues/739) | Return all open windows to primary monitor | enhancement, Triaged |
| [#732](https://github.com/n4af/TR4W/issues/732) | Send UDP command to PSTRotator for rotor control | Rotor Control, Triaged |
| [#730](https://github.com/n4af/TR4W/issues/730) | ContestOnlineScore: only half of band-specific QSOs shown | Online Scorebook, Triaged |
| [#719](https://github.com/n4af/TR4W/issues/719) | Investigate SQLite 3 instead of flat file log | Modern Delphi, Triaged |
| [#668](https://github.com/n4af/TR4W/issues/668) | Option to enforce callsign validity on entry | Triaged |
| [#645](https://github.com/n4af/TR4W/issues/645) | FM mode anomaly | Triaged |
| [#584](https://github.com/n4af/TR4W/issues/584) | Set soundcard per radio for DVK (2-radio) | enhancement, Two Radio, DVK, Triaged |
| [#485](https://github.com/n4af/TR4W/issues/485) | Summary report should use fixed font for table | Triaged |
| [#479](https://github.com/n4af/TR4W/issues/479) | Add 60M band | enhancement, Triaged |
| [#420](https://github.com/n4af/TR4W/issues/420) | Reconnect to DX cluster | Triaged |
| [#418](https://github.com/n4af/TR4W/issues/418) | Documentation updates | Documentation, Triaged |
| [#415](https://github.com/n4af/TR4W/issues/415) | Translation updates 2020-July | Translation, Triaged |
| [#391](https://github.com/n4af/TR4W/issues/391) | Two more telnet clusters to trcluster.dat | DX Cluster, Triaged |
| [#390](https://github.com/n4af/TR4W/issues/390) | Configurable path for Log File Directory | enhancement, Triaged |
| [#384](https://github.com/n4af/TR4W/issues/384) | MP3 recorder not working in newer OS | Triaged |

### Housekeeping — Should Be Closed

| Issue | Title | Reason |
|-------|-------|--------|
| [#688](https://github.com/n4af/TR4W/issues/688) | Lock bandmap while updating | PR #869 merged 2026-04-13 directly addressed this — close after confirming in build |
| [#778](https://github.com/n4af/TR4W/issues/778) | Add support for Yaesu FTX-1F | **Duplicate of #817** — close as duplicate |
| [#396](https://github.com/n4af/TR4W/issues/396) | Applied merge by mistake | 2020 incident, revert was committed — close as resolved |
| [#383](https://github.com/n4af/TR4W/issues/383) | Status line when radio connection lost | Reconnection infrastructure added; verify if visible to user and close |

---

## Planning Summary

### Immediate / Low Effort
- Close #396 (stale incident), #778 (duplicate of #817), #688 (verify PR #869 resolved it)
- Verify and potentially close #383, #735, #736, #766, #703 against current build
- Close out #87 — determine if section SCP work was ever followed up

### Near-Term Feature Work (Active Areas)
- **POTA**: #877 (free-form parser — Claude prompt posted), plus follow-on from recent POTA Nfer work
- **Radio Factory**: #856 (KeepAlive), #854 (rename tNetObject), #853 (discovery dialog), #852 (Icom 7700), #850 (9700 logic)
- **Band Map**: #835 (UDP lookup on click), #784 (exchange not cleared), #788 (deleted spot still showing)
- **CW / WinKeyer**: #871 (extra space — in active diagnosis), #800 (K4 CW sync)

### Medium-Term / Architecture
- #719 (SQLite log)
- #448/#449 (Flex TCP/UDP)
- #574 (peer network, no server)
- #768 (SentExchange in UDP broadcast)
- #750 (X-QSO marking)

### Long Backlog (Low Priority / Pending Resources)
- New radio requests (#817, #436, #446, #431)
- New contest/DOM requests (#829, #789, #776)
- Online scorebook (#772, #783)
- Translation (#415, #685)
- Legacy radio fixes (#683, #623)

---

*Updated 2026-04-15 by cross-referencing all open GitHub issues, recent commits (through 4.146.11), and PR #869. Note: `Triaged` label requires actual per-issue analysis with recommendations posted in the issue comments — it is not a bulk acknowledgment label.*
