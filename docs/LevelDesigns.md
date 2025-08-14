# Level Design Overview

This document outlines the unique design themes and elements for each level in the game.

## Debug System

### Debug Borders
- **Toggle Key**: F12 (debug_toggle)
- **Purpose**: Shows colored borders around all interactive elements for development
- **Easy Disable**: Set `DebugSettings.show_debug_borders = false` for deployment
- **Colors**:
  - 🟢 **Player**: Green border - main character
  - 🔴 **Enemies**: Red border - dangerous entities
  - 🟠 **Collectibles**: Orange border - fruits/items to collect
  - 🟣 **Hidden Gems**: Purple border - special collectibles
  - ⚫ **Hazards**: Gray border - spikes and dangers
  - 🟤 **Interactive**: Brown border - crates and interactive objects

## Level 01: Forest Adventure
**Theme**: Natural forest environment
**Difficulty**: Beginner
**Color Palette**: Earth tones and greens

### Elements:
- **Background**: Deep blue-green (0.15, 0.25, 0.4)
- **Platforms**: Various earth tones for visual variety
- **Enemies**: 1 EnemyPatrol (red)
- **Collectibles**: 4 fruits (apple, banana, cherry, orange)
- **Hidden Gems**: 1 emerald gem
- **Hazards**: 2 spikes
- **Interactive**: 2 crates, 2 flip gates
- **Special**: Section markers for progression

### Scoring:
- Base Score: 1000
- Fruit Bonus: 50 points each
- Gem Bonus: 100 points each
- Perfect Completion: +500 bonus

## Level 02: Industrial Zone
**Theme**: Factory/industrial environment
**Difficulty**: Intermediate
**Color Palette**: Metallic grays and blues

### Elements:
- **Background**: Dark industrial blue (0.15, 0.15, 0.25)
- **Platforms**: Metallic colors (grays, blues, browns)
- **Enemies**: 2 EnemyPatrol + 1 EnemyCharger
- **Collectibles**: 5 industrial parts (gear, bolt, spring, wrench, oil)
- **Hidden Gems**: 2 gems (sapphire, ruby)
- **Hazards**: 3 spikes in clusters
- **Interactive**: 3 crates, 2 flip gates
- **Special**: More challenging enemy placement

### Scoring:
- Base Score: 1500
- Fruit Bonus: 75 points each
- Gem Bonus: 150 points each
- Perfect Completion: +750 bonus

## Level 03: Sky Realm
**Theme**: Clouds and sky environment
**Difficulty**: Advanced
**Color Palette**: Light blues and whites

### Elements:
- **Background**: Sky blue (0.6, 0.8, 1.0)
- **Platforms**: Cloud platforms (semi-transparent whites/blues)
- **Enemies**: 1 EnemyPatrol + 2 EnemyCharger
- **Collectibles**: 6 sky essences (cloud, star, wind, lightning, rainbow, feather)
- **Hidden Gems**: 3 gems (diamond, crystal, star)
- **Hazards**: 2 spikes + 1 rolling boulder
- **Interactive**: 3 crates, 3 flip gates
- **Special**: Highest difficulty with most elements

### Scoring:
- Base Score: 2000
- Fruit Bonus: 100 points each
- Gem Bonus: 200 points each
- Perfect Completion: +1000 bonus

## Design Principles

### Visual Distinction
Each level uses a unique color palette to create distinct atmospheres:
1. **Forest**: Earthy greens and browns
2. **Industrial**: Metallic grays and blues  
3. **Sky**: Light blues and whites

### Progressive Difficulty
- **Level 01**: 1 enemy, 4 collectibles, 1 gem
- **Level 02**: 3 enemies, 5 collectibles, 2 gems
- **Level 03**: 3 enemies, 6 collectibles, 3 gems

### Unique Elements
Each level introduces new challenges:
- **Level 01**: Basic platforming
- **Level 02**: Enemy clusters and industrial hazards
- **Level 03**: Cloud platforms and rolling boulders

## Development Features

### Debug System
- **F12**: Toggle debug borders on/off
- **Visual Feedback**: Colored borders around all interactive elements
- **Easy Deployment**: Single boolean flag to disable all debug features

### Health & Timer Systems
- **5 Hearts**: Player health system
- **Real-time Timer**: Level completion tracking
- **Fall Damage**: Lose heart when falling into death zones
- **Double Jump**: Enhanced movement mechanics
- **No Ground Shake**: Smooth landing experience

### Scoring System
- **Progressive Rewards**: Higher scores for harder levels
- **Completion Bonuses**: Extra points for collecting everything
- **Time Bonuses**: Faster completion = higher scores