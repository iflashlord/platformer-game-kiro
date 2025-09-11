# MainMenu Production Features

## Overview
The MainMenu implements production-ready UX with clean navigation, platform-aware behavior, and polish aligned to the current codebase.

## New Features

### Visual Design
- **Theme**: Consistent custom theme via `ui/MainMenuTheme.tres`.
- **Responsive layout**: Adapts to desktop and web viewports.
- **Animations**: Fade-in intro; hover/focus tween scaling and tint.
- **Glitch transition**: Optional menu glitch effect via `DimensionManager`.

### Navigation & Input
- **Keyboard/gamepad**: Full focus navigation; Enter/Accept triggers focused button.
- **Quick keys**: `Esc` triggers Quit (desktop), `pause` opens Options.
- **Focus feedback**: Hover/focus SFX (`ui_hover`, `ui_focus`) and visual highlights.

### Platform Optimization
- **Web**: Quit button hidden; control hints reflect keyboard on web.
- **Mobile**: Touch hint text when `OS.has_feature("mobile")`.
- **Version label**: Reads from `ProjectSettings.application/config/version`.

### Audio Integration
- **Intro → Menu music**: Plays `game_intro`, then `menu_theme` loop.
- **UI SFX**: `ui_select` on press; hover/focus cues with fallback if SFX missing.

## Menu Structure

### Main Buttons (as implemented)
1. **▶ PLAY / CONTINUE** — Single button; label switches to “Continue” if a save exists.
2. **🗺 LEVEL SELECT** — Opens the Level Map Pro screen.
3. **⚙ OPTIONS** — Opens standalone settings (with reset progress).
4. **📜 CREDITS** — Opens credits.
5. **✕ QUIT** — Exits game (hidden on web platforms).

Notes:
- A separate “Continue” button exists in the scene but is hidden at runtime.
- An Achievements screen exists in the repo but is not wired in the main menu yet.

### Additional Features
- **Version Display**: `v{version}` in footer.
- **Platform Info**: Web/desktop control hints.
- **Save Detection**: Toggles Play label and focus based on persistence.
- **Scene Transitions**: Direct `change_scene_to_file` with optional glitch effect.

## Technical Implementation

### Files Structure
```
ui/
├── MainMenu.tscn              # Main menu scene
├── MainMenu.gd                # Main menu logic
├── MainMenuTheme.tres         # Theme resource
├── LevelMapPro.tscn/.gd       # Level select
├── SettingsMenuStandalone.tscn/.gd  # Options screen
├── CreditsMenu.tscn/.gd       # Credits screen
├── LoadingScreen.tscn/.gd     # Optional loading transition
└── MenuNavigationHelper.gd    # Optional navigation utilities
```

### Key Classes
- `MainMenu` — Controller: setup, platform hints, button callbacks, SFX.
- `SettingsMenuStandalone` — Settings + reset progress action.
- `CreditsMenu` — Scrollable credits with back to menu.
- `LevelMapPro` — Level selection and unlocks.
- `LoadingScreen` — Optional transition scene.
- `MenuNavigationHelper` — Helper utilities (not required by MainMenu).

## Integration Points

### Save System Integration
```gdscript
var has_save_data := false
if Persistence and Persistence.has_method("has_save_data"):
    has_save_data = Persistence.has_save_data()

# Single Play/Continue button behavior
if has_save_data:
    play_button.text = "  Continue"
else:
    play_button.text = "  Play"

# Separate Continue button (present but hidden)
continue_button.visible = false
```

On press:
```gdscript
func _on_play_pressed():
    if has_save_data and Persistence.has_method("get_next_recommended_level"):
        var target = Persistence.get_next_recommended_level()
        change_scene_to_file(target)
    else:
        change_scene_to_file("res://levels/Level00.tscn")
```

### Audio System Integration
```gdscript
# Intro → menu loop
Audio.play_music("game_intro", false)
await get_tree().create_timer(4.0).timeout
Audio.play_music("menu_theme", true)

# UI SFX with fallback
_play_ui_sound("ui_select")    # press
_play_ui_sound("ui_hover")     # hover
_play_ui_sound("ui_focus")     # focus
```

### Scene Routes
- Play/Continue → `res://levels/Level00.tscn` (or next recommended level)
- Level Select → `res://ui/LevelMapPro.tscn`
- Options → `res://ui/SettingsMenuStandalone.tscn`
- Credits → `res://ui/CreditsMenu.tscn`
- Quit → `get_tree().quit()` (desktop only in practice)

## Customization Options

### Theme Customization
Edit `ui/MainMenuTheme.tres` to modify:
- Button styles and colors
- Font sizes and families
- Border radius and effects
- Hover and focus states

### Layout Customization
Modify `ui/MainMenu.tscn` to adjust:
- Button arrangement and spacing
- Screen layout and proportions
- Background effects and colors
- Animation timing and effects

### Content Customization
Update scripts to modify:
- Menu options and navigation
- Save/continue rules (`Persistence` helpers)
- Credits information
- Loading/transition behavior

## Best Practices

### Performance
- Efficient signal connections and minimal idle work
- Tween-based hover/focus for lightweight effects
- Web-optimized assets per project settings

### Accessibility
- Full keyboard navigation and focus visuals
- Clear audio cues on hover/focus/press
- High-contrast theme support via theme overrides

### Maintainability
- Modular files and single-responsibility scripts
- Optional helpers (Navigation, Loading) to keep MainMenu simple
- Clear scene route constants for easy updates

## Future Enhancements

### Planned Features
- [ ] Wire Achievements into the main menu
- [ ] Animated/background vignette variants
- [ ] Cloud save sync and profiles
- [ ] Localization (multi-language UI)
- [ ] Advanced graphics/options presets

### Extension Points
- Custom theme variants and SFX packs
- Alternative transitions (shader-based, wipes)
- Dynamic content (e.g., news panel, tips)

## Testing

### Manual Testing Checklist
- [ ] Play label switches to “Continue” when a save exists
- [ ] Hover/focus visual + audio cues trigger
- [ ] Web hides Quit; desktop shows Quit
- [ ] Keyboard/gamepad focus navigation works
- [ ] Scene routes open correct targets
- [ ] Intro → menu music sequence plays

### Automated Testing
- Unit tests for route selection and label toggling
- Integration tests for persistence detection
- Smoke tests for platform differences (Web/Desktop)

## Deployment Notes

### Web Deployment
- Quit button automatically hidden
- Touch hints shown on mobile feature
- Optimized loading (see WebOptimization.md)

### Desktop Deployment
- Full feature set available
- Native window controls and exit flow
- High DPI support per project settings

This MainMenu reflects current behavior in `ui/MainMenu.gd` and is ready for production with clear paths for future enhancements.
