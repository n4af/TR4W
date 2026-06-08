# Running VCL forms inside the Win32 message-loop app

**Status:** proof-of-concept, captured for the Delphi 12/13 migration. NOT in
`master` — the working example lives on branch `Add-VCL-to-Program`
(commit `67785ae`, NY4I, Dec 2025). This document preserves the *technique* so
the knowledge survives independently of that branch.

## Why this matters

TR4W is a raw Win32 program: `program tr4w;` runs its **own** `GetMessage` /
`TranslateMessage` / `DispatchMessage` loop (`tr4w.dpr`) and creates windows by
hand with `CreateWindow`. It does **not** use the VCL `Application.Run` loop and
has no VCL `MainForm`. That makes windows like the **Band Map** and the **Telnet
(DX Cluster)** window painful — they're hand-built Win32 windows that would be
far easier to build and maintain as ordinary VCL forms designed in the Delphi
form editor.

This technique lets a standard VCL form (designed in the form editor, `.dfm` +
`.pas`) run **alongside** the legacy Win32 message loop, without converting the
whole program to a VCL app. It's the bridge for an **incremental** migration:
re-implement one window at a time as a VCL form while the legacy loop keeps
running, rather than a big-bang rewrite.

## The recipe (the five wiring changes)

### 1. `tr4w.dpr` uses clause — add `Forms` and the form unit
```pascal
uses
  Forms,                          // the VCL Application object
  Messages, MMSystem, Windows,
  ...
  Unit2 in 'src\Unit2.pas' {Form2};   // your form-editor form
```

### 2. `tr4w.dpr` startup — initialize VCL but DON'T let it own the app
At the top of the main `begin` block, **before** the legacy init:
```pascal
Application.Initialize;
Application.ShowMainForm := False;   // <-- critical
Application.Title := 'TR4W';

form2 := TForm2.Create(nil);         // <-- create manually, owner = nil
form2.Show;                          //     (NOT Application.CreateForm)
```

Two non-obvious points, both essential:

- **`Application.ShowMainForm := False`** — keeps the VCL `Application` from
  designating a main form and from auto-terminating. The Win32 window stays the
  real heart of the program.
- **`TForm2.Create(nil)`, never `Application.CreateForm(TForm2, Form2)`.** The
  POC comment spells this out: *"Do NOT do this `Application.CreateForm(...)`"*.
  `Application.CreateForm` makes the first-created form the **MainForm**, and
  closing the MainForm calls `Application.Terminate` — which would kill the
  whole program when the user closes that VCL window. Manual `Create(nil)` keeps
  the form a free-floating window whose close does not end the app.

Note the program still uses its own `while GetMessage(...)` loop — it never
calls `Application.Run`.

### 3. `tr4w.dpr` message loop — give VCL forms their keyboard messages
Inside the existing `while GetMessage(Msg, 0, 0, 0)` loop, **before**
`TranslateAccelerator`:
```pascal
// Give VCL a chance to handle dialog messages
if Application.DialogHandle <> 0 then
   begin
   if IsDialogMessage(Application.DialogHandle, Msg) then
      begin
      Continue;
      end;
   end;
```
Without this, a focused VCL form gets no tab/arrow/default-button navigation,
because those are dispatched by `IsDialogMessage`, which the legacy loop
otherwise never calls.

### 4. `VC.pas` — a global form reference
```pascal
uses ... Unit2, ... ;
var
  form2: TForm2;     // global so MainUnit can show/hide it
```

### 5. `MainUnit.pas` — a trigger to prove it works
A `FORM` command typed in the Call window creates/shows the form:
```pascal
// in the AnsiIndexText(...) command list, add 'FORM', then:
14: begin
      if form2 <> nil then
         VC.form2.Show
      else
         begin
         VC.form2 := TForm2.Create(nil);
         VC.form2.Show;
         end;
    end;
```

### The form itself (`Unit2.pas` / `Unit2.dfm`)
A completely ordinary form-editor form — `TForm2 = class(TForm)` with a
`TButton` and a `TMemo`, `{$R *.dfm}`. It `uses MainUnit`, so the VCL form can
call straight into the legacy globals/`logger`. The takeaway: once the wiring
above is in place, **the Delphi form designer just works** — no special form
code is required.

## Caveats / open questions for the real migration

- **Proof-of-concept.** The author's own note: *"It's a theory anyway."* It
  brings up a designed form; it has not been hardened for production.
- **`Application.DialogHandle` is the *active* dialog only.** It covers the
  form that currently has the VCL dialog focus. Multiple simultaneous
  non-modal VCL forms may need each form's own `IsDialogMessage`, or routing the
  message pump through `Application.HandleMessage` / a per-form check.
- **No `Application.Run`.** The legacy Win32 loop remains in charge. The eventual
  D13 end state (full VCL, `Application.Run`, a VCL main form) is different — but
  this technique is the *transitional* path that lets VCL forms (Band Map,
  Telnet, new feature dialogs) be introduced one at a time first.
- **Ownership / lifetime.** Forms are created with owner `nil`, so they are not
  auto-freed by an `Application`/owner — free them explicitly or manage the
  global reference (`form2 := nil` on destroy) to avoid showing a freed form.

## Reference
- Branch `Add-VCL-to-Program`, commit `67785ae` — the working POC diff
  (`.gitignore`, `tr4w.dpr`, `tr4w/src/MainUnit.pas`, `tr4w/src/VC.pas`,
  `tr4w/src/Unit2.pas`, `tr4w/src/Unit2.dfm`).
- Hand-derived by NY4I after considerable research; see also the broader
  Delphi 12/13 conversion plan in `docs/`.
