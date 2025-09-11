# Save Data

This project uses a cross‑platform JSON save format managed by `systems/Persistence.gd`.

## Storage

- Desktop: `user://profile.save` (via `FileAccess`)
- Web: `localStorage` under key `dimension_runner_profile` (via `JavaScriptBridge`)

## Profile Schema (summary)

```
{
  "profile_name": "Player",
  "created_at": <unix>,
  "last_played": <unix>,
  "total_playtime": <seconds>,
  "levels": {                // legacy per-level stats
    "Level01": {
      "best_time_ms": 12345,
      "best_score": 2000,
      "completed": true,
      "time_trial_completed": false,
      "attempts": 3,
      "deaths": 5,
      "last_played": <unix>
    }
  },
  "level_completions": {     // detailed best completion per level
    "Level01": {
      "score": 2200,
      "completion_time": 58.4,
      "deaths": 1,
      "hearts_remaining": 4,
      "gems_found": 3,
      "total_gems": 3,
      "hidden_gems_collected": 1,
      "total_hidden_gems": 1,
      "completed": true,
      "timestamp": <unix>
    }
  },
  "settings": {              // audio/graphics toggles applied at boot
    "master_volume": 1.0,
    "music_volume": 0.7,
    "sfx_volume": 1.0,
    "fullscreen": false,
    "vsync": true
  },
  "statistics": {            // global counters
    "total_score": 12345,
    "total_deaths": 12,
    "total_jumps": 456,
    "total_collectibles": 78,
    "levels_completed": 2,
    "time_trials_completed": 0
  },
  "achievements": [],
  "unlocked_levels": ["Level02"],
  "version": "1.0.0"
}
```

## API Highlights

- `save_profile(profile?)` / `load_profile(name?)`
- `save_level_completion(level_name, completion_data)` – updates `level_completions`, stats, and unlocks
- `get_level_completion(level_name)` – returns best run for that level
- `set_best_time(level, ms)` / `set_best_score(level, score)`
- `is_level_unlocked(level_name)` – resolves requirements from `data/level_map_config.json`
- `reset_level_progress()` / `reset_profile()`
- `get_last_level()` / `get_next_recommended_level()`

## Unlock Rules

Evaluated from `data/level_map_config.json`:
- `previous_level`: must be completed
- `min_score`: minimum score on `previous_level`
- `deaths_max`: maximum deaths on `previous_level`
- `relic_count`: total gems across all levels

Manual overrides: `unlocked_levels` list, or dev mode in the level map.

## Reset Everything

From `ui/SettingsMenu.tscn/gd` → “Reset Everything”:
- Resets audio settings to defaults
- Calls `Persistence.reset_level_progress()` and `Persistence.reset_profile()`

