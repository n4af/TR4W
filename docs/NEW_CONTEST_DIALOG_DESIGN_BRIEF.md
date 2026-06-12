# New Contest Dialog — Design Brief

**Project:** Redesign of the TR4W "Open configuration file / start a new contest" dialog
**Date:** 2026-06-12
**Status:** Feature analysis complete; awaiting implementation after TR4W port
**Reference implementation:** TR4QT (Qt/C++) "Contest Chooser"

---

## 1. Purpose

Modernize TR4W's New Contest dialog, originally designed in the Windows XP era, for
Windows 11 — both in **feature set** and in **platform/visual presentation**. This brief
captures the conclusions of a comparative analysis of five dialogs in the same space:
**TR4W, TR4QT, N1MM, Win-Test, and DXLog.net.**

This is a **feature analysis**, not a code design. Implementation details (control
classes, the floating-date resolver, etc.) are out of scope here.

---

## 2. What the current TR4W dialog is

The existing dialog is effectively **two unrelated tools bolted into one window**:

1. **Left half — a raw Windows file/folder browser.** It shows a literal filesystem path
   (`c:\tr4w\tr4w\target`), a `[..]` parent-directory entry, and a scrolling list of
   `.cfg` entries whose only metadata is encoded in the *filename*
   (e.g. `[2025 NAQP-CW NY4I]`). A bottom-left button resumes the most recently opened
   contest, captioned with a raw file path (`Latest config file (Alt+A): ...cq-vhf.cfg`).
2. **Right half — a new-contest form.** MY CALL, a CONTEST dropdown, a dynamic
   instruction/field area, and six generic Cabrillo `CATEGORY-*` dropdowns.

Most of the shortcomings below flow from this split personality.

### Things the current dialog already does RIGHT (carry forward)

- **One-click "resume last contest"** (Alt+A) — the fastest recovery path of any of the
  five dialogs (e.g., PC dies mid-contest at a multi-op; power back up, one click, logging
  again). Keep the capability; fix only the presentation.
- **Dynamic, contest-driven form.** Selecting California QSO Party adds a `MY STATE` field
  and contest-specific instruction text. The capability is correct; the execution is dated.
- **Per-contest `MY CALL` override.** You can set the operating call to anything (club call,
  special-event call) for a given contest — a genuine gap in TR4QT.

---

## 3. Shortcomings of the current dialog

1. **The filesystem leaks into the UI.** Users must think in folders, `[..]`, and absolute
   paths. Brittle and unintuitive.
2. **Metadata trapped in filenames.** `[2025 NAQP-CW NY4I]` packs year/contest/call into one
   string — no sortable columns, no real contest name vs. file name.
3. **Resume vs. Create are conflated** with no clear boundary; ambiguous which list drives
   what, and what OK does.
4. **No search/filter** on a contest list that grows unbounded.
5. **Dynamic form presentation is dated:** the instruction text sits in an inert recessed
   gray panel (easily mistaken for decoration), and the fixed-size XP frame makes the layout
   *jump* when fields appear rather than resizing.
6. **The "resume last" button speaks implementation** ("Latest config file" + a raw path)
   instead of intent, and sits in a corner competing with the list — hence operators have to
   be verbally coached to "click the big button."
7. **XP-era platform:** flat gray, default font, fixed non-resizable modal, no DPI awareness
   (blurs/clips at 150 %+), ignores Windows theme/accent/dark mode.

---

## 4. Comparative feature matrix (five dialogs)

Legend: **✓** present · **◐** partial · **✗** absent but relevant · **—** out of that
dialog's scope (the competitor dialogs are config-only and handle "resume an existing log"
elsewhere).

