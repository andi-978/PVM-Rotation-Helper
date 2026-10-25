# Runtime files and provenance register

Generated package inventory; not proof of rights or personal human review.

The implementation was developed with Codex assistance. The user describes the reference plugin as inspiration for the idea. Earlier project records also document third-party source analysis in the development context; this alone is not a finding of copied code, and a completely uninfluenced implementation is not claimed. See AI-STATUS.md for the distinction and the evidence still unverified.

Current work uses user requirements, the official Jagex API and project-collected Wiki/beta game-data facts. Registering a filename does not establish the provenance of every line. No third-party sources were reopened or compared for this inventory.

**Runtime fingerprint (41 registered files including manifest):** `84e468a0aad09e3c4173de9b4d31f30f9b60f4ad2b53417e484f2abdc6f107f0`

A personal human review must identify this exact version. Earlier review statements do not automatically cover changed code. This register does not mark human review complete.

## data/abilities.lua

156 static ability records from project-collected Wiki/beta game-data research, including Necromancy; no imports.

SHA-256: `cb7ee9431c7de97e45130c68e1f61abc91211d48e8e4603b34145bc060229956`

Direct module imports: none.

## data/ability_types.lua

Project ability-type index from Wiki game-data facts of 22 October 2026; no third-party plugin-source data or imports; unknown types remain explicitly unconfirmed.

SHA-256: `61290b42ba126f85c7614a9cc8899683d6abe9c9d905730045452f7fce44987f`

Direct module imports: none.

## data/ammunition.lua

Project selection of evidenced usable T10–T120 arrows/bolts from Wiki game-item facts of 23 October 2026; no quest/minigame ammunition or unfinished items; native Jagex artwork, no imports; provenance in AMMUNITION-DATA.json.

SHA-256: `679898860245c7ce0d68046591e323f343649f9edb9655ac5f9be6ed738fedee`

Direct module imports: none.

## data/catalogue_names.lua

Static four-language display/search names for 1253 project items, 156 abilities and 141 spells/incantations; Jagex live configuration facts dated 19 October 2026 via OpenRS2 caches 2742–2745, matched through internal live Struct names rather than beta numbers; project skill/recast/tier qualifiers and canonical English catalogue labels; no plugin-source imports, images or runtime queries; full provenance in development/pvm-lernstudio/data/CATALOGUE-LOCALIZATION-DATA.json.

SHA-256: `c78db51491813f3451b91a52508332d57ac2c1e4264a6a4d84bdef235c0ddf62`

Direct module imports: none.

## data/equipment.lua

1063 canonical weapon/EOF catalogue records from project-collected Wiki item facts; removed records are not recreated as hidden selectable objects; special attacks evidenced through linked combat infoboxes; no plugin-source data, images or imports; historical evidence in WEAPON-DATA.json.

SHA-256: `b032a121a70582255c4278acd346c924fdb02f8aa6e59b5acd20daca8984ca25`

Direct module imports: none.

## data/equipment_legacy.lua

Minimal numeric aliases from removed project catalogue records to canonical IDs, plus boolean legacy special flags; no names, images or selectable records; derived from historical project WEAPON-DATA.json to remove obsolete selection entries while preserving saved profiles; no imports.

SHA-256: `169f35db7af1f48dd56e644f3b6eda97ef69bca970c08147c71ac9cceae10666`

Direct module imports: none.

## data/item_names.lua

Confirmed canonical profile ID to internal Obj-name mappings from the explicitly authorized project English beta metadata export of 24 October 2026; provenance and observed numbers in ITEM-NATIVE-DATA.json; runtime contains configuration names rather than native numeric ID constants; no imports.

SHA-256: `d20b513924400ffa144298357e3d5509e9202d9c6ad7335065fd88ad2a481423`

Direct module imports: none.

## data/languages.lua

Language autonyms and accepted localized key aliases extracted from existing project i18n/key-binding resources; plain language data without imports or executable logic.

SHA-256: `63e841f1ef0ee3d53ba040173d83102fd18300360be0d556e942e67e92273257`

Direct module imports: none.

## data/potions.lua

Project selection of evidenced usable combat potions and three explicitly checked combat bombs from Wiki facts of 23 October 2026; highest evidenced dose per family; bomb Obj names from the authorized read-only three-ID check of 24 October; no throwing action; native item artwork only, no imports; provenance in POTION-DATA.json.

