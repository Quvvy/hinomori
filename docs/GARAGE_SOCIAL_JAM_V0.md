# Garage Social Jam V0

Status: Prototype.

See `STUDIO_WORLD.md` for physical object contracts, `RHYTHM_SYSTEM.md` for chart/runtime isolation, and `TESTING.md` for the complete regression path.

Garage Social Jam V0 is a small shared stem-station toy. It now has an optional prototype skill layer that reuses the existing four-key rhythm runner for local practice parts. It does not add persistence, rewards, economy, progression, or band identity.

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

## Skill Layer Prototype

After choosing Practice and joining a station, the local player sees a small `Play Part` slip for that station. `Play Part` starts a full-song static Teenage Dirtbag practice chart for the occupied instrument only.

The charts are static Luau modules authored from offline MIDI reference. The Roblox runtime does not parse MIDI or auto-chart.

| Station | Chart | Notes |
| --- | --- | --- |
| Drums | `teenage_dirtbag_drums_practice` | 720 notes, hard kick/snare/hat/crash chart |
| Bass | `teenage_dirtbag_bass_practice` | 320 notes, medium/hard groove chart |
| Guitar | `teenage_dirtbag_guitar_practice` | 740 notes, hard riff/strum chart |
| Voice | `teenage_dirtbag_voice_practice` | 270 notes, medium phrase-and-hold chart |

Garage practice charts live in `GarageSkillCatalog`, separate from the arcade `RhythmSongCatalog`, and should not appear in the arcade song list.

## Current Limits

- Occupancy is server-authoritative and session-only.
- One player can occupy one instrument at a time.
- One station can have one occupant at a time.
- Stem playback is still local on each client, but active stems align to the server-owned `jamStartedAtServerTime`.
- If a Sound's `TimeLength` is not available, the client warns once and defers clock alignment until it can align.
- Garage skill runs are local-only and opt-in after occupying a station.
- Miss feedback is currently placeholder audio ducking: missed notes briefly lower the local rhythm playback volume, then restore it.
- Teenage Dirtbag is prototype content unless music rights are secured.
- Garage skill implementation is part of the current working tree and must be committed before a Git collaborator can clone it.
- No full mix usage.
- No instrument progression, band naming, persistence, economy, monetization, or rewards.

## Studio Checklist

- Enter Play and confirm normal Hinomori startup logs still appear.
- Confirm main UI, phone/snack UI, locker UI, arcade menu, and existing rhythm Solo still work.
- Walk to `GarageJam_001`.
- Check the `RehearsalBoard` and choose Practice; confirm instrument prompts unlock.
- Join Drums and confirm only the drums stem plays.
- Confirm the character is placed at `DrumsStation.PlayerAnchor` and movement is locked.
- Leave Drums and confirm the drums stem stops.
- Confirm movement is restored.
- Join Bass, Guitar, and Voice one at a time and confirm each maps to its own stem.
- While occupying each station, confirm `Play Part` appears and starts only that station's practice chart.
- Confirm misses briefly duck the local rhythm playback volume and the next successful hit restores it.
- Confirm leaving, respawning, or losing station occupancy stops the skill run and restores audio.
- In a two-player Studio test, confirm two players cannot occupy the same station.
- In a two-player Studio test, confirm different occupied stations layer using the shared jam clock.
- Confirm `Workspace.Wheatus-Teenage Dirtbag-full-mix-05-29-2026` remains stopped.
