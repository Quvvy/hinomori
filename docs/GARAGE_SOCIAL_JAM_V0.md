# Garage Social Jam V0

Status: Prototype.

Garage Social Jam V0 is a small local stem-station toy. It is not a second rhythm game, does not score players, and does not add persistence, rewards, economy, band identity, or multiplayer sync.

## Studio World

- `Workspace.World.Garage.GarageJam_001`
- `DrumsStation`
- `BassStation`
- `GuitarStation`
- `VoiceStation`

Each station has a `PromptPart` and `ProximityPrompt`. The prompt text changes from `Join` to `Leave` while the local player is playing that station.

## Stem Mapping

The full mix is intentionally unused.

| Station | Workspace Sound |
| --- | --- |
| Drums | `Workspace.Wheatus-Teenage Dirtbag-drums-05-29-2026` |
| Bass | `Workspace.Wheatus-Teenage Dirtbag-bass-05-29-2026` |
| Guitar | `Workspace.Wheatus-Teenage Dirtbag-guitar-05-29-2026` |
| Voice | `Workspace.Wheatus-Teenage Dirtbag-voice-05-29-2026` |

Drums are credited as Peter Brown in the station label and prompt feedback.

## Current Limits

- Stem playback is client-local.
- Multiple local stems can layer and align to the first active local stem.
- Multiplayer/shared synchronized jam occupancy is deferred.
- No full mix usage.
- No charting, scoring, instrument progression, band naming, or rewards.

## Studio Checklist

- Enter Play and confirm normal Hinomori startup logs still appear.
- Confirm main UI, phone/snack UI, locker UI, arcade menu, and existing rhythm Solo still work.
- Walk to `GarageJam_001`.
- Join Drums and confirm only the drums stem plays and the prompt says Peter Brown.
- Leave Drums and confirm the drums stem stops.
- Join Bass, Guitar, and Voice one at a time and confirm each maps to its own stem.
- Join multiple stations locally and confirm stems layer.
- Confirm `Workspace.Wheatus-Teenage Dirtbag-full-mix-05-29-2026` remains stopped.