SHA-256: `fa6f86127607b86573e416190796ccaf45222accfaea3e4227a0def9af40d099`

Direct module imports: none.

## data/prayers.lua

Reviewed passive PvM prayer catalogue with 83 standard-prayer/ancient-curse identities, four selected-language names and levels from Jagex live caches 2742-2745 dated 19 October 2026; noncombat/PvP-target/unverified-PvM/preset/helper exclusions and raw evidence in development PRAYER-DATA.json; no native numeric Sprite IDs, state reads or imports.

SHA-256: `af33bfc4b17c4b34e2abc3b880adbb0d5dd8d57dbd8927e91576f97226aeb613`

Direct module imports: none.

## data/spells.lua

130 unique current non-teleport Magic spell identities from project-collected Wiki game facts of 24 October 2026 and the project beta Struct export of 21 October; Standard, Ancient including Seren/Senntisten, Lunar and shared Polypore; no Sprite IDs, imports, plugin-source data or runtime audit fields; per-record page/revision evidence in SPELL-DATA.json.

SHA-256: `5c7f65767425de807dcb20527bda7f37278cb677dfd6819c6cc7dda2f8701ca5`

Direct module imports: none.

## data/ui_text.lua

Project UI labels and displayed key-name translations in German, French and Brazilian Portuguese, with English keys; language resources rather than official game-name claims; no imports.

SHA-256: `409dd558b3274d087670a5a6ba9d581d021308038e35a1b4cb3f86dbc3ce6b6d`

Direct module imports: none.

## lib/action_bars.lua

Project import of five named native action-bar families without collapsing empty or unknown occupied slots; reviewed canonical item identities resolved from documented associated objects and unambiguous current ability/spell/prayer artwork; raw object/sprite observations remain transient; explicit active indexes and saved hidden bars preserved; user requirements, project pan exports and official UI API; semantic fallback only for older interfaces.

SHA-256: `13d50526924b6025f2f059522653fab792f8ef0244d406aad5628200792c845d`

Direct module imports: `lib/bar_settings`, `lib/equipment`, `lib/keybinds`, `lib/locator`, `lib/model`, `lib/native_bars`, `lib/prayers`, `lib/spells`, `lib/util`.

## lib/action_click.lua

Project optional matching of official MiniMenuEntrySelected events to visible action-bar Sprites; based on user requirements and official Jagex API, without third-party plugin source.

SHA-256: `27942a77e954d87f97ec5ee1f7713eec5364defebfd6f338ba5b97203226bc0b`

Direct module imports: `lib/locator`.

## lib/app.lua

Project user actions, saved profiles, protected first phase and explicit Start; transient duplicate-input suppression, independent input-channel failures, text-form guards and immediate context invalidation and progression reset after successful structural changes; passive cells save without requiring a following ability and incantations remain passive; own special/EOF context actions require an actually hovered registered editor control and add Assign before Select to retain normal left-click selection; official API and user requirements; no third-party menu entries read or changed.

SHA-256: `22601c82b5bc79f71b2cb94e83d59f6071c01d167f60e033a066de02f6004e4d`

Direct module imports: `lib/action_click`, `lib/catalogue`, `lib/equipment`, `lib/i18n`, `lib/interaction`, `lib/keybinds`, `lib/locator`, `lib/model`, `lib/prayers`, `lib/spells`, `lib/storage`, `lib/util`.

## lib/bar_settings.lua

Project read-only import from explicitly labelled visible Controls/Action Bar settings; based on user screenshots and official Component/Interface API; no guessed variable encodings.

SHA-256: `8b378c1e9f979ce5b22839a0f17c0279ab4ba5bf61416b55154725ae6d636b46`

Direct module imports: `lib/keybinds`, `lib/locator`, `lib/util`.

## lib/catalogue.lua

Project filtered catalogue using six official ability-book enums, current types and icons; minigame entries excluded and equipment/situational conditions do not imply minigame status; known recast and nine Greater selection families remain available; at most 512 entries per book, with explicit fallback for incomplete/empty book data and declared pair-count checks; unknown type filters derive from resulting records even after optional lookup errors; eleven incantations remain passive; confirmed saved IDs can remain readable without proving current new-selection membership; user requirements, game facts, official Config API and project beta data.

