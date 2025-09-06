# Enemy Stomping System

## Overview
Players can now defeat enemies by jumping on top of them, similar to classic platformer games like Super Mario Bros. This provides an offensive mechanic and rewards skilled movement.

## Features

### Stomping Mechanics
- **Activation**: Player must be falling with downward velocity > 50 pixels/second
- **Detection**: Collision normal must point upward (player on top of enemy)
- **Effect**: Instantly defeats most enemies (999 damage)
- **Bounce**: Player bounces upward with configurable velocity (-300 by default)
- **Jump Reset**: Restores one jump for combo potential

### Visual & Audio Feedback
- **Screen Flash**: Yellow flash on successful stomp
- **Screen Shake**: 100ms shake effect
- **Particle Effect**: Landing particles at stomp location
- **Player Squash**: Player sprite squashes on impact
- **Enemy Squash**: Enemy gets squashed animation before disappearing
- **Score Text**: "  +[points]" in orange text

### Score System
- **Points Awarded**: Same as enemy's normal point value
- **Score Display**: Special "+points" prefix on floating score text
- **Game Integration**: Points automatically added to player's score

## Implementation Details

### Player Script Changes
- Added `stomp_bounce_velocity` and `stomp_detection_threshold` exports
- Added `handle_enemy_stomping()` function in physics process
- Added `stomp_enemy()` method for stomping logic
- Added `_handle_stomp_effects()` for visual/audio feedback

### Enemy Script Changes
- Modified collision detection to distinguish stomps from side hits
- Added `enemy_stomped` signal
- Updated `take_damage()` to accept `from_stomp` parameter
- Enhanced `defeat()` method with stomp-specific effects
- Added squash animation for stomped enemies

### Collision Logic
```gdscript
# In Player: Check if landing on top
if collision_normal.y < -0.7:  # Normal pointing up
    stomp_enemy(collider)

# In Enemy: Avoid damage if being stomped
if player_velocity.y > 50 and collision_normal.y > 0.7:
    # Don't damage player, let player handle stomp
    continue
```

## Usage

### For Players
1. **Jump on enemies** from above to stomp them
2. **Gain points** equal to the enemy's value
3. **Bounce upward** to chain stomps or reach higher platforms
4. **Side collisions** still cause damage and trigger invincibility

### For Level Designers
- Place enemies near platforms for easy stomping access
- Use stomping as a way to reach higher areas
- Consider enemy placement for combo opportunities

## Configuration

### Player Settings (in Player.gd)
- `stomp_bounce_velocity`: How high player bounces (-300 default)
- `stomp_detection_threshold`: Minimum fall speed to stomp (50 default)

### Enemy Settings (in PatrolEnemy.gd)
- `points_value`: Points awarded for stomping
- `health`: HP (most enemies die in one stomp)

## Testing
Use `InvincibilityTest.tscn` (now renamed to Combat Test):
- Jump on enemies from platforms to test stomping
- Walk into enemies from side to test damage/invincibility
- Observe bounce effect and score display
- Test combo stomping between multiple enemies

## Compatibility
- Works with all enemies that inherit from PatrolEnemy
- Compatible with existing invincibility system
- Integrates with existing score and effects systems
- Maintains backward compatibility with non-stomping damage sources