# Hub control and exclusive-state removal — 0.9.14

Date: 25 October 2026. Baseline: the SHA-verified own 0.9.13 package. This targeted release removes Hide plugin windows and code used exclusively by that Hub action. Earlier own audits remain in development history and their original delivered archives.

## Caller and ownership trace

The removed Hub button was the only production caller of App:hideWindows. That wrapper was the only producer setting uiHidden to true; Start and openSettings merely restored it, and the remaining checks guarded its effects. uiHidden was instance-only state, absent from model/storage fields. Removing it therefore needs no saved-profile migration or reset.

The wrapper called shared Stop and destroyUI functions. Both remain used by shutdown, game-interface availability, rendering recovery and normal visibility/capture lifecycle paths. They are not removed. panelClosed, minimized, overlay visibility/overrides, click-through and manual phase controls also remain independently used.

## Implementation

- Remove the Hub button and move the settings opener into its row directly below language checks. Total Hub scroll content is 32 pixels shorter in both one- and two-column layouts.
- Remove App:hideWindows, the transient uiHidden flag and Start/settings/Show-overlay restoration branches that existed only for the deleted action.
- Remove the obsolete hide guards from context/input visibility, profile-dialog display, native window capture, main rendering/failure rendering and overlay checks. Existing generation/scope, panel Close/Minimize and actual overlay visibility checks remain.
- Remove both unused UI translation rows and their builder inputs. The generated resource now contains 163 used four-language rows.
- Update the source-register purpose, current English guides/listing and exact current regression report. Generated evidence is rebuilt rather than edited to erase old test names.

There is no change to schema, stored profile names, rotation steps, passive selection, category separation or native identity facts. No native database is opened or migrated. No client command, external message or publication is performed.

## Verification scope

Existing Hide-specific cases were retired or adapted to actual surviving actions. Regression coverage retains Hub Start/Stop after closing settings, empty phases, failed Start with unavailable parent/player, saved-data preservation, Show overlay, closed/minimized forms, stale context controls, gear reopening and independent Hub hosts. Four languages and narrow/wide Hub layouts check the settings opener immediately below language rows and the removed control's absence.

Independent review checks the caller trace and final source diff. The complete current Lua run, Python tooling tests, UI resource reproduction, package/import boundaries and source/ZIP/installed file hashes are verified before delivery. [LOCAL-TEST-REPORT](LOCAL-TEST-REPORT.md) and [SOURCE-REGISTER](SOURCE-REGISTER.md) record the final results and fingerprint.

Final automated result: **555 Lua checks across 68 isolated suites**, **40 Lua files parsed**, and **75 Python checks passed**. All **163 current UI translation rows** reproduce from the builder. These results apply to the final frozen source and verification inputs.

Automated checks do not establish a native rendering/FPS/platform test, personal human review or external approval. Installation is an own-file copy into the verified beta development folder; activation/reload remains a separate client action.
