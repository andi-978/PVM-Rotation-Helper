# Maintainer guide — 0.9.14

The [technical reference](TECHNICAL-REFERENCE.md) explains every module, lifecycle event, saved structure, input path, catalogue identity, rendering path and functional limitation. [README](../README.md) is the player guide. [SOURCE-REGISTER](SOURCE-REGISTER.md) records current imports and hashes, and [TESTING](TESTING.md) defines the release checks.

## Dependency and responsibility boundaries

main.lua constructs App and connects official events. App coordinates the model, storage, input matching, catalogues and UI; it is not a game controller. UI pages call explicit app/catalogue actions. Data modules contain reviewed facts rather than executable game behaviour. Every Lua module is reachable through registered literal imports; the checker rejects cycles and unused modules.

Keep native reads at their existing boundaries. native_bars reads exact named visible slots; locator handles the bounded older-interface fallback. keybinds/action_click determine whether an input attempt matches the expected stored ability. interaction reads pointer position only during an own gesture. item_identity validates reviewed configuration names at initialization. No runtime HTTP, inventory reads, gameplay input or arbitrary numeric identity discovery belongs in these paths.

Window visibility uses the existing panelClosed/minimized state and overlay visibility/override. The retired Hub-wide hide action and transient uiHidden state are not compatibility fields and must not be recreated. Shared Stop, destroyUI and capture teardown remain active lifecycle functions.

Picker presentation is separate from saved identity lookup. Weapons excludes ammunition; Spells excludes the eleven incantations presented under Necromancy. Filtering those duplicate choices must not remove current/saved incantation resolution or native-bar imports. Passive editor selection has one visible mark while retaining the preceding ability insertion boundary internally.

## Changes and state ownership

Use four-space indentation, English identifiers/comments and purposeful module names. Player-visible text uses canonical English lookup keys with resources for de/en/fr/pt-BR. Game names come from reviewed localized facts; an English client name is not a substitute for a missing plugin-language name.

Persisted mutations go through App:change: copy, mutate, validate, check the expected storage snapshot, save and then adopt. A failed save must not silently replace active data or clear the user's last valid state. Temporary selection, drafts, gesture data, observed native artwork and input deduplication are instance state; do not serialize them.

Invalidate old callbacks before a structural/context transition can receive queued native events. Rebuild only the affected scope. Stop/unavailable interface/destruction must retire captures and subscriptions. A delayed release/drag callback must not rearm a finished gesture or act on a newer selected slot.

Treat input progression as an attempted action, never a confirmed cast/hit. Preserve manual phase selection and repetitions. Passive item/spell/prayer entries are visual references even when a manual action-bar label is attached.

## Compatibility that still has a purpose

| Retained field or identity | Reason |
|---|---|
| pvm_lernstudio_v1 / pvm_lernstudio_previous_v1 | Existing PersistentDB records. |
| Ownership marker and callback prefix | Safe own-folder updates and stable subscription identifiers. |
| Numeric canonical item IDs and equipment_legacy aliases/flags | Existing saved references; never guessed current native object IDs. |
| Old incantation ability steps | Previously authored profiles remain readable; new insertion is passive and following skips them. |
| settings.followClicks / followKeys / iconSize / locator | Validated older-schema fields; they are not active UI controls or progression switches. |
| Saved bar name/position/size/gap/column fields | Older bar layouts remain loadable; current manual/native slots use their own presentation. |
| profile.bindings | Old validated references and saved-ability restoration; no phantom locator frames are created from stored rectangles. |
| settings.columns | Default rotation width until a separate overlayWidth exists. |

Compatibility data is not the same as dead executable code. Remove an unused helper or write-only transient flag after checking all callers/tests; do not remove serialized fields without an explicit validated migration. A test that only inspects an obsolete internal flag is not a reason to keep the flag—verify the resulting visible state or behaviour instead.

Saved profile names remain literal, including strings equal to a UI label or earlier product name. Names matching recognized standard phase templates localize for display. Other custom phase names stay literal.

## Data maintenance

Offline builders and fact collectors are not runtime dependencies. Reproduction uses reviewed snapshots. Fresh item collection records candidates only; review/filter/classify before generating production data. Do not admit a new item merely because its current number or localized name resembles a saved canonical identity.

Record provenance, source revisions, inclusion/exclusion decisions, identity ambiguity and unresolved mappings. Preserve recorded snapshot dates; record the date of a newly executed audit separately. The language builder may update authored UI labels, while game-name builders must reproduce verified four-language facts.

No third-party plugin source/documentation is reopened for this process. Historical own analyses remain in the workspace history. This technical process does not certify personal human review, content rights or Jagex approval; see [AI-STATUS](AI-STATUS.md).

## Review and release sequence

1. Reproduce a concrete issue and identify its owner/callers, error paths and saved-data implications.
2. Implement the smallest repair or remove proven unreachable/unused executable work. Keep a clear reason for retained fallback/compatibility paths.
3. Test behaviour that would expose the defect, including queued callbacks, save failure and unavailable native proxies where relevant.
4. Complete the first whole-package pass, then perform the second independent module-by-module pass on that corrected source. Recheck cross-module contracts and documentation.
5. Freeze runtime, harness, suites and offline audit inputs before the full Lua run. Run Python checks and the offline catalogue audit.
6. Package only current registered files. Preflight must validate the exact evidence, not a green report from older tests. Compare source, ZIP and installed hashes.
7. Keep automated checks separate from actual native-client rendering/FPS/platform checks and personal/external approval.

The update tool copies registered own files into the verified beta development folder and does not enable/reload the plugin. PersistentDB, private backups, unrelated files and historical evidence are not a cleanup target.

