# First Slice Plan - Locker Hallway Identity

## Recommendation

Do not start with full character creation.

Start with the smallest playable loop that proves the core fantasy:

> A player has a persistent student identity, owns a locker, decorates it, receives a safe template note, and can see that identity survive a session restart.

Character creation should appear in this slice only as a thin placeholder: display name, year, and maybe one simple "transfer form" choice saved to the profile. Full personality-quiz creation, weighted appearance, wardrobe, and monetization should wait until the locker/social loop has something worth expressing.

## Why This First

The V0 hypothesis is:

> Do players care about their student, their locker, their notes, and being seen by other players?

A standalone character creator answers the wrong first question. It can prove that players like making an avatar, but not that they care about this specific school world.

The first slice should prove:

- The locker feels owned.
- The locker can visibly change.
- Server data drives the visible state.
- Notes can be delivered safely without free-text stranger risk.
- The Studio world has enough school structure to test the loop.

## Slice Name

**Slice 1: Locker Hallway Identity**

Status target: Prototype

## Player Experience

1. Player spawns at school.
2. Player sees a short "transfer student" prompt if they have no profile customization yet.
3. Player is assigned their persistent locker.
4. Player walks to the locker hallway.
5. Player interacts with their locker.
6. Locker menu opens.
7. Player applies one sticker/decor item to a fixed slot.
8. The locker updates visibly in-world.
9. Player can open a note panel and see/send one stranger-safe template note.
10. Player leaves and rejoins Play mode, or resets profile in mock data, and the saved locker state can be verified.

## Explicit Non-Goals

- No full personality quiz.
- No paid cosmetics.
- No wardrobe shop.
- No desk rotation yet.
- No friend free-text notes yet.
- No full hand-off accept/decline flow yet.
- No arcade yet.
- No full town traversal.
- No NPC relationships.

## Asset Dependency Rule

Cursor should use simple placeholders for this slice unless a real asset already exists in the repo or Studio place.

Cursor must tell the user instead of silently faking completion if it needs any of these assets and cannot make them through code or Studio automation:

- final locker model art
- final sticker/decor icons
- school hallway set dressing
- uniform/body/face/hair assets
- custom UI illustration or texture work
- audio/music
- final Japanese signage or typography treatment

For Slice 1, acceptable placeholders are:

- blockout locker models
- plain Parts for decor slots
- colored SurfaceGuis for stickers
- text labels for note templates
- basic Roblox UI controls

## Required Repo Work

### 1. Data Model

Update player profile data so the locker slice can persist:

- `studentProfile.displayName`
- `studentProfile.year`
- optional `studentProfile.transferStyle` or `studentProfile.morningAnswer`
- `studentProfile.hasCompletedTransferSetup`
- `assignedLockerId`
- `lockerDecor`
- `lockerNotesSettings`
- visible stranger notes, if not already represented

Keep the schema small. The goal is one persistent locker state, not the whole student identity system.

For local Studio testing, Cursor may set the data layer to use mock storage in Studio, but it must verify and document what actually persists. Do not promise persistence across full Studio restart unless the current data library proves it.

### 2. Locker Service

Implement server-authoritative locker ownership and decor.

Minimum methods:

- `requestLockerSummary(player)`
- `requestLockerState(player, lockerId)`
- `applyLockerDecor(player, lockerId, slotId, itemId)`
- `clearLockerDecor(player, lockerId, slotId)`

Validation:

- Player must be alive.
- Player can only modify their own locker.
- Player must be close enough to the locker prompt.
- `slotId` must be a known slot.
- `itemId` must be in the allowed starter decor list.
- Cooldowns should prevent spam.

Locker assignment should be collision-safe for active players. For the prototype, maintain a server-session map of active locker owners, prefer a player's saved `assignedLockerId` if free, otherwise assign the first free locker from `Locker_001` through `Locker_006`. If all six are occupied, fail gracefully and document the prototype limit. Do not use `UserId % lockerCount` alone.

### 3. Locker World Binding

Create a simple way for code to identify lockers placed in Studio.

Recommended attributes on each locker model:

- `LockerId`
- `OwnerUserId` if assigned dynamically, or leave unset and map server-side
- `InteractDistance`

Recommended model structure:

```text
Workspace
  World
    School
      LockerHallway
        Lockers
          Locker_001
            PromptPart
              ProximityPrompt
            DecorSlots
              Slot_01
              Slot_02
              Slot_03
```

The repo should own code. Studio should own the physical models, prompt parts, slot parts, lighting, and hallway layout.

Modules under `src/modules/Game` are already folder-mapped by Rojo. Extra service helper modules under `src/services/LockerService` must be mapped explicitly if they need to appear under `ReplicatedStorage.Shared.Services.LockerService`.

### 4. Locker UI

Replace the current single `Locker` button with a real menu opened from proximity interaction.

Minimum UI:

- locker title/name
- sticker/decor inventory list with 3 starter items
- fixed slot picker
- apply button
- clear slot button
- note panel entry point
- close button

Keep it plain and functional. This is a prototype UI, not final art.

### 5. Starter Decor Catalog

Add a small config module for V0 locker items.

Minimum starter items:

- `spring_sticker`
- `arcade_token_sticker`
- `stationery_label`

Each item should define:

- id
- display name
- slot type, if needed
- color/icon/asset placeholder

