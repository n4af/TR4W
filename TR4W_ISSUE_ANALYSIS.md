# TR4W: Open Issues Potentially Resolved by Existing Commits

> Cross-reference of 172 open GitHub issues against 1,300 commits and 111 merged PRs  
> Repository: [github.com/n4af/TR4W](https://github.com/n4af/TR4W)  
> Generated: 2026-03-14

## Summary

| Category | Count | Action |
|----------|-------|--------|
| Directly referenced by issue number in commits | 12 | Close after quick verification |
| Partially addressed — work started or related fix merged | 3 | Review scope, close or update |
| Likely addressed by Radio Factory / Icom / reconnect work | 5 | Verify against new architecture, close or update |
| NSIS installer commit directly satisfies the request | 1 | Close |

**Total candidates for closure: 21 out of 172 open issues**

---

## Tier 1 — Issue Number Explicitly Referenced in Commits (Close These)

These issues have commits with the issue number directly in the commit message. In Howie's workflow, `issue NNN` in a commit message typically means the issue was worked on in that build. These should be closable.

| Issue | Title | Commit(s) | Date | Author |
|-------|-------|-----------|------|--------|
| [#91](https://github.com/n4af/TR4W/issues/91) | Multipliers Remaining Display | `1bbb401c` — "4.45.9 issue 91" | 2016-02-10 | N4AF |
| [#125](https://github.com/n4af/TR4W/issues/125) | `-` key in call window does nothing | `ef7f63b8` — "4.47.3 issue # 125" | 2016-03-08 | N4AF |
| [#159](https://github.com/n4af/TR4W/issues/159) | With CWByCAT, use CWTiming for AutoSend/AutoTerminate | `c62ed0fa` — "4.50.7 Issue # 159 uTelnet" | 2016-06-26 | N4AF |
| [#271](https://github.com/n4af/TR4W/issues/271) | PLS ADD RSGB DX Contest | `67d1e4fe` — "issue 271 remove RSGB" | 2023-06-08 | N4AF |
| [#656](https://github.com/n4af/TR4W/issues/656) | Improve format of summary data | `a39da6a1` — "issue 656 4.123.6" | 2023-06-19 | N4AF |
| [#688](https://github.com/n4af/TR4W/issues/688) | Lock the bandmap window while updating to prevent flashing | `1cd40d24` — "issue 688 4.127.3" | 2023-10-15 | N4AF |
| [#694](https://github.com/n4af/TR4W/issues/694) | Spot filter handles 60M wrong | `626f757a`, `569cacf3` — "issue 694 4.126.5" | 2023-09-15 | N4AF |
| [#785](https://github.com/n4af/TR4W/issues/785) | ADIF Import fails to input DOK from WAG contest | `64a70edc` — "issue 785 WAG IE" | 2024-10-23 | N4AF |
| [#805](https://github.com/n4af/TR4W/issues/805) | Croatian DX (9A DX) fails to support mix mode | `ac79688e` — "4.140.1 issue#805 9A DX" | 2024-12-21 | N4AF |
| [#834](https://github.com/n4af/TR4W/issues/834) | Make main window have rounded corners | `a0744e69` — "4.145.1 issue 834 Main window rounded corners" | 2026-03-04 | N4AF |

### Edge Cases — Referenced but May Be Partial

| Issue | Title | Commit(s) | Notes |
|-------|-------|-----------|-------|
| [#87](https://github.com/n4af/TR4W/issues/87) | SCP-like behavior for Section names | `42749d70` — "getting ready for Issue 87. This closes #163." | Commit says "getting ready for" — suggests prep work only. Verify if follow-up was done. |
| [#800](https://github.com/n4af/TR4W/issues/800) | CW Speed Sync not following K4 | `ad86674b` — "4.140.5 minus issue 800", PR #804 (CW speed fix) | The commit says "minus issue 800" which may mean "excluding" this fix. PR #804 fixed CW speed for Kenwood/Elecraft but noted Icom/Yaesu/Flex/HamLib still needed. Needs clarification from Howie. |

---

## Tier 2 — Partially Addressed or Superseded by Major Work

These issues describe features or fixes where significant related work has been merged, but the commit did not reference the issue number. The work may fully or partially cover them.

### [#415](https://github.com/n4af/TR4W/issues/415) — Translation updates 2020-July

Two commits reference this: `e64d9c39` and `8e17a349` (2020-07-04) — "Create TC_WAGWarn [issue 415)". The issue had a checklist of 4 translation items. The WAGWarn item was done. **Check if the other 3 items (`TC_CANNOTOPENLOG`, `TC_LOGNOTPRESENT`, `TC_IMPORTFILENOTFOUND`) were completed** in subsequent commits.

### [#713](https://github.com/n4af/TR4W/issues/713) — RAEM contest, error text in STX_STRING after ADIF

Referenced in PR #725 body ("issue-713-raem" branch name). PR #725 was merged 2024-02-06 — "Added code to handle the ADIF export of myexchange." The PR body says STX_STRING was not being set properly and the fix was to set it to "None" and log an error. **This likely addresses the issue — close with reference to PR #725.**

### [#446](https://github.com/n4af/TR4W/issues/446) — Add support for Expert Electronics Universal Transceiver Interface

Referenced in PR #672 body. The PR was about network parameter safeguards, not TCI implementation. **This is a false positive** — the issue is likely still open and unaddressed.

---

## Tier 3 — Likely Addressed by Radio Factory / Reconnection Work (Jan–Feb 2026)

Your major Radio Factory PR (#827) and surrounding commits from December 2025 through February 2026 introduced architecture changes that likely address several open issues, even though those issue numbers were not explicitly referenced.

### [#383](https://github.com/n4af/TR4W/issues/383) — Add a message to status line when radio connection is lost

**Likely addressed.** The reconnection work (`ff069fd7`, `4e94f924`, `f40ff310`) added comprehensive disconnection detection, state tracking, and logging. The `Disconnecting` flag and state transitions provide the infrastructure for a status message. **Verify whether the status bar was actually updated to show a disconnect message, or whether only the log/debug output was added.**

### [#826](https://github.com/n4af/TR4W/issues/826) — Can the NSIS installer files be put into GitHub repo?

**Directly addressed.** Commit `0af3d6c3` (2026-02-25, Tom Schaefer): "Add NSIS installer script with HamLib DLLs." **Close this one — you did exactly what was asked.**

### [#735](https://github.com/n4af/TR4W/issues/735) — Add support for direct logging via TCP to ACLog

**Partially addressed.** The External Logger Factory (`uExternalLoggerFactory.pas`, `uExternalLoggerManager.pas`, commit `18321c2d`) created the framework with `lt_ACLog` as a planned type. The issue itself describes a stub `LogQSOToACLog` function. **The framework is in place but ACLog protocol implementation may still be a stub. Check `uExternalLogger.pas` for actual ACLog send logic.**

### [#736](https://github.com/n4af/TR4W/issues/736) — Add HRD support to external logger

**Same situation as #735.** The factory pattern supports `lt_HRD` as a type. **Check whether the HRD TCP protocol was actually implemented or remains stubbed.**

### [#766](https://github.com/n4af/TR4W/issues/766) — Exception when editing a contact with external logger

**Likely addressed.** The reconnection and exception-handling work added comprehensive exception protection throughout socket operations and message handlers (`ff069fd7`). The external logger reconnection logic (`4e94f924`) specifically handles `EIdNotConnected`, `EIdConnClosedGracefully`, and other Indy exceptions. **Test by editing a contact while an external logger is connected.**

---

## Tier 4 — Worth Investigating (Radio-Specific Issues vs. New Architecture)

These open issues describe radio-specific problems that the new factory pattern architecture may have changed the behavior of, either fixing or potentially requiring new approaches.

### [#703](https://github.com/n4af/TR4W/issues/703) — K4 over network doesn't reset split mode when clicking bandmap

The K4 now goes through the factory pattern with `TK4Radio` class. Split handling was reworked. **Test on current build — the split toggle logic was rewritten in the factory pattern refactor.**

### [#803](https://github.com/n4af/TR4W/issues/803) — Split after clicking spot not working on K4 over TCP

Same area as #703. Both relate to K4 + TCP + split mode. **These two should be tested together on the current build.**

### [#121](https://github.com/n4af/TR4W/issues/121) — S&P mode entered on Icom radios in split mode

This was filed in 2016 against the old Icom polling code. The new `TIcomRadioBase` with CI-V protocol (`4d0528fc`) is a completely new implementation. **Test on IC-7300/7610/9700 to see if the new CI-V implementation still has this behavior.**

### [#315](https://github.com/n4af/TR4W/issues/315) — Detect data mode on IC-9100

The IC-9100 was not in the initial Icom CI-V implementation (IC-7300, IC-7610, IC-9700 were). However, if the IC-9100 uses the same CI-V protocol, HamLib Direct may now cover it. **Check if the IC-9100 works via HamLib Direct.**

### [#685](https://github.com/n4af/TR4W/issues/685) — Add descriptions for HamLib options

The HamLib Direct DLL work (`bcc66f16`) replaced the rigctld approach. If the old HamLib CTRL-J options were replaced or removed, this issue may be moot. **Check if the old HamLib menu options still exist or were superseded.**

---

## Not Addressed — Remaining 151 Issues

The remaining 151 open issues had no direct commit references and no strong evidence of resolution in the commit history. These include:

- **Feature requests** from 2015–2016 that were never implemented (SO2R boxes, OmniRig, Wizard, etc.)
- **New radio requests** (TS890/TS990, FTX-1F, Expert Electronics TCI)
- **New contest requests** (UKSMG, URC DX RTTY, etc.)
- **UI enhancements** (bandmap colors, beam heading sort, etc.)
- **Documentation** (#418 — documentation updates)
- **Stale issues** (#396 — accidental merge from 2020, likely can be closed as resolved)

### Housekeeping Candidates

These issues may be closable for reasons other than code changes:

| Issue | Title | Reason |
|-------|-------|--------|
| [#396](https://github.com/n4af/TR4W/issues/396) | Applied merge by mistake | This was a 2020 incident report, not an active bug. The revert was committed. Close as resolved. |
| [#833](https://github.com/n4af/TR4W/issues/833) | Is the source to the resource files available? | This is a question, not an issue. Answer it and close. |

---

*Analysis performed by cross-referencing all open GitHub issues against the complete Git commit history and merged PR descriptions of [n4af/TR4W](https://github.com/n4af/TR4W).*
