# Architecture - Hinomori

## Runtime Layout

Rojo maps repository code into two runtime sides:

```text
ReplicatedStorage
  Packages
  Shared
    Modules
    Services/<Service>/<Service>Client + Shared
  UI
ServerScriptService
  ServerPackages
  Services/<Service>/<Service>Server
StarterPlayer/StarterPlayerScripts/Client
```

`default.project.json` is the mapping authority. Unknown Studio instances are preserved in key containers so Rojo does not own the physical map.

## Startup

Both startup scripts require services in this explicit order:

1. DataService
2. SessionService
3. LockerService
4. NoteService
5. HandOffService
6. ArcadeService
7. GarageJamService

All modules are required first, then every `Init` runs, then every `Start` runs. Startup catches and warns on individual require/lifecycle failures so one feature should not prevent unrelated services from loading. DataService must remain first.

## Service Responsibilities

| Service | Server responsibility | Client responsibility |
| --- | --- | --- |
| DataService | Load/release typed profiles and expose server profile access | Observe local profile data |
| SessionService | Global phase, day key, session-only first-day progress | Session state, phase controls, first-day guide |
| LockerService | Discover/assign lockers, validate decor, serve owner/visitor state | Locker/transfer menus and decor rendering |
| NoteService | Validate/filter/rate-limit template and friend notes | Note request helpers and feedback |
| HandOffService | Pending offers, distance/cooldown/expiry, accept/decline/cancel | Phone UI and temporary accepted-item presentation |
| ArcadeService | Queue, spectators, match lifecycle, result sanitization, rewards | Cabinet menu and local rhythm runner |
| GarageJamService | Practice readiness, station occupancy, movement locks, shared clock | Prompt binding, aligned local stems, skill menu/run cleanup |

## Service Pattern

Use `src/services/FooService/` and the existing lifecycle:

- `Init`: initialize tables/signals and construct the Networker endpoint.
- `Start`: bind players, prompts, world objects, and cross-service behavior.
- Client-callable server methods receive `player` first and appear in the explicit Networker whitelist.
- Public server-to-client methods are handled by the matching client object.

Do not create remotes directly or hide state-changing behavior in shared modules.

## Data Ownership

`src/services/DataService/DataServiceShared.luau` defines the profile shape. `src/shared/Data.luau` configures DataServiceTyped and uses mock storage in Studio.

Only the server mutates player data. Other services obtain the loaded profile through DataServiceServer. A profile schema edit is a persistence change and requires migration/default/compatibility decisions, not just a type edit.

Keep transient occupancy, offers, queues, guidance, and active runs out of the profile unless a dedicated design requires persistence.

## Main Data Flows

### Locker And Notes

The server discovers valid lockers, repairs IDs, assigns an available locker, and persists `assignedLockerId`. Prompt interaction opens server-authoritative state. Decor and note actions validate locker identity, ownership/visitor role, distance, cooldown, catalogs/templates, settings, and blocks before mutation. Locker visuals are derived from authoritative decor.

### Hand-Off

The sender selects a catalog snack and nearby player. The server validates both players, distance, cooldown, and pending-state rules, then creates a short-lived offer. Accept/decline/cancel/expiry clears server state and notifies both clients. The visible snack is currently temporary client presentation, not inventory.

### Arcade

The cabinet prompt opens a menu. Server state owns queue, spectators, one active match, and result collection. The client runs the selected static chart locally and submits a summary; the server clamps judgments to chart note count, awards prototype tickets/sticker, broadcasts results, and clears the match.

### Garage

The rehearsal board calls `enterPractice` after server distance validation. Station joins validate Practice readiness, distance, occupancy, character/humanoid/root, and `PlayerAnchor`. The server positions and movement-locks the player, broadcasts occupants and `jamStartedAtServerTime`, and restores state on leave/death/respawn/removal. Clients align active local stems to the shared clock. An occupied player may opt into that station's local garage chart.

## UI Mounting

`src/ui/init.luau` creates `HinomoriUI` and mounts `SessionHud`. It remounts this persistent root on character spawn.

Feature menus are mounted by client services during `Start`:

- SessionServiceClient: session flow and first-day guide
- LockerServiceClient: locker and transfer prompt
- HandOffServiceClient: phone/hand-off menu
- ArcadeServiceClient: arcade menu and rhythm runner
- GarageJamServiceClient: rehearsal board, skill slip, and rhythm runner

New features should follow the owner service rather than turning `ui/init.luau` into a monolithic controller. Missing world references must not throw during mounting.

## Configs And Catalogs

- Config modules define world paths, IDs, distances, and feature constants.
- Catalogs define valid decor, snacks, songs, and garage charts.
- Services validate user-provided IDs against catalogs.
- Static rhythm maps are Luau modules parsed at runtime; MIDI/Guitar Pro files are offline references only.
- Garage charts stay separate from arcade songs.

## World Discovery Today

`WorldAutoIds.ensureSequentialIds` scans direct child Models under a supplied folder, adds a semantic CollectionService tag, preserves one valid ID, repairs missing/duplicate IDs deterministically, and returns sorted IDs. Lockers and desks use it.

This is not yet a general world registry. Arcade and garage still resolve fixed names/paths. The planned registry should add descriptor-based validation, tagged discovery, add/remove binding, and shared diagnostics without changing current gameplay in its first migration.

## Cleanup Contract

Any system that takes control of a player, UI, Sound, camera, movement property, queue slot, or occupancy must have one safe cleanup path. Call it on all applicable exits:

- normal finish or explicit leave
- UI close or another run starting
- occupancy/state loss
- death and respawn
- `PlayerRemoving`
- timeout or remote failure

Cleanup should be idempotent. Garage audio ducking and movement restoration are examples where repeated cleanup must remain safe.

## Extension Checklist

Before adding a service or world interaction:

- identify the server authority and validation boundary
- reuse a catalog/config instead of scattering IDs
- define missing/malformed world behavior
- define player removal, respawn, timeout, and cancellation cleanup
- state whether data is persistent or session-only
- state how a builder creates a second content instance
- add one-player and two-player tests when state is shared
