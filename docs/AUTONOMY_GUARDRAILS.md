# Autonomy Guardrails

Use this before any high-effort or multi-slice run.

## Operating Rule

Work one slice at a time. A slice is not complete until its acceptance criteria, repo checks, Studio verification path, docs/status update, and user-facing summary are done.

Do not optimize for "more features shipped." Optimize for preserving the rural student-life thesis while making the current slice playable and testable.

## Required Reading Before Each Slice

Read these before touching code:

1. `AGENTS.md`
2. `README.md`
3. `docs/CURRENT_STATE.md`
4. `docs/GDD.md`
5. `docs/ARCHITECTURE.md`
6. `docs/STUDIO_WORLD.md`
7. `docs/ROADMAP.md`
8. the current approved slice plan and relevant subsystem document

The repository is the collaborator-facing source of truth. The owner's private llm-wiki is optional provenance and must not be required for implementation.

## Scope Discipline

Allowed V0 spine:

- persistent locker identity
- template notes and owner safety controls
- generic hand-off pipeline
- one arcade cabinet pair with queue/spectators
- minimal session flow tying school to after-school
- one garage Practice space with shared station occupancy and prototype skill charts

Do not add these without explicit user approval:

- full character creator
- wardrobe shop or monetization
- paid random identity traits
- PE, clubs, music room, cleaning duty, dorms, full schedule, city bus
- complex NPC relationships
- inventory/economy systems beyond a slice's placeholder need
- open free-text stranger communication
- offline/social persistence beyond the slice plan

## Implementation Discipline

- Keep the co-located service pattern.
- Keep server authority for all state-changing actions.
- Use Networker whitelists for client-server calls.
- Validate alive state, distance, cooldowns, ownership/targeting, and item ids server-side.
- Prefer config/catalog modules for slice data instead of hardcoded strings scattered across UI and services.
- Use placeholders for prototype art and UI unless final assets already exist.
- Do not turn placeholders into implied final art.
- Do not refactor unrelated systems just because they look rough.

## Studio, MCP, and Asset Rules

Use Studio/MCP directly when it can safely verify or scaffold the current slice.

After any Studio-facing slice, provide a Studio checklist covering what was verified and what the user still needs to inspect manually.

If an asset is needed and cannot be made safely through code/Studio automation, stop and tell the user exactly what is needed. This includes:

- final character, uniform, hair, face, or body assets
- final locker, snack, arcade, or town models
- sticker/icon art
- music, sound effects, or rhythm charts
- final Japanese signage or typography
- custom UI illustration or texture work

Acceptable prototype placeholders:

- blockout Parts and simple models
- colored SurfaceGuis
- basic Roblox UI controls
- text labels
- simple temporary hand props
- placeholder sounds only if they are generated or already available

## Stop Conditions

Stop and ask before proceeding if:

- a change would expand beyond V0 scope
- a feature needs product direction not covered by the GDD/roadmap/approved plan
- persistence or moderation behavior would become more permanent than the slice plan states
- a real asset is required
- implementation would require deleting or rewriting unrelated user work
- Studio cannot be verified enough to know whether the slice works

## Completion Checklist Per Slice

Before moving to the next slice:

- acceptance criteria met
- relevant automated checks run, or failure explained
- Studio/MCP verification attempted
- manual Studio checklist written if needed
- docs/roadmap updated honestly
- known limits documented
- final summary includes what changed, what was verified, and what still needs manual review
