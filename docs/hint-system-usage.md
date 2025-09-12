# Hint System Usage Guide

The hint system displays contextual messages triggered by in-level areas or programmatically via the global EventBus. It supports narration audio, dimension layers (A/B/Both), auto-hide, and one-time hints.

## Components

### HintArea (actors/HintArea.tscn)
An Area2D that triggers hint messages when the player collides with it. Supports dimension layers and optional narration.

**Properties:**
- `hint_message` (String): The main message to display
- `hint_title` (String): Optional title for the hint (leave empty to hide)
- `narration_audio` (String): Optional narration clip name (in `audio/narration/*.ogg|.wav`)
- `narration_limit_enabled` (bool): Limit how many times narration plays
- `narration_max_plays` (int): Max narration plays if limit enabled
- `auto_hide_delay` (float): Seconds before auto-hiding (0 = manual hide only)
- `show_once_only` (bool): If true, hint only shows the first time
- `target_layer` (Enum: `A` | `B` | `Both`): Which dimension layer activates this hint
- `auto_register_layer` (bool): Auto-adds a LayerObject for DimensionManager integration

### HintDisplay (ui/HintDisplay.tscn)
The UI component that displays the hint messages. Automatically included in GameUI. Dynamically resizes to content and animates in/out.

## Usage

### Basic Setup
1. Add a HintArea to your level scene
2. Set the `hint_message` property in the inspector
3. Optionally set a `hint_title`
4. Position and resize the collision area as needed

### Advanced Options
- **Auto-hide**: Set `auto_hide_delay` to automatically hide after X seconds
- **One-time hints**: Enable `show_once_only` for tutorial messages
- **Manual triggering**: Call `trigger_hint()` on the HintArea from code
- **Dimension layers**: Set `target_layer` to `A`, `B`, or `Both`. When not active in current dimension, the hint won’t show; if the dimension changes while showing, it auto-hides.
- **Narration**: Set `narration_audio` to play a narration clip; background music ducks automatically and restores on stop. Use `narration_limit_enabled` + `narration_max_plays` to avoid repetition.

### Example Usage

```gdscript
# In your level script, manually trigger a hint
$WelcomeHint.trigger_hint()

# Reset a one-time hint to show again
$TutorialHint.reset_shown_state()

# Force-hide a currently showing hint (e.g., during cleanup)
$DangerHint.force_hide_hint()

# Programmatic/global hint without a HintArea (e.g., from any script)
EventBus.hint_requested.emit("Cheat Activated: All levels unlocked!", "DEV MODE")
```

## Visual Customization

The HintDisplay can be customized by editing `ui/HintDisplay.tscn`:
- Change background style in the Panel's theme override
- Modify text appearance in the Label nodes
- Adjust positioning and size
- Add animations via the AnimationPlayer
- Configure dynamic size bounds in `ui/HintDisplay.gd` exports: `min_width`, `max_width`, `min_height`, `max_height`, `padding`.

## Testing
- Add a `HintArea.tscn` to any level and set a visible collider.
- Verify: entering shows hint; exiting hides it; auto-hide works if delay > 0.
- Switch dimensions (F) to confirm layer-aware behavior (`target_layer`).
- Set `narration_audio` to confirm narration plays and music ducks.

## Integration

The system uses EventBus signals:
- `hint_requested(message: String, title: String)`
- `hint_dismissed()`

This allows for easy integration with other UI systems or custom hint displays.

Notes:
- `actors/HintArea.gd` emits `EventBus.hint_requested`/`hint_dismissed` on enter/exit.
- `ui/HintDisplay.gd` listens to these signals, resizes to content, and animates display.
- Narration is handled via `systems/Audio.gd` (`play_narration`, `stop_narration`) with temporary music ducking.
