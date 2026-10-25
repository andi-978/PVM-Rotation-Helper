# Technical reference — PvM Rotation Helper 0.9.14

This document describes the implementation shipped in this package. [README](../README.md) explains player use; [CODEGUIDE](CODEGUIDE.md) is the maintainer's overview; [SOURCE-REGISTER](SOURCE-REGISTER.md) identifies exact runtime hashes and imports; [TESTING](TESTING.md) explains verification. The [current change audit](AUDIT-0.9.14.md) records findings separately from the architecture; the earlier 0.9.12 two-pass review remains preserved in development history and its delivered archives.

## 1. Purpose and execution model

The plugin stores player-authored combat sequences and renders them using native RuneScape UI components. A profile contains manually selected phases, ability steps and passive reminders. It can follow matching input attempts in Learner or Advanced mode, or remain a static reference in Expert mode. It does not calculate a rotation.

The client loads main.lua and project Lua modules in its plugin environment. No browser, web server, external runtime library or background service is needed. The manifest has empty dependency objects, permission arrays and URL mappings. Maintenance Python programs and their research snapshots are development tools; the game does not execute them.

All game artwork is requested from native configuration or associated objects. There are no bundled ability/item image libraries. A missing or unverified identity produces a neutral placeholder or prevents new selection; it does not justify a guessed numeric ID.

## 2. Package structure and responsibilities

| File or group | Responsibility |
|---|---|
| main.lua | Construct the environment adapter and App, attach official client events, handle availability transitions and shutdown. |
| lib/app.lua | Coordinate user actions, selected profile/phase, input gates, progression, drafts, saving and render requests. |
| lib/model.lua | Define defaults, validate exact fields and bounded collections, and migrate supported older stored schemas in memory. |
| lib/storage.lua | Load/validate the current own record, maintain the previous snapshot, protect unreadable/invalid data and reject stale saves. |
| lib/util.lua | Validate numbers, fields, arrays and UTF-8 text; copy/compare data; normalize display/search text. |
| lib/catalogue.lua | Combine reviewed ability metadata with current ability-book membership, icons and type filters. |
| lib/equipment.lua | Join reviewed weapons/ammunition/potions, resolve legacy item identities, and manage ordered passive reminders and special/EOF assignments. |
| lib/item_identity.lua | Validate reviewed item configuration names once at initialization and keep canonical IDs separate from current native numbers. |
| lib/spells.lua | Resolve the spell/incantation catalogue, current artwork, book/type filters and localized search. |
| lib/prayers.lua | Resolve reviewed prayer/curse identities, current artwork and selected-language book/name search. |
| lib/i18n.lua | Format UI text and selected-language catalogue names without changing saved identities or literal custom names. |
| lib/native_bars.lua | Read exactly five evidenced native bar families and fourteen independently named artwork/key positions per bar. |
| lib/locator.lua | Find confirmed visible slot rectangles, with a bounded older-interface semantic fallback. |
| lib/bar_settings.lua | Read explicitly labelled English native action-bar settings templates as a compatibility fallback, without guessing variable encodings. |
| lib/action_bars.lua | Import recognized typed contents and keys without compressing empty/unknown positions or removing hidden saved bars. |
| lib/keybinds.lua | Parse/display manual key labels and conservatively match current official KeyDown attempts. |
| lib/action_click.lua | Match the expected ability to a confirmed native action-bar component in a menu-selection event. |
| lib/interaction.lua | Own window/icon capture, scale-aware pointer geometry, clipped registered drop targets and finalization/cancellation. |
| lib/diagnostics.lua | Print bounded local technical availability and assignment information on explicit request. |
| ui/widgets.lua | Native styled controls, text, artwork, scoped callbacks, dropdowns and drag/resize grips. |
| ui/view.lua | Main window, page routing, shared window host, locator frames and recoverable rendering-error view. |
| ui/pages.lua | Profile overview/forms, overlay preferences and selected-page presentation. |
| ui/editor.lua | Editable paged rotation sequence, retained selection, captions/repetitions and reminder controls. |
| ui/ability_picker.lua | Shared twelve-category catalogue, selected-language search and adjacent filters. |
| ui/equipment_picker.lua | Special-attack and EOF weapon/amulet assignment. |
| ui/manual_bars.lua | Typed slot assignment, manual key labels, unknown artwork and visible-bar tabs. |
| ui/rotation.lua | Flatten/pack visible cells, retain joined special/EOF weapon groups, paginate and draw the passive rotation display. |
| ui/hub.lua | Official Hub content/settings integration, Start/Stop, profile selector, languages, visibility and click-through. |
| data/abilities.lua, ability_types.lua | Reviewed ability identities and type facts. |
| data/equipment.lua, ammunition.lua, potions.lua | Reviewed canonical item catalogues. |
| data/equipment_legacy.lua | Minimal old numeric aliases/flags required to keep saved references readable. |
| data/item_names.lua | Reviewed canonical item ID to native configuration-name mappings. |
| data/spells.lua, prayers.lua | Reviewed spell/prayer facts and prayer translations. |
| data/catalogue_names.lua | Four-language static names for items, abilities and spells. |
| data/ui_text.lua, languages.lua | UI translations, language identities and accepted key aliases. |
| plugin.json, LOCAL_DEV_ID.txt | Local manifest and installation ownership marker. |