For the prototype, colored Parts or SurfaceGuis are acceptable. Do not block on final art.

### 6. Template Note Stub

Implement the first safe note behavior as part of the locker slice.

Minimum:

- Player can fetch stranger note templates.
- Player can leave one template note on another online player's locker.
- Stranger notes respect:
  - 1 sender per target locker per in-game day
  - max 5 visible stranger notes
  - stranger notes enabled/disabled setting

Can be simplified if only one test player is present:

- Support a debug/test locker note route.
- Make clear in code comments and docs that full multi-player note delivery is next.

No free text yet.

Offline locker notes are out of scope for Slice 1. If solo testing needs a note path, add a clearly marked debug route and document that it is not final gameplay.

### 7. First Transfer Student Prompt

Add a tiny first-run setup, not a full character creator.

Minimum:

- display name text field or default Roblox display name
- first-year default
- one flavor choice, such as:
  - Quiet train
  - Sunny bike ride
  - Rainy walk

This choice should save to `studentProfile` but does not need to affect appearance yet.

## Suggested Build Order for Cursor

1. Verify startup and service registration.
2. Add/confirm profile fields for locker state and starter identity; document mock persistence behavior after testing.
3. Implement locker ownership/state APIs server-side.
4. Implement simple client locker interaction flow.
5. Build the locker menu UI.
6. Add starter decor catalog and visible in-world slot rendering.
7. Add template note send/view stub.
8. Add the tiny transfer student first-run prompt.
9. Format and lint.
10. Write a Studio checklist for anything that cannot be verified by automated/MCP tooling.

## Acceptance Criteria

The slice is done when:

- A player can open their locker from a Studio ProximityPrompt.
- The server rejects edits to lockers the player does not own.
- The player can apply one of at least 3 starter decor items.
- Decor appears on the correct locker slot in-world.
- Locker state is stored in the profile schema.
- A player can view available stranger note templates.
- A player can leave/view a template note through the locker UI or a debug test path.
- Stranger-note safety rules are present, even if the first prototype uses a simplified day clock.
- Stranger notes target active online locker owners only, or any solo debug path is clearly marked.
- The first-run student prompt saves a small student profile.
- The repo documents what local Studio/mock data does and does not persist.
- Cursor leaves a manual Studio checklist at the end of implementation if Studio verification cannot be fully automated.

## Persistence Notes (Studio mock)

`src/shared/Data.luau` sets `useMock = RunService:IsStudio()` so Play mode uses ProfileStore's in-memory mock store.

**Verified behavior (prototype):**
- Profile data (transfer setup, `assignedLockerId`, `lockerDecor`, `strangerNotes`) persists across **Stop Play → Play again** within the same Studio session while `rojo serve` stays connected.
- **Full Studio restart** or closing the place may reset mock profiles — do not treat Studio mock as production persistence.
- Live production uses ProfileStore (`profileStoreIndex = "Hinomori"`) when `useMock` is false.

**Known limits:**
- Locker assignment is session-scoped for occupancy (`_activeLockerOwners`); saved `assignedLockerId` is reclaimed on rejoin when unoccupied.
- Stranger notes require the locker owner to be **online** on the same server.
- Day-key rate limits use real-world `os.date("%Y-%m-%d")`, not in-game calendar.

## Studio Checklist

Cursor should ask the user to perform these in Roblox Studio if it cannot drive Studio directly:

- Confirm `Workspace.World` exists.
- Create `Workspace.World.School`.
- Create `Workspace.World.School.LockerHallway`.
- Create `Workspace.World.School.LockerHallway.Lockers`.
- Add at least 6 locker models named `Locker_001` through `Locker_006`.
- Each locker model has a `PromptPart`.
- Each `PromptPart` has a `ProximityPrompt`.
- Each locker model has a `DecorSlots` folder.
- Each locker has at least 3 slot parts named `Slot_01`, `Slot_02`, and `Slot_03`.
- Each locker model has a unique `LockerId` attribute matching its name or numeric id.
- Slot parts are positioned where stickers/decor should appear.
- Spawn location is close enough to the locker hallway for quick testing.
- Lighting is readable in Play mode.
- Proximity prompts are visible and reachable.
- In two-player local test, one player cannot edit the other player's locker.
- Stop and restart Play mode, then verify the saved mock/profile locker state behaves as expected for the current data mode.

## Cursor Handoff Prompt

Use this prompt when handing the plan to Cursor:

```text
Implement Slice 1: Locker Hallway Identity from docs/FIRST_SLICE_PLAN.md.

Stay inside V0 scope. Do not build full character creation, wardrobe monetization, desk rotation, arcade gameplay, clubs, PE, schedules, dorms, or NPC relationship trees.

Prioritize server-authoritative locker ownership, one persistent locker decor loop, a minimal first-run student profile prompt, and a safe template-note stub. Use the existing co-located service pattern, Networker, DataServiceTyped, and repo architecture from AGENTS.md.

If MCP/automation cannot fully verify Roblox Studio behavior, write a clear manual Studio checklist at the end with exact objects/attributes/prompts the user must create or test.

If implementation needs real art/model/audio assets that cannot be generated or created directly in code, stop and tell the user exactly which assets are needed. Use placeholders only for the prototype unless a final asset already exists.
```
