# Level Completion System

This document describes the comprehensive level completion system with explosion effects, progression tracking, and level map navigation.

## 🎉 Level Completion Flow

### 1. **Completion Detection**
- Player reaches the "Finish" section marker
- Level completion is triggered automatically
- Timer stops and final stats are calculated

### 2. **Explosion Effect**
- Large celebration explosion at player position (150 radius, non-damaging)
- Golden screen flash effect (0.5 seconds)
- Screen shake for impact
- Celebration particle burst (50 particles)
- "Level Complete" sound effect
- 1.5 second delay for visual impact

### 3. **Results Screen**
- Shows level completion statistics:
  - **Level Name**: Themed display name
  - **Completion Time**: MM:SS.MS format
  - **Hearts Remaining**: X/5 with color coding
  - **Hidden Gems**: X/Y with collection status
  - **Final Score**: Calculated with bonuses
- **Performance Colors**:
  - 🟢 Green: 4-5 hearts remaining
  - 🟡 Yellow: 2-3 hearts remaining  
  - 🔴 Red: 0-1 hearts remaining
  - 🟡 Gold: Perfect gem collection
  - 🔵 Cyan: Some gems found
  - ⚫ Gray: No gems found

### 4. **Navigation Options**
- **🔄 Retry Level**: Restart same level with full hearts
- **🗺️ Level Map**: Return to level selection map
- **🏠 Main Menu**: Return to main menu

## 🗺️ Level Map System

### **Vertical Progression**
Levels are arranged from bottom to top, representing climbing difficulty:

```
☁️  LEVEL 03: SKY REALM        (Advanced)
    ↑ Unlock: Complete Level 02
    
🏭  LEVEL 02: INDUSTRIAL ZONE   (Intermediate)  
    ↑ Unlock: Complete Level 01
    
🌲  LEVEL 01: FOREST ADVENTURE  (Beginner)
    ↑ Unlock: Complete Tutorial
    
🎮  TUTORIAL: LEARN THE BASICS  (Always Available)
```

### **Level Status Display**
Each level shows:
- **🔒 Locked**: Gray button, "Complete previous level to unlock"
- **🆕 Available**: Cyan text, "Not completed yet - ready to play!"
- **✅ Completed**: Performance-based colors showing best stats
- **🏆 Perfect**: Gold highlighting for perfect completion

### **Statistics Tracking**
For each completed level:
- **⏱️ Best Time**: Fastest completion time
- **💎 Hidden Gems**: Gems found / Total gems
- **❤️ Best Hearts**: Most hearts remaining at completion
- **🏆 Best Score**: Highest score achieved

## 💾 Persistence System

### **Completion Data Structure**
```gdscript
{
    "level_name": "Level01",
    "completion_time": 45.67,
    "hearts_remaining": 4,
    "gems_found": 1,
    "total_gems": 1,
    "score": 2150,
    "completed": true,
    "timestamp": 1234567890
}
```

### **Best Performance Logic**
New completion is considered "better" if:
1. **More hearts remaining** (primary)
2. **More gems found** (secondary)  
3. **Faster completion time** (tertiary)

### **Progress Unlocking**
- **Tutorial**: Always available
- **Level 01**: Unlocked after Tutorial completion
- **Level 02**: Unlocked after Level 01 completion
- **Level 03**: Unlocked after Level 02 completion

## 🎮 Health System Integration

### **Heart Reset**
- **New Level Start**: Always begin with 5/5 hearts
- **Level Retry**: Reset to full health
- **Death Zones**: Lose 1 heart when falling
- **Game Over**: When 0 hearts remain

### **Heart Tracking**
- Hearts remaining at completion are saved
- Displayed in level map as performance indicator
- Color-coded for quick visual assessment

## 🏆 Scoring System

### **Base Scores**
- **Tutorial**: 500 points
- **Level 01**: 1000 points  
- **Level 02**: 1500 points
- **Level 03**: 2000 points

### **Bonus Calculations**
- **Time Bonus**: Faster completion = more points
- **Heart Bonus**: 100 points per heart remaining
- **Gem Bonus**: 100-200 points per gem (varies by level)
- **Perfect Bonus**: 250-1000 points for 100% completion

### **Performance Tiers**
- **🥇 Gold**: 2500+ points (perfect performance)
- **🥈 Silver**: 2000+ points (excellent)
- **🥉 Bronze**: 1500+ points (good)
- **✅ Complete**: Any completion

## 🎯 Tutorial System

### **Tutorial Level**
- **Purpose**: Teach basic mechanics
- **Elements**: Movement, jumping, double jump, collectibles, hazards
- **Completion**: Required to unlock Level 01
- **Simplified**: Lower difficulty and scoring

### **Learning Objectives**
- **Movement**: WASD controls
- **Jumping**: Space for jump, double jump mechanics
- **Collection**: Orange fruits and purple gems
- **Hazards**: Gray spikes and red death zones
- **Completion**: Reach finish marker

## 🔧 Debug Features

### **Debug Toggle**
- **F12**: Toggle debug borders during gameplay
- **Development**: Borders enabled by default
- **Production**: Easily disabled with single flag

### **Level Testing**
- **AllLevelsDemo.tscn**: Comprehensive feature showcase
- **Individual Levels**: Each level can be tested independently
- **Completion Testing**: Full completion flow testing

## 🚀 Deployment Configuration

### **Production Settings**
```gdscript
# In DeploymentConfig.gd
const PRODUCTION_BUILD = true  # Disable all debug features
```

### **Debug Removal**
- Debug borders automatically hidden
- Debug labels removed
- Console logs minimized
- Performance optimized

This system provides a complete, professional level progression experience with visual feedback, performance tracking, and smooth navigation between levels!