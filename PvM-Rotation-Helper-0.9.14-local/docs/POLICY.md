# Functional boundaries and moderation status — 0.9.14

This is a technical inventory, not legal advice or Jagex approval. Existing project references: [Plugin guidelines](https://developer.runescape.com/rs/submission/guidelines.html) and [EULA, Schedule 4](https://legal.jagex.com/docs/terms/eula), recorded as reviewed on 24 October 2026.

| Implemented function | Boundary or outstanding assessment |
|---|---|
| Manually authored fixed rotations/phases | No automatic boss/wave/phase selection or optimal-sequence calculation. |
| Progression from matching keys/action-bar clicks | Automatically highlights the next stored ability step. An attempt is not proof of execution. This combat assistance must be explicitly disclosed. |
| Learner slot frames | Own click-through rendering over confirmed visible slots; no changes to other controls' hit areas, positions or visibility. |
| Expert mode | Static sequence without input-driven progression. |
| Weapons, ammunition, potions/bombs, spells, special weapon/EOF | Passive reminders; no game action. |
| Prayer reminders | Manually placed standard-prayer/curse cells; no prayer-state observation, conditional choice or activation. The guidelines also prohibit prayer indicators, so this passive presentation is not asserted to be exempt. |
| Detect/Diagnose | Explicit read operations. Only Detect saves the plugin's profile assignments. |
| Windows/search/language/transparency | Own components only. |
| Right-click assignment on own special/EOF icons | Own Select/Assign entries only; no modification of game Ops or game action. |

No generated game input, prayer switching, mechanic prediction, positioning instructions, hidden combat decision, other-player data, chat processing or runtime networking. Permission and dependency collections are empty.

The current guidelines explicitly prohibit automatic ability recommendations. Learner and Advanced automatically highlight the next ability in a user-written sequence after matching input. That implementation may fall within the prohibition even though it never executes an ability. This is an unresolved potential conflict, not a finding of compliance. Combat overlays and input/menu features also receive additional review. Expert is static, but its presence does not approve the complete package. Individual determination remains with Jagex; no moderation submission has been made.

The examples also prohibit prayer-switching indicators or indications of which prayer to use. User-authored prayer cells in a combat sequence may still fall within that wording. They remain passive here, but passive implementation alone does not establish approval or a policy exception. This additional question must be disclosed for individual review.

Schedule 4 of the EULA incorporates the applicable plugin guidelines, requires rights to incorporated content, and disallows unfair advantage such as automation. This audit checks observable implementation boundaries and documents evidence; it does not certify legal compliance, content rights or personal human review.

Personal human review and historical provenance evidence remain documented in [AI-STATUS.md](AI-STATUS.md). This document neither establishes copied code nor claims that rewriting documentation resolves historical questions.
