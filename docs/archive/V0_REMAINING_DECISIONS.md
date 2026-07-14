# V0 Remaining Decisions

The current V0 prototype slice chain is implemented with placeholders. These roadmap items remain intentionally unbuilt because they need product, moderation, persistence, or validation decisions before implementation.

## Needs Approval Before Building

- **Offline locker note delivery**: requires persistence semantics for social messages and cleanup/decay behavior across servers.
- **Note/charm/ticket hand-off skins**: requires deciding whether the snack hand-off loop is good enough to generalize, plus item-specific outcomes.
- **Unblock/report flows**: block exists; reporting was not added because external moderation behavior should not be invented silently.

## Implemented (Phase 8)

- **Friend-tier free-text notes**: Roblox friends only, `TextService` filtered, separate `friendNotes` profile array, locker UI split by tier. See `docs/FRIEND_NOTES_PLAN.md`.

## Current Prototype Spine

- Locker identity and decor
- Template stranger notes with rate limits and owner controls
- Friend filtered free-text notes (online owner required)
- Snack hand-off pipeline
- Arcade social stage with rhythm gameplay
- Session phase flow without assigned desks
- Placeholder Studio world folders for School, Town, Arcade, classroom desks, lockers, and arcade cabinet pair
