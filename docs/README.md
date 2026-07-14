# Hinomori Documentation

This folder contains the canonical collaborator-facing design and engineering context. The repository does not require access to the owner's private llm-wiki.

## Required Reading

| Order | Document | Purpose |
| --- | --- | --- |
| 1 | `../AGENTS.md` | Rules and guardrails for coding agents |
| 2 | `../README.md` | Human setup and Team Create/Rojo workflow |
| 3 | `CURRENT_STATE.md` | Honest inventory of what exists now |
| 4 | `GDD.md` | Product and design contract |
| 5 | `ARCHITECTURE.md` | Services, authority, data flow, UI, and extension rules |
| 6 | `STUDIO_WORLD.md` | Current world contracts and builder workflow |
| 7 | `ROADMAP.md` | Future sequence and milestone gates |
| 8 | Relevant subsystem docs | Feature-specific behavior and constraints |
| 9 | `AUTONOMY_GUARDRAILS.md` | Required before autonomous or multi-slice work |

## Current Subsystem Documents

- `SOCIAL_SYSTEMS.md` - lockers, notes, hand-offs, safety, and persistence boundaries
- `RHYTHM_SYSTEM.md` - arcade and garage chart/runtime contracts
- `GARAGE_SOCIAL_JAM_V0.md` - garage world, occupancy, stems, and practice flow
- `UI_DIEGETIC_DIRECTION.md` - phone, paper, world-surface, and HUD language
- `TESTING.md` - automated, one-player, two-player, and viewport checks

## Source-Of-Truth Rules

- `CURRENT_STATE.md` wins for implementation status.
- `GDD.md` wins for product intent and guardrails.
- `ROADMAP.md` wins for future priority.
- `ARCHITECTURE.md` and source code win for engineering contracts.
- `STUDIO_WORLD.md` and the shared Team Create place describe world content.
- Files under `archive/` are historical records only.

If documentation and code disagree, inspect the code and shared place, report the mismatch, and update the canonical document as part of the same slice. Do not silently choose the more convenient claim.

## Documentation Maintenance

Every completed slice should update:

- current status and known limits
- affected subsystem contract
- Studio paths or prefab requirements
- testing checklist
- roadmap status when a milestone changes

Use implementation labels consistently: **Implemented**, **Prototype**, **Planned**, **Future direction**, and **Out of scope**.
