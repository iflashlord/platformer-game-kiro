extends Control
class_name SettingsMenu

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolume/Slider
@onready var master_label: Label = $Panel/VBox/MasterVolume/ValueLabel
@onready var music_label: Label = $Panel/VBox/MusicVolume/ValueLabel
@onready var sfx_label: Label = $Panel/VBox/SFXVolume/ValueLabel
@onready var test_sfx_button: Button = $Panel/VBox/TestSFX
@onready var reset_progress_button: Button = $Panel/VBox/ResetProgress
@onready var back_button: Button = $Panel/VBox/BackButton

signal settings_closed

func _ready():
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect button signals
	test_sfx_button.pressed.connect(_on_test_sfx_pressed)
	reset_progress_button.pressed.connect(_on_reset_everything_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Update button text to clarify it resets everything
	if reset_progress_button:
		reset_progress_button.text = "Reset Everything"
	
	# Load current settings
	_load_settings()
	
	# Initially hidden
	visible = false

func show_settings():
	visible = true
	_load_settings()
	master_slider.grab_focus()

func hide_settings():
	visible = false
	settings_closed.emit()

func _load_settings():
	"""Load current settings and update UI"""
	if Audio:
		# Safely get volume values with fallbacks
		master_slider.value = Audio.get_master_volume() if Audio.has_method("get_master_volume") else Audio.master_volume if "master_volume" in Audio else 1.0
		music_slider.value = Audio.get_music_volume() if Audio.has_method("get_music_volume") else Audio.music_volume if "music_volume" in Audio else 0.8
		sfx_slider.value = Audio.get_sfx_volume() if Audio.has_method("get_sfx_volume") else Audio.sfx_volume if "sfx_volume" in Audio else 1.0
		_update_labels()
	else:
		# Set defaults if no Audio system
		master_slider.value = 1.0
		music_slider.value = 0.8
		sfx_slider.value = 1.0
		_update_labels()

func _update_labels():
	"""Update volume percentage labels"""
	master_label.text = str(int(master_slider.value * 100)) + "%"
	music_label.text = str(int(music_slider.value * 100)) + "%"
	sfx_label.text = str(int(sfx_slider.value * 100)) + "%"

func _on_master_volume_changed(value: float):
	"""Handle master volume change"""
	if Audio and Audio.has_method("set_master_volume"):
		Audio.set_master_volume(value)
	_update_labels()

func _on_music_volume_changed(value: float):
	"""Handle music volume change"""
	if Audio and Audio.has_method("set_music_volume"):
		Audio.set_music_volume(value)
	_update_labels()

func _on_sfx_volume_changed(value: float):
	"""Handle SFX volume change"""
	if Audio and Audio.has_method("set_sfx_volume"):
		Audio.set_sfx_volume(value)
	_update_labels()

func _on_test_sfx_pressed():
	"""Test SFX volume with sample sound"""
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx("ui_select")
	else:
		print("🔊 Audio system not available for testing")

func _on_reset_everything_pressed():
	"""Show simple reset confirmation"""
	var dialog = ConfirmationDialog.new()
	dialog.title = "Reset Everything"
	dialog.dialog_text = "Reset ALL data to defaults?\n\n• Audio volumes → Default\n• Level progress → Cleared\n• All unlocks → Cleared\n\nThis cannot be undone!"
	
	# Connect confirmation
	dialog.confirmed.connect(_reset_everything)
	
	# Style the dialog
	add_child(dialog)
	dialog.popup_centered()
	
	# Cleanup when done
	dialog.tree_exiting.connect(func(): dialog.queue_free())

func _reset_everything():
	"""Reset all game data and settings"""
	print("🔄 Resetting everything...")
	
	# Reset audio settings to defaults
	_reset_audio_settings()
	
	# Reset game progress
	_reset_game_progress()
	
	# Show success message
	_show_simple_success()

func _reset_audio_settings():
	"""Reset all audio settings to default"""
	if Audio and Audio.has_method("reset_to_defaults"):
		Audio.reset_to_defaults()
		print("🔊 Audio settings reset to defaults")
	elif Audio:
		# Manual reset if no reset method
		Audio.set_master_volume(1.0)
		Audio.set_music_volume(0.8)
		Audio.set_sfx_volume(1.0)
		print("🔊 Audio settings manually reset")
	
	# Update UI sliders
	_load_settings()

func _reset_game_progress():
	"""Reset all game progress data"""
	if Persistence:
		Persistence.reset_level_progress()
		Persistence.reset_profile()
		print("💾 Game progress reset")
	else:
		print("❌ Persistence system not available")

func _show_simple_success():
	"""Show simple success message"""
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Complete"
	dialog.dialog_text = "Everything has been reset!\nRestart the game to see all changes."
	
	add_child(dialog)
	dialog.popup_centered()
	dialog.tree_exiting.connect(func(): dialog.queue_free())

func _on_back_pressed():
	hide_settings()

func _input(event):
	"""Handle input events for settings menu"""
	if not visible:
		return
		
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		hide_settings()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		# If a slider has focus, don't interfere
		var focused = get_viewport().gui_get_focus_owner()
		if focused and focused is HSlider:
			return
		# Otherwise allow normal button activation
		get_viewport().set_input_as_handled()
