# Changelog

## 0.9.14 — 25 October 2026

- Remove Hide plugin windows from the Plugin Hub. Move the settings opener directly below language controls and reduce unused Hub scroll height.
- Remove the exclusively used hideWindows action, transient uiHidden state, restoration/visibility branches and unused translations. Preserve shared Stop, teardown, normal settings Close/Minimize, Show overlay, click-through and manual phase controls.
- Keep saved profiles, schema and storage keys unchanged. Update English guides, architecture, source register and regression evidence for the current controls.

## 0.9.13 — 25 October 2026

- Keep ammunition out of Weapons. Arrows, bolts and the four reviewed tar ammunition identities remain in Ammunition, with existing localized names, styles and tiers.
- Remove Necromancy incantations from Spells while retaining their Necromancy choices. The shared Spells picker contains Magic spells; its book/type options exclude the duplicate incantation choices. Existing saved incantations and native-bar recognition remain readable.
- Make passive editor selection visually exclusive: adding/selecting a weapon, ammunition, potion, spell or prayer highlights that cell instead of also marking the preceding ability. Preserve the ability insertion boundary and assisted cursor.
- Preserve saved profiles and selected-language catalogues; verify both Editor and Bindings category paths with regressions.

## 0.9.12 — 25 October 2026

- Perform a complete module/function review, then an independent second pass over the corrected implementation, with separate coverage/findings records.
- Fix stale editor/bar-slot callbacks, post-delete input state, overlapping native-bar key corrections, stale native proxies/geometry and capture/Stop finalization paths.
- Preserve captions, reveal and selection for compatible old incantation steps without making them active progression triggers; correct rotation pager capacity.
- Remove proven unused executable helpers and write-only transient state while keeping validated saved-data compatibility and necessary older-client fallbacks.
- Add a comprehensive English technical reference and concise maintainer guide; clarify storage, module responsibilities, input attempts, native reads, limits and functional exclusions.
- Use English names for new audit/test/package reports. Preserve historical evidence and private records.
- Bind packaging/preflight to exact runtime, suite, harness and offline audit-input hashes. Fresh weapon-fact collection no longer writes unreviewed runtime data.
- Automated regressions do not establish current native rendering, FPS, platform coverage or personal/external approval.

## 0.9.11 — 25 October 2026

- Expose all twelve catalogue categories on Bindings, including weapons, ammunition, potions, spells and prayers. Click/drop assignments retain the existing key label; clearing a slot removes both its reference and label. Passive typed slots never become ability bindings or advance the rotation.
- Extend explicit visible-bar detection with confirmed canonical items and recognized spell/prayer identities. Preserve unrecognized or ambiguous actions as typed unknown slots with readable labels and transient observed artwork, without compressing positions or saving guessed native identities. Manual reassignment remains available.
- Use natural Editor, Bindings and profile-heading labels in all four plugin languages while preserving every saved profile name literally.
- Replace repeated full content rebuilds during held resizing with geometry-only previews. Keep existing controls, icon pixels, captions and pages; perform the complete content reflow once after release. Cache the gesture's minimum size and defer saves until capture ends. Component-work regressions use a strict API simulation; native client FPS has not been measured.
- Finish title dragging on explicit release notifications from the handle, window and containing layer. Retire captures on completion/cancellation and ignore stale duplicate notifications so a released window does not continue following the pointer.

## 0.9.10 — 24 October 2026

- Rename the active development package and console identifier to pvm-rotation-helper. Update source/listing paths, tooling, tests and instructions; Lua imports remain package-relative.
- Preserve existing save keys, ownership marker, callback references and historical source/data paths. Keep all original database records and back up only this project's exact records before a guarded namespace copy.
- Select the screenshot-matching schema-6 profile namespace explicitly rather than assuming the old console name identifies the current stored profiles. Copy raw structured-data bytes only into absent new identity variants; never overwrite a destination or decode/rewrite native serialization.
- Keep all gameplay and display behaviour unchanged, including prayer reminders, passive frames, localized branding, unlimited steps, caption placement, page following and manual phase changes.

