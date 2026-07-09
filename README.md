# Hinomori

Peaceful rural Japanese **student roleplay** for Roblox — locker identity, notes, hand-offs, and arcade hangout. Built with Luau, Rojo, and Wally.

Design wiki: `C:\Users\elifs\Projects\llm-wiki`

## Setup

1. Install tools:

```powershell
cd "E:\cursor\rural japan school game"
aftman install
wally install
```

2. Open the place in Roblox Studio:

   - **Option A (recommended for first setup):** Open `hinomori.rbxl` from the repo root (generated via `rojo build -o hinomori.rbxl`).
   - **Option B:** Open your existing `hinomori` place and connect the Rojo plugin to `localhost:34872`.

3. Start Rojo and connect the Studio plugin:

```powershell
rojo serve
```

In Studio: **Rojo plugin → Connect** (host `localhost`, port `34872` — default when serve is running).

4. Play in Studio to verify server/client startup logs (`[Hinomori] Server startup complete` and `Client startup complete`).

> **Note:** ProfileStore logs `Roblox API services unavailable` in Studio play without published place access — expected; data won't persist locally until published.

## Repo layout

```
src/
  services/          # Co-located Client + Server + Shared per system (Leif pattern)
  startup/           # Server + Client bootstraps
  modules/           # Core, Game, Math, Platform utilities
  ui/                # Modular UI initializer + feature modules
  shared/Data.luau   # DataServiceTyped profile schema
```

Map geometry lives in the Studio place file. Code syncs via Rojo only.

## Adding a new service

1. Create `src/services/FooService/FooServiceClient.luau`, `FooServiceServer.luau`, `FooServiceShared.luau`
2. Add mappings to `default.project.json` under `ReplicatedStorage.Shared.Services` and `ServerScriptService.Services`
3. Register `"FooService"` in `SERVICE_ORDER` in both startup scripts
4. Whitelist client-callable methods in `Networker.server.new` on the server module

## Packages (Wally)

- Signal, Janitor, Sift
- Networker (typed remotes)
- DataServiceTyped + ProfileStore (persistence)

## Tooling

| Command | Purpose |
|---------|---------|
| `rojo serve` | Live sync to Studio |
| `stylua src` | Format Luau |
| `selene src` | Lint Luau |
