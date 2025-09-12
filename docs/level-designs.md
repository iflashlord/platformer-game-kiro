# Level Design Overview

This document summarizes the intended design, theme, and mechanics of the playable levels, aligned with the current implementation and the Level Map configuration.

## Debug & Tools

### Debug Borders
- **Toggle**: `debug_toggle` input action.
- **Purpose**: Colored borders around interactables during development.
- **Disable for Release**: `DebugSettings.show_debug_borders = false`.
- **Color Key**: Player (green), Enemies (red), Collectibles (orange), Hidden Gems (purple), Hazards (gray), Interactive (brown).

### Common Systems
- **Health**: 5-heart system with UI updates via `HealthSystem`/`GameHUD`.
- **Timer**: Level timer via `GameTimer` and results summary.
- **Results**: Completion screen (`ui/LevelResults.tscn`) showing score, hearts, time, gems.
- **Persistence**: Best score/time, completions, hearts, gems saved per level.

## Level00 — First Steps (Tutorial)
- **Theme**: Soft forest/ruins intro; calm palette.
- **Focus**: Movement, jumping (buffer/coyote), dimension flip, basic hazards.
- **Traversal**: Simple platforms, a few jump pads, one or two dynamic platforms.
- **Collectibles**: Fruits along the golden path; at least one Hidden Gem.
- **Hazards**: Gentle spike placements; death zones below.
- **Checkpoints**: Early and mid checkpoints.
- **Portal**: Standard LevelPortal to finish; shows Level Results.

## Level01 — Mystic Realms
- Refer to `docs/Level01_Design.md` for a detailed layout.
- **Theme**: Forest adventure; earthy tones.
- **Focus**: Crates (regular/bounce), first enemy encounters, secret paths.
- **Traversal**: Larger gaps, vertical segments, optional side routes.
- **Collectibles**: Fruits on main and optional routes; multiple Hidden Gems.
- **Hazards**: Spike clusters; simple environmental traps.
- **Enemies**: Patrol enemy; basic combat or avoidance; stomp enabled.
- **Checkpoints**: Start, mid, pre-portal.
- **Portal**: Completion gateway with effects.

## Level02 — Parallel Worlds
- **Theme**: Dimensional overlays; stronger use of A/B layers.
- **Focus**: Dimension gating puzzles; switching to progress safely.
- **Traversal**: Interleaved platforms across layers; moving platforms; jump pads.
- **Collectibles**: Placed to encourage flips and exploration; Hidden Gems behind flips.
- **Hazards**: Layer-specific spikes/hazards that force timing.
- **Enemies**: Introduces FlyingEnemy with patrol/sine or chase behavior.
- **Checkpoints**: Frequent to encourage experimentation.
- **Portal**: Standard; hints at the boss ahead.

## Level_GiantBoss — The Giant’s Last Stand (Boss)
- **Theme**: Arena confrontation; high-contrast palette; dramatic music.
- **Focus**: Multi-phase boss with stomp/bounce windows and telegraphed attacks.
- **Traversal**: Safe platforms, temporary hazards, dimension-aware opportunities.
- **Hazards**: Boss projectiles, shockwaves, spike summons.
- **UI**: `ui/BossHealthUI.*` shows boss health; `GameHUD` minimized.
- **Victory**: Portal activates after boss defeat to finish level.

## Progression & Unlocks
- Ordering and unlocks are defined in `data/level_map_config.json`.
- Current sequence:
  - `Level00` → `Level01` (previous level)
  - `Level01` → `Level02` (previous level + min_score 100 on `Level01`)
  - `Level02` → `Level_GiantBoss` (previous level + min_score 10 on `Level02`)
- The Level Map shows lock reasons (e.g., “Need 100 points on Level01”).

## Design Principles

### Visual Distinction
- `Level00`: Soft greens/browns, onboarding clarity
- `Level01`: Natural forest, richer contrast and secrets
- `Level02`: Dimensional overlays, purple/blue accents
- `Boss`: Stark arena, readable telegraphs

### Progressive Difficulty
- `Level00`: Intro; low hazard density; basic flips
- `Level01`: Adds crates, patrol enemies, secret hunts
- `Level02`: Layer puzzles, moving pieces, flying enemy
- `Boss`: Pattern recognition, timing, survivability

### Feature Introduction
- Early levels introduce one new mechanic at a time (crates, flips, enemy types) and reinforce mastery before the boss.

## Scoring & Completion
- Fruits and gems increase score; Hidden Gems tracked separately.
- Hearts remaining contribute to results; perfect runs track high hearts and full gem counts.
- Level Results include: score, time, deaths, hearts, gems (incl. hidden), completion flag.

## Development Notes
- Use `LevelPortal` for completion and ensure `BaseLevel` emits results and saves via `Persistence`.
- Group gems in `gems` and hidden items in `hidden_gems` for BaseLevel counters.
- Place `Checkpoint` nodes at natural boundaries; hook into `Respawn`.
- Playtest flips with `DimensionManager` to ensure hazards/threats align between layers.