Every runtime Lua module must be reachable from main.lua through literal registered imports. The package checker rejects cycles, unreachable modules, unregistered files and unregistered/dynamic imports. Function-level dead code still requires source/caller review; module reachability alone is insufficient.

## 3. Initialization and lifecycle

1. App.new refreshes ability, item, spell and prayer configuration availability.
2. Storage loads and validates the own saved snapshot. An absent record creates local defaults; an existing unreadable or invalid record enters protected read-only mode.
3. The instance starts stopped. An available native parent and player permit rendering; availability alone does not start input following.
4. Hub callbacks populate client-owned plugin panes with this plugin's controls.
5. A pending render rebuilds the plugin's own UI, retires the previous callback scopes and restores the relevant drafts/selections.
6. Explicit Start begins at phase one and its first active ability, resets duplicate/failure state and may make the rotation display visible.
7. Explicit Stop removes the dynamic KeyDown subscription, makes the static click handler inert, clears assisted selection/capture and destroys locator frames. A retained editor insertion mark remains a separate editing concept.
8. Unloading unsubscribes all registered client events and destroys own UI/Hub components.

| Event | Behaviour |
|---|---|
| Draw | Check parent/player availability, update the app clock, debounce appearance saves, update own captures and perform pending rendering. While active, focused and outside own captures, locator refresh is throttled to a quarter-second interval. |
| WindowFocusChanged | Focus loss stops following. Regaining focus requests rendering and does not resume automatically. |
| WindowSizeChanged | Minimization stops following. A normal game-window resize cancels capture, invalidates observed geometry and requests fresh layout. |
| GameStateChanged | Invalid/unavailable game state stops and removes own UI; a valid available state requests rendering. |
| KeyDown | Dynamically subscribed only while the app's input gates permit keyboard progression. Repeated, invalid, blocked or ambiguous events are ignored. |
| MiniMenuEntrySelected | Optional statically registered click channel; the callback checks activity and ownership boundaries before reading matching native data. It returns immediately when following is stopped. |
| MiniMenuReady | Optional own-editor Select/Assign menu entries for actually hovered registered special/EOF controls. Other entries and game Ops are not changed. |
| ContentLayerReady / SettingsLayerReady | Optional native integration points. Their absence does not create a fake dependency. |
| PluginShutdown | Stop, destroy, detach and unsubscribe. |

The Hub contains Start/Stop, profile selection, Show overlay, Click-through, language checks and the settings opener immediately below those checks. There is no separate whole-plugin hide state. Closing/minimizing the settings panel and toggling the rotation display remain independent; the shared Stop and interface teardown paths are still required for input/capture cleanup.