## 0.9.9 — 24 October 2026

- Rename the product to PvM Rotation Helper, with localized visible titles/settings labels, updated English documentation/listing artwork and unchanged saved profile names. Keep existing development-folder, ownership and database identifiers for compatibility.
- Add 83 reviewed passive PvM prayer reminders: 44 standard prayers and 39 ancient curses, with four-language names, prayer-book filters, localized search/preview and confirmed named native artwork.
- Extend the existing ordered reminder format with exact-one prayer identities; reuse insertion, independent dragging, deletion, phase-end persistence, deduplication and the eight-cell group limit. Prayer reminders neither switch prayers nor advance progression.
- Draw passive prayer/item/spell reminders in editor-style square frames in the rotation display. Frames remain decorative, click-through and separate from full-opacity artwork.
- Normalize native name markup into plain display/search text while preserving raw source observations. Retain unlimited phase steps, captions above abilities, automatic page following and manual phase navigation.

## 0.9.8 — 24 October 2026

- Remove the fixed 96-ability-step limit per phase. Long phases remain fully validated, persist without truncation and migrate from supported older schemas without writes during loading.
- Keep rendering capacity separate from phase length: long editor and overlay sequences use pages, without imposing a 15-step phase cap.
- Verify input-driven page following in Learner/Advanced: completing the final configured repetition at a page boundary reveals the next expected ability's page within the same phase. Expert remains static and phase changes remain manual.
- Remove the obsolete 96-step limit message and generator row. Preserve all other limits, saved data and click-through phase navigation.
- Place each custom caption directly above its own ability icon in profile previews and the rotation overlay; retain key labels below and align joined reminder icons within the row.

## 0.9.7 — 24 October 2026

- Rechecked 0.9.6 against current official Jagex structure, API, submission and plugin guidelines; the corresponding full audit is preserved in development history.
- Reset repeat/completion/duplicate-input state after successful ability insertion or movement; failed and no-op edits preserve current progress.
- Disable unintended own actions on passive controls, and keep short profile-dialog scroll thumbs within their tracks.
- Remove the duplicate Start/Stop, Settings and X controls from the rotation overlay. Add synchronized Click-through directly below Show overlay in the Hub; retain clickable manual phase navigation as an explicit click-through exception.
- Preserve bundled ability choices when native books are truncated or entirely empty; validate declared enum pair counts and retain the Unconfirmed type filter after optional lookup errors.
- Reject explicitly contradictory Struct identities and malformed provided item tiers while preserving supported absent metadata and saved references.
- Reject truncated offline localization containers/fields and validate download checksums before cache commit. Verified catalogue facts and all four language resources remain unchanged.
- Correct documented platform verification scope and distinguish local technical checks, incomplete submission manifest and the unresolved possible conflict with prohibited automatic ability recommendations. No publication or Jagex approval is claimed.

## 0.9.6 — 24 October 2026

- Completed a code-based audit of active data, core, UI, documentation and package tools; added focused regressions for reproduced failures. The corresponding audit is preserved in development history.
- Preserve every saved profile name literally in all languages, including names identical to default names or UI labels.
- Keep overlay callbacks active when resizing only the settings panel, and preserve edit controls for saved reminder placeholders with unavailable native artwork.
- Protect rendering-error reporting and cleanup, release destroyed UI registries, tolerate stale locator cleanup and validate explicit native drop completion when pointer access disappears.
- Display recognized saved key aliases in the selected language without rewriting storage or altering actual key glyphs; deduplicate equivalent labels.
- Correct reminder insertion selection and canonicalize legacy item aliases during moves. Native-only future identities retain neutral names rather than leaking the client language into search/preview.
- Remove unused reminder staging, the obsolete ordinary per-step equipment picker, unread native-name state, unused identity/name helpers, obsolete translation generation and stale duplicate test scenes. Keep saved-data migrations and ID aliases that preserve existing profiles.
- Preflight the full installation plan before file replacement and reject redirected, blocked or hard-linked managed destinations; preserve unrelated files and PersistentDB.
- Keep active code and companion documents in English, with localized player text in language resources. Clarify concept inspiration and recorded package data sources without asserting code/data theft or rewriting historical records.