SHA-256: `137c128e4a8fcc2a438021c6a240ba9fd286124de01692d6576d9be71741b0ca`

Direct module imports: `data/abilities`, `data/ability_types`, `lib/i18n`, `lib/spells`, `lib/util`.

## lib/diagnostics.lua

Project bounded diagnostics for direct native slots/key fields/presets, name enumeration, scan boundaries, icons, aggregate catalogue availability and initialization-time item identities; based on user requirements, project beta exports and official API documentation; tolerates absent API domains; transient aggregate gesture counters only, with no event history or personal tracking IDs.

SHA-256: `de005a8525070f4b56f29b9bf1c1a6da33fb7f06a0d2a9b3be25eedf84a29933`

Direct module imports: `lib/equipment`, `lib/item_identity`, `lib/keybinds`, `lib/locator`, `lib/native_bars`, `lib/spells`, `lib/util`.

## lib/equipment.lua

Project active item/EOF catalogue with numeric legacy aliases and minimal flags for saved references; no arbitrary native numeric scan or unchecked ID namespace; new selection requires confirmed current identity; selected-language display/search and ordered passive item/spell/prayer cells preceding the next ability or at phase end; legacy switches remain readable; no inventory/equipment reads; artwork resolves through confirmed configuration names.

SHA-256: `8022623a9d44416a95063080407241bb22121dc4062937872f5242a0b13718b7`

Direct module imports: `data/ammunition`, `data/equipment`, `data/equipment_legacy`, `data/item_names`, `data/potions`, `lib/i18n`, `lib/item_identity`, `lib/prayers`, `lib/spells`, `lib/util`.

## lib/i18n.lua

Project UI text selection, static selected-language catalogue display/search with accent folding and a bounded cache, and localized standard phase templates without rewriting saved custom names; no client-language fallback for a missing reviewed name in any language; based on user requirements, project UI text and localized Jagex configuration facts.

SHA-256: `e7164fe1f0a360c2f182ee1e4d8a0a4be68bb9be6316df8cbd37439c5406d3b3`

Direct module imports: `data/catalogue_names`, `data/languages`, `data/ui_text`, `lib/util`.

## lib/interaction.lua

Project native icon/window gestures with independent previews, clipped drop rectangles and current registered sources; cached minimum and geometry-only held resize with one full reflow/save on release; idempotent capture cancellation retires title callbacks; based on user recordings/tests and official Component/Mouse documentation; reads mouse position only during own gestures, without history.

SHA-256: `d67c77f583daa31558d47c80f3cf342ed104fb8f61a56a767d86ec54dc398abe`

Direct module imports: `lib/util`.

## lib/item_identity.lua

Project one-time validation of confirmed internal Obj names against the current client at initialization; canonical saved IDs remain separate from native artwork IDs; based on the authorized project beta metadata check of 24 October 2026, project item facts and official ObjType/ID documentation; checks catalogue role and excludes quest/noted/lent/augmented/unfinished states without localized action-text matching; explicit malformed tiers are rejected while absent metadata remains supported; no numeric fallback scan, inventory reads or database writes.

SHA-256: `a3499fd070ec1783b5f0be50665eddb4494fb3115fb117be28080603b7194a8c`

Direct module imports: `lib/util`.

## lib/keybinds.lua

Project matching of official KeyDown codes/modifiers to current native ability slots and explicit manual labels; six evidenced recast families; passive/unknown slot labels block ambiguous ability fallback and associated objects cannot match ability sprites; current readable keys outrank saved labels; user requirements, project pan exports, Wiki game facts and official Keyboard/Events API; no key history or generated gameplay input.

SHA-256: `564befc046d84d8aae43093b13605549ba4c4501349bd6e1061e147f98044f67`

Direct module imports: `data/languages`, `lib/catalogue`, `lib/i18n`, `lib/locator`, `lib/native_bars`, `lib/util`.

## lib/locator.lua

Project bounded read-only traversal of named action-bar component roots and exact native slot rectangles; documented associated-object observations prevent item artwork from being treated as an ability; user requirements and official Component/Interface/Sprite/Button API; no arbitrary interface discovery.

SHA-256: `b241ad88e3c1309d5f23a820c921513b47110b1e781188bc9fd757085012f74b`

Direct module imports: `lib/native_bars`, `lib/util`.

## lib/model.lua

