# ROADMAP - Hinomori

## North Star

Hinomori is a peaceful rural Japanese student-life roleplay game. The fantasy is not completing a school timetable or grinding an economy. It is gradually feeling known in a small town: having a locker, recognizing familiar places, sharing small objects, making after-school plans, and collecting memories of ordinary days.

> I wish I lived in this town.

The product should create three feelings in order:

1. **I belong here.** My student, locker, and familiar places recognize me.
2. **Other people matter.** The world gives us gentle reasons to notice and approach each other.
3. **I want to see another day.** Weather, seasons, gatherings, and small discoveries vary the ritual without turning it into chores.

The current game is a **prototype**, not a finished town. Locker identity, notes, snack hand-offs, arcade play, session flow, garage occupancy, and garage practice charts exist, but several systems and world objects are still one-off or placeholder implementations.

## Product Pillars

### Place Before Feature Count

Every location needs a social purpose, a visual identity, and a reason to pass through it. A larger empty map is worse than a compact town where players repeatedly cross paths.

### Rituals Before Grind

Return reasons should feel like school life: checking a locker, meeting at the arcade, walking home in rain, seeing a seasonal notice, or keeping a photo. Avoid streak anxiety, mandatory chores, and paid relief from friction.

### Expression Through Small Things

Identity should accumulate through chosen details: locker decor, bag charms, stationery, photos, stickers, outfits, and keepsakes. Do not sell random body traits or identity rerolls.

### Diegetic By Default

Use school paper, phones, signs, boards, counters, cabinets, and physical interaction points. Keep the permanent HUD tiny. Generic quest, inventory, and shop panels are a last resort.

### Social Safety Is Gameplay Quality

Stranger communication stays template based. Free text remains filtered and relationship gated. Rate limits, distance checks, blocking, clearing, and graceful failure are part of the feature, not cleanup work.

## Town Shape

Hinomori should become a **compact open town**, not an enormous seamless map and not a menu of teleports.

The player should usually be free to choose where to go, while the world uses soft rhythms to concentrate people. School arrival, lunch, after school, weather, and local events change what feels relevant; they do not lock players into a strict timetable.

Recommended first town topology:

```text
                     [Hill / Shrine]
                           |
[River Path] -- [School] -- [Shopping Street] -- [Arcade]
                    |              |
                [Bus Stop]     [Conbini]
                    |
                 [Garage]
```

This is a relationship diagram, not a final literal layout. The important properties are:

- School, shopping street, and arcade form a short, legible main route.
- The garage is discoverable but slightly tucked away, making it feel personal.
- The river and shrine are quieter edge destinations with views and seasonal value.
- Players can see or infer their next destination from landmarks, signs, terrain, and pedestrian flow.
- Crossing the active core on foot should take roughly 60-90 seconds, subject to playtesting.
- Important routes should offer at least two choices later, but V1 can begin with one polished loop.

Do not build the whole town at once. Block out the topology first, test travel time and player convergence, then finish one route and one destination at a time.

## Architecture Direction

### Builder Contract

A builder should be able to duplicate a supported world prefab, move it, and press Play. They should not need to rename every copy, edit service code, or wire remotes by hand.

The intended contract for repeatable world objects is:

1. The model has a semantic `CollectionService` tag such as `HinomoriLocker` or `HinomoriArcadeCabinet`.
2. The model follows a small documented child contract such as `PromptPart`, `ProximityPrompt`, anchors, slots, or display surfaces.
3. Runtime discovery assigns or repairs a unique attribute ID.
4. A binder validates the model and attaches behavior once.
5. Invalid copies warn once and are skipped without breaking unrelated UI or services.
6. A Studio authoring command can validate or stamp prefabs before publishing, but runtime remains resilient.

Names should remain readable for builders, but names should not be identity or registration requirements.

### Build Once, Skin Many Times

Reusable systems should be modular where they remove repeated behavior:

