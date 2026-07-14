# Studio World And Builder Guide

## Authority And Verification Status

The shared Roblox Team Create place is the authoritative world. Git/Rojo owns code; it does not own the complete map.

Roblox Studio MCP was not callable from this Codex task during the 2026-07-14 documentation pass, even after the place was opened. The paths below are code-backed and match the most recent recorded Studio inspection from 2026-07-10, but a collaborator should run the verification checklist at the end before changing world content.

Do not use the tracked `rural.rbxl` as current world truth. It is a legacy snapshot. Do not assume a `rojo build` output contains the Team Create geometry.

## Expected World Topology

```text
Workspace
  World
    School
      LockerHallway
        Lockers
      Classroom
        Desks
    Arcade
      CabinetPair_001
    Garage
      GarageJam_001
        RehearsalBoard
        DrumsStation
        BassStation
        GuitarStation
        VoiceStation
```

The world may contain additional visual parts and folders. Code should depend only on documented contracts, not decorative names.

## Locker Contract

Root: `Workspace.World.School.LockerHallway.Lockers`

Each valid direct child locker is a `Model` containing:

```text
Locker model
  PromptPart (BasePart)
    ProximityPrompt
  DecorSlots (Folder)
    Slot_01 (BasePart)
    Slot_02 (BasePart)
    Slot_03 (BasePart)
```

Runtime behavior:

- Adds CollectionService tag `HinomoriLocker`.
- Preserves a valid unique `LockerId` attribute such as `Locker_001`.
- Repairs missing or duplicated IDs on server start and after direct children are added.
- Discovers lockers from structure and attribute, not model name.
- A model missing `PromptPart` or `DecorSlots` is skipped as an invalid candidate.

A builder may duplicate a complete valid locker without renaming it. Runtime repairs the copied ID. Do not hand-edit persisted player data to match model names.

## Desk Contract

Root: `Workspace.World.School.Classroom.Desks`

Each direct child desk station is a `Model`. Runtime adds `HinomoriDesk` and repairs a `DeskId` such as `Desk_01`. A station may contain `LabelPart` and should contain the visual desk/chair plus its functional `Seat`.

Desks are atmosphere props. They are not assigned to players and must not reintroduce assigned-seat UI or profile/session fields. The current seat should align with the chair's `Desk/Chair/Bottom/WoodSurface` placement in the authored model.

## Arcade Contract

Current root: `Workspace.World.Arcade.CabinetPair_001`

Required current interaction:

```text
CabinetPair_001 (Model)
  PromptPart (BasePart)
    ProximityPrompt
```

The current service expects this exact singleton name and uses one shared queue, spectator set, and active match. `CabinetId` exists as a config/attribute concept, but duplicating the model does **not** create an independent cabinet today.

Do not promise copy-paste arcade setup until the planned world-registry and multi-instance arcade migration ships. A malformed/missing cabinet should disable arcade prompt binding and warn without breaking other services.

## Garage Contract

Current root: `Workspace.World.Garage.GarageJam_001`

### Rehearsal Board

```text
RehearsalBoard (Model)
  PromptPart (BasePart)
    ProximityPrompt
```

Expected prompt text:

- `ObjectText = "Rehearsal Board"`
- `ActionText = "Check the board."`

The board opens a paper UI. `Practice` is server-distance validated and unlocks local station prompts. `Show` is flavor-only.

### Instrument Stations

Each fixed station model contains:

```text
<Instrument>Station (Model)
  PromptPart (BasePart)
    ProximityPrompt
  PlayerAnchor (BasePart)
```

Fixed mappings:

| Station ID | Model name | Sound key |
| --- | --- | --- |
| `drums` | `DrumsStation` | `drums` |
| `bass` | `BassStation` | `bass` |
| `guitar` | `GuitarStation` | `guitar` |
| `voice` | `VoiceStation` | `voice` |

The server places the player's HumanoidRootPart at `PlayerAnchor`, sets movement properties to zero without anchoring the character, and restores previous values on leave/death/respawn/removal.

The garage and stations are named singleton content today. Duplicating or renaming them is not supported until their registry migration.

## Recorded Garage Sounds

These exact direct Workspace Sound names were recorded in the last Studio inspection:

| Purpose | Path | Recorded asset ID |
| --- | --- | --- |
| Drums stem | `Workspace.Wheatus-Teenage Dirtbag-drums-05-29-2026` | `rbxassetid://127415973583162` |
| Bass stem | `Workspace.Wheatus-Teenage Dirtbag-bass-05-29-2026` | `rbxassetid://83092464893825` |
| Guitar stem | `Workspace.Wheatus-Teenage Dirtbag-guitar-05-29-2026` | `rbxassetid://134153333825177` |
| Voice stem | `Workspace.Wheatus-Teenage Dirtbag-voice-05-29-2026` | `rbxassetid://121048595409706` |
| Full mix | `Workspace.Wheatus-Teenage Dirtbag-full-mix-05-29-2026` | `rbxassetid://71360783633686` |

The last recorded `TimeLength` was about 230.4 seconds for all five Sounds. Code resolves names with `FindFirstChild`-style path traversal because names contain dashes.

The full mix is intentionally unmapped and must remain stopped. All commercial music is prototype-only unless rights are secured.

## Builder Workflow

1. Pull Git and open the shared Team Create place.
2. Connect Rojo only after confirming the correct place.
3. Duplicate the complete root Model for a currently supported copy-paste type.
4. Keep required child names and types intact.
5. Move/rotate the root Model; do not separate prompts, slots, seats, or anchors from it.
6. Enter Play and inspect attributes, prompts, Output warnings, and interaction distance.
7. Save/publish world changes through Team Create and commit code separately.

For unsupported singleton content, add no duplicate and do not invent a naming convention. Plan the registry/multi-instance migration first.

## Graceful Failure Standard

- Missing world roots, prompts, anchors, slots, or Sounds warn once with an actionable path.
- One malformed object disables only that object/feature.
- UI startup and unrelated locker, hand-off, arcade, or garage systems continue.
- State-changing requests fail server-side when their physical validation point is absent.
- Never silently substitute the full mix or another Sound for a missing stem.

## Owner Studio Verification Checklist

- Confirm the expected world roots and exact capitalization.
- Confirm every locker has `PromptPart`, `ProximityPrompt`, `DecorSlots`, and three slot parts.
- Duplicate one locker without renaming; Play and confirm a unique `LockerId` appears.
- Confirm classroom station seats align with chair surfaces and remain sittable.
- Confirm `CabinetPair_001.PromptPart.ProximityPrompt` opens the arcade.
- Confirm `GarageJam_001` contains the board and four named station models.
- Confirm every station has a prompt and `PlayerAnchor` clear of geometry.
- Confirm all five recorded Sounds still exist and the full mix remains stopped.
- Confirm Rojo connection does not remove `Workspace.World` geometry.
- Update this document immediately if the live shared place differs.
