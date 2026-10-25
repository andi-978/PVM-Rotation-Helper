# Technical verification — 0.9.14

[LOCAL-TEST-REPORT.md](LOCAL-TEST-REPORT.md) records Lua 5.4 execution against a strict API simulation, not an RS3 client run. Each suite uses fresh Lua state. Runtime files are hashed before and after a full run.

The runner also fingerprints every Lua suite, fake_client.lua, the runner itself, shared verification tooling and offline ability-audit inputs before/after execution. Package/preflight checks reject a changed harness, added/removed suite, changed facts or an older report missing this evidence. New generated reports use the English PvM-Rotation-Helper-Test-run.json/Test-report.md and Package-inventory.json naming; older reports remain historical evidence.

The 0.9.12 review uses a first complete-source pass and a second independent review with rotated module ownership. Focused red-to-green regressions precede complete frozen-source runs. The audit inventories source/function coverage; it does not claim measured 100% executable branch coverage or an absence of all possible defects.

The 0.9.14 Hub cleanup retires tests for the removed whole-plugin hide action while retaining actual settings Close/Minimize, Show overlay, Start/Stop, unavailable-parent, protected-storage and stale-callback checks. Hub layouts are checked in four languages and narrow/two-column hosts, including settings placement directly below the language controls and absence of the removed button.

From the development workspace:

```powershell
py -3 tests/run_tests.py
py -3 -m unittest discover -s tests -p 'test_*.py'
py -3 tools/audit_equipment_duplicates.py
py -3 tools/release_preflight.py
py -3 tools/package_plugin.py --install-local
```

The packaging tool copies only registered project files into the verified beta development folder. It does not activate the plugin or change PersistentDB. It removes only unchanged obsolete files recorded in the previous inventory. Unknown files remain; a locally modified obsolete file blocks removal.

## Native checks before submission

- Hub/gear, profile selection, four languages, forms, window sizes and UI scaling.
- Five visible action-bar families, modifiers, empty slots, detection without Start, corrections and recast stages across phases.
- All twelve Bindings categories at narrow and wide sizes in four languages; click/drop ability, item, ammunition, potion, spell and prayer assignments, key-label preservation, Clear slot and save/reload. Passive references and unknown slots must never supply ability bindings or progress the rotation, even when their labels match an ability key.
- Explicit Detect with readable associated objects and ability/spell/prayer artwork: save confirmed canonical identities, retain an unknown marker for ambiguous/unrecognized artwork, and keep slot positions and readable labels. Raw detected artwork is transient; test manual reassignment and reload without persisting native object/Sprite observations as identity guesses.
- Start/Stop, repeats, duplicate events, final step and manual phase/mode changes. Input does not prove execution.
- Long phases beyond the previous 96-step cap, save/reload and older-schema migration; dense-array and late-step field validation still apply. Match the last step of a visible page through KeyDown, verify the next page appears only after all repeats, and verify the phase stays unchanged.
- Focus loss, minimization, logout, unloading, chat/console and own forms; no residual input subscriptions or frames.
- Passive reminders including bombs, special weapons/EOF, search/dropdowns and item artwork.
- Standard-prayer/ancient-curse selection, all four localized names/searches, mixed reminder order, unavailable prayer artwork, save/reload and no prayer-driven progression; decorative passive frames accept no game action or overlay selection.
- Localized product titles/settings hints at narrow widths and literal old-brand profile names after language changes/reload.
- Natural Editor, Bindings and profile-heading labels in German, English, French and Portuguese, with literal saved profile names.
- Drag/resize updates, release outside controls, scrolling, transparency, click-through and visibility; phase buttons remain clickable under click-through while surrounding overlay areas pass clicks through.
- Resize Profiles, Editor, Bindings, Overlay Settings and the rotation overlay: frames/title/footer track the pointer, native icon pixels and existing fields/captions stay unchanged during capture, and a single final reflow updates wrapping and paging after release. Cover long phases and retained editor/overlay pages; no storage writes or catalogue refreshes should occur while held.
- Release title drags through the handle, window and containing-layer notifications, including ancestor completion, unavailable pointer access, Stop/focus cancellation and stale duplicate notifications. A completed drag must not keep following later pointer movement or cause a second save.
- Migration, damaged data and concurrent clients without reset or silently overwriting a stale snapshot.
- Test each documented submission platform separately: Windows, Linux, Android and iOS. Windows observations do not establish any other platform's behaviour. Confirm the portal's current platform options before submission.

Earlier native observations apply only to their recorded fingerprints. A complete native matrix for the current runtime is not confirmed. Personal human code review and Jagex moderation are separate steps.

The 0.9.5 regressions cover every static localized name, rejection of other-language aliases, direct language changes, default phase names without rewriting stored names, literal custom names, phase actions above step actions, visible UI translation keys, and special/EOF dialogs with deliberately different synthetic client names.

An English translation of an existing test report preserves its original test results and date. Updating report text or documentation does not imply that tests were rerun or that a client test occurred.


The preceding 0.9.6 audit added regressions for literal saved profile names, independent overlay callbacks during panel resize, validated native drag completion, protected rendering-error reporting, canonical legacy reminder moves and complete installation-path preflight. The 0.9.7 review added stale progress after edits, passive button callbacks, short scroll tracks, incomplete enum snapshots, contradictory configuration identity, malformed tier metadata and offline collector corruption checks. The 0.9.11 regressions cover typed passive bar slots, conservative native detection, natural localized labels, constant-size resize previews and explicit title-release cleanup. Strict-fake tests count component allocation, destruction, catalogue work and saves during repeated pointer updates; they do not measure real client FPS. Final counts are generated from the integrated source rather than inferred from earlier runs. See [the current audit](AUDIT-0.9.14.md).
