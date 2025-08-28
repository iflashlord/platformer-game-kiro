# Hint System Usage Guide

The hint system allows you to display contextual messages to players when they enter specific areas in your levels.

## Components

### HintArea (actors/HintArea.tscn)
An Area2D that triggers hint messages when the player collides with it.

**Properties:**
- `hint_message` (String): The main message to display
- `hint_title` (String): Optional title for the hint (leave empty to hide)
- `auto_hide_delay` (float): Seconds before auto-hiding (0 = manual hide only)
- `show_once_only` (bool): If true, hint only shows the first time

### HintDisplay (ui/HintDisplay.tscn)
The UI component that displays the hint messages. Automatically included in GameUI.

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

### Example Usage

```gdscript
# In your level script, manually trigger a hint
$WelcomeHint.trigger_hint()

# Reset a one-time hint to show again
$TutorialHint.reset_shown_state()
```

## Visual Customization

The HintDisplay can be customized by editing `ui/HintDisplay.tscn`:
- Change background style in the Panel's theme override
- Modify text appearance in the Label nodes
- Adjust positioning and size
- Add animations via the AnimationPlayer

## Testing

Use the example level `examples/Level_HintSystem.tscn` to test the hint system:
- Walk around to trigger different hints
- See auto-hide behavior
- Test one-time hint functionality

## Integration

The system uses EventBus signals:
- `hint_requested(message: String, title: String)`
- `hint_dismissed()`

This allows for easy integration with other UI systems or custom hint displays.