| Feature | TR4W | TR4QT | N1MM | Win-Test | DXLog |
|---|---|---|---|---|---|
| **— List / selection —** | | | | | |
| Database-backed list (not filesystem) | ✗ | ✓ | ✓ | — | — |
| Columned existing-contest grid (Name/Type/Date/Ver) | ✗ | ✓ | — | — | — |
| Resume-vs-Create clearly separated | ◐ | ✓ | — | — | — |
| Delete / manage existing contests | ◐ | ✓ | — | — | — |
| One-click "resume **last**" (no selection step) | ◐ | ✗ | ✗ | ✗ | ✗ |
| Rolling "next contest first" sort | ✗ | ✓ | ✗ | ✗ | ✗ |
| Date filter ("this month only") | ✗ | ✗ | ✗ | ✓ | ✗ |
| Type-ahead search on contest list | ✗ | ✗ | ✗ | ✗ | ✗ |
| Native date/time picker for start | ✗ | ✓ | ✓ | — | — |
| **— Contest metadata —** | | | | | |
| Human-readable schedule shown | ✗ | ✗ | ✗ | ✗ | ✗ |
| Description shown in dialog | ✗ | ✗ | ✗ | ✗ | ✗ |
| Website / rules link | ✗ | ✗ | ✓ | ✗ | ✗ |
| Contest-driven exchange/category fields | ◐ | ✓ | ✓ | ◐ | ◐ |
| Per-contest field guidance | ◐ | ✓ | ✓ | ✗ | ✗ |
| Dialog resizes to fit dynamic fields | ✗ | ✓ | ✗ | ✗ | ✗ |
| Auto-filled, editable contest name | ✗ | ✓ | ✗ | ✗ | ✗ |
| **— Setup / entry —** | | | | | |
| Category dropdowns (band/mode/power/etc.) | ✓ | ✓ | ✓ | ✓ | ✓ |
| Per-contest MY CALL override | ✓ | ✗ | ◐ | ◐ | ◐ |
| Sent exchange field | ✗ | ✗ | ✓ | ✓ | ✓ |
| Operators field | ✗ | ✗ | ✓ | ✓ | ✓ |
| Soapbox field | ✗ | ✗ | ✓ | ✗ | ✗ |
| Populate from last log/contest | ✗ | ✗ | ✓ | ✗ | ✗ |
| **— Station —** | | | | | |
| Station identity fields (grid, zones, address) | ✗ | ✗ (in Prefs) | ◐ | ✓ | ✓ |
| Multiple station profiles (Load/Save) | ✗ | ✗ | ✗ | ✓ | ◐ |
| Network / multi-op setup in dialog | ✗ | ✗ | ✗ | ✓ | ✗ |
| **— Platform / UX —** | | | | | |
| Win11-native styling & DPI awareness | ✗ | ✓ | ✗ | ✗ | ◐ |
| Resizable dialog | ✗ | ◐ | ✗ | ✗ | ✗ |
| Filesystem paths hidden from user | ✗ | ✓ | ✓ | ✓ | ✓ |

### How to read the matrix

- **TR4W's column is almost entirely ✗** in list/selection and metadata — the XP-era gap.
- **TR4QT already recovers the list/selection tier** and is the only Win11-native one. It is
  the reference for the redesign.
- **The whole "Contest metadata" block is empty across all five** — nobody surfaces
  schedule/description/website *in the dialog*, yet the TR4QT contest factory already carries
  that data. This is a leapfrog opportunity, not catch-up.
- **N1MM owns "setup/entry" richness** (exchange, operators, soapbox, populate-from-last).
- **Win-Test owns "station"** (profiles + network) — relevant only if dialog scope grows.

---

## 5. Scope decisions (resolved)

**Scope 1 — Station identity:** The new dialog does **NOT** absorb full station identity or
Win-Test-style station profiles. That stays in **Preferences > Station Info** (persistent
home-station default — callsign, name, license class, grid, zones, state, section, county).
The dialog **DOES** keep a per-contest **MY CALL** operating-call override, pre-filled from
Station Info but editable so the user can run a **club / special-event call** for a contest.

*Known accepted limitation:* a club call operated from a **different QTH** would also have a
different grid/zone/section. This is the minority case and will **not** clutter the dialog —
handle by editing Station Info or as a future enhancement.

**Scope 2 — Resume model:** **Hybrid.** Keep the single one-click **"Resume last"** button
(zero-decision fast path) **and** make the existing-contests grid **sortable via clickable
column headers**. No separate "recent contests" widget.
*Nuance:* sort/surface by a **"Last Opened/Modified"** key, not the contest's Start Date, so
the contest you were just working floats to the top.

---

## 6. Target feature set & implementation tiers

Features split into two tiers by dependency on the **contest factory**, which TR4W does not
have yet. Plan: **(1) port TR4W first, (2) then port the TR4QT contest factory (floating-date
schedule, website, description, exchange definitions) from Qt/C++ into Delphi 12.**

