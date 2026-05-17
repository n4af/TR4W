# Feature request: optional auto-synchronize on log mismatch

## Context

When a TR4W client (re)connects to TR4WServer and the local log's CRC32 differs
from the server's, the "Difference in logs" dialog appears and waits for the
operator to choose Synchronize / Exit / Clear all logs in network.

In real multi-op operation this dialog fires every time a client reconnects
after even a brief disconnect (network blip, laptop sleep, manual server
restart) — because the server kept logging new QSOs while the client was
offline, so the CRC necessarily differs. Operators report always clicking
Synchronize, every time, which makes the dialog more obstacle than safeguard.

This is **a TR4W client-side change**. The server cannot drive this decision
because:

- `TLogFileInformation` is a fixed 19-byte packed record with no spare field
  to carry an "auto-sync" hint.
- Even if a hint existed, the action (overwriting the local log with the
  server's) happens on the client; the server cannot perform it remotely.

## What exists today

- Trigger: `uNet.pas:838-862` `ProcessServerLogInfo`. The relevant comparison
  is `if s^.liLocalCRC32 <> s^.liSeverCRC32 then IdenticalLogs := False;` —
  contest is displayed in the dialog but is not part of the trigger.
- Dialog: `CreateModalDialog(220, 110, tr4whandle, @LogCompareDlgProc,
  integer(s))` on mismatch. The dialog's Synchronize button pulls the full
  `SERVERLOG.TRW` from the server's sync port (`PORT + 1`).

## Proposed change

Add an INI key under the TR4W network section, e.g.:

```ini
[NETWORK]
AUTO SYNCHRONIZE ON CONNECT = 1
```

In `ProcessServerLogInfo`, when `IdenticalLogs = False` and the new flag is
true, invoke the same code path the Synchronize button triggers and skip
`CreateModalDialog` entirely. Default to `0` (current behavior — show the
dialog) so this is opt-in for the operator who already knows they always
click Synchronize.

Suggested log line on auto-sync:
`logger.Info('Auto-synchronizing local log from server (CRC mismatch: local %x, server %x)', [...])`
so operators can confirm in `tr4w.log` that the sync happened.

## Out of scope

- Contest mismatch: not currently used in the trigger, intentionally left
  alone. If contests differ, the existing dialog already shows it; auto-sync
  would silently overwrite which may surprise an operator who connected to
  the wrong server. If we ever want to be stricter, the natural check is
  `if (s^.liLocalCRC32 <> s^.liSeverCRC32) and (LocalContest = s^.liContest)
  then auto-sync else still show the dialog` — but probably not worth the
  complexity until someone hits the wrong-server case.
- Direction: this only handles "server is authoritative, pull from server."
  TR4W's existing Synchronize button is one-directional in the same way;
  any "merge local into server" feature would be a separate, much larger
  change.

## Related: Python TR4WServer

The Python reimplementation of TR4WServer (in c:\projects\TR4WServer)
mirrors the Delphi server's wire protocol exactly. It does not need any
changes for this feature — the auto-sync logic is purely client-side. If
the protocol ever does grow an auto-sync hint field, both servers would
need a coordinated update.

The Python server already implements:
- Serial-number lockout (matches `tr4wserverUnit.pas` behavior — startup
  scan of `NumberSent`, per-client `SM_SERIAL_NUMBER_CHANGED` push on
  connect, increment on reservation).
- Live per-station status table built from `TStationState` broadcasts
  (Band / Freq / St / PTT / Qs / Callsign / Op).
- `LOG RECORD SIZE` is configurable in `tr4wserver.ini` and validated
  against the on-disk `SERVERLOG.TRW`, so a future TR4W release that
  changes `SizeOf(ContestExchange)` produces a clear startup error rather
  than silent corruption.
