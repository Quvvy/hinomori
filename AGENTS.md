# Agent Brief - Hinomori

Read this file before changing the project. Hinomori is a Roblox slice-of-life game built with strict Luau, Rojo, and Wally.

## Read Order

1. `AGENTS.md`
2. `README.md`
3. `docs/CURRENT_STATE.md`
4. `docs/GDD.md`
5. `docs/ARCHITECTURE.md`
6. `docs/STUDIO_WORLD.md`
7. `docs/ROADMAP.md`
8. The relevant subsystem document in `docs/`
9. `docs/AUTONOMY_GUARDRAILS.md` before multi-slice or high-autonomy work

The repository is self-contained. The owner's external llm-wiki is optional background, not required project context.

## Product Thesis

**Vision:** peaceful rural Japanese student roleplay - *"I wish I lived in this town."*

Retention should come from rituals, identity, and recognition: lockers, notes, small hand-offs, spectators, familiar routes, weather, and memories. It should not come from grind, rigid schedules, paid identity rerolls, or anxiety-driven streaks.

The game is currently a **prototype**. Preserve the current locker -> social -> after-school loop before adding more locations or major systems.

## Status Labels

| Label | Meaning |
| --- | --- |
| **Implemented** | Real repository behavior with appropriate authority and verification |
| **Prototype** | Playable but incomplete, placeholder, or not release-ready |
| **Planned** | Approved next work that is not built |
| **Future direction** | Product intent; do not build without an explicit slice |
| **Out of scope** | Do not build unless the user explicitly changes scope |

Do not describe planned behavior as implemented. `docs/CURRENT_STATE.md` is the current feature inventory; `docs/ROADMAP.md` owns future sequencing.

## Architecture Rules

### Services

Each system lives in `src/services/FooService/`:

- `FooServiceClient.luau` -> `ReplicatedStorage.Shared.Services.FooService`
- `FooServiceShared.luau` -> shared types and constants when needed
- `FooServiceServer.luau` -> `ServerScriptService.Services.FooService`

Startup order is explicit in both startup scripts. `DataService` must remain first. Add a service to `default.project.json` and both startup lists; do not rely on folder iteration order.

### Networking And Authority

- Use Networker for client/server traffic and explicitly whitelist every client-callable server method.
- Never trust the client for profile data, locker state, notes, hand-offs, queue/occupancy, scores, rewards, or item ownership.
- Validate alive state, distance, cooldown, ownership, target, item/catalog IDs, and active state server-side.
- Other services mutate profiles only through `DataServiceServer` profile access.
- Keep server-only logic out of ReplicatedStorage modules.

### UI

- `src/ui/init.luau` mounts the persistent `HinomoriUI` root and session HUD.
- Client services mount their own feature menus during `Start` (locker, phone/hand-off, session flow, arcade, garage).
- Preserve the phone + paper + world-surface language in `docs/UI_DIEGETIC_DIRECTION.md`.
- Do not add React, Roact, or Fusion unless explicitly requested.
- A missing world object must warn once and disable only the affected feature; it must not throw during UI startup.

### World And Builder Content

- Git/Rojo owns scripts, shared modules, UI code, configs, and catalogs.
- The shared Roblox Team Create place owns geometry, lighting, terrain, props, Sounds, and `Workspace.World`.
- Do not add gameplay logic as ad hoc Studio scripts.
- Lockers and desks currently get runtime tags/IDs. Arcade and garage are still named singleton setups; do not claim they are copy-paste safe yet.
- The next architecture milestone is the builder-safe world registry described in `docs/ROADMAP.md`.

## Scope Guardrails

Current spine:

- persistent locker identity and decor
- safe stranger templates and filtered Roblox-friend notes
- snack hand-off pipeline
- minimal session/first-day guidance
- arcade queue, spectators, Solo/1v1 four-key rhythm
- garage Practice gate, shared occupancy/stems, and opt-in prototype charts

Do not add without explicit approval:

- full schedule simulation, many functional classrooms, PE, clubs, dorms, or city transport
- complex NPC relationship trees
- deep inventory/economy/job systems
- stranger free text or new offline social persistence
- paid random identity, rerolls, monetization UI, or pain/FOMO mechanics
- a second rhythm engine, runtime MIDI parser, or auto-chart pipeline

## Working Safely

- The worktree may contain user or agent changes. Inspect `git status` and diffs first. Never reset or overwrite unrelated work.
- Before Studio-facing edits, confirm the baseline: startup, HUD, locker, hand-off, arcade, rhythm, and garage as relevant.
- Use Roblox Studio MCP to inspect exact world paths and assets when available. If unavailable, say so and leave a precise manual checklist.
- Missing or malformed world content must fail locally and gracefully.
- Work one complete slice at a time. Do not bundle unrelated refactors.
- After Studio-facing work, report automated checks, MCP checks, and remaining human Studio checks separately.
- If a required final asset cannot be made with available tools, tell the user exactly what is needed instead of faking completion.

## Standard Verification

```powershell
stylua --check src
selene src
rojo build default.project.json -o build\verification.rbxl
```

Use `docs/TESTING.md` for the complete one-player and two-player regression checklists.

## Current Priority

Stabilize the existing prototype, then implement the builder-safe world registry beginning with lockers. Do not expand the town before the current loop and duplication contracts are dependable.
