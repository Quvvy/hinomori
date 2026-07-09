# Agent Brief

You are working on **Hinomori**, a Roblox slice-of-life game built with Luau, Rojo, and Wally.

**Vision:** peaceful rural Japanese student RP -- *"I wish I lived in this town."* Retention comes from rituals and identity (locker, notes, arcade spectators), not grind or paid random identity rerolls.

**Design wiki:** `C:\Users\elifs\Projects\llm-wiki` -- read `wiki/concepts/rural-japan-vertical-slice-v0.md` for V0 scope.

---

# Read First

1. `AGENTS.md` (this file)
2. `README.md`
3. `docs/GDD.md`
4. `docs/ROADMAP.md`
5. `docs/AUTONOMY_GUARDRAILS.md` before multi-slice or high-autonomy work

If a request conflicts with GDD or wiki V0 scope, call that out before implementing.

---

# Implementation Status Labels

| Label | Meaning |
|-------|---------|
| **Implemented** | In repo; real gameplay (server-authoritative) |
| **Prototype** | Works but incomplete; may change |
| **Planned** | Next milestone; not built |
| **Future direction** | Intentional target; do not build without explicit milestone |
| **Out of scope** | Do not build unless user explicitly asks |

Current scaffold status: **Prototype** -- V0 slice chain implemented with placeholders: locker identity, snack hand-off, arcade social stage, session flow, and deassigned classroom desks.

---

# Architecture

## Co-located services (Leif pattern)

Each system lives in `src/services/FooService/`:

- `FooServiceClient.luau` -> `ReplicatedStorage.Shared.Services.FooService`
- `FooServiceShared.luau` -> shared types/constants
- `FooServiceServer.luau` -> `ServerScriptService.Services.FooService`

Startup order is explicit in `src/startup/Server.server.luau` -- **DataService first**.

## Packages

- **Networker** -- all client->server calls; whitelist methods in `Networker.server.new`
- **DataServiceTyped** -- player profiles via `src/shared/Data.luau`; other services mutate data only through DataService
- **Signal, Janitor, Sift** -- events, cleanup, immutable table ops

## UI

Modular UI under `src/ui/` -- `init.luau` bootstraps HUD/Menus. No React/Fusion unless explicitly requested.

---

# Security Rules

- **Never trust the client** for locker state, notes, hand-offs, arcade scores, or rewards.
- All RemoteFunction/Event traffic goes through **Networker** with an explicit client-access table.
- Validate player alive, distance, cooldowns, and friendship tier server-side (`Shared.Modules.Core.Validate`).
- Do not put server-only logic in ReplicatedStorage modules.

---

# V0 Scope (Planned)

**In:** persistent locker, template notes, hand-off pipeline, one arcade cabinet pair with spectators, and classroom atmosphere props.

**Out:** PE, music room, cleaning duty, full schedule, dorms, multiple classrooms, clubs, city bus, complex NPC trees.

See wiki: `rural-japan-vertical-slice-v0`.

---

# Studio vs Repo

- **Repo:** all scripts, modules, UI code, config tables
- **Studio place (`hinomori.rbxl`):** map geometry, lighting, props, spawn locations under `Workspace.World`

Do not move gameplay logic into Studio scripts.

---

# Current Priority

V0 slice chain complete as a prototype. Next work should harden existing V0 systems, not add out-of-scope features, unless the user explicitly chooses a new milestone.

Do not add major systems outside V0 without explicit ask.
