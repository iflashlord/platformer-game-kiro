# Glitch Dimension - Project Overview

## Project Configuration

### Basic Information
- **Name**: Glitch Dimension
- **Version**: 1.0.0
- **Engine**: Godot 4.4
- **Target Platform**: Web (HTML5) with desktop exports
- **Resolution**: 1280x720 (16:9 aspect ratio)
- **Renderer**: GL Compatibility (optimal web support)

### Current Highlights
- **Dimension Flip**: Layer A/B switching with FX and audio.
- **Tight Platforming**: Coyote time, jump buffer, variable/double jump.
- **Level Select (Pro)**: Data‑driven level map with unlock rules, cards, and thumbnails.
- **Boss Battle**: Giant Boss with dedicated health UI.
- **Saves & Progress**: Cross‑platform persistence (web/local file) with per‑level stats.
- **Pause & Scene Flow**: Central pause manager and scene transitions.
- **Touch Ready**: On‑screen controls for web/mobile.
- **Analytics (offline)**: Local gameplay/UI/performance event logging.

## Project Structure

### Core Systems (`systems/`)
- `Game.gd` — Game state, scoring, attempts.
- `LevelLoader.gd` — Async scene loading.
- `SceneManager.gd` — Scene transitions.
- `PauseManager.gd` — Pause overlay + flow.
- `Audio.gd` — Master/Music/SFX buses, SFX pool, volume persistence.
- `FX.gd` — Screen shake, flashes, hit‑stop.
- `DimensionManager.gd` — Dimension switching feedback and rules.
- `Respawn.gd` — Checkpoints and respawn.
- `Persistence.gd` — Profiles, level completion, stats.
- `LevelCompletion.gd` — Completion flow and effects.
- `Analytics.gd` — Local event log (`user://analytics_log.json`).
- `ObjectPool.gd` — Reuse effects/objects.
- `HealthSystem.gd`, `GameTimer.gd`, `EventBus.gd`, `PerformanceMonitor.gd` — Support systems.

### Actors (`actors/`)
- `Player.*` — Movement, double jump, stomp, i‑frames.
- `LevelPortal.*` — Exit/complete level.
- `Collectible.*` (`CollectibleFruit`), `CollectibleGem.*`, `HiddenGem.*` — Scoring and secrets.
- `InteractiveCrate.*`, `BounceCrate.*` — Breakable/interactive objects.
- `Spike.*`, `DangerousSpike.*`, `DeathZone.*` — Hazards.
- `JumpPad.*`, `DynamicPlatform.*`, `LayerPlatform.*` — Traversal.
- `FlyingEnemy.*` — Patrol/chase enemy with stomp interaction.
- `GiantBoss.*` — Multi‑phase boss encountered in final level.

### UI System (`ui/`)
- `MainMenu.tscn/gd` — Main menu and navigation.
- `LevelMapPro.tscn/gd` — Professional level select.
- `PauseMenu.tscn/gd` — Pause overlay and actions.
- `LevelResults.tscn/gd` — Completion summary with continue options.
- `SettingsMenuStandalone.tscn/gd` — Settings + reset progress.
- `AchievementsMenu.tscn/gd` — Achievements UI (early version).
- `TouchControls.tscn/gd` — Mobile/web controls.
- `GameHUD.tscn/gd` — In‑game HUD (health, pause button).
- `BossHealthUI.tscn/gd` — Boss fight UI.

### Levels (`levels/`)
Playable levels are defined by scripts/scenes and the data‑driven map (`data/level_map_config.json`).
- `Level00` — “First Steps” — order 1 — difficulty 1 — est 2–3 min — unlock: none.
- `Level01` — “Mystic Realms” — order 2 — difficulty 2 — est 4–5 min — unlock: previous `Level00`.
- `Level02` — “Parallel Worlds” — order 3 — difficulty 3 — est 5–7 min — unlock: previous `Level01`, min_score 100.
- `Level_GiantBoss` — “The Giant’s Last Stand” — order 4 — difficulty 5 — est 8–12 min — unlock: previous `Level02`, min_score 10.

