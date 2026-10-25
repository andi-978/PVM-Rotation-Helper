# PvM Rotation Helper 0.9.14

Create personal combat rotation profiles and display them as icon sequences. The plugin does not perform game actions. This local development build has not received individual Jagex approval. [Changelog](CHANGELOG.md) · [Submission status](docs/SUBMISSION.md).

## Create a rotation

1. Open the gear or **PvM Rotation Helper settings** in the Plugin Hub.
2. Under **Combat Rotation Profiles**, select **New** or choose an existing profile. **Rename** changes its name.
3. Open **Rotation Editor** for the profile. Category buttons occupy two rows. Below them, the search field uses half the width and its filters sit immediately to the right. Results update as you type; hover names appear at the lower right. Search and preview use only the selected plugin language, independently of the client language. For example, German uses “Schauder-Armbrust”; “Eldritch crossbow” is not an additional German search alias.
4. Click abilities to insert steps. The selected step determines the insertion point. Drag steps to reorder them. **Delete step** removes the selected step. The retained green selection is enough to edit or delete after Stop or focus loss; another selection click is unnecessary. **Edit details**, below the phase actions, opens repeats, caption, key label and row-break settings.
5. **Add phase** creates a section. The first phase is protected from deletion. Names matching standard templates such as “Phase 1” follow the plugin language, for example “Fase 1” in Portuguese. Every saved profile name remains exactly as entered, including names equal to a UI label or a default name. Other custom phase names remain literal. The profile overview expands and collapses each phase's sequence. Phase changes are always manual.

A phase has no fixed ability-step count limit. Twelve profiles and twelve phases per profile remain supported. The editor and overlay split long sequences into pages according to the available space; the visible page is not the complete phase. A storage failure preserves the previous active data.

A step's custom caption appears directly above its own ability icon in the profile preview and rotation overlay. Up to two lines are visible; the full caption remains saved and editable. Key labels remain below the icon. Empty-caption phases keep their compact row height.

## Weapons, ammunition, potions and spells

**Weapons** provides weapon-only style and tier filters. **Ammunition** contains arrows, bolts and reviewed tar ammunition; these entries do not also appear under Weapons. **Potions** includes combat potions and Vulnerability, Poison and Sticky bombs. **Spells** contains 130 Magic spells without teleports. The eleven Necromancy incantations, including their two teleports, are selected under **Necromancy** and remain passive reminders.

These categories are passive reminders. Example: ability A → weapon → potion → spell → ability B. Each click immediately saves an entry after the selected insertion point, even at the end of a phase without a following ability. Selecting another ability does not move existing reminders. Drag reminders separately to reposition them; **Delete reminder** removes only the selected reminder. Deleting the following ability also removes its stored preceding reminder group, so move reminders elsewhere first if you want to retain them. Up to eight reminders may precede an ability or remain at the phase end. In the display overlay, reminders have no click action, key label or progression frame. Only ability steps advance the rotation. Previously saved incantation steps are skipped during assisted progression without rewriting the saved records; Expert manual editing preserves the exact selected step.

Adding or selecting a passive reminder marks that reminder alone in the editor. The previous ability's insertion boundary remains remembered for later insertions without showing a second green selection. Clicking an already present reminder in the catalogue selects its existing cell rather than adding a duplicate.

Left-clicking **Weapon Special Attack** or **Essence of Finality / EOF** selects the ability like any other step. **Right-click → Assign** opens the special-weapon picker. Each step can have one assigned special weapon; a new assignment replaces it. EOF can also have an amulet colour. Weapon and ability icons stay together without an internal arrow. Other abilities do not open this dialog.

Duplicate, augmented, dyed, noted, lent, quest-only, minigame-only and unfinished weapons are removed from selection. Coloured EOF amulets remain available. Legacy ID mappings preserve existing profiles. Artwork resolves through confirmed native configuration names. **138 known weapons still lack a confirmed beta mapping** and cannot be selected anew; saved references remain passive placeholders.

Current ability books are read when the plugin loads. Incomplete API data is not evidence that an ability was removed. New items and spells are added after verification.

## Prayer reminders

**Prayers** provides 83 reviewed PvM choices: 44 standard prayers and 39 ancient curses, including Necromancy. Choose **All prayer books**, **Standard prayers** or **Ancient curses** beside the search field. Search and hover names use the selected plugin language. Skill-only effects, PvP-only entries, Quick Prayer presets and dummy controls are excluded; prayers with both combat and other uses remain.

Click or drag a prayer to insert a passive reminder, move it independently and use **Delete reminder** to remove it. Prayers share the existing eight-reminder group limit with other items/spells and remain saved at phase end. They neither activate a game prayer nor advance the rotation. All passive prayer, weapon, ammunition, potion and spell cells use square framed tiles in the rotation display so their artwork is easier to distinguish. The frames remain click-through.

The product's visible name follows the plugin language: **PvM Rotation Helper**, **PvM-Rotationshelfer**, **Assistant de rotations PvM** or **Assistente de rotações PvM**. Existing profile names remain literal. The technical development identifier is now **pvm-rotation-helper**. Existing save keys, ownership marker and callback references remain compatibility identifiers.

## Import key bindings

