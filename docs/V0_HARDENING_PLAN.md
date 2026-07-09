# V0 Hardening Plan — Phase 7

## Status

Prototype hardening pass. Validates the full V0 social loop with structured two-player QA, fixes prototype friction in notes/hand-off/arcade flows, and documents targeted Studio blockout polish.

## Goal

Prove Solo + 1v1 arcade, two-player notes, and snack hand-off work end-to-end. Patch highest-friction UX gaps without opening Phase 2 friend-text or offline delivery.

## In Scope

- Structured send result + proximity check for stranger notes
- User-facing toasts for note send success/failure
- All stranger templates selectable from locker menu
- Display names on note slips (not raw user ids)
- Per-note block affordance for locker owners
- Cancel outgoing snack hand-off offer
- Leave arcade spectator list from cabinet menu
- Studio blockout readability checklist (user applies in Studio)

## Out of Scope

- Friend-tier free-text notes
- Offline locker note delivery
- Note decay job, unblock/report UI
- Scroll-speed persistence, mobile rhythm controls
- Spectate camera, stub-match cleanup

## Acceptance Criteria

- Failed note sends show a clear toast reason (not silent failure)
- All 5 stranger templates selectable; notes show display names
- Owners can block any visible note sender from that note slip
- Senders can cancel a pending outgoing snack offer
- Spectators can leave the watch list from the arcade menu
- `stylua src`, `selene src`, and `rojo build` pass

---

## QA Checklist A — Two-Player Notes + Snack

Use a local two-player Studio server.

**Locker notes**

1. Player A owns a locker; Player B opens it from the hallway prompt.
2. B picks a template from the picker and sends → A sees the note with B's display name.
3. A toggles **Close notes** → B cannot send (toast explains why).
4. A toggles **Open notes** → B can send again.
5. A uses **Clear notes** → all visible notes removed.
6. B leaves a note; A taps **Block** on that note slip → note disappears; B cannot send again.
7. B tries a second note same day → toast shows daily limit message.
8. B walks away from locker and tries to send → toast shows too far.

**Snack hand-off**

1. A opens phone, picks nearby B and a snack, sends offer.
2. B sees incoming offer; **Accept** → placeholder snack appears on B; both get toasts.
3. Repeat; B **Declines** → both get feedback.
4. A sends offer, walks away, B accepts → server rejects (too far).
5. A sends offer, taps **Cancel offer** before B responds → offer cleared.
6. Let offer expire (~15s) without response → sender gets expiry toast.

---

## QA Checklist B — Arcade Solo

1. Stand at cabinet; prompt says **Play rhythm**.
2. Join queue, select Easy, start **Solo** from queue front.
3. Rhythm UI opens; audio plays; scroll speed label shows default **2.5x**.
4. Tap notes register judgments; hold notes render taller and require holding the key.
5. Adjust scroll **+** / **-**; approach speed changes.
6. Finish song → result toast → active match clears → tickets increase by 1.

Repeat with **Medium** to confirm hold density.

---

## QA Checklist C — Arcade 1v1

Local two-player server required.

1. Both players join queue; front two start **1v1** with selected song.
2. Both get rhythm UI; each plays and finishes.
3. Result toast shows both scores; match clears; tickets +2 each.
4. One player disconnects mid-match → other gets cancel feedback.

---

## Studio Blockout Checklist

Apply in Studio under `Workspace.World` and **save the place**. Tweak only where playtest shows confusion.

| Area | Path | Readability targets |
|------|------|---------------------|
| Arcade | `World.Arcade.CabinetPair_001` | Prompt reads **Play rhythm**; D/F/J/K pad labels visible; spacing for two queued players |
| Locker hall | `World.School.LockerHallway` | Sign/runner/nameplates guide players to lockers |
| Classroom | `World.School.Classroom` | Board + desk props don't block movement |

Prior polish examples: neon trim, hall sign, floor runner (`docs/RHYTHM_FIRST_PASS.md`).

---

## Verification

```powershell
stylua src
selene src
rojo build default.project.json -o build\v0-hardening.rbxl
```

Run all three QA checklists in Studio Play. Log blockers and fix in-loop.
