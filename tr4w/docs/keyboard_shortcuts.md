# TR4W Keyboard Shortcut Inventory

Last audited: April 2026. Update this file whenever a new shortcut is added.

---

## Function Keys

All 36 combinations are user-programmable via contest .cfg files:
- **F1–F12** — CQ mode messages
- **Ctrl+F1–F12** — Alternate messages
- **Alt+F1–F12** — Alternate messages

---

## Alt + Letter

**All 26 letters are taken.** Partial list of known bindings:
- Alt+A/B/C/D/E/F/G/H/I/J/K/L/M/O/P/Q/R/S/T/V/W/X/Y/Z

Also taken: Alt+= , Alt+- , Alt+` (backtick)

---

## Ctrl + Letter

Sourced from `src/uMenu.pas` constants (the authoritative list).

| Key | Status | Bound to |
|-----|--------|---------|
| Ctrl+A | TAKEN | RC_SENDKEYBOARD_HK |
| Ctrl+B | TAKEN | RC_COMMWITHPP_HK |
| Ctrl+C | TAKEN | RC_CLEARMSHEET_HK |
| Ctrl+D | TAKEN | RC_DAQSLINT_HK |
| Ctrl+E | **FREE** | — |
| Ctrl+F | **FREE** | — |
| Ctrl+G | **FREE** | — |
| Ctrl+H | **FREE** | — |
| Ctrl+I | TAKEN | RC_IAQSLINT_HK |
| Ctrl+J | TAKEN | RC_CTRLJ_HK (Options) |
| Ctrl+K | TAKEN | RC_CLEARDUPES_HK |
| Ctrl+L | TAKEN | RC_VIEWEDITLOG_HK |
| Ctrl+M | **FREE** | — |
| Ctrl+N | TAKEN | RC_NOTE_HK |
| Ctrl+O | TAKEN | RC_MISSMULTSREP_HK |
| Ctrl+P | TAKEN | RC_Redoposscalls_HK |
| Ctrl+Q | TAKEN | RC_QTCFUNCTIONS_HK |
| Ctrl+R | TAKEN | RC_RECALLLASTENT_HK |
| Ctrl+S | TAKEN | RC_SHDX_CALLSIGN_HK |
| Ctrl+T | **FREE** | (was RC_TRANSFREQ_HK, commented out) |
| Ctrl+U | TAKEN | RC_VIEWPAKSPOTS_HK |
| Ctrl+V | TAKEN | RC_EXECONFIGFILE_HK |
| Ctrl+W | **FREE** | — (not in menu file) |
| Ctrl+X | **FREE** | — |
| Ctrl+Y | TAKEN | RC_REFRESHBM_HK |
| Ctrl+Z | **FREE** | — |
| Ctrl+1–4 | TAKEN | AI window controls |

**Available Ctrl+letters: E, F, G, H, M, T, W, X, Z**

---

## Ctrl+Alt Combinations

Taken: Ctrl+Alt+1, 2, B, I, L, M, N, S, T, W

---

## Shift+Ctrl Combinations

Taken: Shift+Ctrl+` through 9 (window selection), Shift+Ctrl+0 (MP3 recorder)

---

## Special / Configurable Keys

These are soft-configured defaults (user can change):
- `'` apostrophe — StartSendingNowKey
- `\` backslash — QuickQSLKey1
- `=` equals — QuickQSLKey2
- `,` comma — PossibleCallLeftKey
- `;` semicolon — PossibleCallAcceptKey
- `.` period — PossibleCallRightKey
- `]` right bracket — TailEndKey
- `-` dash — SwitchRadioKey (in call window)

---

## Other Special Keys

- Tab — Search & Pounce
- Shift+Tab — CQ mode
- Esc, Del, Enter, Ins, Pause
- PgUp, PgDn, Ctrl+PgUp, Ctrl+PgDn
- Numpad 0–9 — CW memories (when KeypadCWMemories=True)

---

## Key Source Files

| File | What it defines |
|------|----------------|
| `src/uMenu.pas` | Menu accelerator definitions (lines 41–132) |
| `src/trdos/LOGSTUFF.PAS` | Configurable character key definitions (lines 510–577) |
| `src/MainUnit.pas` | Key processing logic |
| `tr4w.dpr` | WM_KEYDOWN / WM_CHAR dispatch in main message loop |
| `src/uFunctionKeys.pas` | Function key window handling |