API exceptions are caught at boundaries where native proxies or optional domains may disappear. A failing key/click/scan channel is disabled until explicit Start; the error goes to the local developer console. A rendering failure offers an explicit retry/settings path rather than an uncontrolled retry loop.

## 4. Saved model and compatibility

The runtime stores structured Lua data through two unchanged compatibility keys:

- pvm_lernstudio_v1: current saved state.
- pvm_lernstudio_previous_v1: the previous candidate's base snapshot.

These strings and the callback/ownership identifiers are compatibility details, independent of the visible translated product name. The technical folder/console ID is pvm-rotation-helper.

The following is a structural summary, not a complete copy-paste profile:

~~~text
state
  version
  activeProfile
  settings
  profiles[]
    name, mode
    phases[]
      name
      steps[]
        ability, key, caption, repeats, breakAfter
        reminders[]       optional ordered passive references before this ability
        switches[]        optional legacy item references
        specialWeapon     optional assignment for special attack/EOF
        eof               optional EOF amulet colour
      tailReminders[]     optional passive references after the final ability
    bars[]
      enabled, slots[]    shared across this profile's phases
      legacy name/geometry fields
    activeBars[]          optional indexes of currently represented bars
    bindings              legacy validated rectangle references
~~~

A passive reminder has exactly one identity: objectID, spell or prayer. A typed bar slot has exactly one identity or an unknown marker, plus its key:

~~~lua
{ability = "COMBATV2_ABILITY_CONSTITUTION_DEMON_SLAYER", key = "Q"}
{objectID = 1215, key = "Shift+Q"} -- canonical item identity, not an observed native number
{spell = "reviewed spell configuration name", key = "W"}
{prayer = "reviewed prayer configuration name", key = "1"}
{unknown = true, key = "2"}
{ability = "", key = ""} -- compatible empty slot
~~~

The spell/prayer strings above are explanatory placeholders; only actual reviewed catalogue IDs validate.

There is no fixed number of ability steps per phase. Arrays must still be dense and every entry is validated. Other bounds remain intentional: twelve profiles, twelve phases per profile, thirty-two stored bars, up to twenty-eight compatible stored slots per bar, and eight reminders per ordered group. Current native detection and the visible manual bar editor use fourteen positions; the wider stored bounds preserve older data.

Captions are saved up to 160 Unicode characters, profile/phase names up to 80, manual key labels up to 30 and repetitions from 1 to 99. Visible captions use at most two lines; their saved text is not truncated by the display. Position/size bounds and exact permitted fields are enforced by model.lua. Legacy fields without current controls are retained only where required to validate/migrate existing records; they do not imply an active feature.

Supported older versions migrate a deep copy in memory. Loading never writes a migration back, silently resets an invalid record or trusts a surviving configuration number as a new identity. Missing current book membership is distinct from invalid saved data: previously stored future ability identities may be restored only under the documented format/configuration/icon checks, while unconfirmed new selection remains blocked.

### Save transaction boundary

App:change copies the current state, applies one requested mutation, validates the complete candidate, and asks Storage.save to compare the current database record with the last loaded/saved snapshot. A mismatch protects against overwriting another client and requires explicit reload.

Storage writes the prior state to the own previous key before writing the current candidate. On failure, the active in-memory candidate is not adopted. The API does not provide an atomic compare-and-swap or a two-record transaction, so this is stale-write detection rather than a complete multi-client lock. A backup write can succeed before a primary write fails; the primary saved state is still protected.

PersistentDB is shared across characters/clients of the same client type on the device, and beta/live stores are separate. The plugin does not create character-specific namespaces or use a tracking ID. The earlier one-time folder-rename migration is separate from normal runtime storage and is not repeated by installation.

## 5. Editing and passive entries

The editor insertion mark, assisted current step and manual bar slot selection have different responsibilities. A normal selection does not move a reminder. A click inserts and saves immediately; a valid drag explicitly reorders a single entry. Structural changes invalidate old scoped controls before their queued callbacks can affect a new profile/phase/selection.

