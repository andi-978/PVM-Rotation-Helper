# Data use — 0.9.14

All data remains local to the plugin (Data Protection Case 1). The manifest requests no permissions, network destinations or transfers to the developer.

## Stored data

Custom profile names, phases, steps, passive item/spell/prayer references, typed slot/key assignments including unknown occupied markers, language and display preferences. Raw observed native object/sprite numbers and slot rectangles are not persisted as bar contents. PersistentDB keys remain `pvm_lernstudio_v1` and `pvm_lernstudio_previous_v1`; the latter stores the previous snapshot. Updates and the product rename do not reset these records. The plugin developer maintains no user account or activity timeline. Prayer reminders read static name/icon metadata, without observing active prayers.

PersistentDB is shared per device and client type, not per character. Beta and live data are separate. Stale-snapshot protection is not a complete multi-client lock because the API has no atomic transaction for this comparison.

The local 0.9.10 technical-identifier migration uses a separate SQLite transaction to copy this project's exact records into absent new identity namespaces, retaining every original. Its exclusive backup contains only the two own keys across the three known historical own namespaces. Other plugins' payloads are not read or included, and the private backup is excluded from installable/review archives. Raw native serialization is preserved byte-for-byte. This migration is separate from ordinary in-plugin saves and does not activate or control a client.

## Transient reads

- Static official configuration for identity, icon and type; no inventory or equipped-item contents.
- Visible action-bar slots, documented associated-object numbers, artwork and key labels during explicit detection. Current native slots are also read while matching an input attempt or refreshing ability frames. Unknown artwork stays only in the current detection cache. Game key bindings are not modified.
- Matching official keyboard/menu events after starting Learner/Advanced progression. No OS hook or keystroke history. A short-lived ability/channel/time token prevents double counting.
- Mouse positions only during the plugin's own drag gestures, without coordinate history. Search text, hover names and callback scopes are transient.
- Special/EOF context actions only while a registered own editor control is actually hovered. Other menu entries are neither queried nor modified; Select/Assign remain own UI actions.
- Focus, window and game availability to suspend processing; no boss, NPC or other-player monitoring.

Stop, focus loss, minimization, logout and hiding the overlay through Show overlay unsubscribe keyboard progression and disable click matching. The optional static menu-event handler remains inert until a permitted run; unloading removes all registered event handlers. The plugin's forms block progression. General chat/console fields cannot all be identified reliably; press Stop before using them.

## Diagnostics and deletion

Diagnostics print bounded technical names/IDs, catalogue counts, mode and slot/key-binding state in the developer console. There is no event history or automatic transmission. Before voluntarily sharing output, check for personal profile names or unrelated console lines. Earlier development metadata exports are not runtime resources.

Remove individual profiles, steps or slots with the explicit deletion controls. Clearing all plugin PersistentDB is a separate client action after making a backup; updates do not perform it. The developer has no remote copy and cannot remotely delete local records.
