# Glitch Dimension - Broken Reality

## Overview

A 2D platformer built with Godot 4.4 featuring dimension-shifting, a professional level select with unlocks, and smooth web deployment get inspired from classic platformers like Crash Bandicoot.

## 🎮 Play Online

https://glitch-dimension-broken-reality.behrouz.nl/

## 📚 Docs Quick Links

- Architecture: `docs/Architecture.md`
- Save Data: `docs/SaveData.md`
- Level Map Config: `docs/LevelMapConfig.md`
- Game Config: `docs/GameConfig.md`
- Audio System: `docs/AudioSystem.md`
- Analytics: `docs/Analytics.md`
- Web Optimization: `docs/WebOptimization.md`
- Deployment Guide: `docs/DEPLOYMENT_GUIDE.md`

## ✨ Highlights

- **Dimension Flip**: Switch layers on the fly to solve puzzles and avoid hazards.
- **Tight Platforming**: Coyote time, jump buffering, variable jump, double-jump.
- **Level Select (Pro)**: Polished horizontal card UI with thumbnails, hearts and scores, keyboard/mouse navigation, and unlock rules from data.
- **Progress & Saves**: Cross‑platform persistence (file on desktop, localStorage on web) with best runs and stats.
- **Boss Battle**: Giant Boss encounter with dedicated health UI and mechanics.
- **Touch Ready**: Mobile touch controls for web/mobile builds.
- **Production Systems**: Audio buses + pooling, FX (shake/flash), object pool, event bus, analytics, pause/scene managers.

## 🎯 Controls

- **Move**: `A/D` or Arrow Keys
- **Jump**: `Space` or `W`/Up Arrow
- **Flip Dimension**: `F`
- **Pause**: `Esc`
- **Restart Level**: `R`

Touch controls are available on web/mobile (movement, jump, dimension flip).

### Cheat Code (Level Map)

- On the Level Select screen, press the `0` key five times quickly to unlock all levels (dev unlock; does not modify save data).

## 🧱 Tech Overview

- **Engine**: Godot 4.4 (GL Compatibility renderer for web).
- **Autoloads**: See `project.godot` and `docs/Architecture.md` for global singletons.
- **Input Map**: Declared in `project.godot:[input]` (WASD/arrows, `Space`/`W` jump, `F` flip, `Esc` pause, `R` restart).
- **Persistence**: File on desktop or `localStorage` on web; schema in `docs/SaveData.md`.
- **Data-Driven**: Level map and unlock rules in `data/level_map_config.json`; game tuning in `data/game_config.json`.

## 🗺️ Level Select & Progression

- **Unlock Rules**: Defined in `data/level_map_config.json` (per‑level requirements like previous level, min score, deaths max).
- **Hearts & Scores**: Level cards show latest/best score and hearts remaining from your best completion.
- **Dev Mode**: Optional dev mode can unlock all levels in the selector UI; a simple cheat is available on the map (press `0` five times quickly).
- **Persistence**: Best scores/times, completions, attempts, deaths, and per‑level completion details are tracked in `systems/Persistence.gd`.

Key scenes and scripts:
- `ui/LevelMapPro.tscn` + `ui/LevelMapPro.gd`: Professional level map UI and navigation.
- `systems/Persistence.gd`: Save format, unlock logic, “Reset Everything” support from settings.
- `data/level_map_config.json`: Level metadata, order, thumbnails, unlock rules, visuals.

See `docs/LevelMapConfig.md` for the full schema.

## 🧩 Core Systems

- **Game State**: `systems/Game.gd` signals for pause, restart, scoring, collectibles.
- **Audio**: `systems/Audio.gd` with Master/Music/SFX buses, SFX player pool, runtime volume control, narration ducking.
- **FX**: `systems/FX.gd` for screen shake, flashes, hit-stop.
- **Pause**: `systems/PauseManager.gd` + `ui/PauseMenu.tscn` with resume/restart/level select/main menu.
- **Scene Flow**: `systems/SceneManager.gd` with simple transitions and main routes.
- **Persistence**: Cross‑platform saves, level completions, stats, unlocks; reset via `ui/SettingsMenu.tscn` (“Reset Everything”).
- **Analytics**: `systems/Analytics.gd` batching to a local log (`user://analytics_log.json`) with gameplay/UI/performance events.
- **Object Pool**: `systems/ObjectPool.gd` for performance and memory reuse.