Project version-6 profile validation and in-memory older-version migration; unlimited dense step arrays with bounded profiles/phases/bars/reminders; strict discriminated bar slots for ability, canonical item, spell, prayer or unknown occupied marker; user requirements and project schema; no storage writes.

SHA-256: `13b7221610295db8e60d53f36f76b8a3639a9cb32a39f9935deefc6a5d8ed9b5`

Direct module imports: `lib/equipment`, `lib/util`.

## lib/native_bars.lua

Project read-only access to exactly five native COMBAT_BAR families with fourteen explicitly named artwork/key components and documented Sprite.associatedObjectID; based on the user-authorized official pan-component export of 22 October 2026 and official Interface/Component/Sprite API; no OCR or guessed variable encodings; object numbers remain transient observations.

SHA-256: `6eb8984d0d4cdb120670ad3476c0a2f23d90b259809cdeab74c35460802dcc79`

Direct module imports: `lib/util`.

## lib/prayers.lua

Project passive prayer catalogue, selected-language search and named current Struct/Param icon validation; based on reviewed project prayer facts and official Struct/Param API; no prayer-state observation, switching, game action or independent progression; saved identities remain readable without current artwork.

SHA-256: `37f404bfac0fd2c16bbfddbc2b7524465e8bd14196e1634fdade25d419fe870f`

Direct module imports: `data/prayers`, `lib/util`.

## lib/spells.lua

Project passive catalogue of 130 Magic spells and eleven incantations evidenced in the project beta export; book/type filters and selected-language name search; selection requires a readable positive current native ICON parameter with no contradictory configuration name; saved identities remain loadable when API data is absent; user requirements, project spell facts and official Struct/Param API; never casts or triggers progression.

SHA-256: `92a587369d62b3ac169965df6c6be37056c2bf09fde8b21ecff2debdf4fa46f8`

Direct module imports: `data/abilities`, `data/spells`, `lib/i18n`, `lib/util`.

## lib/storage.lua

Two project PersistentDB keys, previous-snapshot backup and non-atomic stale-snapshot conflict protection; legacy key strings preserve existing profile compatibility.

SHA-256: `0bf6089cb19884d114f07b7bd25bcd3c046207fb99cd6d511b4ce94234cdca6a`

Direct module imports: `lib/model`, `lib/util`.

## lib/util.lua

Project copy/type/UTF-8/text helpers, dense-array checks with optional count bounds and resolution of both official ID-index forms; based on project implementation and authorized read-only beta observations; no imports.

SHA-256: `376667449211b42dd263dcc9e91b9698be149ade790ae9e7eb38a35ff8467eb6`

Direct module imports: none.

## main.lua

Project client-event registration and Start/Stop lifecycle; independent optional ContentLayerReady and SettingsLayerReady integration; optional MiniMenuReady adds only registered own editor actions and is removed on shutdown; user requirements and official event documentation; no runtime dependencies beyond registered project modules.

SHA-256: `4949a8cb94f2bdfc2e7778e8e5e28e5ac915eb39c0728b72086fbb0f51a989cb`

Direct module imports: `lib/app`, `ui/hub`, `ui/view`.

## plugin.json

Local beta development manifest with Ribbon and Settings gear integration; project metadata and official manifest/event documentation; explicit empty permission arrays and dependency objects; genuine contact email deferred at user request; not submission-ready.

SHA-256: `2a6faba5be06cce9be25a557badf40bd0f89d24dcc25cbd8d54f52484beeabf2`

Direct module imports: none.

## ui/ability_picker.lua

Project shared Editor/Bindings catalogue with all twelve visible categories including weapons, ammunition, potions, spells and prayers; selected-language search and adjacent filters; Bindings assigns typed slots without modifying rotation reminders; scoped result callbacks retire before Destroy; user requirements and official native UI API.

SHA-256: `e40155a22d0f9bde1d8354efb8b30318472bf6f72e6b4b38b1705fa42100eb9d`

Direct module imports: `lib/equipment`, `lib/prayers`, `lib/spells`, `lib/util`.

## ui/editor.lua

Project icon/reminder editor with compact phase navigation, protected first phase, wrapping phase actions above step actions, persistent selection, repeated insertion and separate reminder drag sources; selected reminders can be deleted independently; special/EOF assignment is an explicit right-click action; row allocation follows occupied content; user recordings/instructions and official UI API.

