# Menu Flow - Glitch Dimension

## Game Flow Overview

```
Game Start
    ↓
Main Menu (MainMenu.tscn)
    ├── PLAY → Level00 (Tutorial)
    ├── LEVEL SELECT → LevelMapPro.tscn
    │   ├── Level Cards (unlock/score/hearts)
    │   ├── ENTER/Click → Load selected level
    │   └── BACK TO MENU → MainMenu.tscn
    ├── OPTIONS → SettingsMenuStandalone.tscn
    │   ├── Volume Controls (Master/Music/SFX)
    │   ├── Test Sound Button
    │   └── BACK TO MENU → MainMenu.tscn
    └── QUIT → Exit game (hidden on web)
```

## Level Progression

### Unlocked by Default:
- **Level00** (Tutorial) - Always available
- **CrateTest** (Crate Chaos) - Always available

### Progressive Unlocks
Unlock rules are defined in `data/level_map_config.json` and enforced by `systems/Persistence.gd` using:
- `previous_level`
- `min_score`
- `deaths_max`
- `relic_count`

## Key Features

### Main Menu
- **Responsive Design**: Adapts to different screen sizes
- **Keyboard Navigation**: Arrow keys + Enter/Escape
- **Web Optimization**: Quit button hidden on web platforms
- **Audio Integration**: Plays menu music on startup

### Level Select
- **Visual Progress**: Cards show latest/best score and hearts remaining
- **Lock Status**: Clear indication of locked/unlocked levels with requirement overlay
- **Keyboard/Mouse**: Horizontal navigation with focus/hover effects
- **Dev Mode**: Cheat unlock in view (press `0` five times quickly)

### Settings Menu
- **Real-time Audio**: Volume changes apply immediately
- **Test Functionality**: Sound test button for immediate feedback
- **Persistence**: Settings automatically saved
- **Keyboard Support**: Full navigation without mouse

## User Experience Flow

### New Player Experience:
1. **Game starts** → Main Menu appears
2. **Click PLAY** → Tutorial (Level00) loads immediately
3. **Complete tutorial** → CrateTest unlocks automatically
4. **Use LEVEL SELECT** → See progress and choose levels
5. **Unlock progression** → New levels become available

### Returning Player Experience:
1. **Game starts** → Main Menu with familiar interface
2. **LEVEL SELECT** → See all progress and unlocked content
3. **Choose any unlocked level** → Jump straight to preferred content


## Technical Implementation

### Scene Management:
- **MainMenu.tscn** - Entry point (set in project.godot)
- **LevelMapPro.tscn** - Professional level selection view
- **SettingsMenuStandalone.tscn** - Standalone settings interface
- **Level scenes** - Individual levels via `SceneManager`

### Data Flow:
- **data/level_map_config.json** - Level metadata and unlock requirements
- **Persistence** - Saves progress, completions, and settings
- **SceneManager** - Simple scene changes
- **Audio** - Music and SFX

### Input Handling:
- **Keyboard**: Arrow keys, Enter, Escape for navigation
- **Mouse/Touch**: Click/tap support for all buttons
- **Gamepad**: Standard gamepad navigation (if connected)

## Customization Options

### Adding New Levels:
1. Create level scene file
2. Add entry to `data/level_map_config.json` under `level_nodes`
3. Add a thumbnail under `content/thumbnails/`
4. Level appears in Level Map

### Modifying Unlock Requirements:
- Edit `data/level_map_config.json` unlock_requirements section
- Supports previous level, min score, deaths max, relic count

### Styling Changes:
- Modify .tscn files for visual appearance
- Update theme overrides for fonts and colors
- Adjust layout containers for different screen sizes

## Accessibility Features

### Visual:
- High contrast color scheme
- Large, readable fonts
- Clear button states (enabled/disabled)

### Navigation:
- Full keyboard navigation support
- Logical tab order through interface
- Visual focus indicators

### Audio:
- Volume controls for different audio types
- Test functionality for hearing-impaired users
- Audio feedback for important actions

The menu system provides a complete, professional game experience with intuitive navigation and clear progression feedback.
