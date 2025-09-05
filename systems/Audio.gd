extends Node

# Audio buses
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"
const NARRATION_BUS = "Narration"

# SFX player pool
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_pool_size: int = 10
var current_sfx_index: int = 0

# Music player
var music_player: AudioStreamPlayer

# Narration player and queue
var narration_player: AudioStreamPlayer
var narration_playing: bool = false

# Audio resources cache
var sfx_cache: Dictionary = {}
var music_cache: Dictionary = {}

# Volume settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0

func _ready():
	# Create audio buses if they don't exist
	_setup_audio_buses()
	
	# Create music player
	music_player = AudioStreamPlayer.new()
	music_player.bus = MUSIC_BUS
	add_child(music_player)
	
	# Create SFX player pool
	for i in sfx_pool_size:
		var player = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		sfx_players.append(player)
	
	# Create Narration bus if it doesn't exist
	if AudioServer.get_bus_index(NARRATION_BUS) == -1:
		var idx = AudioServer.get_bus_count()
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, NARRATION_BUS)
		AudioServer.set_bus_send(idx, MASTER_BUS)
	
	# Create narration player
	narration_player = AudioStreamPlayer.new()
	narration_player.bus = NARRATION_BUS
	add_child(narration_player)
	narration_player.connect("finished", Callable(self, "_on_narration_finished"))
	
	# Load settings from persistence
	_load_audio_settings()
	
	# Set initial volumes
	update_volumes()

func _setup_audio_buses():
	# Get the audio server
	var _master_idx = AudioServer.get_bus_index(MASTER_BUS)
	
	# Create Music bus if it doesn't exist
	if AudioServer.get_bus_index(MUSIC_BUS) == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, MUSIC_BUS)
		AudioServer.set_bus_send(1, MASTER_BUS)
	
	# Create SFX bus if it doesn't exist
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, SFX_BUS)
		AudioServer.set_bus_send(2, MASTER_BUS)

func play_music(track: String, loop: bool = true):
	var stream = _load_music(track)
	if stream:
		if "loop" in stream:
			stream.loop = loop
		music_player.stream = stream
		music_player.play()
		print("Playing music: ", track)

func stop_music():
	music_player.stop()


func play_sfx(sfx_name: String):
	var stream = _load_sfx(sfx_name)
	if stream:
		var player = _get_available_sfx_player()
		player.stream = stream
		player.play()
		player.play()

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Find an available player or use round-robin
	for player in sfx_players:
		if not player.playing:
			return player
	
	# All players busy, use round-robin
	var player = sfx_players[current_sfx_index]
	current_sfx_index = (current_sfx_index + 1) % sfx_pool_size
	return player
func _load_sfx(sfx_name: String) -> AudioStream:
	if sfx_name in sfx_cache:
		return sfx_cache[sfx_name]
	
	var path = "res://audio/sfx/" + sfx_name + ".ogg"
	if ResourceLoader.exists(path):
		var stream = load(path)
		sfx_cache[sfx_name] = stream
		return stream
	
	# Try .wav extension
	path = "res://audio/sfx/" + sfx_name + ".wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		sfx_cache[sfx_name] = stream
		return stream
	
	print("SFX not found: ", sfx_name)
	return null

func _load_music(track: String) -> AudioStream:
	if track in music_cache:
		return music_cache[track]
	
	var path = "res://audio/music/" + track + ".ogg"
	if ResourceLoader.exists(path):
		var stream = load(path)
		music_cache[track] = stream
		return stream
	
	# Try .wav extension
	path = "res://audio/music/" + track + ".wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		music_cache[track] = stream
		return stream
	
	print("Music not found: ", track)
	return null

func play_narration(narration_name: String):
	# Stop any current narration immediately
	if narration_playing:
		narration_player.stop()
		_restore_music_volume()
	
	var stream = _load_narration(narration_name)
	if stream:
		narration_playing = true
		_set_music_volume_temp(0.2) # Lower music volume
		narration_player.stream = stream
		narration_player.play()

func stop_narration():
	if narration_playing:
		narration_player.stop()
		_restore_music_volume()

func _on_narration_finished():
	narration_playing = false
	_restore_music_volume()

func _load_narration(narration_name: String) -> AudioStream:
	var path = "res://audio/narration/" + narration_name + ".ogg"
	if ResourceLoader.exists(path):
		return load(path)
	path = "res://audio/narration/" + narration_name + ".wav"
	if ResourceLoader.exists(path):
		return load(path)
	print("Narration not found: ", narration_name)
	return null

# Helper to lower/restore music volume
var _music_volume_backup: float = music_volume

func _set_music_volume_temp(temp_volume: float):
	_music_volume_backup = music_volume
	set_music_volume(temp_volume)

func _restore_music_volume():
	set_music_volume(_music_volume_backup)

func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	_save_audio_settings()

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	_save_audio_settings()

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	update_volumes()
	_save_audio_settings()

func update_volumes():
	var master_idx = AudioServer.get_bus_index(MASTER_BUS)
	var music_idx = AudioServer.get_bus_index(MUSIC_BUS)
	var sfx_idx = AudioServer.get_bus_index(SFX_BUS)
	
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func _load_audio_settings():
	if Persistence:
		var profile = Persistence.get_current_profile()
		master_volume = profile.get("master_volume", 1.0)
		music_volume = profile.get("music_volume", 0.7)
		sfx_volume = profile.get("sfx_volume", 1.0)

func _save_audio_settings():
	if Persistence:
		var profile = Persistence.get_current_profile()
		profile["master_volume"] = master_volume
		profile["music_volume"] = music_volume
		profile["sfx_volume"] = sfx_volume
		Persistence.save_profile()
