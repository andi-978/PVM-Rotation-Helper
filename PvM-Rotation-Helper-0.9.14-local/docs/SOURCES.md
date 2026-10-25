# Sources and development material — 0.9.14

Current work uses the project's implementation/tests/tools, user requirements and changelog, official Jagex documentation and verified game-data facts. Third-party plugin source/documentation has not been reopened or compared for this work. [AI-STATUS.md](AI-STATUS.md) distinguishes the user's account of idea inspiration from recorded earlier source analysis; neither is presented as a verified finding of code copying.

## Official API references

The project records these references as reviewed on 24 October 2026:

- [Getting started](https://developer.runescape.com/rs/getting-started.html), [Manifest](https://developer.runescape.com/rs/structure.html).
- [Events](https://developer.runescape.com/rs/core/events.html), [PersistentDB](https://developer.runescape.com/rs/core/persistentdb.html), [ObjType](https://developer.runescape.com/rs/game/config/objtype.html).
- [Components](https://developer.runescape.com/rs/ui/component.html), [Stylesheets](https://developer.runescape.com/rs/ui/stylesheets.html), [Button](https://developer.runescape.com/rs/ui/interactive_components/button.html), [Sprite](https://developer.runescape.com/rs/ui/decorative_components/sprite.html).
- [Submission](https://developer.runescape.com/rs/submission/process.html), [Description](https://developer.runescape.com/rs/submission/example.html), [Guidelines/AI policy](https://developer.runescape.com/rs/submission/guidelines.html), [EULA](https://legal.jagex.com/docs/terms/eula).

The 25 October 2026 two-pass review rechecked the official event, PersistentDB, Component, Keyboard, Mouse and manifest contracts. It reviewed current own source/callers and synthetic native failures rather than treating earlier test counts or current configuration availability as full native-client verification. See [the technical reference](TECHNICAL-REFERENCE.md) and [current audit](AUDIT-0.9.14.md).

Catalogues use project-collected Wiki game facts with revisions and explicitly authorized project beta metadata exports. No downloaded game images or third-party plugin code are included as catalogue resources. Artwork resolves through native Jagex configuration.

Full development evidence is under `development/pvm-lernstudio/data/`: WEAPON-DATA, AMMUNITION-DATA, POTION-DATA, SPELL-DATA, ITEM-NATIVE-DATA, CATALOGUE-LOCALIZATION-DATA and PRAYER-DATA.json. Generators/tests are in `tools/` and `tests/`; raw facts and observations are in `outputs/`. They are not loaded by the plugin. A separate review-material archive accompanies the product ZIP.

Earlier project documents and seven obsolete one-off patch/observation tools remain unchanged under `history/pvm-lernstudio/0.9.0/`. Archiving does not rewrite the development history. The [source register](SOURCE-REGISTER.md) records actual imports and hashes; registration alone does not establish every line's provenance or personal human review.

## User requirements and UI evidence

- The 0.9.2 interaction changes follow `rs2client_OxbM2Y28uW.mp4`, `0XEl5wEZk8.png`, `20QzsVVhgN.png` and the user's additional instructions. The nine Greater selection pairs and eleven passive incantations use previously evidenced project ability identities, without importing third-party plugin source or guessed native IDs.
- The compact toolbar/search layout follows `lYcJrHrffQ.png` and `hPODfwbQQm.png` from 24 October 2026.
- Retained selection and right-click assignment follow `gcaz388nMI.png` and the user's explicit interaction request. References: [MiniMenu:Add and priority](https://developer.runescape.com/rs/game/minimenu.html), [MiniMenuReady](https://developer.runescape.com/rs/core/events.html#minimenuready), [Component.isMouseOver](https://developer.runescape.com/rs/ui/component.html#state-properties). Only own editor context actions are added.
- Native rectangle-drawn vertical profile-scroll arrows follow `xPke0rz6ZA.png`; the underlying scroll actions are unchanged.
- The synchronized 1–100 numeric transparency field follows `KUtBIfxKAO.png` and uses the existing InputField/Slider and preview/save path.
- The 0.9.4 search/filter row follows `C8YaZMXTvt.png`, including extra style/tier and spellbook filters. Narrow layouts stack extra filters in the right column.
- The localization, literal-profile-name and cleanup requirements include `pKmnzy97P3.png` and the user's follow-up instructions. Phase actions now occupy a row above step actions. Custom names remain literal.
- The 0.9.7 Hub click-through placement and removal of duplicate overlay toolbar/close controls follow `Xpbvenvbgf.png` and the user's follow-up instructions. Manual phase buttons remain clickable under click-through by explicit request.
- The 0.9.8 unlimited phase-step capacity, input-driven page following and caption placement follow the user's further instructions, including `smXMMGETk8.png` and `Q2enwLKmP9.png`. Captions sit above their own ability icons; phases change manually rather than following page progression.
- The 0.9.9 prayer category, framed passive tiles and localized product rename follow `z0AqDkoL7W.png`, `3jWMimyTvO.png`, `Qz3g9MTZnu.png` and the user's explicit instructions. The old technical folder/save identifiers remain for compatibility; historical product names in prior archives are not rewritten.
- The 0.9.10 technical rename to pvm-rotation-helper follows the user's explicit request. Earlier folder/provenance names stay recorded in history and development facts; active package/listing paths and console instructions use the new identifier. Own-record storage metadata distinguishes current screenshot-matching profiles from older training namespaces.

- The 0.9.11 complete Bindings categories, natural navigation translations and geometry-only resize preview follow `rs2client_M2z3o2mswq.mp4` and the user's follow-up reports. The user explicitly requested manual labels for items, spells and prayers to represent complete bars. Typed native import uses only the documented associatedObjectID property of Sprite/Button and reviewed catalogue identity mappings. Explicit release/cancellation hooks address the reported sticky title drag; no mouse-button polling API is assumed.

- The 0.9.12 review follows the user's explicit request for two complete source-review passes, removal of proven dead executable code and comprehensive English documentation. New report paths are English; original historical outputs and provenance dates are preserved. No additional third-party plugin material or client automation was used.

The user's recordings and screenshots are not distributed in the runtime package.

The 0.9.14 Hub cleanup follows the user's explicit request to remove Hide plugin windows and exclusively owned code. Production callers/state writers were traced before removing the transient hide action and visibility guards. Shared Stop/teardown, panel Close/Minimize, Show overlay, click-through and manual phase functions remain independently used. No schema or native profile migration is required.

The 0.9.13 category and exclusive-selection corrections follow rs2client_8PldfqgJpW.mp4 and the user's explicit instructions. The four tar identities already belong to the reviewed ammunition data; the change separates existing categories rather than collecting new game facts. The video demonstrates the previous double outline, while strict UI regressions check the new selection behaviour for every passive kind.

## Selected-language catalogue names

The static name resource contains 1253 items, 156 abilities and 141 spells, including eleven incantations, in English, German, French and Brazilian Portuguese.

Names come from Jagex game configuration dated 19 October 2026 via the documented [OpenRS2 data API](https://archive.openrs2.org/api): live caches [English 2742](https://archive.openrs2.org/caches/runescape/2742), [German 2743](https://archive.openrs2.org/caches/runescape/2743), [French 2744](https://archive.openrs2.org/caches/runescape/2744) and [Portuguese 2745](https://archive.openrs2.org/caches/runescape/2745), each identified by the archive as sourced from Jagex. Only individual configuration groups were read. The offline collector checks JS5 checksums/file tables, English name anchors and localized segment prefixes. Live internal Struct names resolve four numeric IDs that differ between beta and live.

Vampyre Slayer, Vital Drain, Sanguine offering and Invoke Arisen Flesh are present in the live data. Their German names are “Vampirtöter”, “Lebensentzug”, “Sanguinopfer” and “Fleischerhebung-Anrufung”. An initial assumption that they were beta-only was corrected through live name resolution; the active resource uses verified localized names for them.

Project display qualifiers distinguish four basic attacks by skill, two scythe recasts and eighteen item tiers. Canonical English catalogue labels remain for unambiguous selection. Full raw/used names and provenance are in `development/pvm-lernstudio/data/CATALOGUE-LOCALIZATION-DATA.json`; `tools/build_catalogue_localizations.py` reproducibly renders `data/catalogue_names.lua`. Artwork and saved identities retain their confirmed configuration-name mapping. There is no runtime HTTP request.


## Implementation and data inventory

The user confirms concept-only inspiration and no reuse of another plugin's code or data. The active package is implemented within this project; literal module imports resolve only to registered project modules. Catalogue provenance identifies Jagex game configuration/native artwork, project-collected beta exports and Wiki game facts, while UI translations are project resources. These are distinct from another plugin's data. The current audit does not reprocess other plugin sources or claim a copying comparison; historical analysis is documented separately in AI-STATUS.md without treating it as evidence of copying.

## Prayer facts

`PRAYER-DATA.json` records all 137 own-index COMBATV2 prayer/curse identities. The 83 reviewed PvM choices have four-language names/levels from the same Jagex-sourced live cache snapshots. Nineteen named candidates are excluded, and 35 aggregate/dummy/state helpers are recorded separately. Selection excludes skill-only effects, Quick Prayer controls, PvP-target effects and entries without verified PvM use; dual-use combat support remains. Native tooltips and recorded official/game-fact references support scope decisions; individual Wiki pages were inaccessible and no unlock/monster-susceptibility test was performed.

`tools/build_prayer_catalogue.py` reproduces the runtime resource, normalizing native markup/line breaks into plain text while retaining raw observations. The runtime stores named identities rather than Sprite constants and resolves current artwork through official Struct/Param access. No active prayer state, downloaded game images or third-party plugin sources are used.

A read-only check of the same primary English cache also verified prayer-book membership. Expanding nine tiered parent Structs yields 46 standard prayers; the ancient book yields 45 curses. Every included record belongs to its correct expanded book and COMBATV2_ABILITIES_PRAYER. The 91 actual prayers minus two skill-only and six PvP-target/unverified-PvM exclusions yield the implemented 83. Tiered children such as Charge and the Force prayers remain actual choices; aggregate parent/state helpers are not additional selectable entries.