A selected passive cell suppresses the preceding ability's editor outline without discarding its insertion boundary or assisted cursor. Selection and progression are separate: ordinary reminders still never trigger an ability input. A repeated catalogue click selects/reveals the existing identical reminder without another storage write.

New passive entries are ordered before the next ability, or in phase.tailReminders when no following ability exists. A newly appended ability inherits existing tail reminders in order. Moving/removing one reminder operates on a validated candidate; special/EOF assignments remain attached to their ability step. Old incantation steps remain readable and are skipped by input following, while new incantations are passive spell references.

Deleting an ability removes that step together with its stored preceding reminders/legacy switches and special/EOF assignments. Independent reminder deletion removes only the selected reminder. Moving reminders first can retain them elsewhere before deleting the following ability. Within a group, duplicate identical references are rejected or collapsed according to the existing move contract; storage does not turn them into multiple casts.

The first phase cannot be deleted. Phase controls are manual in every mode. Completing a visible page can reveal the next expected ability's page after all repetitions, but it never selects another phase automatically.

The Bindings picker uses the same categories and localized names as the editor. Its callback assigns a typed bar slot instead of modifying the rotation. Replacing a slot retains its key; clearing removes both assignment and label. Passive manual labels describe the player's bar and do not become ability triggers or perform game actions.

## 6. Input matching and progression

Learner and Advanced follow input attempts, not server-confirmed executions. They do not observe damage, adrenaline consumption, cooldown success, prayer activation, equipment changes or cast success.

Keyboard following requires an explicit active run, a focused/available game, a visible rotation display with an expected ability, supported/unblocked keyboard APIs, and no plugin text form/confirmation/picker or own gesture. Modifier codes and key labels are parsed explicitly; key history, character decoding and OS hooks are not used. The plugin cannot reliably identify every general game chat/console field, so Stop remains the reliable user control before typing there.

Current readable native key labels outrank saved labels from a different preset. Manual labels fill only permitted missing/unreadable metadata paths. Duplicate/conflicting assignments are rejected conservatively. Associated objects and ambiguous semantic cells cannot become ability matches because their sprite resembles the expected icon. Known recast sequences share a binding family for displayed/saved labels, but a current native stage must still match the expected artwork.

The click channel accepts only matching documented menu-selection actions on confirmed visible native action-bar rectangles. Clicking this plugin's rotation art does not execute a game action. Matching keys and clicks share a short cross-channel duplicate token containing ability/channel/time only; it expires after 250 milliseconds and does not store an input history.

An accepted attempt increments the current repetition. After the final repetition it selects the next active ability in the same phase, skipping compatible passive incantation records. At phase completion the assisted cursor ends and the player must select a phase or restart. Expert mode does not subscribe for input-driven progression.

## 7. Catalogue identities, names and artwork

| Identity | Saved form | Artwork/name source |
|---|---|---|
| Ability | Named reviewed/current configuration identity | Current COMBATV2_ABILITY_ICON; selected-language static game facts. |
| Item | Stable canonical objectID | Reviewed internal Obj name validated against current configuration; selected-language static name. |
| Spell/incantation | Named reviewed Struct identity | Positive current icon Param; selected-language static name. |
| Prayer/curse | Named reviewed Struct identity | Positive current icon Param; four reviewed names in prayer data. |
| Unknown bar action | unknown=true | Transient detected native art only; localized neutral text and a question mark after reload. |

Current facts contain 156 reviewed ability records, 1,253 canonical item identities, 141 spell/incantation identities and 83 prayer/curse choices. Of the canonical items, 1,115 have reviewed native mappings and 138 weapons remain unresolved. These are recorded catalogue facts, not a claim that every future game object or every character unlock is covered.

Picker categories are exclusive where identities would otherwise be duplicated: Weapons contains actual weapons, while arrows, bolts and the four reviewed tar identities are Ammunition. The Spells picker offers the 130 Magic spell identities; the eleven passive incantations are selected through Necromancy. Their internal spell lookup, current artwork, saved references and native-bar recognition are retained. Picker-specific exclusion also removes the duplicate Incantation type/Necromancy book choices and resets obsolete UI filters.

