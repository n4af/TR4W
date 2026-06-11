# TR4W Internationalization – Delphi 7 → Delphi 12

## 1. Current State (Delphi 7)

- **Language-specific constant units**
  - TR4W uses units like `tr4w_consts_en.pas` containing string constants such as:
    - `TC_YOU_ARE_USING_THE_LATEST_VERSION = 'You are using the latest version';`
    - `TC_SET_VALUE_OF_SET_NOW = 'Set value of %s. Set now?';`
    - `TC_ISADUPE = '%s is a dupe!!';`
  - Code references these via identifiers (`TC_...`) rather than hardcoded literals, which is already good separation of text from logic.
  - There are 9 supported languages, with 2 files per language.

- **INI-based configuration help**
  - Separate INI file(s) provide help/description text for configuration parameters, e.g.:
    - `[BACKUP LOG FREQUENCY]`
      - `DEFAULT=0`
      - `DESCRIPTION=Backups up the TR4W log to the above location every number of contacts.`
    - `[BAND MAP DISPLAY GHZ]`
      - `DEFAULT=FALSE`
      - `DESCRIPTION=For VHF contests, displays GHz frequencies in the bandmap`
  - The item in `[]` is a stable parameter name (not localized).
  - `DESCRIPTION` is displayed in the configuration UI as help text. This is effectively a second catalog of user-visible strings separate from `TC_*`.

- **Encoding / codepage handling**
  - There are translations for Chinese and Cyrillic languages.
  - Current approach relies on ANSI/codepage behavior in Delphi 7, which complicates handling of multi-language text and requires care around fonts and file encodings.

- **Translation workflow today**
  - 9 languages, 2 files per language.
  - Translation is done using tools like LibreTranslate for initial machine translation, followed by human review by native speakers.
  - Reviewers work directly with language files (Pascal/INI), rather than through a centralized translation UI or database.

---

## 2. Target Model (Delphi 12)

### 2.1 Core Delphi 12 I18N Model

- Delphi 12 remains centered on **resource-based localization**:
  - `resourcestring` declarations in code.
  - Form resources (`.dfm`) and general resources (`.rc`), localized into **resource-only DLLs** per language. [web:4][web:22]
- At runtime:
  - The app uses `LoadResString` and resource loading functions to fetch localized text.
  - Delphi redirects resource loading to the appropriate language-specific resource DLL if present. [web:22]

### 2.2 Migration Goals for TR4W

- **Unify all user-visible text under the Delphi resource system**:
  - Move `TC_*` constants from `const` to `resourcestring`.
  - Treat INI `DESCRIPTION` text either as:
    - External language-specific text files (UTF-8/Unicode), or
    - `resourcestring` values keyed by parameter name (preferred for a unified pipeline).

- **Single EXE + one resource DLL per language**
  - Aim for a design where there is:
    - 1 TR4W EXE.
    - 1 resource DLL per language (e.g. `TR4W.de`, `TR4W.it`, `TR4W.ru`).
  - Avoid an explosion of DLLs by keeping TR4W essentially monolithic from the resource point of view.

- **Unicode-first handling**
  - Delphi 12 is Unicode-based (UTF-16) internally, which simplifies Chinese and Cyrillic support once all strings live in `resourcestring`s or Unicode-aware files.
  - Ensure fonts and controls used in TR4W can display all necessary glyphs.

- **Modular string units**
  - Instead of one mega-unit, define string units aligned with logical areas of TR4W, for example:
    - `uStrings_Main` – general UI, prompts, messages (`TC_*` equivalents).
    - `uStrings_Config` – configuration-related prompts and config help text.
    - `uStrings_Network`, `uStrings_CW`, etc., if needed.
  - This improves readability, compilation times, and mapping between features and translations.

---

## 3. Translation Workflows

### 3.1 Using Delphi’s External Translation Manager (ETM)

**Role of ETM**

- ETM is a standalone desktop tool provided by RAD Studio for translators who do not have the full IDE installed. [web:4][web:38]
- It operates **only at build-time**:
  - ETM is used to edit translation projects.
  - It does not ship with or run as part of the TR4W executable.
- Runtime TR4W remains a compiled EXE + resource DLLs; ETM is never on the main execution path.

**Planned ETM-based workflow**

1. **Prepare the project for localization**
   - Convert all `TC_*` constants to `resourcestring` declarations.
   - Ensure all user-visible text in forms is in `.dfm` resources.
   - Optionally migrate INI-based help descriptions into `resourcestring`s:
     - For example, `RS_CFG_BACKUP_LOG_FREQUENCY_DESCRIPTION = 'Backups up the TR4W log to the above location every number of contacts.'`.

2. **Create resource DLL projects**
   - Use **Resource DLL Wizard** / **Project > Languages > Add** to add target languages (9 existing ones) to the TR4W project. [web:4][web:22]
   - This generates:
     - A base language project (e.g. English).
     - A resource DLL project per language, containing localized `.dfm` and string resources.

3. **Translators use ETM**
   - Provide the ETM tool to translators/reviewers.
   - They open the translation group/project:
     - See a table of resource IDs / `resourcestring` names.
     - See source text and target text fields for each language.
     - Edit translations, mark status, and optionally add comments.
   - This becomes the primary editing environment for human reviewers.

