# ROADMAP - Hinomori

## Product Thesis

Hinomori is a peaceful rural Japanese student roleplay game for Roblox. The core loop is not a strict school schedule. It is a shared student-life home base that gives players identity, social prompts, small objects to exchange, and after-school reasons to gather.

Current design thesis:

> School is where your student life has a place. After school is where the memorable plans happen.

Primary loop:

1. Arrive at school.
2. Check locker / homeroom / day state.
3. Use small social toys: notes, snacks, hand-offs, locker expression.
4. Shift into after-school.
5. Gather at an activity such as the arcade.
6. Earn a small memory item that feeds back into locker identity.

## Scope Rules

- Prefer small public identity spaces over private housing. Locker first; dorms much later, maybe never.
- Use soft world states instead of a rigid class schedule.
- Build social systems as reusable primitives: notes, snacks, charms, tickets, and gifts should all sit on the same hand-off foundation when possible.
- Keep stranger communication template/sticker based. Free text for strangers is out of scope because of moderation and harassment risk.
- Do not add monetization, rerolls, paid identity framing, or large generic game panels while the core roleplay loop is still being proven.
- Validate small versions before building expensive systems.

## Phase 0 - Scaffold (Done)

- [x] Rojo + Wally project structure (Leif co-located services)
- [x] DataServiceTyped profile schema
- [x] Networker wiring for V0 services
- [x] Modular UI initializer
- [x] Studio world folders for School, Town, Arcade, lockers, classroom desks, and arcade scaffold

## Phase 1 - Locker Identity (Prototype)

- [x] Locker interaction prompts in `Workspace.World.School.LockerHallway`
- [x] Server-authoritative locker customization
- [x] Persistent locker recognition across sessions
- [x] Template stranger notes stub with owner controls
- [x] Copy-paste-safe locker IDs/tags generated at runtime

Design direction:

- Locker = persistent identity over time.
- Desk/seat = optional rotating social friction later, not core identity.
- Locker hallway should be a social center, not just a menu access point.
- Locker rewards should come from school/after-school life: arcade stickers, photo strips, band stickers, charms, notes, seasonal items.

## Phase 2 - Hand-Off And Notes (Prototype)

- [x] Stranger template note send/receive with rate limits
- [x] Owner controls: disable strangers, clear, block
- [x] Unified offer/accept/decline pipeline for snack skin
- [x] Distance + cooldown validation
- [x] Friend-tier free text after stranger loop works (Roblox friends only, `TextService` filtered — see `docs/FRIEND_NOTES_PLAN.md`)
- [ ] Offline locker note delivery

Design direction:

- Stranger notes stay template/sticker based.
- Friend free text is later and must still use Roblox filtering.
- Template notes need behavior safety, not just content safety: rate limits, owner clear, disable strangers, block/report affordances.
- Generic hand-off should remain the base for notes, snack sharing, charm gifting, photo strips, tickets, and future small objects.

## Phase 3 - Arcade Social Stage (Prototype)

- [x] Cabinet queue + spectator spots
- [x] Solo + 1v1 flow
- [x] First playable four-lane rhythm loop with text chunk maps
- [x] Multiple test songs/maps
- [x] Compact cabinet/result UI styling

Design direction:

- Arcade = competitive precision and social stage.
- The core fantasy is: "watch me beat you."
- Keep the cabinet readable from outside: queue, current players, score/combo/result, and spectator reactions.
- Two dance machines / participant slots are the right direction for 1v1.
- Future modes should be architected as slots + rulesets, not one hardcoded cabinet interaction.

Potential future arcade modes:

- Solo
- 1v1
- 1v1v1v1
- 2v2
- Co-op score
- Relay / crowd challenge

## Phase 3.5 - Rhythm Engine Quality Pass (Done)

Purpose: improve the existing arcade rhythm engine before building more arcade or garage content.

- [x] Add hold-note gameplay using the existing `timeMs,lane,holdMs` parser format
- [x] Keep each chart row as one judgment for server result compatibility
- [x] Add session-local scroll speed setting, default `2.5x`, adjustable `0.8x` to `3.0x`
- [x] Widen timing windows so a competent 4-key player is not punished unfairly
- [x] Add a small number of test holds to the Easy and Medium placeholder maps
- [x] Do not add chord notes, band systems, auto-chart tooling, settings persistence, DataService changes, or new Networker methods in this pass

Target timing windows:

| Judgment | Target Window |
| --- | --- |
| Perfect | 60ms |
| Great | 115ms |
| Good | 180ms |
| Miss | 230ms |

Hold-note behavior:

- Press the hold head inside the normal timing window.
- Keep the key held until near the hold end.
- Release too early = dropped hold / miss / combo break.
- Release near or after the end = complete the note with one judgment based on head timing.
- Auto-complete if the player is still holding when the end passes.

Verification:

```powershell
stylua src
selene src
rojo build default.project.json -o build\rhythm-holds-settings.rbxl
```

Studio checks:

- Tap notes still work.
- Hold notes render visibly longer than taps.
- Early hold release misses.
- Holding through the end scores once.
- Scroll speed changes note approach speed.
- Solo and 1v1 result submission still clear the active match.

See `docs/RHYTHM_FIRST_PASS.md` for map format and Studio checklist.

## Phase 4 - Session And Diegetic UI (Prototype)

- [x] Bus prologue -> school -> after-school phase transitions
- [x] Phone + paper + world-surface UI language
- [x] Removed assigned desks from session flow
- [x] First-time transfer card asks for name only

Design direction:

- UI surfaces should be tiny HUD, student phone, school paper/card, or world-device surface.
- Avoid generic dark prototype panels as the default.
- No Gakuran clone, no paid random identity framing, no reroll screen.
- First-day guidance should use diegetic UI primitives instead of a large quest panel.

