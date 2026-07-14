# Fourth Slice Plan - Session Flow and Rotating Desks

## Recommendation

Build a minimal session frame tying school and after-school together, plus rotating desks as social friction.

This is not a school schedule sim. It is a prototype wrapper around the V0 loop: bus prologue, school, after-school, and a rotating desk assignment that contrasts with persistent lockers.

## Scope

Status target: Prototype

In scope:

- server-owned phase state: `BusPrologue`, `School`, `AfterSchool`
- prototype UI controls to advance/set phase
- server-session desk assignment
- desk rotation when starting a new prototype day
- placeholder classroom desks
- client-side desk assignment labels

Out of scope:

- full schedule
- bell system
- classes, teachers, clubs, PE, music room, cleaning duty
- real bus travel or city bus
- persistent desks
- NPC relationships

## Player Experience

1. Player joins and sees the current phase.
2. Player receives a rotating desk assignment for the current server/day.
3. Player can identify their assigned desk from a label.
4. Prototype controls can advance Bus Prologue -> School -> After School -> new day.
5. Starting a new prototype day rotates desks while lockers remain persistent.

## Acceptance Criteria

- SessionService exposes current phase, day key, assigned desk, and desk assignment list.
- Client UI shows phase and assigned desk.
- Phase can advance through Bus Prologue, School, and After School.
- New prototype day rotates desks.
- Desks are not stored in profile data.
- Placeholder desks exist under `Workspace.World.School.Classroom.Desks`.
- Desk labels appear client-side.
- No full schedule, class system, or bus simulation is introduced.

## Studio Checklist

Use Studio/MCP where possible. If not fully verified, leave this checklist for the user:

- Reconnect Rojo if needed and confirm `[Hinomori] Server startup complete` appears in Play mode.
- Confirm `[Hinomori] Client startup complete` appears in Play mode.
- Confirm `Workspace.World.School.Classroom.Desks` exists.
- Confirm `Desk_01` through `Desk_08` exist with `DeskId` attributes and `LabelPart`.
- Confirm `SessionFlowUI` appears in Play mode.
- Confirm phase label starts at Bus Prologue.
- Click `Next phase` and verify School, then After School, then Bus Prologue.
- Confirm `New day` rotates desk assignment.
- Confirm desk label appears over the assigned desk.
- Confirm locker assignment/decor does not change when desks rotate.
- In two-player local test, confirm players receive different desks when space allows.

## Verified This Pass

- `stylua src` passed before docs update.
- `selene src` passed with 0 warnings before docs update.
- `rojo build default.project.json -o build\slice4-check.rbxl` passed before docs update.
- Studio Edit mode has placeholder classroom desks.
- Studio Edit mode sees `DeskConfig`, `DeskWorld`, `DeskVisuals`, and `SessionFlowMenu`.
- Studio Client Play mode showed `SessionFlowUI`.

## Follow-up Verification - 2026-07-06

- Fixed session panel startup so state fetch retries instead of staying on a single failed load attempt.
- Fixed desk assignment date seed parsing; Studio Play now shows `Day phase: Bus prologue` and `Today's desk: Desk_01`.
- `stylua src` passed.
- `selene src` passed with 0 warnings.
- `rojo build default.project.json -o build\session-loading-fix.rbxl` passed.
- MCP could not simulate an actual mouse click on the phase buttons because Studio blocks synthetic input from this context, so manual button checks are still needed.

## Known Prototype Limits

- Studio Play runtime did not show initialized server lifecycle through MCP, so full phase/desk server flow remains manual until Rojo/Studio startup is confirmed.
- Phase controls are prototype tester controls, not final diegetic UI.
- Desk assignment is server-session scoped and not persisted.
- Desk rotation uses real-world day key plus user id as a prototype seed.
