# Level Map Config

Level Select is driven by `data/level_map_config.json` and rendered by `ui/LevelMapPro.gd`.

## Root Structure

```
{
  "map_config": { ... },
  "level_nodes": [ ... ],
  "visual_settings": { ... }
}
```

## map_config

- `title`: UI title text
- `layout`: e.g. `grid`
- `grid_columns`: number of columns to target
- `card_size`: `{ width, height }` base card size
- `progress_bar`: `{ show, position, color_complete, color_incomplete }`
- `dev_mode`:
  - `unlock_all`: if true, all levels show as unlocked in the selector
  - `show_debug_info`: show extra debug UI and header dev toggle button

## level_nodes (array)

Each item describes one level card:
- `id`: unique level ID (e.g. `Level00`, `Level_GiantBoss`)
- `display_name`: card title
- `description`: short description (optional)
- `order`: sort order (ascending)
- `thumbnail`: texture path used by the card
- `difficulty`: 1–5 suggested difficulty
- `estimated_time`: human readable duration
- `rewards`: list of strings (badges/achievements)
- `unlock_requirements` (object):
  - `previous_level`: ID of prerequisite level (supported)
  - `min_score`: minimum score on `previous_level` (supported)
  - `deaths_max`: maximum deaths on `previous_level` (planned; not enforced)
  - `relic_count`: total gems across all levels (planned; not enforced)
- `theme_color`: hex string for card tinting

## visual_settings

Cosmetics for LevelMapPro effects:
- `card_effects`: `{ unlock_animation, hover_scale, focus_pulse, completion_glow }`
- `colors`: `{ locked, unlocked, completed, perfect, focus_border }`

## Runtime Behavior Notes

- Lock overlay shows requirements on the card when locked.
- Cards display best/latest score and hearts remaining based on `Persistence.get_level_completion(level_id)`.
- Keyboard navigation cycles unlocked cards; a cheat unlock is available (press `0` five times quickly) to enable dev mode at runtime.

## Dev Mode & Cheat

- `dev_mode.unlock_all` unlocks all levels in the selector view (non‑persistent, display‑side only).
- `dev_mode.show_debug_info` shows a header toggle button labeled “DEV: ON/OFF”.
- Runtime cheat: press the `0` key 5 times quickly on the Level Map to activate the same unlock‑all behavior (export‑safe; does not modify save data).

## Card Data & Status

- Score label: shows “Best: {score}” or “Latest: {latest} • Best: {best}” when both are available; otherwise “Not Completed”.
- Hearts row: reflects `hearts_remaining` from the latest completion (0–5). If no data exists, shows empty hearts and “--/5”.
- Status tints: perfect/complete/unlocked/locked affect card brightness; perfect cards add a subtle sparkle effect.

## Thumbnails

- Thumbnails should exist at the paths in `level_nodes[].thumbnail`.
- For web/export safety, thumbnails are preloaded in `LevelMapPro.gd` (constants for Level00/Level01/Level02/Level_GiantBoss). Keep IDs consistent with these preloads or extend the script when adding levels.

## Progress Header

- Shows “Progress: X/Y Complete • Z Perfect • Total Score: N • Avg Hearts: H/5” as available.
- Progress bar animates to the percentage of completed levels.

## Input & Navigation

- Left/Right to change selection, Enter/Jump to activate, Esc/Pause to return to Main Menu.
- Mouse wheel up/down scrolls left/right.

## Scene Loading

- Selected level loads via `change_scene_to_file("res://levels/{id}.tscn")` with a short glitch transition.
- Ensure each `level_nodes[].id` has a matching scene file name in `levels/`.