SHA-256: `944a37a560cfe37a430d5c8bda297653e5d7caf8182ca58f3d9185f8a57840cc`

Direct module imports: `lib/equipment`, `lib/interaction`, `lib/model`, `lib/util`, `ui/ability_picker`, `ui/equipment_picker`, `ui/rotation`.

## ui/equipment_picker.lua

Project paged special-attack/EOF assignment selector with style/tier filters, selected-language live search and explicitly removable reminders; based on user requirements and official native Button item rendering.

SHA-256: `42a716c388cceca629a91fcdbea9da7f9d72195d20b40a0afc11745923011d2b`

Direct module imports: `lib/equipment`, `lib/util`.

## ui/hub.lua

Project window integration in official ContentLayerReady/SettingsLayerReady surfaces; Start above profile selection, synchronized Click-through directly below Show overlay, settings directly below language controls, bounded widths, independently replaceable callback scope, own scrollable profile dialog, exclusive language checks and shared visibility state; vertical arrows are drawn from native rectangles independently of font glyphs and short scroll thumbs stay within their track; user requirements and official Events/UI API.

SHA-256: `67aea897db9497c83c7ce8eedc9d662676a42489f29563767024ca620b44a603`

Direct module imports: `lib/i18n`, `ui/widgets`.

## ui/manual_bars.lua

Project complete typed action-bar editor with ability, canonical item, spell, prayer and unknown occupied slot references; scoped click/drag assignment preserves manual key labels and retires stale detection artwork; selected-language hover names and transient unknown artwork; user requirements and official UI API; passive labels never become progression triggers.

SHA-256: `3f7f49e61f144d292a6b1d61309547e66efdf32db43b06340b5065c5e3d42cdd`

Direct module imports: `lib/action_bars`, `lib/diagnostics`, `lib/equipment`, `lib/interaction`, `lib/keybinds`, `lib/model`, `lib/prayers`, `lib/spells`, `lib/util`, `ui/ability_picker`.

## ui/pages.lua

Project profile overview with centred white names, gold context labels, explicit Rename and fixed phase headers with expandable sequences; overlay settings use native slider/check controls and synchronized numeric input limited to 1–100 with the existing preview/save debounce; no old layout-navigation alias; user requirements and official UI API.

SHA-256: `f2bb9a495c60603e1e351cb834541b6888241968dfc51538fca546626346d1bc`

Direct module imports: `lib/model`, `lib/util`, `ui/editor`, `ui/manual_bars`, `ui/rotation`.

## ui/rotation.lua

Project compact rotation overlay with manually selected phase buttons interactive under click-through, bounded pagination following the expected ability, captions above their icons and native square passive frames; geometry-only resize preview preserves cell controls until final reflow; user requirements and official UI API.

SHA-256: `bc670e2a0b45464b0ba743bf64824def34f689979726e0febc554e9887416e4a`

Direct module imports: `lib/spells`, `lib/util`.

## ui/view.lua

Project stable window frame with fixed header controls, independent panel/overlay scopes, selected-language pages and main-window geometry; held resize changes existing frame/viewport/title/footer/grip geometry without replacing content, followed by full release reflow; user requirements and official UI API.

SHA-256: `d18be56f10f182d654e04377d197d841d5cdc4dd8ad86f96ec3235331a019608`

Direct module imports: `lib/locator`, `lib/util`, `ui/pages`, `ui/rotation`, `ui/widgets`.

## ui/widgets.lua

Project native styled controls, scoped callbacks, localized text, full-alpha artwork, passive square tiles and drag/resize grips; title capture listens on handle, window and host release channels and rejects delayed completed gestures; documented Component/Button/Sprite/Slider APIs and user recordings; no mouse-button polling.

SHA-256: `edf0fb0ce0320a8449dfe594a39d0ea0f27d4c3d416f1ec48a30b74cbc6f7977`

Direct module imports: `lib/equipment`, `lib/interaction`, `lib/prayers`, `lib/spells`, `lib/util`.

## Package-check boundaries

Only explicitly registered project paths are packaged. Unregistered files, symlinks and unregistered require paths are rejected. These checks do not automatically detect third-party code inserted inside a registered file. The tool does not perform plagiarism or rights verification and does not establish Jagex approval.

Outstanding evidence: [AI-STATUS.md](AI-STATUS.md). Architecture: [CODEGUIDE.md](CODEGUIDE.md).
