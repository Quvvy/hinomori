# Game Design Document - Hinomori

## North Star

Hinomori is a peaceful rural Japanese student-life roleplay game for teens on Roblox.

> I wish I lived in this town.

The player should feel that they belong somewhere, that other players matter, and that another ordinary day may hold a small new memory. The game is not a full school simulator and not a generic cozy farming or tycoon game.

## Fantasy

The player is a student in a compact rural town. School gives their identity a place; after school gives them reasons to gather. Expression comes from selected details and accumulated memories rather than randomized body traits or conspicuous wealth.

The desired emotional stack is:

1. **Atmosphere:** a readable town, seasons, weather, familiar routes, and restrained diegetic UI.
2. **Identity:** student name, locker, stationery, charms, photos, stickers, and later curated clothing choices.
3. **Connection:** safe prompts to notice, approach, help, challenge, or make plans with another player.
4. **Memory:** ordinary activities leave small visible traces that make the next visit feel continuous.

## Audience And Tone

- Teen Roblox players who enjoy roleplay, customization, music, and social hangouts.
- Calm and sincere rather than childish, chaotic, or aggressively competitive.
- Rural Japanese setting treated as a place with ordinary routines, not a collection of decorative stereotypes.
- Inspired by quiet student-life media, but not a clone of Gakuran or another specific Roblox game.

## Current V0 Hypothesis

> Do players care about their student, their locker, their notes, and being seen by other players?

The prototype loop is:

1. Arrive and write a student name on the homeroom card.
2. Find and recognize a persistent locker.
3. Add a small locker decoration.
4. Send or receive a safe note.
5. Share a snack with another nearby student.
6. Move into after school.
7. Play or watch at the arcade, or practice in the garage.
8. Return to identity/social space with a reason to remember the day.

The final memory callback is still incomplete. It should eventually be a visible item such as a sticker or photo strip rather than an abstract currency-only reward.

## Social Centers

### Locker Hallway

The locker hallway is the identity and planning center. It supports persistent decor, notes, and recognition. Lockers should become richer through things players did elsewhere in town.

### Arcade

The arcade is a competitive social stage: **"watch me beat you."** Queue, participants, spectators, rhythm results, and cabinet readability matter as much as the minigame itself.

### Garage

The garage is a cooperative hangout: **"let's sound good together."** Practice is framed through a rehearsal board and shared instrument occupancy. The prototype skill charts are optional and must not turn the garage into a shaming or progression-heavy competition.

## Town Direction

Hinomori should become a **compact open town**. Players should usually choose where to go, while soft world rhythms make some places feel timely. Avoid both a giant empty seamless map and a menu of disconnected teleports.

The first active route should connect school, a small shopping street, the arcade, and the garage. River, shrine, bus stop, and conbini can become edge landmarks after the core route works. Crossing the active core should initially target roughly 60-90 seconds and be adjusted from playtests.

Use time, weather, board notices, lighting, sound, and local events to concentrate players without enforcing a class-by-class schedule.

## Identity And Objects

- Locker identity is persistent.
- Desks and chairs are atmosphere props, not assigned player identity.
- Backpack and keychain expression may use desk/bag hooks in a future dedicated slice.
- Small objects should carry social or memory value before they become inventory volume.
- Prefer curated selection and earned/remembered provenance over rarity ladders.

## UI Direction

The UI spine is **Phone + Paper + World Surface**:

- tiny HUD for time/day/location-level context
- phone for social and utility tools
- paper/cards for school identity, notes, guidance, and results
- world/device surfaces for lockers, boards, counters, and arcade cabinets

Do not default to large generic panels, permanent quest trackers, reroll screens, or monetization framing. See `docs/UI_DIEGETIC_DIRECTION.md`.

## Social Safety

- Stranger notes use approved templates/stickers only.
- Roblox friends may use short free text only after server friendship checks and Roblox text filtering.
- State-changing social actions are server-authoritative and distance/cooldown validated.
- Owners need controls to clear, disable, and block unwanted note interactions.
- Do not add open stranger free text, unfiltered display, or invented reporting behavior.
- Offline social delivery requires an explicit persistence, moderation, expiry, and cleanup design.

## Monetization Guardrails

V0 has no monetization UI. Future monetization may support chosen expression after players already care about the underlying ritual.

Acceptable future directions may include selected cosmetic details, stationery, charms, locker presentation, or original music-related expression. Do not monetize random identity traits, pain relief, social exclusion, or schedule pressure.

## Anti-Patterns

- full school timetable before the social loop is fun
- enormous map that disperses a small server
- Animal Crossing, Stardew, or generic cozy-sim imitation
- chaotic flex-avatar hangout with no place identity
- paid body/face rerolls or gacha identity
- mandatory chores, anxious streaks, or FOMO event pressure
- deep economy, jobs, clubs, dorms, or NPC trees before town rituals are proven
- free-text stranger communication
- treating placeholder/commercial prototype content as release-ready

## Content And Rights

Teenage Dirtbag, Flamewall, and other commercial music currently used for testing are prototype content only unless the appropriate release rights are secured. Release content should use original, commissioned, or properly licensed music with documented ownership of audio, stems, and charts.

## Source Of Truth

This repository is the collaborator-facing design source. `docs/CURRENT_STATE.md` records what exists; `docs/ROADMAP.md` records what comes next. The owner's private llm-wiki may preserve research provenance, but collaborators do not need it to work safely.
