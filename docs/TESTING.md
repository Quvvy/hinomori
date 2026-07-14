# Testing And Regression Guide

Use this guide after every slice. A feature is not complete because it builds; Studio behavior and neighboring systems must remain usable.

## Automated Checks

From the repository root:

```powershell
stylua --check src
selene src
rojo build default.project.json -o build\verification.rbxl
```

Use `stylua src` only when intentionally formatting source. A Rojo build validates the repository tree; it does not validate the authoritative Team Create geometry.

## Startup Baseline

In the shared place with Rojo connected:

- Start one-player Play.
- Confirm `[Hinomori] Server startup complete`.
- Confirm `[Hinomori] Client startup complete`.
- Confirm the small HUD appears.
- Inspect Output for service require/Init/Start failures.
- Treat expected Studio profile/API warnings separately from real service failures.

If startup or core UI is already broken, stop and report the baseline before adding a feature.

## One-Player Baseline

### Student And Session

- A fresh mock profile sees the name-only homeroom card.
- Completing it removes the prompt and updates first-day guidance.
- HUD uses player-facing phase/location language, not internal loading labels or desk assignment.
- Phase controls can reach School and After School without errors.

### Locker And Notes

- Open the assigned locker and a visitor locker.
- Apply and remove decor; world visuals follow server state.
- Send a template note from a visitor context and see success/failure feedback.
- Owner can open/close stranger notes, clear notes, and block a visible sender where applicable.
- Walking out of range causes server rejection instead of a silent or client-only success.

### Hand-Off Phone

- Open the phone/snack surface without covering core HUD unexpectedly.
- Sending with no nearby target fails gracefully.
- Pending outgoing offer can be cancelled.
- Offer expiry clears UI/state and reports feedback.

### Arcade

- Cabinet prompt opens the menu.
- Join/leave queue and spectator list.
- Select each arcade catalog song without garage charts appearing.
- Start Solo and confirm audio, D/F/J/K lanes, tap notes, holds, judgments, combo, and scroll-speed control.
- Finish or time out; active match clears and result/reward state updates once.

### Garage

- Instrument prompts are unusable before choosing Practice at the rehearsal board.
- Practice closes the board, confirms `Doors are open.`, and enables available stations.
- Join each station individually; player moves to its anchor and cannot walk/jump away.
- Leave restores movement and frees the station.
- `Play Part` starts only the occupied station's chart/stem.
- A miss briefly ducks volume; the next hit or cleanup restores it.
- Closing, leaving, respawning, or losing occupancy stops the skill run and restores audio/movement/UI.
- Full mix remains stopped.

## Two-Player Baseline

Use **Test -> Start** with one server and two clients. Friend-note tests require accounts that Roblox reports as friends.

### Notes

- Player B opens Player A's locker and sends one approved stranger template.
- A sees B's display name; daily limit, closed notes, block, and distance failures produce clear results.
- Friend free text is filtered before display and rejected for non-friends.
- Clearing/blocking affects the authoritative locker state for both clients.

### Hand-Off

- A offers a snack to nearby B; B accepts and both receive feedback.
- Repeat with decline.
- A sends then cancels before response.
- Move players apart before accept; server rejects and clears safely.
- Let an offer expire; neither client remains stuck in a pending state.

### Arcade

- Both join the same queue and start 1v1 from the valid queue position.
- Both receive the same match/song and can submit results.
- Match clears after both results or timeout; rewards occur once.
- Disconnect/reset one participant and confirm the other receives cancellation/cleanup feedback.

### Garage

- Both choose Practice.
- Two players cannot occupy the same station.
- One player cannot occupy two stations.
- Different occupied stations layer for both clients.
- A later station join aligns to the existing `jamStartedAtServerTime`, not 0:00.
- Leaving one station stops only its stem; leaving all stations resets the jam clock.
- Reset/disconnect frees occupancy and restores remaining clients' prompt state.

## Viewport And Input Checks

Test at one desktop and one mobile-ish viewport:

- paper/phone/world panels fit without clipped controls
- toast slips and first-day guidance do not overlap critical menus
- locker note rows remain readable with longest current text
- arcade/garage result text does not cover lane input
- ProximityPrompt interaction remains understandable on touch/gamepad

The current four-key rhythm game is keyboard-first. Do not claim mobile rhythm support until an explicit input slice implements and tests it.

## Missing-Object Resilience

In a disposable Studio copy or by temporarily moving one object at a time:

- missing locker candidate is skipped
- missing arcade prompt disables arcade only
- missing rehearsal board disables Practice only
- missing one garage station/prompt/anchor/Sound disables that path only
- startup HUD and unrelated features still mount
- each missing requirement warns once rather than spamming Output

Restore all objects before saving/publishing.

## Reporting Format

Every implementation handoff should state:

- automated commands and results
- Studio checks actually run
- two-player checks actually run
- checks MCP/automation could not perform
- remaining owner checklist
- assets or permissions still required

Never mark a human keyfeel, visual overlap, multi-client, or Team Create save check as passed when it was only inferred from code.
