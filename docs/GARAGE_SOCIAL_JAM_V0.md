# Garage Social Jam V0

Status: Prototype.

Garage Social Jam V0 is a small shared stem-station toy. It is not a second rhythm game, does not score players, and does not add persistence, rewards, economy, or band identity.

## Studio World

- `Workspace.World.Garage.GarageJam_001`
- `DrumsStation`
- `BassStation`
- `GuitarStation`
- `VoiceStation`

Each station has a `PromptPart` and `ProximityPrompt`. The prompt text changes from `Join` to `Leave` while the local player is playing that station.
Each station also has a `PlayerAnchor` used to place and temporarily hold the player behind the instrument while they are occupying it.

Players must check the `RehearsalBoard` and choose `Practice` before instrument prompts become usable.

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

- Occupancy is server-authoritative and session-only.
- One player can occupy one instrument at a time.
- One station can have one occupant at a time.
- Stem playback is still local on each client, but active stems align to the server-owned `jamStartedAtServerTime`.
- If a Sound's `TimeLength` is not available, the client warns once and defers clock alignment until it can align.
- No full mix usage.
- No charting, scoring, instrument progression, band naming, or rewards.

## Studio Checklist

- Enter Play and confirm normal Hinomori startup logs still appear.
- Confirm main UI, phone/snack UI, locker UI, arcade menu, and existing rhythm Solo still work.
- Walk to `GarageJam_001`.
- Check the `RehearsalBoard` and choose Practice; confirm instrument prompts unlock.
- Join Drums and confirm only the drums stem plays and the prompt says Peter Brown.
- Confirm the character is placed at `DrumsStation.PlayerAnchor` and movement is locked.
- Leave Drums and confirm the drums stem stops.
- Confirm movement is restored.
- Join Bass, Guitar, and Voice one at a time and confirm each maps to its own stem.
- In a two-player Studio test, confirm two players cannot occupy the same station.
- In a two-player Studio test, confirm different occupied stations layer using the shared jam clock.
- Confirm `Workspace.Wheatus-Teenage Dirtbag-full-mix-05-29-2026` remains stopped.
