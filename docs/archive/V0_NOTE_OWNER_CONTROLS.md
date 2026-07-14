# V0 Note Owner Controls

## Summary

Adds safe owner controls for locker stranger notes:

- enable/disable stranger notes
- clear all stranger notes
- block a sender, which also removes that sender's visible notes

This hardens the existing template-note prototype without adding friend free-text or offline delivery.

## Scope

In scope:

- owner-only controls from the locker menu
- server-authoritative state changes
- sender block list in profile data
- send rejection when the target locker owner has blocked the sender

Out of scope:

- friend free-text notes
- offline note delivery
- external report/moderation pipeline
- anonymous notes
- group notes

## Acceptance Criteria

- Locker owners can toggle stranger notes on/off.
- Locker owners can clear visible stranger notes.
- Locker owners can block the sender of a visible note.
- Blocked senders cannot leave new stranger notes.
- Non-owners cannot use owner controls.
- No open-text stranger communication is introduced.

## Studio Checklist

- Open own locker and confirm note controls appear.
- Toggle stranger notes off.
- In two-player test, confirm another player cannot leave a note while disabled.
- Toggle stranger notes on.
- Have another player leave a template note.
- Confirm the owner can clear all notes.
- Have another player leave a new note, then block sender.
- Confirm that sender's notes disappear and future notes from that sender fail.

## Known Limits

- Blocking uses user ids and is profile-persistent.
- There is no unblock UI yet.
- Reporting is not implemented; this avoids inventing moderation behavior before the product decision is made.
