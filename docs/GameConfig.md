# Game Config (data/game_config.json)

Centralized tuning for gameplay, physics, audio, graphics, scoring, and accessibility. Loaders can read this JSON to apply defaults at boot.

Sections:

- `accessibility`
  - `colorblind_support`, `high_contrast_mode`, `large_ui_scale`, `reduced_motion`, `screen_reader_support`, `subtitle_size`
- `audio`
  - `fade_duration`, `master_volume`, `music_volume`, `sfx_volume`, `ui_volume`
- `debug`
  - `enable_cheats`, `log_level`, `performance_overlay`, `show_debug_info`, `show_fps`
- `difficulty` (named presets)
  - `easy`/`normal`/`hard`: `checkpoint_frequency`, `damage_multiplier`, `enemy_speed_multiplier`, `extra_lives`
- `gameplay`
  - `coyote_time`, `default_lives`, `invincibility_time`, `jump_buffer_time`, `max_fall_speed`, `respawn_delay`, `terminal_velocity`
- `graphics`
  - `bloom_enabled`, `motion_blur`, `particle_density`, `screen_shake_intensity`, `target_fps`, `vsync_enabled`
- `performance`
  - `effect_quality`, `max_audio_sources`, `max_particles`, `shadow_quality`, `texture_quality`
- `physics`
  - `acceleration`, `air_friction`, `double_jump_velocity`, `friction`, `gravity`, `jump_velocity`, `max_fall_speed`, `wall_slide_speed`
- `scoring`
  - `combo_multiplier`, `death_penalty`, `fruit_points`, `gem_points`, `max_combo`, `perfect_bonus`, `time_bonus_multiplier`

Notes:
- The project loads this via `systems/ConfigManager.gd` at startup and merges with built‑in defaults.
- Applied by systems:
  - `Audio.gd`: `master_volume`, `music_volume`, `sfx_volume` (and updates `AudioServer`).
  - `Player.gd` / movement: `gravity`, `jump_velocity`, `coyote_time`, `jump_buffer_time`.
  - `FX.gd`: `screen_shake_intensity` where referenced.
  - `HealthSystem.gd`: default lives/hearts.
- Override at runtime via `ConfigManager.set_game_config(section, key, value)`; values are persisted back to `data/game_config.json` in development.
