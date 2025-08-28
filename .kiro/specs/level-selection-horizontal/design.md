# Design Document

## Overview

The horizontal level selection system will transform the current vertical single-column layout into a modern horizontal carousel showing 2.5 level cards at a time. This design provides better space utilization, improved visual appeal, and enhanced navigation experience while maintaining all existing functionality for level unlocking, progress tracking, and activation.

## Architecture

### Layout Structure
```
LevelMapPro (CanvasLayer)
├── Background (ColorRect)
├── UI (Control)
│   ├── Header (VBoxContainer)
│   │   ├── TitleContainer (HBoxContainer)
│   │   └── ProgressContainer (VBoxContainer) - Enhanced
│   ├── LevelsContainer (Control)
│   │   └── HorizontalScrollContainer (ScrollContainer)
│   │       └── LevelGrid (HBoxContainer) - Changed from VBoxContainer
│   └── Footer (HBoxContainer)
└── AnimationPlayer
```

### Key Changes from Current System
1. **Grid Layout**: Change from VBoxContainer to HBoxContainer for horizontal arrangement
2. **Card Sizing**: Resize cards to fit 2.5 cards in viewport (approximately 512px width each)
3. **Scroll Direction**: Change from vertical to horizontal scrolling
4. **Navigation Logic**: Update keyboard navigation for left/right movement
5. **Focus Management**: Implement horizontal focus indicators and smooth scrolling

## Components and Interfaces

### Enhanced LevelCard Class
```gdscript
class LevelCard extends Control:
    # Properties
    var level_id: String
    var level_data: Dictionary
    var level_info: Dictionary
    var is_unlocked: bool = false
    var is_completed: bool = false
    var is_perfect: bool = false
    
    # UI Sizing for 2.5 card layout
    const CARD_WIDTH = 512
    const CARD_HEIGHT = 320
    const CARD_MARGIN = 16
    
    # Enhanced visual feedback
    func set_focused(focused: bool)
    func activate()
    func update_status(unlocked, completed, perfect)
```

### Horizontal Navigation System
```gdscript
# Navigation properties
var selected_index: int = 0
var cards_per_view: float = 2.5
var card_width: int = 512
var card_spacing: int = 16

# Navigation methods
func _navigate_horizontal(direction: int)
func _scroll_to_selected_smooth()
func _update_focus_display()
```

### Enhanced Progress Display
```gdscript
# Progress visualization
func _update_progress_enhanced()
func _create_progress_animations()
func _display_completion_stats()
```

## Data Models

### Level Card Configuration
```json
{
    "card_dimensions": {
        "width": 512,
        "height": 320,
        "spacing": 16,
        "visible_count": 2.5
    },
    "scroll_behavior": {
        "smooth_scrolling": true,
        "scroll_speed": 800,
        "snap_to_cards": true
    },
    "visual_effects": {
        "focus_scale": 1.05,
        "hover_transition": 0.2,
        "completion_glow": true
    }
}
```

### Navigation State
```gdscript
# Navigation state management
var navigation_state = {
    "selected_index": 0,
    "scroll_position": 0.0,
    "is_scrolling": false,
    "last_input_time": 0.0
}
```

## Error Handling

### Level Loading Errors
1. **Missing Scene Files**: Display error message and remain on selection screen
2. **Invalid Level Data**: Skip corrupted level entries and log warnings
3. **Thumbnail Loading Failures**: Generate placeholder thumbnails with level theme colors
4. **Navigation Bounds**: Prevent navigation beyond available levels

### Input Handling Errors
1. **Rapid Input Prevention**: Debounce navigation inputs to prevent rapid scrolling
2. **Focus Recovery**: Restore focus to valid level if current selection becomes invalid
3. **Scroll Boundary Protection**: Prevent scrolling beyond first/last level

### Visual Rendering Errors
1. **Card Sizing Fallbacks**: Use default dimensions if custom sizing fails
2. **Animation Failures**: Gracefully degrade to instant transitions
3. **Theme Loading Issues**: Use built-in colors if custom theme unavailable

## Testing Strategy

### Unit Tests
1. **Level Card Creation**: Test card generation with various level data configurations
2. **Navigation Logic**: Verify horizontal navigation with different input methods
3. **Progress Calculation**: Test progress display with various completion states
4. **Unlock Requirements**: Validate level unlocking logic with different prerequisites

### Integration Tests
1. **Scroll Container Behavior**: Test horizontal scrolling with mouse and keyboard
2. **Level Loading Integration**: Verify level activation connects properly to LevelLoader
3. **Animation Coordination**: Test smooth transitions between navigation states
4. **Input System Integration**: Verify keyboard, mouse, and touch input handling

### Visual Tests
1. **Layout Responsiveness**: Test 2.5 card layout at different screen sizes
2. **Focus Indicators**: Verify visual feedback for selected levels
3. **Progress Display**: Test progress bar and statistics display
4. **Card Status Visualization**: Verify locked/unlocked/completed visual states

### Performance Tests
1. **Smooth Scrolling**: Ensure 60fps during horizontal scrolling animations
2. **Card Rendering**: Test performance with maximum number of level cards
3. **Memory Usage**: Monitor memory consumption during navigation
4. **Thumbnail Loading**: Test async thumbnail loading performance

## Implementation Phases

### Phase 1: Layout Restructure
- Convert VBoxContainer to HBoxContainer
- Implement 2.5 card sizing and spacing
- Update ScrollContainer for horizontal scrolling
- Basic horizontal navigation

### Phase 2: Enhanced Navigation
- Smooth scrolling animations
- Keyboard and mouse input handling
- Focus management and visual feedback
- Scroll-to-selected functionality

### Phase 3: Visual Enhancements
- Improved progress display
- Enhanced card visual effects
- Better completion indicators
- Animation polish

### Phase 4: Integration and Testing
- Level activation integration
- Error handling implementation
- Performance optimization
- Cross-platform testing