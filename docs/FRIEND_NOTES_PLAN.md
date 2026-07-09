# Friend Notes Plan — Phase 8

## Status

Prototype. Roblox friends can leave short filtered free-text notes on a locker; strangers remain template-only.

## Goal

Add the friend tier from the template-note system: filtered personal text for friends, separate from stranger template notes.

## In Scope

- `friendNotes` profile array (filtered text, sender, day key)
- Server `sendFriendNote` with `IsFriendsWith`, proximity, rate limits, `TextService` filter
- Locker UI: friend notes section (owner), text input + send (visitor friend)
- Block and clear apply to both stranger and friend notes

## Out of Scope

- Open-text stranger notes
- Offline locker delivery (owner must be online)
- Report / unblock UI
- Friend note auto-decay

## Product Rules

| Rule | Value |
|------|-------|
| Friendship | `player:IsFriendsWith(ownerUserId)` on server |
| Max raw length | 120 characters |
| Rate limit | 2 friend notes per sender per locker per day |
| Max visible | 10 friend notes |
| Stranger toggle | Does not block friend notes |
| Block list | Applies to both tiers |

## Acceptance Criteria

- Friends can send filtered text; owner sees it under Friend notes
- Non-friends do not see the friend text field
- Stranger template flow unchanged for non-friends
- Block removes friend + stranger notes from sender
- Clear notes empties both sections
- Structured toasts for all friend send failures
- `stylua src`, `selene src`, `rojo build` pass

## Studio Checklist (Two Players, Must Be Roblox Friends)

1. B opens A's locker → friend text field visible; stranger template picker still works.
2. B sends a short message → A sees it under Friend notes with B's display name.
3. Non-friend C opens A's locker → no friend text field.
4. A blocks B from a friend note slip → note gone; B cannot send stranger or friend notes.
5. A clears notes → both Friend and Stranger sections empty.
6. B sends 3 friend notes same day → third fails with daily limit toast.

## Verification

```powershell
stylua src
selene src
rojo build default.project.json -o build\friend-notes.rbxl
```