| Foundation | Used By |
| --- | --- |
| World registry + prefab validation | Lockers, cabinets, boards, benches, vending machines, shops, activity stations |
| Interaction binder | Prompts, distance checks, busy states, local affordances |
| Slot/ruleset activity framework | Arcade cabinets, garage stations, festival games, sports tables |
| Hand-off pipeline | Snacks, notes, charms, tickets, photos, gifts |
| Item/catalog metadata | Decor, hand props, shop stock, memory rewards |
| World-state service | Time band, weather, season, event flags, location availability |
| Location/landmark registry | Spawn routing, guidance, analytics, ambient audio, map signs |
| Surface UI primitives | Paper, phone, world devices, counters, result slips |
| Seating/pose binder | Chairs, benches, stools, picnic spots, photo poses |
| Ambient-zone system | Music, insects, train sounds, lighting and weather transitions |

Do not create a universal framework for every prop. Static scenery stays scenery. Build a reusable foundation only when at least two real features share behavior or when builder error would otherwise scale with every copy.

### Important Copy-Paste-Safe World Types

These should eventually follow the builder contract:

- **Lockers:** unique persistent IDs, decor slots, prompt, note surface.
- **Arcade cabinets:** unique cabinet IDs, player slots, spectator anchors, supported rulesets, screen surfaces.
- **Garage/rehearsal spaces:** room ID, rehearsal board, instrument stations, player anchors, audio set key.
- **Instrument stations:** station ID, instrument key, prompt, player anchor, optional cable boundary.
- **Boards and notice surfaces:** board ID, content channel, prompt or physical display.
- **Vending machines and shop counters:** vendor ID, stock catalog key, interaction point, display anchors.
- **Benches, chairs, and stools:** seat tag, pose/occupancy metadata, optional social grouping ID.
- **Photo spots:** camera anchor, participant anchors, framing metadata, location/season stamp.
- **Bus stops and doors:** route or destination key, arrival anchor, availability rules.
- **Activity props:** activity type, participant slots, spectator slots, ruleset key.
- **Ambient zones:** location key, priority, soundscape key, lighting/weather modifiers.
- **Spawn and landmark points:** stable semantic key, not hand-maintained numbered names.

## Current Systems Audit

### Prototype And Worth Keeping

- Co-located client/server/shared service pattern with explicit startup order.
- DataServiceTyped profile ownership and Networker whitelist pattern.
- Server-authoritative locker, note, hand-off, arcade, and garage state changes.
- Modular UI bootstrap and phone/paper/world-surface visual language.
- `WorldAutoIds` sequential ID repair used by lockers and desks.
- Catalog-driven locker decor, hand-off items, arcade songs, and garage charts.
- Shared four-key rhythm engine with taps, holds, results, and garage-only options.

### Main Scaling Gaps

- Arcade configuration assumes one named `CabinetPair_001`.
- Garage configuration assumes one named `GarageJam_001` and four named stations.
- Prompt binding and world lookup patterns are repeated across systems.
- Runtime auto-ID support is folder-based and currently specialized to lockers/desks.
- There is no unified prefab validation report or builder-facing authoring command.
- Session phases are prototype global states, not yet a coherent town clock/world-state model.
- Items are split across small catalogs without a shared item outcome/ownership model.
- No location registry, ambient-zone framework, analytics funnel, or performance budget exists.
- Existing world and UI flows still require regression testing whenever a new location mounts.
- Commercial Teenage Dirtbag audio/charts are prototype content and cannot be treated as release-ready.

## Milestone 0 - Stabilize The Prototype

**Status:** Next

**Player outcome:** The current school -> social -> arcade/garage loop works reliably before the map expands.

Work:

- Establish one repeatable baseline smoke test for startup, transfer card, locker, notes, snack, arcade Solo/1v1, garage Practice, station leave, and respawn cleanup.
- Add focused automated tests for pure modules: ID assignment, catalogs, rhythm parsing/scoring, and state transitions where practical.
- Resolve stale prototype fields and documentation deliberately; do not silently migrate profile data.
- Audit mobile input and mobile-ish UI readability, especially rhythm and world prompts.
- Confirm every service fails locally when its world objects are absent instead of breaking startup.
- Record a small performance baseline for client memory, server script time, instance count, and initial load.

Exit gate:

- Automated format/lint/build pass.
- One-player and two-player Studio checklist pass.
- No known regression in the current V0 spine.
- Prototype-only licensed audio is clearly marked and isolated.

## Milestone 1 - Builder-Safe World Foundation

**Status:** Planned

**Player outcome:** No new content yet; builders can grow the world without fragile manual wiring.

Work:

