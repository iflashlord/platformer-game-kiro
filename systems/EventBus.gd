extends Node

# Global event bus to replace per-frame polling with signals
# This improves performance by eliminating unnecessary checks

# Player events
signal player_jumped(player)
signal player_landed(player, impact_velocity: float)
signal player_died(player)
signal player_respawned(player)
signal player_dimension_changed(player, new_layer: String)

# Collectible events
signal fruit_collected(fruit_type: String, position: Vector2)
signal gem_collected(gem_type: String, value: int, position: Vector2)
signal collectible_spawned(type: String, position: Vector2)

# Crate events
signal crate_destroyed(crate_type: String, position: Vector2)
signal crate_bounced(position: Vector2)
signal explosion_triggered(position: Vector2, radius: float)

# Enemy events
signal enemy_defeated(enemy_type: String, position: Vector2)
signal enemy_spotted_player(enemy: Node, player)
signal enemy_lost_player(enemy: Node)

# Level events
signal level_started(level_name: String)
signal level_completed(level_name: String, time: float, score: int)
signal level_unlocked(level_name: String)
signal checkpoint_reached(checkpoint_id: String, position: Vector2)
signal level_portal_entered()

# UI events
signal score_changed(new_score: int, change: int)
signal health_changed(new_health: int, max_health: int)
signal time_updated(current_time: float)
signal menu_opened(menu_name: String)
signal menu_closed(menu_name: String)

# Audio events
signal music_requested(track_name: String, loop: bool)
signal sfx_requested(sound_name: String, position: Vector2)
signal volume_changed(bus_name: String, volume: float)

# Visual effects events
signal screen_shake_requested(intensity: float, duration: float)
signal hit_stop_requested(duration: float)
signal particle_burst_requested(type: String, position: Vector2, count: int)

# System events
signal game_paused()
signal game_resumed()
signal settings_changed(setting_name: String, value)
signal save_requested()
signal load_requested()

# Debug events
signal debug_borders_toggled(enabled: bool)

# Hint system events
signal hint_requested(message: String, title: String)
signal hint_dismissed()

func _ready():
	# Connect to audio system
	music_requested.connect(_on_music_requested)
	sfx_requested.connect(_on_sfx_requested)
	
	# Connect to FX system
	screen_shake_requested.connect(_on_screen_shake_requested)
	hit_stop_requested.connect(_on_hit_stop_requested)

# Audio event handlers
func _on_music_requested(track_name: String, loop: bool):
	if Audio:
		Audio.play_music(track_name, loop)

func _on_sfx_requested(sound_name: String, position: Vector2):
	if Audio:
		Audio.play_sfx(sound_name)

# FX event handlers
func _on_screen_shake_requested(intensity: float, duration: float):
	if FX:
		FX.shake(intensity)

func _on_hit_stop_requested(duration: float):
	if FX:
		FX.hit_stop(duration)

# Convenience functions for common events
func request_music(track_name: String, loop: bool = true):
	music_requested.emit(track_name, loop)

func request_sfx(sound_name: String, pos: Vector2 = Vector2.ZERO):
	sfx_requested.emit(sound_name, pos)

func request_shake(intensity: float, duration: float = 0.3):
	screen_shake_requested.emit(intensity, duration)

func request_hit_stop(duration: float = 120.0):
	hit_stop_requested.emit(duration)

func notify_player_landed(player, velocity: float):
	player_landed.emit(player, velocity)

func notify_collectible_gathered(type: String, pos: Vector2):
	if type.begins_with("fruit_"):
		fruit_collected.emit(type, pos)
	elif type.begins_with("gem_"):
		gem_collected.emit(type, 10, pos)

func notify_crate_destroyed(type: String, pos: Vector2):
	crate_destroyed.emit(type, pos)
	
	# Trigger appropriate effects
	match type:
		"tnt":
			request_hit_stop(120)
			request_shake(300)
		"nitro":
			request_shake(200)
		"bounce":
			request_sfx("bounce_crate", pos)