## Phase 5 - Copy-Paste World Setup (Prototype)

- [x] Runtime-generated locker/desk tags and IDs for builder-safe copy-paste
- [x] Locker assignment uses discovered lockers instead of a hard-coded six-locker limit
- [x] Placeholder classroom desks replaced with `SchoolDesk` + `SchoolChair` stations
- [x] Hidden functional seats added to new chair stations

## Phase 6 - First-Day Loop Guidance (Prototype)

- [x] Gentle first-day homeroom note using the diegetic UI primitives
- [x] Server-session progress hooks for locker, decor, note, snack, after-school, and arcade actions
- [x] No new economy, quest rewards, monetization, schedule sim, or out-of-scope school systems

## Phase 7 - V0 Hardening (In Progress)

Repo hardening shipped (see `docs/V0_HARDENING_PLAN.md`):

- [x] Structured stranger-note send results with proximity check and user-facing toasts
- [x] All stranger templates selectable from locker menu; display names on note slips
- [x] Per-note block affordance for locker owners
- [x] Cancel outgoing snack hand-off offer from phone UI
- [x] Leave arcade spectator list from cabinet menu
- [x] QA runbooks documented for notes/snack, Solo arcade, and 1v1 arcade
- [x] Studio blockout readability checklist documented (user applies in Studio)

Manual Studio verification still open:

- [x] Manual two-player pass for notes and snack hand-off
- [x] Manual arcade pass for Solo and 1v1 rhythm completion
- [x] Verify rhythm timing after the hold/scroll-speed pass
- [x] Polish school/arcade blockout only where it improves readability
- [x] Confirm desktop and mobile-ish viewport readability for main V0 UI

## Phase 8 - Garage Social Jam (Prototype V0 Started)

Purpose: add a cozy co-op music hangout without competing with the arcade rhythm game.

Garage thesis:

> Arcade = "watch me beat you." Garage = "let's sound good together."

V1 should be a social jam toy, not a second rhythm game.

Prototype V0 now exists as a local-only stem station test. See `docs/GARAGE_SOCIAL_JAM_V0.md`.

- [x] One blockout garage space
- [x] Rehearsal board Practice gate before instrument interaction
- [x] Four shared-occupancy stem stations: drums, bass, guitar, voice
- [x] Station prompts request server-authoritative join/leave
- [x] One instrument per player and one occupant per station
- [x] Shared jam clock for local stem alignment across clients
- [x] No full mix usage
- [x] No scoring, charts, persistence, economy, monetization, band naming, or new rhythm engine

- [ ] One garage space
- [ ] One original or properly licensed song
- [ ] One arrangement, one stem set
- [ ] Instrument slots fade stems in/out when occupied or empty
- [ ] Avatar instrument animations
- [ ] Spectators can hang out nearby
- [ ] End with a small memory reward: photo, sticker, or demo tape
- [ ] No scoring, no charts, no moods, no band-name dependency in V1

Audio/content constraints:

- Use pre-rendered stems, not procedural instrument synthesis.
- Do not use Songsterr/commercial tab data in the released game unless rights are secured.
- For final songs, prefer original/commissioned tracks with full mix, stems, BPM/tempo map, and MIDI/Guitar Pro/MusicXML if needed later.
- Mood variants multiply content cost quickly, so save chill/upbeat/intense stem variants for later.

## Phase 9 - Garage Skill Layer (Future, Only If Earned)

Only build this if Garage Social Jam proves players gather around it and want more challenge.

Rules:

- Reuse the existing arcade rhythm engine where possible.
- Do not create separate instrument minigames for V1.5.
- Instrument identity should first come from chart density, pacing, lane labels, animation, stem behavior, and result flavor.
- Chord hits and hold notes are real engine features, not "just charting." Holds are acceptable only after the rhythm quality pass implements them.
- Auto-chart tooling is not needed until multiple original songs exist and charting becomes a real bottleneck.

Possible same-engine instrument feel:

| Instrument | Same-Engine Feel |
| --- | --- |
| Drums | Busier percussive patterns; kick/snare/hat/crash labels |
| Bass | Sparse grooves, holds, weighty feedback |
| Guitar | Clustered rhythms, riff bursts, later true chord input if worth it |
| Keyboard | Repeated melodic motifs, later pattern memory if worth it |

Result feedback should be celebratory only:

- Good: "Band Chemistry: B+", "Bass locked in", "Best moment: final chorus"
- Avoid: worst-performer callouts, harsh ranking, or competitive shaming

## Phase 10 - Band Identity (Future, Additive)

Band identity is cool but should not block Garage V1.

Possible features:

- Band name
- Preset logo builder
- Garage poster
- Demo tape label
- Band sticker for lockers
- School festival signup
- Instrument customization
- Part-time job money feeding into band cosmetics

This should layer on top of proven garage play, not come before it.

## Future School/Town Content Ideas

These are good ideas, but they should wait until the V0 loop is fun.

- Lunch/snack spot with trading and sitting together
- School store / vending machine daily rotation
- Cleaning ritual as a short co-op school-life activity
- PE/gym activity such as dodgeball, table tennis, relay, or paper airplane contest
- Music room, art room, computer room as social toy spaces
- Conbini, river, shrine, bus stop, rainy-day route
- Desk customization after locker identity is stable
- Soft day prompts on the school board

## Out Of Scope (V0)

PE, music room, cleaning duty, full class schedule, dorms, multiple classrooms, clubs, city bus, complex NPC relationship trees, auto-chart tooling, band stats, paid rerolls, monetization UI, and any large system that does not directly prove the locker/social/arcade loop.