## 0.9.5 — 24 October 2026

- Documentation update: all active companion documents and generated documentation are in English. AI-STATUS distinguishes the user's account of idea inspiration, recorded earlier source analysis, and the absence of a verified copying finding. Historical records are preserved. This documentation update does not change the runtime code.
- Runtime identifiers, comments and technical messages use English; localized key labels are language resources. Existing storage identifiers remain for compatibility.
- Standard phase names and automatic profile names follow the selected plugin language, including older saved templates, without rewriting custom names or saved records. Phase actions occupy a row above step actions.
- Added remaining Hub translations for language selection and settings; checked visible pages, status/confirmation messages and filter keys.
- Preview and search for abilities, weapons, special-attack weapons, EOF, ammunition, potions and spells use only the selected plugin language, independently of the client language.
- Complete localized names for 1253 items, 156 abilities and 141 spells/incantations from Jagex game-data snapshots. English names are not additional aliases when another language has a different name.
- Language changes also update live search, hover previews and special/EOF assignment dialogs. Case-insensitive and accent-insensitive lookup remain supported.

## 0.9.4 — 24 October 2026

- Search and type filter share a row, 16 pixels below the second category row.
- Additional weapon/spell filters sit beside them and wrap only when required. Dropdowns follow their buttons; the catalogue uses the available space.

## 0.9.3 — 24 October 2026

- Added a synchronized numeric field to the right of the transparency slider; manual input is clamped to 1–100.
- Profile scroll buttons draw native up/down arrows independently of font glyphs.
- Edit/delete use the retained editor selection after Stop/focus loss, without requiring another click.
- Left-click on special/EOF selects only. Right-click → Assign opens the picker through the native context menu.
- Moved edit/delete actions into the wrapping phase header with additional spacing; moved search below the second category row and before its type filter.
- Removed the separate lower toolbar. Short rotations reserve only occupied rows so more catalogue abilities are visible.

## 0.9.2 — 24 October 2026

- Added direct category buttons in two rows, initially placed the type filter at the left, halved the search field and removed the Equipment/Finality toolbar button. Special-weapon assignment remains attached to its ability icon.
- Added a separate ammunition category; arrows, bolts, weapons, potions and spells are independently movable passive cells.
- One click saves immediately. Selecting another ability does not relocate existing reminders.
- Data version 6 saves phase-end reminders; versions 1–5 remain readable without writing during loading.
- Nine known Greater variants remain selectable through their base families. Eleven Necromancy incantations appear under Necromancy and Spells without requiring an independent progression key press.
- Release/click events share one completion path; duplicate events are suppressed and the first click after a drag remains usable.
- Preserved saved profiles and special-weapon/EOF assignments.

## 0.9.1 — 24 October 2026

- Added Vulnerability, Poison and Sticky bombs as passive potion reminders.
- Supported both native ID-index forms and rejected incorrect static-component proxies.
- Unknown native key labels no longer replace manual corrections.
- Saved future abilities remain readable without book data when identity is confirmed; unverified new selection stays blocked.
- Removed localized item action text from identity verification; confirmed configuration names and state/quest/tier evidence remain authoritative.
- Retired search/dropdown callbacks before destroying their components and bounded buttons to narrow Hub hosts.
- Removed unused native-button probes, metadata, old layout navigation, diagnostic fields and UI wrappers.
- Removed 1827 audit/provenance fields from runtime catalogues while preserving full evidence in development data.
- Reorganized current documentation and the submission draft; retained historical reports and one-off patch tools outside the product.
- Clarified nested catalogue/UI branches, local names and comments.
- Aligned manifest and ZIP checks with documented field types. Nothing published; contact, personal review, provenance evidence and moderation remain outstanding.

## 0.9.0 — 24 October 2026

Passive reminders, 130 non-teleport Magic spells, current ability books, confirmed native item configuration names, compact binding fields and the Hub settings opener. Historical automated/native observations apply only to their recorded fingerprints, not automatically to later versions.
