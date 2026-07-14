# Social Systems

Status: Prototype.

Hinomori's social systems create small reasons to approach another player while keeping stranger communication constrained and server-authoritative.

## Lockers

Each player receives an available discovered locker. The saved `assignedLockerId` is preferred when valid and free; a missing or unavailable saved locker falls back to another discovered locker for the active session.

Owners can configure decor and note settings. Visitors can inspect permitted state and send allowed notes. Locker state is never inferred from client UI or model name.

## Stranger Notes

Strangers select from `NoteTemplates`; they cannot submit arbitrary text. The server validates:

- template ID
- sender/owner relationship and alive state
- locker existence and owner assignment
- sender distance to the locker
- owner settings and blocked senders
- per-day/rate limits and visible capacity

Owners can disable stranger notes, clear notes, and block a visible sender. Display names are resolved for presentation, but UserId remains the identity key.

## Friend Notes

Short free text is restricted to Roblox friends. The server verifies friendship and filters text through Roblox TextService before storing or displaying it. Strangers continue to use templates.

Current friend notes are a narrow online prototype. Do not generalize them into offline messaging, arbitrary contacts, or a private chat system without a moderation/persistence design.

## Hand-Offs

`HandOffCatalog` currently defines three placeholder snacks. The server owns a short-lived offer lifecycle:

```text
offer -> accept | decline | cancel | expire | invalidate by distance/removal
```

Both players must remain valid and nearby. Accepting shows temporary client-side item presentation; it does not create persistent inventory or consume a quantity.

Future charms, tickets, photos, or gifts may reuse the offer/accept/decline interaction pattern, but persistent ownership and item outcomes require a separate item model rather than silently extending snack placeholders.

## Safety And Persistence Boundaries

- No stranger free text.
- No unfiltered text.
- No trust in client-selected targets, item IDs, locker IDs, or success claims.
- No offline locker delivery until expiry, capacity, moderation, cleanup, and cross-server behavior are designed.
- Blocking exists; do not invent a reporting backend or promise Roblox moderation integration without implementing it.
- Social profile arrays should remain bounded and owner-controlled.

## Extension Rules

Any new social object must define:

- who may initiate and receive it
- server distance, cooldown, relationship, ownership, and catalog validation
- whether it is transient or persistent
- filtering/moderation behavior
- accept/decline/cancel/expiry behavior
- owner clear/block controls where applicable
- cleanup on death, disconnect, timeout, and UI close
- one-player failure and two-player success tests

See `TESTING.md` for the current notes and hand-off regression paths.