- Generalize `WorldAutoIds` into a small world registry that discovers tagged instances across configured roots.
- Define a typed prefab descriptor: tag, ID attribute, required children, optional children, validator, and binder.
- Preserve valid IDs, repair duplicate/missing IDs deterministically, and never use display names as identity.
- Support add/remove at runtime through `CollectionService` signals where appropriate.
- Add warn-once diagnostics with the exact model path and missing requirement.
- Add a Studio command/plugin script that can scan, tag, stamp IDs, and print a validation report before publish.
- Migrate lockers first without changing behavior.
- Migrate arcade cabinets second so duplicated cabinets independently queue, play, and report state.
- Migrate garage rooms/stations third; resolve station/audio metadata from attributes or catalog keys rather than fixed names.
- Document prefab contracts in one builder guide with duplication recipes.

Exit gate:

- Duplicating a locker requires no rename or code edit.
- Duplicating an arcade cabinet creates an independent valid cabinet.
- Duplicating a garage station or room either binds correctly or produces one actionable warning.
- A malformed copy cannot break unrelated UI or services.
- Runtime and Studio validation agree on prefab validity.

## Milestone 2 - V0 Loop Product Pass

**Status:** Planned

**Player outcome:** A new player understands why the locker hallway and arcade matter and reaches one satisfying social payoff.

Work:

- Observe first-time players and simplify the first-day guidance around real confusion points.
- Polish transfer/name flow, locker recognition, note readability, and hand-off feedback.
- Decide the smallest honest memory reward that closes the loop: likely one locker sticker or photo strip earned through an activity.
- Improve arcade spectator readability and recovery when players leave mid-queue or mid-match.
- Improve garage Practice framing and occupancy feedback without adding band progression.
- Add minimal funnel analytics: setup complete, locker opened, note sent, hand-off accepted, arcade joined/completed, garage joined/completed.
- Replace or remove content that cannot ship legally, including commercial song prototypes.

Exit gate:

- Most observed new players can reach locker interaction without developer explanation.
- Two players can complete note, snack, and one after-school activity without stuck state.
- The loop ends with a visible identity/memory callback.
- Analytics events are privacy-conscious, documented, and do not drive manipulative design.

## Milestone 3 - Compact Town Blockout

**Status:** Planned after V0 loop validation

**Player outcome:** Players can freely walk a small, memorable route from school to after-school destinations.

Work:

- Block out the school, shopping street, arcade, garage, bus stop, river path, and shrine as landmarks only.
- Build one continuous school -> shopping street -> arcade/garage route first.
- Establish terrain, sightlines, signage, collision, spawn points, and traversal timing before final art.
- Add a location registry and ambient zones so each district can own soundscape, lighting hints, guidance labels, and analytics without bespoke scripts.
- Use soft boundaries, terrain, fences, rail lines, and distant scenery to make a compact map feel larger.
- Keep doors open only when interiors earn their cost; most buildings remain readable facades initially.
- Test player density at target server sizes. Shorten routes or add gathering cues if players rarely meet.
- Establish streaming and instance budgets before adding decorative density.

Exit gate:

- Active-core travel time feels pleasant rather than empty.
- Players can navigate using landmarks without a permanent minimap.
- School, arcade, and garage remain populated enough for their social loops.
- Streaming, prompts, ambient zones, and world registry work after moving between districts.

## Milestone 4 - Soft Town Rhythm

**Status:** Future direction

**Player outcome:** The town changes mood and opportunity without forcing a schedule.

Work:

- Introduce authoritative but low-frequency world state: time band, weather, season, and a small event flag set.
- Begin with three readable time bands: morning arrival, school day, after school/evening.
- Use weather and time to alter lighting, ambience, NPC/scenery dressing, board text, and gathering suggestions.
- Keep core social locations accessible. Events should attract players, not punish late arrivals.
- Add a school/town notice channel consumed by diegetic boards and phone messages.
- Add graceful late-join state synchronization and deterministic cleanup between world states.

Exit gate:

- A player can join at any point and understand the current mood.
- World-state changes do not interrupt an active rhythm match, hand-off, or customization flow.
- At least one weather/time variation changes the route or gathering behavior meaningfully.

## Milestone 5 - One Town Ritual

**Status:** Future direction; choose from playtest evidence

