# Rhythm First Pass - Arcade Mania Prototype

## Status

Prototype. This replaces the arcade's pure score stub with a first playable four-lane rhythm loop while keeping server-owned queue, match state, and ticket rewards.

## What Exists

- Song select in the arcade cabinet menu.
- Four-lane client rhythm runner using `D`, `F`, `J`, `K`.
- Text chunk chart parser for simple map authoring.
- Placeholder songs using the Studio `Workspace.Life in an Elevator` Sound when present, with `rbxassetid://1841647093` as fallback.
- Solo and 1v1 match start paths carry a selected song id.
- Client-side timing feedback for responsiveness.
- Server-side result sanitization, fixed ticket rewards, active-match cleanup, and timeout fallback.
- Placeholder cabinet polish in Studio: clearer screens, pad labels, neon trim, and `Play rhythm` prompt.

## Map Format

Maps live as one ModuleScript per chart in `src/modules/Game/RhythmSongs/`.
`src/modules/Game/RhythmSongCatalog.luau` is only the lightweight index that requires those map modules.

Current examples:

- `LifeInAnElevatorEasy.luau`
- `LifeInAnElevatorMedium.luau`
- `CamelliaFlamewallTest.luau`

Metadata uses `key=value` lines:

```text
title=Life in an Elevator
artist=Roblox placeholder
difficulty=Easy
keys=4
offsetMs=0
audio=workspace:Life in an Elevator
```

Notes start under `[notes]`. Each note is:

```text
timeMs,lane
```

Optional hold length is accepted but not visually implemented yet:

```text
timeMs,lane,holdMs
```

Lanes are numbered `1` through `4`, mapped to `D`, `F`, `J`, `K`.

## Verified

- `stylua src` passed.
- `selene src` passed with 0 warnings.
- `rojo build default.project.json -o build\rhythm-first-pass.rbxl` passed.
- Studio Edit mode sees `RhythmMapParser`, `RhythmScoring`, `RhythmSongCatalog`, and `RhythmGame`.
- Studio Play startup completed for server and client.
- Live Networker state fetch returned two songs.
- Cabinet menu rendered song select, queue/watch, Solo, and 1v1 controls.
- Rhythm UI rendered the placeholder song, note count, score line, and `D/F/J/K` lanes.
- Live smoke test: join queue -> start Solo -> rhythm UI appears -> submit result -> active match clears.

## Follow-up Polish Pass - 2026-07-06

- Added `src/ui/UiStyle.luau` so prototype screens share the same quiet ink/paper/accent palette.
- Restyled arcade, rhythm, locker, snack hand-off, transfer student, and session panels toward one UI direction.
- Collapsed the day/desk test controls behind a small `Tools` toggle so the normal view is less debug-like.
- Added `offsetMs` map metadata support for future chart editor/audio calibration.
- Added `RhythmSongCatalog.validateAll()` and verified the current placeholder charts produce no warnings.
- Removed visible arcade stub wording from the cabinet menu.
- Studio placeholder polish: locker handles/nameplates/vents, locker hall sign/floor runner, classroom board, desk notebooks/pencils, and floor mat.
- `stylua src`, `selene src`, and `rojo build default.project.json -o build\rhythm-polish-pass.rbxl` passed.
- Studio Play smoke test passed again after polish: live queue -> Solo start -> rhythm UI appears -> result submit -> active match clears.

## Follow-up Map Split - 2026-07-06

- Split chart data out of `RhythmSongCatalog.luau`.
- Each chart is now its own ModuleScript under `src/modules/Game/RhythmSongs/`.
- Added `CamelliaFlamewallTest.luau` using `Workspace.camellia - flamewall` / `rbxassetid://81654436561725`.
- The Flamewall map is a placeholder test chart for song switching and density checks, not a final authored chart.

## Known Prototype Limits

- Manual keypress feel still needs human testing; MCP cannot press gameplay keys with the same fidelity as a player.
- 1v1 was wired and protected by timeout, but only the Solo path was smoke-tested in Studio MCP.
- Hold notes are parsed but treated as tap notes for now.
- The chart is placeholder timing against placeholder audio, not a real authored chart.
- Result validation caps/sanitizes submitted judgments and server-awards fixed tickets, but full anti-cheat timing replay is not built.
- Studio placeholder polish exists in the open place; save the place after reviewing if you want to keep those model changes.

## Studio Checklist

- Reconnect Rojo if needed and restart Play.
- Confirm the arcade cabinet prompt says `Play rhythm`.
- Stand near the cabinet and press `E`.
- Confirm the cabinet menu shows two `Life in an Elevator` difficulties.
- Join queue, select Easy, and start Solo.
- Confirm the rhythm UI opens and the audio starts.
- Press `D`, `F`, `J`, `K` on incoming notes and judge whether the hit timing feels responsive.
- Let the song finish and confirm a result toast appears.
- Confirm tickets increase after a completed run.
- Try Medium and confirm note density changes.
- In a two-player local server, queue two players and start `1v1`.
