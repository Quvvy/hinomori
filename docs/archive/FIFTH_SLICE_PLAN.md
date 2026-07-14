# Fifth Slice Plan - Minimal Diegetic UI Foundation

## Recommendation

Replace generic prototype panels with a future-proof phone + paper + world-surface UI language.

This supersedes the previous first-day guidance idea. The first-day guide should be implemented later using these primitives.

## Scope

Status target: Prototype

In scope:

- UI direction documentation
- Shared UI primitives for paper, phone, world surfaces, tiny HUD labels, icon buttons, toast slips, and list rows
- V0 visual conversion for session HUD, transfer prompt, locker menu, snack hand-off, arcade menu, match result, and light rhythm styling
- Existing gameplay behavior preserved

Out of scope:

- New gameplay systems
- Data schema changes
- Monetization/reroll UI
- Friend free-text or offline notes
- Final art, custom icons, Japanese signage, phone models, paper textures, sounds

## Acceptance Criteria

- V0 menus no longer look like generic dark prototype panels.
- HUD is tiny and readable.
- Transfer prompt reads as a school paper/card.
- Snack hand-off opens as a student phone-style surface.
- Locker menu reads as locker paper/notes.
- Arcade menu reads as a cabinet/world-surface overlay.
- Match result appears as a compact slip.
- Rhythm gameplay still starts, accepts D/F/J/K input, and finishes.
- No server contracts, rewards, persistence, or moderation behavior changes.
- `stylua src`, `selene src`, and `rojo build` pass.

## Studio Checklist

- Confirm transfer form looks like school paper, not a dark modal.
- Confirm HUD is small and readable in school and arcade scenes.
- Confirm locker menu opens, applies decor, and owner note controls still work.
- Confirm phone/snack UI opens and two-player snack hand-off still completes.
- Confirm arcade menu opens at cabinet, queue/song/Solo/1v1 controls still work.
- Confirm rhythm Solo starts and finishes; D/F/J/K input still works.
- Confirm match result is compact and clears automatically.
- Confirm no UI text overlaps on desktop and mobile-ish viewport sizes.
- Confirm prototype tools remain hidden behind a small debug/tools affordance.
- Confirm no monetization/reroll UI appears.

## Asset Dependency Rule

No final assets are needed. Cursor must tell the user if future polish requires final phone art, paper texture art, Japanese typography/signage, custom icons, sound effects, final arcade art, or final locker UI art.