4. **Build localized binaries**
   - Run “Build All” in Delphi or via CI:
     - Builds TR4W EXE.
     - Builds one resource DLL per language (e.g. `TR4W.de`, `TR4W.it`, etc.).
   - At runtime, TR4W loads the appropriate resource DLL based on locale or explicit language selection.

**Benefits**

- Centralized, Delphi-native translation view via ETM.
- No changes to runtime performance characteristics beyond standard resource loading.
- Translators do not have to touch `.pas` or `.ini` files directly once the pipeline is set up.

---

### 3.2 Optional Web-Based Translation System (Upstream of Delphi)

If a more centralized, web-based workflow is desirable, a custom translation management web app can sit **upstream** of Delphi’s resource system.

**Core mental model**

- Delphi (EXE + resource DLLs) is a **resource consumer**.
- The web app + database is the **source of truth** for translations.
- A generator runs during the build to export from the DB into Delphi-friendly resource artifacts.

**Suggested schema**

- `StringKey`
  - `Id` (PK)
  - `Name` (e.g. `TC_YOU_ARE_USING_THE_LATEST_VERSION`, `RS_CFG_BACKUP_LOG_FREQUENCY_DESCRIPTION`)
  - `Context` / `Description` (how/where it’s used; helps translators)
  - `Module` (e.g. `Main`, `Config`, `Network`) – used to generate modular Delphi string units.

- `Language`
  - `Id` (PK)
  - `Code` (e.g. `en`, `it`, `zh-Hans`, `ru`)
  - `Name` (human-readable language name)

- `Translation`
  - `Id` (PK)
  - `StringKeyId` (FK → `StringKey`)
  - `LanguageId` (FK → `Language`)
  - `Text` (Unicode text)
  - `Status` (e.g. MachineTranslated, Draft, Reviewed, Approved)
  - `LastEditorId` (FK → `User` / `Translator`)
  - `LastEditedAt` (timestamp)

- `TranslationAudit`
  - `Id` (PK)
  - `TranslationId` (FK)
  - `OldText`
  - `NewText`
  - `ChangedById` (FK → `User`)
  - `ChangedAt`

- `User` / `Translator`
  - Holds account info, roles, permissions for translators and reviewers.

**Typical workflow**

1. **Key definition**
   - Developers register all localization keys in `StringKey`:
     - All `TC_*` messages.
     - All config help descriptions.
   - Each key is associated with a `Module` and `Context`.

2. **Initial population / machine translation**
   - Use LibreTranslate (or another MT) to prefill `Translation.Text` for new keys and languages.
   - Mark MT entries with `Status = MachineTranslated`.

3. **Human review via web UI**
   - Translators log in to the web app.
   - Filter by language, module, status.
   - Edit translations inline, promote `Status` to `Reviewed` / `Approved`.
   - All edits are recorded in `TranslationAudit` for full history.

4. **Build-time export to Delphi**
   - A generator tool queries the DB and outputs:
     - Base-language `resourcestring` units, partitioned by `Module`, e.g.:
       - `uStrings_Main.pas`
       - `uStrings_Config.pas`
     - Per-language resource source files for resource DLL projects (e.g. `.rc` or Delphi localization project files).
   - The TR4W build then:
     - Compiles the base EXE with `resourcestring` units.
     - Builds resource DLLs per language, based on exported translation data.

**Benefits**

- Central, auditable translation store across all languages.
- Supports MT + human review workflow cleanly.
- Web-based access for translators; no Delphi installation required.
- Delphi and ETM remain downstream consumers of exported resource data, so runtime is unaffected.

---

## 4. Open Design Points / Future Questions

- **INI vs `resourcestring` for config help**
  - Option A: keep help text in external, per-language INI/JSON files (UTF-8), and load at runtime.
  - Option B (preferred for a unified system): move help text into `resourcestring`s and treat the INI as a map from parameter name to `resourcestring` key.

- **Exact modularization strategy**
  - Decide on the module breakdown for `uStrings_*` units:
    - Minimum: `uStrings_Main` and `uStrings_Config`.
    - Optional: additional units for major TR4W subsystems (SO2R, networking, DX cluster, etc.).

- **FMX / macOS port**
  - FireMonkey on macOS will not use Win32 resource DLLs, but the same `StringKey`/`Translation` database and generator approach can be reused.
  - Platform-specific generators can target:
    - Windows: `resourcestring` + resource DLL projects.
    - macOS: FMX-friendly resource packaging within the app bundle.

- **Build integration**
  - Decide how the translation generator is integrated:
    - As a pre-build step in Delphi’s project options.
    - As part of a CI pipeline script that regenerates `uStrings_*` and resource files before invoking the Delphi compiler.

---

## 5. Summary Mental Model

- **Delphi app**:  
  - Fully language-aware through `resourcestring`s and resource DLLs.  
  - At runtime, it only deals with resources; it does not know about ETM or any web app.

- **ETM**:  
  - Optional, Delphi-provided desktop tool for translators.  
  - Build-time only; edits resource projects that are later compiled.

- **Optional web app + DB**:  
  - Source of truth for keys and translations.  
  - Provides a modern, collaborative translation workflow.  
  - Feeds Delphi’s resource system via generation of `resourcestring` units and resource project files.

This document is meant as a high-level design note to keep the mental model of TR4W’s Delphi 12 I18N migration consistent as the implementation proceeds.