# Audio System

Implemented in `systems/Audio.gd` with Godot 4.4.

## Buses

- `Master`: global output
- `Music`: background music
- `SFX`: sound effects
- `Narration`: optional voice lines (ducking music)

`Audio.gd` ensures buses exist at runtime and sets up one `AudioStreamPlayer` for music, one for narration, and a pool of 10 for SFX.

## Volumes

Runtime setters:
- `set_master_volume(v)`
- `set_music_volume(v)`
- `set_sfx_volume(v)`

Values are persisted via `Persistence` and applied with `Audio.update_volumes()`.

## Adding Sounds

- Music: place `res://audio/music/<track>.ogg|.wav`
  - Play with `Audio.play_music("<track>", loop=true)`
- SFX: place `res://audio/sfx/<name>.ogg|.wav`
  - Play with `Audio.play_sfx("<name>")`
- Narration: place `res://audio/narration/<name>.ogg|.wav`
  - Play with `Audio.play_narration("<name>")`

## Tips

- Prefer `.ogg` for web exports.
- Keep names lowercase and consistent.
- For rapid sequences, leveraging the SFX pool prevents cut‑offs.

