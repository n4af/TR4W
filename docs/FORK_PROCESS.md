# TR4W → TR4W-2026 Fork Process

Runbook for splitting the Delphi 12 migration onto its own repository, keeping
the shipping Delphi 7 line stable throughout. Read alongside
[`tr4w-migration-strategy.md`](tr4w-migration-strategy.md) (the phased migration
plan) and [`PHASE_INVENTORIES.md`](PHASE_INVENTORIES.md) (asm / `wsprintf`
worklists).

Decided 2026-06-12 (NY4I).

---

## Why a separate repo

The migration is long, multi-phase (Unicode → 64-bit → VCL), and will **never
merge back** into the Delphi 7 line. Doing it in place would destabilize the
shipping version for the duration. So:

- **`TR4W/TR4W`** stays the **Delphi 7 line** — releasable throughout the
  migration.
- **`TR4W/TR4W-2026`** (working title) is a new, independent repository where
  **all** migration activity happens.

This is archive-the-old + new-repo-for-migration: the standard pattern when a
migration is risky, long, and one-directional.

---

## Ground rule

> **Unless it is a blocking bug, we do not touch TR4W-D7.**

No features, no non-critical refactors, no cleanups on the D7 line once the
freeze is in effect. Only blocking-bug fixes. This is what keeps the
port-to-2026 queue small (see *Overlap discipline*).

---

## Mechanism: mirror-clone, NOT a GitHub fork

A GitHub "fork" implies an upstream relationship and a PR-back intent, and
GitHub is awkward about forks into the *same* org. TR4W-2026 will diverge and
never PR back, so use a **mirror-clone** — it carries the full history, blame,
tags, and branches into a clean independent repo with no fork baggage:

```bash
# 1. Create an EMPTY repo TR4W/TR4W-2026 on GitHub (no README/license/gitignore).

# 2. Mirror the D7 repo and push it into the new one.
git clone --mirror git@github.com:TR4W/TR4W.git tr4w-mirror
cd tr4w-mirror
git push --mirror git@github.com:TR4W/TR4W-2026.git

# 3. Clone TR4W-2026 normally for day-to-day work.
cd ..
git clone git@github.com:TR4W/TR4W-2026.git
```

(GitHub's **Import repository** UI does the same thing if you prefer a no-CLI
path.)

---

## When to fork: the freeze gate

Fork **after** the pre-migration prep is substantially done on the D7 repo, not
before. The prep builds the regression net that the migration is verified
against; it must be written on the frozen D7 baseline so it describes D7
behavior. The fork then carries that net forward.

Freeze-gate checklist (all on `TR4W/TR4W`):

- [ ] Pre-migration prep issues progressed/closed: **#1032–#1039**
      (legacy `BandType` tests, `uCTYDAT`, `uMults`, `uTestUtilsText`,
      and the `uDupeCheck` / `uScoring` / `uExchangeParsing` extractions).
- [ ] ASM removal advanced where cheap on D7 (#997 / #998) — reduces Phase 3
      surface area on the new repo. (Compiles fine in D7; only *breaks* in
      64-bit, so finishing it pre-fork is optional but valuable.)
- [ ] A green `FullBuild.ps1` (all languages + unit tests) on the D7 tip that
      will be mirrored.
- [ ] **D7 feature-freeze date set and announced** *(owner: NY4I)*.

When this is met, mirror-clone and start Phase 1 on TR4W-2026.

---

## Who owns which issues

| Work | Repo | Why |
|------|------|-----|
| Pre-migration prep (tests, extractions) — #1032–#1039 | **TR4W/TR4W (D7)** | Must be written against the frozen D7 baseline to be a valid regression net; rides the mirror into TR4W-2026. |
| Phase 1 blockers — shadow `SysUtils` removal, bundled Indy → D12 package | **TR4W-2026** | They only matter once D12 rejects them; no pre-migration value, only risk on D7. |
| Phase 2 — Unicode (`string`/`AnsiString`, `wsprintf` audit) | **TR4W-2026** | — |
| Phase 3 — 64-bit (remaining `asm`, pointer/`NativeInt` audit) | **TR4W-2026** | — |
| Phase 4 — VCL forms, `TThread`, DUnitX, contest factory | **TR4W-2026** | — |
| Blocking-bug fixes during overlap | **TR4W/TR4W (D7)** first, then port | See below. |

This split is *why* the shadow-`SysUtils` and Indy items were deliberately **not**
opened as D7 pre-migration issues — they are the first issues to open **on
TR4W-2026**.

---

## Overlap discipline (both repos live)

While both lines exist, a **blocking-bug fix lands on D7 first** (it has to — D7
is what's shipping), then is **ported to TR4W-2026**:

- Cherry-picks are clean early and get harder as TR4W-2026 diverges (Unicode,
  asm, VCL changes). Port promptly; don't let the queue age.
- Keep a short **PORTED-FROM-D7** log (or a label) on TR4W-2026 so it's obvious
  which D7 commits have/haven't been carried over.
- The "blocking bugs only" freeze is what keeps this queue small enough to be a
  cherry-pick rather than a re-implementation.

---

## CI / infrastructure for TR4W-2026

The new repo inherits the workflows (`release.yml`, `TagIt`, `FullBuild.ps1`,
the VirusTotal scan) via the mirror, but the runtime environment must be set up:

- **Self-hosted runner:** register the `[self-hosted, win-ci]` runner at the
  **org level** so one machine serves both repos, *or* stand up a second runner.
  *(Decision owner: NY4I — org-level vs. second machine.)*
- **Delphi 12** installed on whatever runner builds TR4W-2026 (Phase 1's whole
  point is "compiles under D12"). D7 and D12 can coexist on one machine, or use
  separate runners.
- **Secrets:** re-add `VIRUS_TOTAL_API_KEY` to TR4W-2026 (or set it org-level).
  Per the CI notes, jobs run under Windows PowerShell 5.1 on a LocalSystem
  self-hosted runner — keep that constraint in mind for any new workflow steps.
- The `TagIt` version-guard hardening (committed image of the bump-before-tag
  rule) carries over with the mirror; no change needed.

---

## Cutover (endgame)

When TR4W-2026 reaches production parity and ships its first D12 release:

1. Rename `TR4W/TR4W` → **`TR4W/TR4W-legacy`** and **archive** it (read-only).
2. Rename `TR4W/TR4W-2026` → **`TR4W/TR4W`** so it becomes the canonical repo.
3. GitHub redirects on rename keep existing git remotes and links resolving —
   **but** the installer/update URLs and the website (`tr4w.net`) point at
   release assets and must be repointed by hand. Audit those before cutover.
4. Stop producing D7 releases.

Naming the migration repo neutrally now (vs. baking a year into the permanent
name) avoids a second rename later; `TR4W-2026` is a *working title* for the
migration window only.

---

## Open decisions (owner: NY4I)

- **D7 feature-freeze date** — gates the fork.
- **Runner topology** — org-level runner serving both repos vs. a second
  machine dedicated to the D12 builds.
- Whether to finish the D7 asm removal (#997 / #998) before the fork or carry it
  into Phase 3 on TR4W-2026.