1. Open a profile's **Bindings** page. Display the required action bars in the game.
2. **Detect** imports visible icons and key labels without requiring Start. It recognizes confirmed ability, item, spell and prayer identities and preserves their slot positions. It does not change game bindings. Hidden older bars remain saved.
3. To correct a slot, select it and click or drag a catalogue entry onto it. Bindings has the same twelve categories as the editor: **All**, **Constitution**, **Defence**, **Melee**, **Ranged**, **Magic**, **Necromancy**, **Weapons**, **Ammunition**, **Potions**, **Spells** and **Prayers**. Search and names use the selected plugin language.
4. Enter a key such as `Q`, `Shift+W` or `Ctrl+1`, then choose **Assign key binding**. A replacement keeps the slot's existing key label. **Clear slot** removes its assignment and label.

Ability assignments apply across phases and both displays. Known recast stages share a binding family. Item, ammunition, potion, spell and prayer slots remain passive references; their optional key labels never advance the rotation or become ability bindings.

An unrecognized or ambiguous native icon is kept in its original slot as **Unrecognized action**, with its readable key label. Its current artwork may remain visible after Detect; that raw artwork is transient and is not saved as a guessed identity. Reassign the slot from the catalogue to identify it manually. After reload, an unresolved saved slot can show a question mark until detection or reassignment.

**Diagnose** prints bounded technical state in the console without changing assignments or requiring Start. Detection covers the main bar and up to four visible additional bars. Editor, Bindings and their profile headings use natural labels in German, English, French and Portuguese; saved profile names remain literal.

## Display and modes

**Start** in the Plugin Hub begins at the first active step of the first phase in Learner/Advanced. **Stop → Start** returns there. Start/Stop, settings access and overlay visibility are controlled from the Hub; the rotation overlay has no duplicate Start/Stop, Settings or close button. Its icons remain decorative; phase buttons remain manually usable. Explicit editing is available through the settings window.

- **Learner:** highlight the current step in the overlay and the matching visible game slot.
- **Advanced:** highlight only in the plugin's overlay.
- **Expert:** display a static sequence without automatic progression.

Learner and Advanced follow matching ability-key events or action-bar clicks. An input attempt does not confirm successful execution. Cooldowns and Revolution do not advance the sequence; the plugin does not recalculate a rotation from boss state. Automatic next-ability highlighting may conflict with Jagex's prohibition on automatic ability recommendations. Individual Jagex determination is outstanding; this local build is not approved.

The overlay automatically reveals the page containing the next expected ability. After the last ability on page 1 is matched, it switches to page 2 if the next step is there. Repeated steps finish all configured repetitions before advancing. Page changes stay within the current phase; selecting another phase remains manual. Expert has no input-driven page changes.

**Overlay Settings** provides background transparency from 0–100%, a synchronized numeric field on the right (manual input 1–100), **Click-through**, **Show overlay** and **Key labels**. Icons remain opaque. In the Hub, **Click-through** sits directly below **Show overlay**; both surfaces share the same saved settings. Click-through passes clicks through the overlay except its **Previous phase** and **Next phase** buttons, which remain clickable and change phases manually. Select Deutsch, English, Français or Português in the Hub.

The Hub's **PvM Rotation Helper settings** opener sits directly below the language controls. Use the settings window's own close/minimize controls for that window and **Show overlay** for the rotation display; these are independent controls.

Move a window by its title bar and resize it using the invisible lower-right grip. Disable click-through before moving or resizing the rotation overlay. Buttons stay compact; content wraps or scrolls. Use **Show overlay** in the Hub to hide the overlay; the settings window retains its own close button. The game's general interface lock is not automatically inherited.

While resizing, the frame, title and footer follow the pointer while existing icons, captions and fields keep their layout and pixel sizes. Rows and search results reflow once after release. Title drags also finish on release notifications from the handle, window or containing layer; Stop, focus loss and teardown cancel a held gesture. This avoids rebuilding the whole interface throughout the drag. Actual client FPS has not been measured.

Stop, focus loss, minimization, logout and unloading end progression; the plugin's forms also block it. **Press Stop before using chat or the console:** not every text field opened with the mouse can be reliably identified.

## Local installation and data

Development folder: `dev_plugins/pvm-rotation-helper`. Put the current local package's contents in that folder, refresh the development-plugin list and enable the current identifier:

```text
prf
pon pvm-rotation-helper
```

Subsequent reloads use `prl pvm-rotation-helper`. Updating files does not automatically reload the client. The earlier 0.9.10 rename migration preserved original storage records and created guarded copies from the verified current profile namespace, with a separate own-record-only backup. It is not rerun during normal updates. Existing destination data is never overwritten by that historical migration. A separate installation without it does not automatically gain access to records isolated under an old plugin identity. Any future distribution would use the official Plugin Hub/mod.io process; no public release currently exists.

PersistentDB is shared per device and client type, not per character; beta and live use separate data. There is no runtime networking, chat recording, inventory access, tracking ID or keystroke history.

[Data use](docs/PRIVACY.md) · [Technical reference](docs/TECHNICAL-REFERENCE.md) · [Maintainer guide](docs/CODEGUIDE.md) · [Testing](docs/TESTING.md) · [In-depth audit](docs/AUDIT-0.9.14.md) · [Sources](docs/SOURCES.md) · [AI and provenance status](docs/AI-STATUS.md).