**Player outcome:** The open town offers one repeatable shared ritual beyond arcade and garage.

Candidate slices:

- Conbini snack stop feeding the existing hand-off system.
- Vending-machine daily selection with no complex economy.
- River photo spot producing a locker photo strip.
- Shrine seasonal wish using templates and a keepsake.
- Rainy bus-stop gathering with umbrellas and conversation prompts.

Selection rule:

- Choose the ritual that strengthens the weakest proven part of the current loop.
- Reuse world registry, hand-off, item catalog, world state, and diegetic surfaces.
- Build one location and one outcome, not a generalized shop/economy simulation.

Exit gate:

- The ritual creates visible player convergence.
- Its reward or memory feeds identity rather than raw currency accumulation.
- The prefab and catalog patterns make a second content variant cheap to author.

## Milestone 6 - Identity And Memory Layer

**Status:** Future direction

**Player outcome:** Ordinary days leave chosen, visible traces on the student.

Possible work:

- Backpack and keychain personalization using desk/bag hooks.
- Photo strips, stickers, notes, event stamps, and demo tapes as scrapbook/locker memories.
- Small uniform and after-school outfit choices using curated selection, not random rerolls.
- Item provenance metadata: where and when a memory came from.
- Capacity and presentation rules that keep lockers readable instead of becoming inventory grids.

Do not begin until the game has enough meaningful sources of memories to justify a collection layer.

## Milestone 7 - Content Expansion

**Status:** Future direction

Expand only through proven reusable foundations and one complete slice at a time.

Possible destinations:

- Conbini or school store.
- Riverbank and shrine seasonal route.
- Festival evening.
- Cleaning ritual or one lightweight school activity.
- Additional original arcade songs and cabinet rulesets.
- Original garage song with licensed stems and authored charts.
- Photo booth or purikura-inspired social photo activity.

Still deferred:

- Full class schedule simulation.
- Many functional classrooms.
- Dorms or private housing.
- Complex NPC relationship trees.
- Deep jobs/economy.
- Clubs as large progression systems.
- City-scale transport.

## Release Content And Rights Gate

Before public release:

- Replace commercial prototype music with original, commissioned, or properly licensed audio.
- Track source, license, creator credit, asset ID, stems, BPM/tempo map, and chart ownership in a content manifest.
- Review Japanese language, signage, uniforms, school details, and town references for authenticity and accidental misuse.
- Replace placeholder art where readability, identity, or rights require final assets.
- Confirm moderation, reporting, filtering, privacy, and data-retention behavior for every social surface.

## Roadmap Decision Rules

Before starting a slice, answer:

1. What player behavior or feeling is this testing?
2. Which existing foundation does it reuse?
3. What is the smallest complete version?
4. How will builders add a second copy or content variant?
5. What server authority, moderation, persistence, and cleanup rules apply?
6. What must be tested in one-player and two-player Studio?
7. Does it increase player convergence or spread the server thinner?
8. Does it leave a memory, relationship, or reason to return?

If those answers are unclear, the slice is not ready to implement.

## Standard Slice Checklist

Every implementation plan must include:

- Explicit in-scope and out-of-scope boundaries.
- Existing contracts that must remain unchanged.
- Builder/prefab setup requirements.
- Graceful behavior for missing or malformed world objects.
- Server-authority, distance, cooldown, occupancy, and cleanup rules where relevant.
- Automated commands: `stylua src`, `selene src`, and a named `rojo build` output.
- A Studio checklist covering baseline regressions and the new feature.
- A two-player checklist when shared state or social interaction is involved.
- Required asset list. If tooling cannot make an asset, the implementer must tell the user exactly what is needed.
- Honest status and documentation updates after verification.

## Immediate Recommendation

The next implementation slice should be **Milestone 1A: World Registry + Locker Migration**, not another town location.

Keep it narrow:

- Define the registry/descriptor contract.
- Move existing locker discovery and ID repair onto it.
- Add validation diagnostics and a small Studio scan/stamp command.
- Prove duplicate, delete, malformed-copy, and saved-ID fallback behavior.
- Do not migrate arcade and garage in the same slice.

Once lockers prove the abstraction, migrate arcade cabinets in a separate slice. That migration is the real test that the foundation supports multiple independent activity instances rather than only numbered storage props.
