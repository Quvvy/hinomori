# Current State - Hinomori

Last audited: 2026-07-14 against the current working tree.

Hinomori is a playable **prototype**. The core systems exist, but world content is still partly hardcoded, visual/audio assets are not release-ready, and the full loop needs a repeatable regression pass before the town expands.

## Feature Matrix

| Area | Status | Current behavior | Important limit |
| --- | --- | --- | --- |
| Student setup | Prototype | First-time homeroom card saves a chosen display name | Legacy `year` and `transferStyle` profile fields remain; style is ignored |
| Session flow | Prototype | Global Bus Prologue, School, and After School phases with session-only first-day guidance | Developer controls and global phase model are not a town clock |
| Desks | Prototype prop | Copy-paste IDs and hidden functional seats; no player assignment | Backpack/keychain hooks are future direction |
| Lockers | Prototype | Persistent assignment, three decor slots, runtime tag/ID repair, owner and visitor menu states | Discovery is folder-based; not yet on a general world registry |
| Stranger notes | Prototype | Approved templates, daily limits, distance checks, disable/clear/block controls | Online interaction; no offline delivery/report pipeline |
| Friend notes | Prototype | Roblox-friend-only short free text, server friendship check, TextService filtering | Online owner required; persistence/expiry policy remains narrow |
| Hand-offs | Prototype | Nearby snack offer, accept/decline/cancel/expiry, temporary recipient prop | Snacks are infinite placeholders; no general inventory ownership |
| Arcade | Prototype | One cabinet pair, queue, spectators, Solo/1v1, D/F/J/K rhythm, tickets and locker sticker | One named singleton cabinet; commercial/placeholder songs |
| Garage social jam | Prototype | Rehearsal-board Practice gate, four server-owned stations, movement lock, shared jam clock | One named garage and four named stations |
| Garage skill | Prototype | Optional full-song static charts per occupied instrument with miss-volume ducking | Local play/result only; commercial prototype song; currently uncommitted |
| Diegetic UI | Prototype | Tiny HUD plus paper, phone, and world-device surfaces | Mobile and dense-text pass still needed |
| Open town | Planned | Compact route and landmark direction in roadmap | Current place is a blockout, not a complete town |
| Builder world registry | Planned next | General tagged prefab discovery/validation | Today only lockers/desks have runtime ID repair |

## Current Player Data

`DataServiceShared.PROFILE_TEMPLATE` owns:

- `studentProfile.displayName`
- `studentProfile.year` (legacy/defaulted)
- `studentProfile.transferStyle` (deprecated/defaulted)
- `studentProfile.hasCompletedTransferSetup`
- `assignedLockerId`
- `lockerDecor`
- `lockerNotesSettings`
- `strangerNotes`
- `friendNotes`
- `blockedNoteSenderUserIds`
- `arcadeTickets`

Do not add, rename, or remove profile fields without a dedicated persistence/migration slice. Studio uses mock profiles through `src/shared/Data.luau`; do not infer production persistence from a Studio session.

## Session-Only State

- global session phase and in-game day key
- per-player first-day progress
- pending snack hand-off offers
- arcade queue, spectators, active match, and submitted results
- garage Practice readiness, station occupancy, movement locks, and shared jam clock
- rhythm scroll-speed preference and active UI/run state

Session-only state must be cleaned on player removal and, where relevant, death/respawn or UI close.

## Authority Boundaries

The server owns all state changes for profiles, notes, hand-offs, arcade membership/results/rewards, garage Practice and occupancy, and movement locks. Clients render menus, collect input, play local rhythm/audio presentation, and request validated actions through Networker.

Arcade result submission is sanitized against the selected chart's note count. It is still prototype anti-cheat, not a complete competitive security model.

## Known Scaling Gaps

- `ArcadeConfig` targets `Workspace.World.Arcade.CabinetPair_001`.
- `GarageJamConfig` targets `Workspace.World.Garage.GarageJam_001` and fixed station names.
- Prompt binding and warn-once discovery are repeated across services.
- `WorldAutoIds` scans direct children of configured folders rather than a general tagged registry.
- No shared item ownership/outcome layer, location registry, ambient-zone system, town world state, analytics funnel, or performance budget exists yet.
- Several old slice documents described superseded behavior and have been archived.

## Content And Release Limits

Teenage Dirtbag stems/charts, Camellia - Flamewall, and other non-original test audio are prototype references only unless release rights are secured. The Teenage Dirtbag full mix is intentionally unused. Do not build release plans around these assets.

No final phone, paper, arcade, garage, locker, signage, animation, or sound-effect art should be inferred from current blockouts.

## Current Worktree Handoff Warning

At this audit, the full-song garage skill layer includes modified and untracked files that are not present on `origin/master`. A collaborator cloning Git will not receive that work until the owner commits and pushes it. Check `git status` before handoff.

## Next Recommended Slice

Implement **World Registry + Locker Migration** as described in `ROADMAP.md`:

1. Define the tagged prefab descriptor/validation contract.
2. Move current locker discovery and ID repair onto it without changing locker behavior.
3. Add diagnostics and a Studio scan/stamp workflow.
4. Prove duplicate, delete, malformed-copy, and saved-ID fallback behavior.
5. Migrate arcade cabinets in a later slice, not the same one.
