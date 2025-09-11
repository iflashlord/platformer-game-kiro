# HintArea Dimension Support

HintArea supports dimension‑aware hints that only appear in specific layers (A/B) of the dimension system, and it integrates optional narration audio with automatic music ducking.

## New Features

### Dimension Support

- **target_layer**: Set which dimension layer the hint belongs to ("A", "B", or "Both").
- **auto_register_layer**: Automatically register with DimensionManager (default: true).
- Hints only trigger when the player is in the matching dimension; switching away auto‑hides active hints.
- "Both" option shows hints in all dimensions.

### Narration Support

- **narration_audio**: Optional audio clip (by name) from `audio/narration/`.
- **narration_limit_enabled** + **narration_max_plays**: Prevent repetitive narration.
- Audio system ducks music while narration plays and restores it on finish.

### Dynamic Hint Display

- **Automatic sizing**: Hint display automatically adjusts size based on content length
- **Configurable bounds**: Set min/max width and height limits
- **Smart text wrapping**: Intelligent text wrapping for longer messages
- **Responsive layout**: Maintains visual appeal regardless of content length

## Usage

### Basic Dimension-Aware Hint

```gdscript
# In the editor or via code
hint_area.target_layer = "A"     # Only shows in dimension A
hint_area.target_layer = "B"     # Only shows in dimension B
hint_area.target_layer = "Both"  # Shows in both dimensions
hint_area.hint_message = "This hint appears based on target_layer setting!"
```

### Dynamic Sizing Configuration

```gdscript
# Configure in HintDisplay
hint_display.min_width = 300.0
hint_display.max_width = 600.0
hint_display.min_height = 80.0
hint_display.max_height = 400.0
```

### Example Scene Setup

```
Level
├── DimensionSwitch (allows player to switch dimensions)
├── HintArea (target_layer = "A")
│   └── hint_message = "Welcome to Dimension A!"
├── HintArea (target_layer = "B")
│   └── hint_message = "You're now in Dimension B!"
└── HintArea (target_layer = "Both")
    └── hint_message = "This appears in both dimensions!"
```

## API Reference

### HintArea New Properties

- `target_layer: String` - Which dimension layer this hint belongs to ("A", "B", or "Both")
- `auto_register_layer: bool` - Automatically register with DimensionManager

### HintArea New Methods

- `set_layer(layer: String)` - Change the dimension layer
- `is_active_in_current_dimension() -> bool` - Check if hint is active

### HintDisplay New Properties

- `min_width: float` - Minimum width for hint display
- `max_width: float` - Maximum width for hint display
- `min_height: float` - Minimum height for hint display
- `max_height: float` - Maximum height for hint display
- `padding: Vector2` - Internal padding for content

## Testing

- Add `actors/HintArea.tscn` to any level; set a visible collider.
- Set `target_layer` to A/B/Both; switch dimension (key `F`) to verify behavior.
- Set `narration_audio` to a valid clip name (e.g., a file in `audio/narration/` without extension) and verify music ducking.
- Configure `auto_hide_delay` to test auto‑hide; confirm `force_hide_hint()` for scripted cleanup.

## Integration Notes

- HintArea automatically integrates with the existing LayerObject system
- No changes needed to existing HintArea instances (they default to layer "A")
- The dimension check happens before triggering hints, ensuring clean behavior
- Dynamic sizing works seamlessly with existing hint animations
- Hints are properly dismissed when player exits hint areas
- Dimension switching automatically hides hints from inactive layers

## Troubleshooting

### Hint Not Hiding When Player Exits

- Check if multiple HintAreas are overlapping
- Verify that `auto_hide_delay` is not interfering with exit behavior
- Use `force_hide_hint()` method for manual cleanup if needed

### Dimension Switching Issues

- Hints automatically hide when their layer becomes inactive
- Use debug output to track hint area state changes
- Check dimension manager integration with `is_active_in_current_dimension()`

## Use Cases for "Both" Dimensions

The "Both" option is perfect for:

- **Tutorial hints**: Basic controls that apply regardless of dimension
- **Universal warnings**: Important safety information
- **Navigation hints**: General movement or interaction guidance
- **Story elements**: Narrative text that should always be visible
- **Debug information**: Development hints that need to be always accessible

### Example Implementation

```gdscript
# Tutorial hint that appears in all dimensions
var tutorial_hint = preload("res://actors/HintArea.tscn").instantiate()
tutorial_hint.target_layer = "Both"
tutorial_hint.hint_message = "Use WASD to move and SPACE to jump!"
tutorial_hint.hint_title = "Basic Controls"

# Dimension-specific puzzle hint
var puzzle_hint_a = preload("res://actors/HintArea.tscn").instantiate()
puzzle_hint_a.target_layer = "A"
puzzle_hint_a.hint_message = "The switch is only visible in this dimension."

var puzzle_hint_b = preload("res://actors/HintArea.tscn").instantiate()
puzzle_hint_b.target_layer = "B"
puzzle_hint_b.hint_message = "The platform appears here in dimension B."
```
