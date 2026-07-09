# Second Slice Plan - Snack Hand-off Pipeline

## Recommendation

Build the generic hand-off pipeline with **snack sharing** as the first playable skin.

This proves a small real-time social moment before the arcade slice: one player offers a snack, the other accepts or declines, both get feedback, and a temporary placeholder snack appears in-world.

## Scope

Status target: Prototype

In scope:

- snack hand-off only
- server-authoritative offer/accept/decline/cancel/expire flow
- distance and cooldown validation
- one outgoing pending offer per sender
- one incoming pending offer per recipient
- placeholder snack catalog
- basic UI for choosing a nearby player and snack
- temporary placeholder snack visual after accept

Out of scope:

- inventory
- economy or currency
- persistence
- notes/charm/ticket variants
- friend checks
- final snack models/icons/animations/sounds
- arcade rewards

## Player Experience

1. Player A stands near Player B.
2. Player A opens `Share Snack`.
3. Player A chooses Player B and a snack.
4. Player B receives an incoming offer modal.
5. Player B accepts or declines.
6. Both players receive clear feedback.
7. On accept, a simple placeholder snack appears briefly on the recipient.

## Asset Dependency Rule

Cursor should use placeholders only:

- colored Parts for snacks
- basic UI buttons and labels
- no final icons, models, sounds, or animations

If the slice needs final snack models, snack icons, eating animations, sound effects, or custom UI art, stop and tell the user exactly what is needed.

## Acceptance Criteria

- A player can offer one of three prototype snacks to a nearby online player.
- The target sees an incoming offer with Accept and Decline.
- Accept, decline, cancel, expiry, invalid target, invalid item, duplicate pending offers, and distance failures are handled server-side.
- Walking out of range before accepting causes accept to fail.
- Player leaving clears their pending incoming/outgoing offers.
- Accepted hand-offs show a temporary placeholder snack visual.
- No profile data changes.
- Roadmap/docs list the slice as prototype and document known limits.

## Studio Checklist

Use Studio/MCP where possible. If not fully verified, leave this checklist for the user:

- Confirm two local players can stand in the school area near the locker hallway.
- Confirm `Share Snack` appears in Play mode.
- Player A can offer `Rice Cracker`, `Melon Bread`, and `Strawberry Milk`.
- Player B receives the incoming offer modal.
- Accept path gives both players feedback.
- Decline path gives both players feedback.
- Offer expires after waiting.
- Player A cannot send multiple pending offers.
- Player B cannot receive multiple pending offers at the same time.
- Moving out of range before accepting fails safely.
- Temporary snack visual appears and then cleans up.
- No data/profile changes are expected from this slice.

## Known Prototype Limits

- Snacks are infinite social placeholders.
- Nearby-player selection is a basic UI list, not final interaction design.
- Visuals are client-side placeholders.
- No friend-tier restrictions yet.
- No inventory, rewards, or persistence yet.
