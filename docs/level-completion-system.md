# Level Completion System

This document reflects the current implementation of completion detection, results UI, persistence, and progression in the project.

## Flow Overview

### Completion Detection
- Player enters `LevelPortal` (emits `EventBus.level_portal_entered`).
- `levels/BaseLevel.gd` listens and calls `_on_level_completed()`.
- Timer stops and stats are captured (score, time, deaths, hearts, gems).

### Pause & Cleanup
- Game pauses: `Game.is_paused = true` and `get_tree().paused = true`.
- `PauseManager` is told to hide/cleanup any pause menu before showing results.

### Optional FX & Audio
- Optional completion FX via `systems/LevelCompletion.gd` and `systems/FX.gd` (flash/shake).
- Completion SFX: `Audio.play_sfx("level_complete")` used by the FX path and UI.

### Results Screen
- `ui/LevelResults.tscn/gd` is instanced and shown.
- Displays: Level name, time, hearts remaining, hidden gems found/total, final score.
- Performance coloring: hearts (green/yellow/red), gems (gold/cyan/gray), score tier tint.
- “Next Level” button auto-evaluates unlock status; shows lock reason text when locked.
- Buttons: Next (or Game Complete), Retry, Level Select, Main Menu.

## Data Saved

### Completion Data Structure (BaseLevel)
```gdscript
{
  "level_name": "Level01",              # or level_id
  "score": 2150,
  "completion_time": 45.67,             # seconds
  "deaths": 1,
  "hearts_remaining": 4,                # 0..5
  "gems_found": Game.get_total_gems(),  # total collected (incl. visible)
  "total_gems": <count of gems in scene>,
  "hidden_gems_collected": <count>,
  "total_hidden_gems": <count>,
  "completed": true
}
```

Notes:
- `BaseLevel` counts gems via groups `gems` and `hidden_gems` (see `_count_total_*` methods).
- `LevelResults` confirms save by calling `Persistence.save_level_completion` again for safety.

## Results UI Details

### Labels
- Time: formatted as `MM:SS.ms`.
- Hearts: `X/5` with performance color.
- Hidden Gems: `found/total` with gold/cyan/gray tint.
- Score: 4‑digit padded with a color tier.

### Next Level Logic
- Determines next via `Persistence.get_next_level_in_progression(current)` or hardcoded fallback map.
- Checks `Persistence.is_level_unlocked(next)` after saving completion.
- If locked: button disabled with requirement text (e.g., “Need 100 points”).
- If final level: shows “GAME COMPLETE!” with a subtle glow.

### Navigation
- Keyboard/gamepad focus across the four buttons, with hover/focus SFX and tweened highlights.
- Exiting results unpauses the game (`Game.is_paused = false; get_tree().paused = false`).

## Unlocking & Level Map

- Unlock rules are data‑driven (`data/level_map_config.json`).
- Supported checks: `previous_level` and `min_score`; future fields may appear but are not enforced yet.
- The Level Map shows lock reasons directly on cards and computes overall progress.

## Health & Retry

- Levels start with full hearts; `HealthSystem` integrates with HUD and deaths increment stats.
- Retry from results uses standard scene reload and resets hearts/timers.

## Scoring Notes

- Score accumulation comes from fruits, gems, enemies, and bonuses implemented per level.
- Hearts remaining and gem completion are emphasized in results and level select.

## Debug & Deployment

- Debug borders and logs are controlled via `DebugSettings` and `DeploymentConfig`.
- Web/desktop parity maintained; results UI and persistence are export‑safe.

This system pauses cleanly, saves robustly, and guides players forward with clear unlock messaging and a polished results screen.
