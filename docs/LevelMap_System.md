# Professional Level Selection System

## Overview
A horizontal, card-based level selection with thumbnails, score/hearts display, clear lock states, keyboard/mouse navigation, and data-driven unlock rules.

## Key Features

### Horizontal Cards
- Large thumbnail cards (responsive; ~2.5 visible), horizontal scroll.
- Score and hearts display using latest/best data and hearts remaining (0–5).
- Lock overlay with requirement text (e.g., “Need 100 points on Level01”).
- Polished overlays, gradients, and focus borders.

### Progress Display
- Overall header: “X/Y Complete • Z Perfect • Total Score: N • Avg Hearts: H/5”.
- Progress bar animates to completion percentage.
- Real-time stats from `Persistence.get_level_completion(level_id)`.

### Visual Effects
- Hover/focus scaling and tint.
- Golden tint + sparkle for perfect completions.
- Dimmed cards for locked levels.

### Navigation
- Left/Right or A/D to change selection.
- Enter/Space/Jump to activate level.
- Esc/Pause to return to Main Menu.
- Mouse wheel up/down scrolls horizontally.
- Smart scrolling keeps selection centered.

## File Structure

```
ui/
├── LevelMapPro.tscn        # Level map scene
└── LevelMapPro.gd          # Controller logic

data/
└── level_map_config.json   # Map config and level metadata

content/
└── thumbnails/             # Level thumbnails
    ├── Level00.png
    ├── Level01.png
    ├── Level02.png
    └── Level_GiantBoss.png

tools/
├── LevelMapEditor.gd       # Config editor helpers
└── ThumbnailGenerator.gd   # Thumbnail creation tool
```

## Configuration

### level_map_config.json
```json
{
  "map_config": {
    "title": "Select Level",
    "layout": "grid",
    "grid_columns": 3,
    "card_size": { "width": 380, "height": 240 },
    "progress_bar": {
      "show": true,
      "position": "top",
      "color_complete": "#4CAF50",
      "color_incomplete": "#757575"
    },
    "dev_mode": {
      "unlock_all": false,
      "show_debug_info": false
    }
  },
  "level_nodes": [
    {
      "id": "Level00",
      "display_name": "First Steps",
      "description": "Welcome to the adventure!",
      "order": 1,
      "thumbnail": "res://content/thumbnails/Level00.png",
      "difficulty": 1,
      "estimated_time": "2-3 min",
      "rewards": ["Movement Master"],
      "unlock_requirements": {},
      "theme_color": "#4CAF50"
    }
  ]
}
```

Notes:
- Unlock rules supported now: `previous_level`, `min_score`.
- Additional fields like `deaths_max`, `relic_count` are planned but not enforced yet.

## Persistence
- Per-level data via `Persistence.get_level_completion(level_id)` for score, hearts, gems, completion.
- Unlock checks are performed in `LevelMapPro.gd` using `unlock_requirements` + saved data from Persistence.

## Dev Mode & Cheat
- `map_config.dev_mode.unlock_all`: unlock all in the selector (display-only, non-persistent).
- `map_config.dev_mode.show_debug_info`: shows a header Dev button (DEV: ON/OFF) to toggle unlock-all.
- Cheat: press `0` key 5 times quickly on the Level Map to enable the same unlock-all behavior. Plays `ui_level_unlock` SFX and refreshes the grid.

## Thumbnails
- Preloaded constants in `LevelMapPro.gd` for Level00/Level01/Level02/Level_GiantBoss for export safety.
- When adding levels, either add a preload or adjust loader logic to include the new thumbnail.

## Scene Flow
- Selecting a card sets `Game.current_level`, triggers a brief glitch effect, resets to dimension A, then loads `res://levels/{ID}.tscn` via `change_scene_to_file`.
- Back button and Esc/Pause return to `ui/MainMenu.tscn` with the same transition.

## Visual Customization
- Card size and grid columns come from config; LevelMapPro adapts card width to viewport.
- Status colors: white (unlocked), dimmed (locked), brightened (completed), golden (perfect).
- Hearts row uses heart textures to show latest `hearts_remaining` or placeholder when unknown.

## Performance
- Preloads and avoids export-time file checks for robustness.
- Smooth tweens for hover/focus; minimal idle processing.

## Future Enhancements
- [ ] Async thumbnail loading
- [ ] Localization of labels and requirement strings
- [ ] Accessibility improvements (screen reader hints)
- [ ] Mobile refinements (touch scrolling, bigger hit areas)

This Level Map matches the current implementation and data schema, and is ready for extension with more levels and rules.
