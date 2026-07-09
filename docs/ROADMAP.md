# ROADMAP - Hinomori

## Phase 0 - Scaffold (Done)

- [x] Rojo + Wally project structure (Leif co-located services)
- [x] DataServiceTyped profile schema
- [x] Networker wiring for V0 services
- [x] Modular UI initializer
- [x] Studio world folders for School, Town, Arcade, lockers, classroom desks, and arcade scaffold

## Phase 1 - Locker Identity (Prototype)

- [x] Locker interaction prompts in `Workspace.World.School.LockerHallway`
- [x] Server-authoritative locker customization
- [x] Persistent locker recognition across sessions
- [x] Template stranger notes stub with owner controls
- [x] Copy-paste-safe locker IDs/tags generated at runtime

## Phase 2 - Hand-Off And Notes (Prototype)

- [x] Stranger template note send/receive with rate limits
- [x] Owner controls: disable strangers, clear, block
- [x] Unified offer/accept/decline pipeline for snack skin
- [x] Distance + cooldown validation
- [ ] Friend-tier free text after stranger loop works
- [ ] Offline locker note delivery

## Phase 3 - Arcade Social Stage (Prototype)

- [x] Cabinet queue + spectator spots
- [x] Solo + 1v1 flow
- [x] First playable four-lane rhythm loop with text chunk maps
- [x] Multiple test songs/maps
- [x] Compact cabinet/result UI styling

## Phase 4 - Session And Diegetic UI (Prototype)

- [x] Bus prologue -> school -> after-school phase transitions
- [x] Phone + paper + world-surface UI language
- [x] Removed assigned desks from session flow
- [x] First-time transfer card asks for name only

## Phase 5 - Copy-Paste World Setup (Prototype)

- [x] Runtime-generated locker/desk tags and IDs for builder-safe copy-paste
- [x] Locker assignment uses discovered lockers instead of a hard-coded six-locker limit
- [x] Placeholder classroom desks replaced with `SchoolDesk` + `SchoolChair` stations
- [x] Hidden functional seats added to new chair stations

## Phase 6 - First-Day Loop Guidance (Prototype)

- [x] Gentle first-day homeroom note using the diegetic UI primitives
- [x] Server-session progress hooks for locker, decor, note, snack, after-school, and arcade actions
- [x] No new economy, quest rewards, monetization, schedule sim, or out-of-scope school systems

## Next - V0 Hardening (Planned)

- [ ] Manual two-player pass for notes and snack hand-off
- [ ] Manual arcade pass for Solo and 1v1 rhythm completion
- [ ] Polish school/arcade blockout only where it improves readability

## Out Of Scope (V0)

PE, music room, cleaning duty, full schedule, dorms, multiple classrooms, clubs, city bus, complex NPC relationship trees.