Ability-book reads are bounded and incomplete enum lists do not prove removal. Item identity validation checks role/state and contradictory tier metadata without scanning arbitrary native numeric ranges or reading an inventory. Search/drawing reuse validated item mappings instead of repeating that scan. Saved legacy references remain recognizable even where artwork is absent.

Player-visible UI text is selected by language code de, en, fr or pt-BR. Search and hover use the same selected plugin language; other-language item aliases are not added as hidden search matches. Actual key glyphs are not accent-folded into different physical keys. Names matching a recognized default phase-name template are localized for display; other custom phase names and every saved profile name remain literal.

Data generation is an offline maintenance activity using explicit own game-fact snapshots and recorded source revisions. It is not an automatic update service. Updating a catalogue requires new evidence, identity/name validation, exclusion review, generator reproduction and tests; an old snapshot date must not be presented as a fresh live check.

## 8. Native bar detection

Detect works without Start. The preferred reader queries the five explicitly evidenced COMBAT_BAR families, uses decoded preset availability, and reads GRAPHIC_n and TEXT_n for each of fourteen positions. Cooldown text is a separate component and is never guessed to be a key. Unavailable components do not shift following slots.

Documented associatedObjectID observations are mapped only through the reviewed canonical/native item index. Otherwise an unambiguous current ability/spell/prayer sprite can establish a known reference. Multiple identities sharing artwork become unknown, and an unrecognized item number is never saved as a canonical item by numerical coincidence.

The older-interface fallback scans only named action-bar roots. Depth/node/slot limits bound traversal; hidden/stale components are skipped. Layered observations of one cell retain explicit numbering and associated-object evidence. Contradictory identities become unknown, and contradictory numbering prevents a guessed import. Partial rows require explicit unambiguous numbering; an unnumbered row requires a complete regular fourteen-cell geometry. The separate older bar-settings text fallback recognizes specifically English native pane templates; the preferred exact named-component reader is independent of the selected display language.

Known empty positions remain empty. Unknown occupied positions remain occupied unknowns. Raw sprite/object numbers and rectangles live in detectedBars only; the persistent model stores typed references/markers and key labels. A manual correction retires that slot's old transient artwork only when saving succeeds. Hidden saved bars are retained, while activeBars describes the current represented selection.

## 9. UI rendering, capture and performance

The main settings/editor window, rotation display and locator frames are separate own UI surfaces. Hub controls live in client-provided panes. A full render retires the old component scopes before Destroy. Search results and panel/overlay content have independently replaceable scopes, so a narrow refresh cannot authorize stale callbacks or invalidate an unrelated live surface.

UI controls use documented native styles/components. Decorative item/spell/prayer cells have disabled square frames with separate full-opacity artwork. The rotation display has manual previous/next phase buttons but no duplicate Start/Stop/settings/close toolbar. With click-through enabled, the surrounding display passes input through while phase button rectangles remain deliberately interactive.

Rotation rendering flattens the visible sequence into cells, keeps joined special/EOF weapon groups together, packs rows at native icon size and paginates according to the available viewport. Ordinary reminders and legacy switches remain independent cells that can wrap separately. Captions sit above their own ability; keys below. Pagination changes display capacity rather than stored phase length.

A window gesture reads the mouse position only during that own capture and accounts for interface scale. Movement updates existing positions. Held resizing caches the layout minimum and changes existing frame, viewport, title, footer, navigation and corner geometry. It does not reconstruct catalogue controls or repeatedly flatten a long phase. Release recomputes the exact minimum, saves once and performs one full reflow. Content wrapping therefore updates on release; no numerical client-FPS improvement is asserted by the simulation.

Native title/corner grips use scoped handle/window/host completion and release paths. Completion/cancellation disarms the old capture, preventing delayed events from rearming it. Item drags use independent previews and resolve destinations only against current own registered controls with scroll clipping. A normal selection click and an actual drag are distinct operations.