## 🏗️ Project Structure

```
actors/      # Player, enemies (e.g., GiantBoss), collectibles, hazards
systems/     # Core game systems (Audio, FX, Game, Persistence, Pause, Scene, etc.)
ui/          # Menus, HUD, Level Map, Results, Settings, Touch Controls
levels/      # Playable levels and base level script
data/        # Config JSONs (level map, game settings)
audio/       # Music, SFX, narration, bus layout
content/     # Sprites, thumbnails, icons
tools/       # Editor and export helpers (LevelMapEditor, BuildManager, etc.)
docs/        # Feature guides and technical docs
web-dist/    # Prebuilt web export (HTML/JS/WASM/PCK)
vercel.json  # Static headers for web hosting (COEP/COOP, caching)
```

## 🧪 Gameplay & UI Overview

- **Player Movement**: `actors/Player.gd` implements variable jump, coyote time, jump buffer, double-jump, stomp bounce, invincibility frames.
- **Level Base**: `levels/BaseLevel.gd` integrates HUD, health, results (`ui/LevelResults.tscn`) and saves completion data.
- **Main Menu**: `ui/MainMenu.tscn/gd` with platform hints, intro music sequence, and transitions.
- **Boss Fight**: `levels/Level_GiantBoss.tscn` with `ui/BossHealthUI.*`.
- **Touch Controls**: `ui/TouchControls.tscn/gd` for mobile/web.

## 🛠️ Local Development

- **Prerequisites**: Godot 4.4, optional Node.js (for Vercel CLI), Git.
- **Open Project**: `godot project.godot`
- **Run**: Start from the Main Menu or any level (`ui/MainMenu.tscn`, `ui/LevelMapPro.tscn`).

Example CLI:
```
godot --editor project.godot
godot --path . --main-scene res://ui/MainMenu.tscn
```

## 🚀 Deployment

- **Prebuilt Web**: `web-dist/` contains an export ready to host (paired with `vercel.json`).
- **Custom Export**: Export “Web” from Godot 4.4 to a folder (e.g., `web-dist/`).
- **Vercel**: Deploy the static folder.

Example with Vercel CLI:
```
cd web-dist
vercel --prod
```

See docs/DEPLOYMENT_GUIDE.md and docs/WebOptimization.md for details.

## 🔒 Privacy & Security

- Analytics is offline by default: events batch to a local file (`user://analytics_log.json`). No network transmission. See `docs/Analytics.md`.
- Security policy and reporting: `SECURITY.md`.

## 📚 Documentation

- Main Menu Features: `docs/MainMenu_Features.md`
- Pause System: `docs/PauseSystem_Features.md`
- Portal System: `docs/PortalSystem.md`
- Giant Boss Guide: `docs/GiantBoss_Guide.md`
- Web Optimization: `docs/WebOptimization.md`
- Deployment Guide: `docs/DEPLOYMENT_GUIDE.md`
- Texture Guide: `docs/TextureGuide.md`
- Asset Checklist: `docs/AssetChecklist.md`

## 🤝 Contributing

- Read `CONTRIBUTING.md` for setup, workflow, and quality checks.
- **Branch**: `git checkout -b feature/your-change`
- **Commit**: `git commit -m "feat: describe your change"`
- **PR**: Open a Pull Request (include screenshots/GIFs for UI).

Guidelines:
- Follow Godot GDScript conventions and keep changes focused.
- Test on web and desktop; verify level select/progression and saves.
- Update docs if you add or change features.

See also: `CODE_OF_CONDUCT.md`.

## 📝 License

MIT — see `LICENSE`.

## 🙏 Credits

- Behrouz Pooladrak — https://www.behrouz.nl
- Make with ❤️ using Kiro IDE from Amazon
- Godot Engine community
- Vercel (hosting)
- Kenney - For providing amazing game assets
 
