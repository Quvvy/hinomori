# Rhythm System

Status: Prototype.

Hinomori uses one four-lane `D/F/J/K` rhythm runner for arcade matches and optional garage skill practice. The shared engine is presentation/input code; arcade and garage keep separate catalogs and gameplay ownership.

## Static Map Format

Maps are text chunks parsed by `RhythmMapParser`:

```text
title=Example
artist=Example Artist
difficulty=Medium
lanes=4
audioStartMs=0

1000,1
1500,2,600
2200,4
```

Each note row is `timeMs,lane,holdMs`. `holdMs` is optional. Lanes are 1-4 and map to D/F/J/K. Times must be non-negative and sorted for authoring clarity.

MIDI, Guitar Pro, or MusicXML may be offline authoring references only. Do not add a runtime MIDI parser or auto-chart pipeline without a separate approved milestone.

## Judgment And Holds

Current target windows:

| Judgment | Window |
| --- | --- |
| Perfect | 60 ms |
| Great | 115 ms |
| Good | 180 ms |
| Miss | 230 ms |

A hold head is judged inside the normal window. Releasing too early misses and breaks combo. Holding through the end completes one chart-row judgment. Existing server result compatibility treats each row as one note.

Avoid accidental same-timestamp chord walls. The V0 runner was not designed around a new simultaneous-chord mechanic; authored charts should stagger intended accents when needed.

## Arcade Path

`RhythmSongCatalog` owns arcade songs and summaries. ArcadeService owns queue, match lifecycle, result submission, sanitization, and rewards. Existing arcade calls use `RhythmGame.start(match, song, onFinish)` without garage options.

Current catalog entries include placeholder/commercial test material. `CamelliaFlamewallTest` is a switching/density test, not release content.

## Garage Path

`GarageSkillCatalog` owns one chart per station and does not feed the arcade menu. A chart uses `stationId` and `soundKey`; GarageJamServiceClient resolves the matching Workspace stem through `GarageJamConfig`.

Current full-song Teenage Dirtbag charts:

| Instrument | Difficulty | Notes | Holds |
| --- | --- | --- | --- |
| Drums | Hard | 720 | 26 |
| Bass | Medium/Hard | 320 | 17 |
| Guitar | Hard | 740 | 13 |
| Voice | Medium | 270 | 85 |

The maps are static Luau modules authored from offline MIDI references. Garage charts are local opt-in practice after server-owned station occupancy. They do not submit arcade results or grant progression/rewards.

Garage-only optional rhythm options provide replaceable miss audio feedback. Current behavior lowers the active playback volume briefly, restores on the next successful hit/hold completion, and uses one idempotent cleanup path. Existing arcade calls pass no options and retain their previous behavior.

## Isolation Rules

- Garage charts never appear in `RhythmSongCatalog` or the arcade menu.
- Garage options default to nil/no-op for old callers.
- Do not change ArcadeService APIs, queue, scoring submission, or rewards to support garage practice.
- Never use the Teenage Dirtbag full mix for station playback or garage skill.
- Do not stop/restart a stem on miss; temporary volume feedback preserves timing.
- A new rhythm mechanic such as true chords requires its own engine-quality slice and regression pass.

## Authoring Quality

A chart is incomplete if it only parses. Human playtesting must confirm:

- notes follow the intended musical part
- intro rest is intentional
- density is readable at target difficulty
- holds match sustained material
- no accidental chord walls or tiny unreadable gaps
- ending occurs before audio completion
- result text matches the instrument/context

Commercial music and derived charts are prototype-only unless rights are secured.

See `TESTING.md` for arcade and garage regression checks.
