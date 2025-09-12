# Player Invincibility System

## Overview
The player now has invincibility frames (i-frames) when taking damage. This prevents the player from taking multiple hits in rapid succession and provides visual feedback during the invincible period.

## Features

### Invincibility Duration
- **Duration**: 3 seconds after taking damage
- **Visual Feedback**: Player sprite blinks (alternates between semi-transparent and fully visible)
- **Damage Immunity**: Player cannot take damage from any source during invincibility

### Visual Effects
- **Blink Frequency**: 0.15 seconds (configurable)
- **Transparency**: Player becomes 30% transparent during blink cycles
- **Restoration**: Player returns to full opacity when invincibility ends

## Implementation Details

### Player Script Changes
- Added invincibility state variables
- Added `handle_invincibility(delta)` function called in `_physics_process`
- Added `take_damage(amount)` method that handles invincibility checks
- Added `start_invincibility()` and `end_invincibility()` methods
- Added `is_player_invincible()` getter method

### Damage Source Updates
All damage sources now use the player's `take_damage()` method instead of directly calling `HealthSystem.lose_heart()`:

- **PatrolEnemy**: Updated `damage_player()` method
- **DangerousSpike**: Updated `damage_player()` method  
- **TNTCrate**: Updated explosion damage to use `take_damage()`
- **EnemyCharger**: Already used `take_damage()` method
- **RollingBoulder**: Already used `take_damage()` method

## Usage

### For Players
- When you take damage, you'll see your character blink for 3 seconds
- During this time, you cannot take additional damage from enemies or hazards
- Use this time to escape dangerous situations

### For Developers
- All damage sources should use `player.take_damage(amount)` instead of direct HealthSystem calls
- The system automatically handles invincibility checks and visual feedback
- Invincibility duration and blink frequency can be adjusted in the Player script

## Testing
Use the `InvincibilityTest.tscn` level to test the system:
- Walk into enemies or spikes to trigger damage
- Observe the 3-second blinking effect
- Verify that additional damage is blocked during invincibility
- Press SPACE for manual damage testing

## Configuration
Adjust these variables in the Player script:
- `invincibility_duration`: How long invincibility lasts (default: 3.0 seconds)
- `blink_frequency`: How fast the player blinks (default: 0.15 seconds)