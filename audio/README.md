# Audio Assets

## Directory Structure

- `music/` - Background music tracks (.ogg or .wav)
- `sfx/` - Sound effects (.ogg or .wav)

## Usage

### Music
```gdscript
Audio.play_music("menu_theme")  # Plays audio/music/menu_theme.ogg
Audio.play_music("level_1", false)  # Plays without loop
Audio.stop_music()
```

### Sound Effects
```gdscript
Audio.play_sfx("jump")  # Plays audio/sfx/jump.ogg
Audio.play_sfx("collect_coin")
Audio.play_sfx("enemy_defeat")
```

## Audio Buses

- **Master** - Controls overall volume
- **Music** - Background music bus
- **SFX** - Sound effects bus

## Volume Controls

Available through the SettingsMenu or directly:
```gdscript
Audio.set_master_volume(0.8)  # 80%
Audio.set_music_volume(0.6)   # 60%
Audio.set_sfx_volume(1.0)     # 100%
```

Settings are automatically saved to the persistence system.