### Audio (`audio/`)
- `sfx/default_bus_layout.tres` — Audio bus configuration (Master/Music/SFX).
- `music/` — Background music.
- `sfx/` — Sound effects and UI sounds.
- `narration/` — Narration/hints (ducking supported in code).

### Web Export (`web-dist/`)
- `index.html`, `.js`, `.wasm`, `.pck` — Prebuilt web export bundle.
- Static headers and caching via `vercel.json`.

## Input System

### Keyboard Controls
- **WASD/Arrow Keys** — Movement
- **Space/W** — Jump
- **F** — Dimension flip
- **ESC** — Pause
- **R** — Restart level

### Touch Controls (Mobile)
- **Left/Right buttons** — Movement with hold‑to‑repeat
- **Jump button** — Jump action
- **DIM button** — Dimension flip
- Auto‑detected on touch devices

## Audio Architecture

### Bus Structure
- **Master** — Overall volume control
- **Music** — Background music bus
- **SFX** — Sound effects bus

### Features
- SFX player pool for performance
- Runtime volume control with persistence
- Lightweight music/narration handling
- Cross‑platform audio support

## Performance Optimizations

### Object Pooling
- Particle systems and temporary FX
- Debris and reusable objects
- Collectibles and transient nodes

### Rendering
- Texture compression for web
- Efficient collisions and grouping
- Layer‑based culling and dimension masks

### Memory & Loading
- Resource caching and cleanup
- Async scene loading via `LevelLoader`
- Save/profile data kept minimal

## Level Progression System

### Data‑Driven Unlocks (`data/level_map_config.json`)
- Per‑level `unlock_requirements` (previous level, min score, etc.).
- Level card visuals (title, color, thumbnail, difficulty, time).
- Optional dev mode flags (`unlock_all`, `show_debug_info`).

### Level Types
- **Tutorial** — Introductory mechanics (Level00).
- **Standard** — Progressive challenges (Level01–02).
- **Boss** — Final fight (Level_GiantBoss).

## Web Deployment

### Export Configuration
- HTML5 optimized (GL Compatibility).
- Touch and keyboard input.
- Responsive canvas.

### Deployment
- Export to `web-dist/` and deploy (e.g., Vercel).

## Development Tools

### Testing Scenes
- `systems/AudioTest.tscn` — Audio system checks.
- `systems/PerformanceTest.tscn` — Performance monitoring.
- `ui/TouchControlsTest.tscn` — Touch input testing.

### Documentation
- `docs/LevelMapConfig.md` — Level map schema and behavior.
- `docs/PortalSystem.md` — Portals and completion flow.
- `docs/MainMenu_Features.md` — Main menu details.
- `docs/PauseSystem_Features.md` — Pause system behavior.
- `docs/WebOptimization.md` — Web build guidance.
- `docs/DEPLOYMENT_GUIDE.md` — Deployment steps.
- `docs/AssetChecklist.md`, `docs/Assets.md` — Asset requirements.

## Asset Requirements

### Textures Needed
- Player/enemy sprites (generally 32×32 tiles)
- Collectibles and gems (16×16)
- Hazards and crates (32×32)
- UI elements/buttons and level thumbnails

### Audio Needed
- Background music tracks
- Jump/land, collect, portal, UI SFX
- Ambient/narration where applicable

### Icons Needed
- Game icon, PWA icons, splash, favicon

## Quality Assurance

### Testing Checklist
- [ ] All levels load without errors
- [ ] Input works on keyboard and touch
- [ ] Audio buses and volumes function
- [ ] Save/load and unlocks behave correctly
- [ ] Performance meets 60 FPS target
- [ ] Web deployment loads and plays

### Performance Targets
- **Frame Rate**: 60 FPS on target devices
- **Memory Usage**: Under 1 GB RAM
- **Loading Time**: Under 10 seconds initial load
- **File Size**: Under 50MB total download

## Deployment Status

### Ready for Production
✅ Core gameplay mechanics
✅ Level progression system
✅ Audio and visual effects
✅ Cross-platform saves
✅ Web optimization
✅ Web deployment configured
✅ Documentation complete

### Pending Assets
⏳ Final artwork and sprites
⏳ Music and sound effects
⏳ Icon and branding assets
⏳ Localization (if needed)

The project is feature-complete and ready for asset integration and final deployment.
