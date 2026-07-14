# Hinomori

Hinomori is a peaceful rural Japanese student-life roleplay game for Roblox. Players build identity through lockers and small personal objects, connect through notes and hand-offs, and gather after school at places such as the arcade and garage.

The project uses strict Luau, Rojo, Wally, Networker, and DataServiceTyped. It is currently a prototype.

## New Collaborator Setup

You need:

- access to this Git repository
- edit access to the shared Hinomori Roblox/Team Create place
- Roblox Studio with the Rojo plugin
- Git and the tools installed through Aftman

Clone the repository, then run:

```powershell
cd "path\to\rural japan school game"
aftman install
wally install
rojo serve
```

Open the **shared Team Create place** in Roblox Studio. In the Rojo plugin, connect to `localhost:34872`.

### Source Of Truth

- **Git/Rojo:** scripts, services, shared modules, UI, configs, catalogs, and documentation.
- **Shared Roblox place:** `Workspace.World`, terrain, lighting, physical models, Sounds, and other Studio-authored content.

Do not treat `rural.rbxl` or a file produced by `rojo build` as the current complete world. The tracked `rural.rbxl` is a legacy snapshot. A normal Rojo build verifies the code tree but does not reproduce the authoritative Team Create map.

Before connecting Rojo, confirm you opened the shared place. Do not sync a different project over the shared place or delete unknown Studio instances. `default.project.json` intentionally preserves unknown instances in key containers.

## First Successful Run

1. Connect Rojo to the shared place.
2. Start Studio Play.
3. Confirm Output contains:
   - `[Hinomori] Server startup complete`
   - `[Hinomori] Client startup complete`
4. Confirm the small session HUD appears.
5. Confirm a locker prompt, phone/snack flow, arcade prompt, and rehearsal board can open.
6. Stop Play before editing world geometry.

ProfileStore/API warnings can be expected in unpublished or restricted Studio sessions. `src/shared/Data.luau` uses mock profiles in Studio, so Studio behavior must not be presented as production persistence.

## Daily Workflow

1. Pull Git changes before starting.
2. Open the shared Team Create place.
3. Run `wally install` when `wally.toml` or `wally.lock` changes.
4. Run `rojo serve` and connect Studio.
5. Make code changes in the repository and map changes in Studio.
6. Test the affected flow and its baseline neighbors.
7. Save/publish Studio changes through the agreed Team Create workflow.
8. Format, lint, and build before handoff.

Do not assume a Studio save commits code, and do not assume a Git commit saves Studio world changes.

## Verification Commands

```powershell
stylua --check src
selene src
rojo build default.project.json -o build\verification.rbxl
```

For a formatter pass after intentional code edits:

```powershell
stylua src
```

See [docs/TESTING.md](docs/TESTING.md) for one-player and two-player Studio tests.

## Repository Layout

```text
src/
  modules/       Core validation, game configs/catalogs, platform helpers
  services/      Co-located client/server/shared gameplay services
  shared/        DataServiceTyped profile definition
  startup/       Explicit client and server startup order
  ui/            Persistent HUD, feature menus, and UI style primitives
docs/             Canonical design, architecture, world, testing, and roadmap
default.project.json
wally.toml
```

Start with [AGENTS.md](AGENTS.md) if you are a coding agent, or [docs/README.md](docs/README.md) for the complete documentation map.

## Collaboration Safety

- Inspect `git status` before editing; do not discard someone else's work.
- Never trust client requests for state-changing gameplay.
- Do not move map logic into Studio scripts.
- Treat commercial songs and charts as prototype-only until rights are secured.
- Keep changes narrow and leave a Studio checklist when automation cannot verify behavior.
