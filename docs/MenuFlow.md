# Menu Flow - HTML5 Platformer

## Game Flow Overview

```
Game Start
    ↓
Main Menu (MainMenu.tscn)
    ├── PLAY → Level00 (Tutorial)
    ├── LEVEL SELECT → LevelSelect.tscn
    │   ├── Level List (with unlock status)
    │   ├── PLAY buttons → Load selected level
    │   ├── TIME TRIAL buttons → Load time trial mode
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

### Progressive Unlocks:
1. **CollectibleTest** - Unlocks after CrateTest with min score 50
2. **DimensionTest** - Unlocks after CollectibleTest with min score 75
3. **EnemyGauntlet** - Unlocks after DimensionTest with max 3 deaths
4. **Level01** - Unlocks after EnemyGauntlet with min score 100
5. **Level02** - Unlocks after Level01 with min score 150
6. **Level03** - Unlocks after Level02 with min score 200
7. **Chase01** - Unlocks after Level03 with min score 250 + 3 relics

## Key Features

### Main Menu
- **Responsive Design**: Adapts to different screen sizes
- **Keyboard Navigation**: Arrow keys + Enter/Escape
- **Web Optimization**: Quit button hidden on web platforms
- **Audio Integration**: Plays menu music on startup

### Level Select
- **Visual Progress**: Shows best times and scores
- **Lock Status**: Clear indication of locked/unlocked levels
- **Time Trials**: Separate unlock requirements for speed challenges
- **Refresh Function**: Updates level status without restart

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
4. **Time Trials** → Challenge modes for completed levels

## Technical Implementation

### Scene Management:
- **MainMenu.tscn** - Entry point (set in project.godot)
- **LevelSelect.tscn** - Dynamic level list generation
- **SettingsMenuStandalone.tscn** - Standalone settings interface
- **Level scenes** - Individual level files loaded via LevelLoader

### Data Flow:
- **levels.json** - Level configuration and unlock requirements
- **Persistence system** - Saves progress and settings
- **LevelLoader** - Handles async level loading with progress
- **Audio system** - Manages music and sound effects

### Input Handling:
- **Keyboard**: Arrow keys, Enter, Escape for navigation
- **Mouse/Touch**: Click/tap support for all buttons
- **Gamepad**: Standard gamepad navigation (if connected)

## Customization Options

### Adding New Levels:
1. Create level scene file
2. Add entry to levels.json with unlock requirements
3. Level automatically appears in Level Select

### Modifying Unlock Requirements:
- Edit levels.json unlock_requirements section
- Supports score, time, death count, and custom criteria

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