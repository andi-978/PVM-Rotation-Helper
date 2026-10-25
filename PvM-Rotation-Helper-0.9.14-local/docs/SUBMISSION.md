# Submission preparation — 0.9.14

As recorded on 24 October 2026, no listing, upload or email has been sent. Project references: [Jagex submission process](https://developer.runescape.com/rs/submission/process.html) and [Manifest structure](https://developer.runescape.com/rs/structure.html).

The product ZIP has `main.lua` and `plugin.json` at its root, required project modules and current documentation. Manifest, archive name and changelog versions match. Dependencies are empty objects and permissions are empty arrays. History, tests/generators and full provenance data are separate.

`submission/pvm-rotation-helper/` holds a local listing draft, English description and original 16:9 title artwork. The feedback draft uses mod.io comments/DMs and prior discussion for collaboration. No contact identity has been invented; the responsible owner must review it before publication.

| Outstanding item | Required evidence or action |
|---|---|
| Contact email | Deferred at the user's request. Do not submit without a real required contact. |
| Personal code review | Personally read and understand the exact current fingerprint. Not confirmed. |
| Historical AI-processing evidence | Not verified in available records; no messages have been sent in this task. |
| Combat assistance | Automatic next-step highlighting may conflict with the express prohibition on automatic ability recommendations. Fully disclose the behaviour; individual Jagex determination remains open. |
| Prayer notes | The guidelines expressly prohibit prayer indicators. Static user-authored reminders inside a combat sequence need individual assessment; no exemption or approval is claimed. |
| Complete native verification | Earlier targeted bomb-identity observations do not establish a complete current-package test. |
| Platforms | The current submission page lists Windows, Linux, Android and iOS. No complete current-runtime native matrix is confirmed for these platforms. The page also mentions Source, while a previously user-supplied 8 October announcement removes that checkbox requirement. Confirm the actual portal options before uploading; do not treat the earlier desktop-only draft list as authoritative. |
| Catalogue | 138 weapons lack a confirmed beta mapping; do not claim complete native coverage. |

The description needs contact, feedback/collaboration, EULA, permissions and data-use sections. Any documented exception to publicly displaying a contact does not remove a contact requirement in the manifest/moderation process.

`tools/release_preflight.py` reports local technical checks, submission-manifest validity and unresolved policy questions separately. The missing contact is a submission-manifest failure even if local structure checks pass. `--for-submission` refuses a submission-ready result while evidence remains outstanding. Local packaging remains possible and preserves configuration. Technical readiness does not establish moderation approval.
