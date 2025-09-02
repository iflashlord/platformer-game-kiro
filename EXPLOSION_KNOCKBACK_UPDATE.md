# Explosion Knockback System Update

## Overview
Enhanced the Explosion system with immediate player knockback when colliding with bombs, providing realistic physics-based reactions.

## 🎯 **New Features**

### **1. Immediate Collision Knockback**
When a bomb directly collides with the player:
- **Instant Response**: Player is thrown away immediately on contact
- **Power-Based Force**: Knockback strength scales with bomb power:
  - **LOW**: 320 force (0.8x multiplier)
  - **MEDIUM**: 400 force (1.0x multiplier) 
  - **HIGH**: 560 force (1.4x multiplier)
- **Directional Physics**: Player is thrown in the correct direction from bomb to player position
- **Upward Component**: Adds 50% upward force for dramatic arc effect

### **2. Explosion Radius Knockback**
When player is caught in explosion radius:
- **Distance-Based**: Force decreases with distance from explosion center
- **Weaker Force**: Base 250 force (weaker than direct collision)
- **Power Scaling**: Same multipliers as collision but reduced base
- **Additive Effect**: Adds to existing player velocity instead of replacing

### **3. Smart Direction Calculation**
- **Safety Checks**: Handles edge case when player and bomb are at same position
- **Default Direction**: Uses Vector2(1, -0.5) as fallback (right and up)
- **Normalized Vectors**: Ensures consistent force application

### **4. Multiple Player Types Support**
The system intelligently detects player type and applies knockback via:
- **`apply_knockback()`** method (preferred)
- **`set_velocity()`** method for CharacterBody2D
- **Direct `velocity`** property assignment
- **`apply_central_impulse()`** for RigidBody2D players

### **5. Visual Feedback**
- **Screen Shake**: Additional camera shake on direct collision
- **Force Scaling**: Shake intensity scales with knockback force
- **Debug Logging**: Comprehensive feedback for knockback forces and directions

## 🔧 **Technical Implementation**

### **Collision Response Flow**
1. Player touches bomb
2. `_throw_player_away()` calculates and applies knockback
3. 0.05 second delay allows knockback to register
4. Bomb explodes with normal effects
5. If player still in radius, `_apply_explosion_knockback()` adds additional force

### **Force Calculation**
```gdscript
# Direct Collision
base_force = 400.0 * power_multiplier
upward_boost = base_force * 0.5

# Explosion Radius  
base_force = 250.0 * power_multiplier * distance_factor
upward_boost = base_force * 0.3
```

### **Distance Factor**
```gdscript
distance_factor = 1.0 - min(distance / explosion_radius, 1.0)
# Result: 1.0 at center, 0.0 at edge
```

## 🎮 **Player Experience**

### **Immediate Impact**
- Player feels immediate consequence of touching bomb
- Clear cause-and-effect relationship
- Satisfying physics response

### **Skill Expression**
- Players can use knockback for movement tricks
- Adds risk/reward to getting close to bombs
- Creates dynamic movement opportunities

### **Visual Clarity**
- Clear directional feedback shows impact source
- Screen shake emphasizes impact moment
- Upward arc creates cinematic feel

## 🚀 **Production Quality Features**

- **Error Handling**: Validates player object before applying forces
- **Performance**: Efficient vector calculations with minimal overhead
- **Flexibility**: Works with different player implementations
- **Debug Support**: Comprehensive logging for troubleshooting
- **Safety**: Handles edge cases like zero-distance collisions

## 📊 **Knockback Values**

| Bomb Power | Direct Collision | Max Explosion Force | Upward Boost |
|------------|------------------|-------------------|---------------|
| LOW        | 320              | 150               | 160/45        |
| MEDIUM     | 400              | 200               | 200/60        |
| HIGH       | 560              | 300               | 280/90        |

The explosion system now provides professional-grade physics feedback that enhances player experience with immediate, clear, and satisfying knockback responses!