Overlay transparency uses a shared numeric field/slider preview and a 400-millisecond save debounce. Manual values clamp to 1–100, while the slider's compatible zero endpoint can still be displayed. Mirrored values suppress programmatic feedback loops. Failed position/visibility saves can retain instance-only overrides so a protected record does not trap a window.

## 10. Functional boundaries and limitations

The plugin does:

- Store/edit/copy/rename personal rotation profiles and manually selected phases.
- Show paged sequences, captions, repetitions, key labels and passive combat notes.
- Match permitted input attempts after explicit Start in Learner/Advanced.
- Read visible bar metadata on explicit Detect and current slot geometry while following input.
- Show an Expert static reference and bounded local diagnostics.
- Adapt UI/catalogue names to the selected plugin language.

It does not:

- Press keys, invoke game actions, equip items, drink potions, cast spells or switch prayers.
- Choose an optimal next ability from combat state, infer boss mechanics or change phases automatically.
- Confirm successful execution, damage, cooldowns, equipped inventory or active prayer state.
- Observe NPCs, bosses, other players, chat messages or account identifiers.
- Send telemetry, use runtime HTTP, download updates or maintain a remote profile copy.
- Guarantee every future item/configuration, all unlock conditions or every client/platform UI behaviour.
- Turn automated tests into personal human review, content-rights verification or Jagex approval.

Input following does automatically highlight the next ability of the player's stored sequence. That behaviour is described explicitly in POLICY.md, together with the unresolved individual assessment of combat/prayer assistance. No hidden policy exemption is implied by a passive implementation.

## 11. Maintenance and verification

The installable ZIP contains runtime source, manifest, ownership marker and English product documentation. Tests, Python tools, raw game facts, listing drafts and detailed development evidence belong to the separate review-material archive. Historical own records remain in history; private profiles/backups, user recordings, unrelated workspace content and third-party source are excluded.

A complete Lua run uses an isolated Lua 5.4 runtime per *_spec.lua, no utf8 library, and a strict documented API-shaped fake. Runtime files and actual harness/suite/offline-audit inputs are hashed before and after the run. Packaging/preflight recheck that exact evidence, including added/removed suites and changes to fake_client.lua. Compilation or a green older report does not substitute for a current full run.

Python tests cover generators, corrupt inputs, canonical identities, package/installation boundaries and filtered historical migration fixtures. Offline catalogue audits compare every recorded entry rather than sampling one displayed icon. Tests do not run the RS3 client or measure native rendering/FPS.

The packaging tool validates imports, manifests and local links, generates the source register, makes root-level main.lua/plugin.json archives and copies only registered own files into the verified beta development folder. It preserves PersistentDB and unrelated files. Only unchanged obsolete files in the prior managed inventory can be retired; a modified obsolete file blocks that removal. Installation copies are verified byte-for-byte and no client command is issued.

For a change: reproduce the issue, make the smallest relevant repair, add a regression where it verifies meaningful behaviour, inspect caller/serialization/UI effects, update documentation, perform the independent second review, freeze inputs, run complete checks, package and compare source/ZIP/installation hashes. Keep native test results, automated results and unresolved personal/external review separate.

## Official API references

The implementation contracts were checked against Jagex's [events](https://developer.runescape.com/rs/core/events.html), [PersistentDB](https://developer.runescape.com/rs/core/persistentdb.html), [components](https://developer.runescape.com/rs/ui/component.html), [Sprite](https://developer.runescape.com/rs/ui/decorative_components/sprite.html), [Button](https://developer.runescape.com/rs/ui/interactive_components/button.html), [Mouse](https://developer.runescape.com/rs/core/mouse.html), [StructType](https://developer.runescape.com/rs/game/config/structtype.html) and [manifest](https://developer.runescape.com/rs/structure.html) documentation. These references describe API contracts; observed native component names and catalogue provenance are recorded separately in SOURCES.md.