- **Tier 1** = available at the TR4W port, no factory needed.
- **Tier 2** = requires the ported contest factory.

| Feature | Target | Tier | Note |
|---|---|---|---|
| **— List / selection —** | | | |
| Database-backed list (no filesystem browser) | ✓ | 1 | Kill `[..]` and absolute paths |
| Columned existing-contest grid (Name/Type/Date/Ver) | ✓ | 1 | From TR4QT |
| Clickable sortable columns | ✓ | 1 | Enables "recent" |
| "Last Opened" column / sort key | ✓ | 1 | Recent activity floats up, not start date |
| Resume-vs-Create clearly separated | ✓ | 1 | Fixes the core two-tools flaw |
| Delete / manage existing contests | ✓ | 1 | From TR4QT |
| One-click "Resume last" button (Alt+A) | ✓ | 1 | Caption = friendly name, not file path |
| Rolling "next contest first" sort (Create list) | ✓ | 2 | Needs floating-date resolver |
| Type-ahead search on contest list | ✓ | 1 | Nobody else has it |
| Native date/time picker for start | ✓ | 1 | |
| **— Contest metadata —** | | | |
| Human-readable schedule shown | ✓ | 2 | e.g. "Fourth full weekend of June" |
| Description shown | ✓ | 2 | factory `meta.description` |
| Website / rules link | ✓ | 2 | factory `meta.website` |
| Contest-driven exchange fields | ✓ | 2 | Factory declares fields |
| Per-contest field guidance (inline placeholders) | ✓ | 2 | TR4QT-style, not a detached gray panel |
| Dialog resizes to fit dynamic fields | ✓ | 1 | Resize mechanism Tier 1; triggering fields Tier 2 |
| Auto-filled, editable contest name | ✓ | 2 | Derived from type + year |
| **— Setup / entry —** | | | |
| Category dropdowns (band/mode/power/etc.) | ✓ | 1 | Already present |
| Per-contest **MY CALL** override | ✓ | 1 | Default from Station Info, editable |
| Sent exchange field | ✓ | 2 | Driven by contest |
| Populate from last contest | ✓ | 1 | From N1MM idea |
| Soapbox field | ✗ | — | Not in this dialog |
| **— Station —** | | | |
| Full station identity fields on dialog | ✗ | — | Stays in Preferences > Station Info |
| Multiple station profiles (Load/Save) | ✗ | — | Not adopting Win-Test model |
| Network / multi-op setup in dialog | ✗ | — | Out of scope (separate) |
| **— Platform / UX —** | | | |
| Per-monitor DPI awareness | ✓ | 1 | Fixes XP-era blur/clip at 150 %+ |
| Win11 theme + accent + dark mode | ✓ | 1 | |
| Segoe UI Variable font | ✓ | 1 | |
| Resizable window | ✓ | 1 | Also serves dynamic fields |
| Filesystem paths hidden from UI | ✓ | 1 | "Show Database Folder" escape hatch only |

---

## 7. Phased outcome

- **At the TR4W port (Tier 1, no factory):** a clean two-zone dialog — sortable,
  database-backed grid with last-opened surfacing + one-click resume on one side; a Create
  form with MY CALL override, type-ahead, native date picker, and populate-from-last on the
  other — plus full Win11 platform modernization. This alone retires every XP-era shortcoming
  that is not contest-knowledge-dependent.
- **After the factory port to Delphi 12 (Tier 2):** rolling next-contest sort, dynamic
  contest-specific fields with inline guidance and auto-naming, and schedule / description /
  website / exchange metadata — all data-driven from the factory.

**Key constraint:** Build the Tier 1 dialog with empty/placeholder hooks for the Tier 2 data
(the dynamic-field region and the Create dropdown source) so that **nothing in Tier 1 has to
be rebuilt** when the factory lands — it simply gets populated from a richer source.

---

## 8. Open items / to verify during implementation

- Confirm the actual gating logic for the OK/Create button (inferred: contest selection is
  mandatory).
- Decide the secondary sort for contests landing on the same date (stable / alphabetical).
- "Populate from last contest" — confirm whether it should match by contest *type* (Tier 2
  refinement) or simply copy the most recent categories (Tier 1).
