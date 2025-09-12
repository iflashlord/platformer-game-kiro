# Architecture

This document outlines the overall runtime architecture, key systems, and data flow for Glitch Dimension (Godot 4.4).

## Autoload Singletons

Loaded from `project.godot:[autoload]` and available globally:
- `ErrorHandler`: Centralized error/info/debug helpers
- `Settings`: In‑memory runtime settings and change signal
- `PerformanceMonitor`: Lightweight FPS/perf helpers
- `InputManager`: Input bindings/utilities
- `SceneManager`: Simplified scene transitions and tracking
- `Analytics`: Local analytics buffer + batching/logging
- `ConfigManager`: Loads `data/game_config.json`, user config, and level map; exposes getters/setters
- `Game`: Core game state, pause/restart, scoring, collectibles
- `LevelLoader`: Scene loading helpers
- `Audio`: Music/SFX/Narration buses and pooling
- `Persistence`: Cross‑platform save system (file/localStorage)
- `FX`: Screen shake, flashes, hit‑stop
- `Respawn`: Checkpoints/spawn handling
- `DimensionManager`: Dimension layer switching utilities
- `ObjectPool`: Reuse temporary nodes for performance
- `EventBus`: Global signals (UI/gameplay events)
- `HealthSystem`: Hearts and damage/lives
- `GameTimer`: Simple run timer helpers
- `DebugSettings`: Debug overlays and toggles
- `DeploymentConfig`: Hosting/export toggles
- `LevelCompletion`: Level completion helpers
- `PauseManager`: In‑game Pause Menu lifecycle

## Scene Flow

- Main Menu (`ui/MainMenu.tscn`) → Level Select (`ui/LevelMapPro.tscn`) → Level (`levels/LevelXX.tscn` inheriting `levels/BaseLevel.gd`) → Results (`ui/LevelResults.tscn`).
- `PauseManager` listens to `Game.game_paused`/`game_resumed` and manages `ui/PauseMenu.tscn`.
- `SceneManager` provides a safe wrapper over `change_scene_to_file()` and resets the dimension layer when loading levels.
 - Level Select supports a dev unlock cheat (press `0` five times) that unlocks all levels in the selector view.

## Level Runtime

- `BaseLevel.gd` performs per‑level setup: resets health/timer/dimension, connects to HUD and `EventBus`, starts music, and tracks completion.
- `LevelManager.gd` auto‑connects to reusable components via groups (fruits, gems, crates, enemies, spikes, jump pads, death zones) and aggregates stats.
- On completion, `BaseLevel.gd` prepares `completion_data` and calls `Persistence.save_level_completion()` then shows `ui/LevelResults.tscn`.

## Input

- Input map is defined in `project.godot:[input]`.
- Movement: `move_left`/`move_right`, Jump: `jump`, Flip: `dimension_flip`, Pause: `pause`, Restart: `restart`.
- Touch: `ui/TouchControls.tscn/gd` generates actions via `Input.action_press/release`.

## Data Flow

- Level Select data: `data/level_map_config.json` (nodes, thumbnails, unlock requirements, visual settings).
- Game tuning data: `data/game_config.json` (audio, gameplay, physics, scoring, accessibility, etc.).
- Save data: `Persistence` keeps a `current_profile` with `levels` (legacy), `level_completions` (detailed best run), `statistics`, `settings`, `unlocked_levels`.

## Persistence & Unlocks

- Desktop: saves to `user://profile.save` (JSON via `FileAccess`).
- Web: saves to `localStorage` under key `dimension_runner_profile` via `JavaScriptBridge`.
- Unlock logic uses `level_map_config.json` requirements: `previous_level`, `min_score` (supported). Fields like `deaths_max`, `relic_count` may be present but are not enforced yet. Manual overrides via `unlocked_levels` and dev mode.

## Audio

- Buses: `Master`, `Music`, `SFX`, `Narration`.
- SFX pool: 10 `AudioStreamPlayer` instances for concurrent sounds.
- Volume persisted via `Persistence` and applied to `AudioServer` in `Audio.update_volumes()`.
 - Narration: `Audio.play_narration()` ducks music and restores on finish; used by `HintArea`.

## Analytics

- Offline by default: queues/batches events and writes to `user://analytics_log.json`.
- Categories: gameplay, ui, performance, error, progression, monetization.
- `opt_out()` clears queue; `clear_user_data()` wipes analytics user data.

## Eventing

- `Game.gd` emits `game_paused`, `game_resumed`, `score_changed`, `time_changed`, and collectible signals.
- `EventBus` defines global signals like `level_unlocked`, `hint_requested`, and component‑specific events.

## Web Deployment

- Prebuilt export in `web-dist/` with `index.html/js/wasm/pck`.
- `vercel.json` sets headers for COOP/COEP, CORS, and caching.
