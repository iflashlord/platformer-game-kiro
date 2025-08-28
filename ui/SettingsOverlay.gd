extends CanvasLayer
class_name SettingsOverlay

# Audio controls
@onready var master_slider: HSlider = $UI/SettingsContainer/AudioSettings/MasterVolume/Slider
@onready var music_slider: HSlider = $UI/SettingsContainer/AudioSettings/MusicVolume/Slider
@onready var sfx_slider: HSlider = $UI/SettingsContainer/AudioSettings/SFXVolume/Slider

# Labels
@onready var master_label: Label = $UI/SettingsContainer/AudioSettings/MasterVolume/ValueLabel
@onready var music_label: Label = $UI/SettingsContainer/AudioSettings/MusicVolume/ValueLabel
@onready var sfx_label: Label = $UI/SettingsContainer/AudioSettings/SFXVolume/ValueLabel

# Buttons
@onready var test_sfx_button: Button = $UI/SettingsContainer/ButtonContainer/TestSFXButton
@onready var close_button: Button = $UI/SettingsContainer/ButtonContainer/CloseButton

signal settings_closed

func _ready():
	_connect_signals()
	_load_settings()
	close_button.grab_focus()

func _connect_signals():
	"""Connect all UI signals"""
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	if test_sfx_button:
		test_sfx_button.pressed.connect(_on_test_sfx_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _load_settings():
	"""Load current audio settings"""
	if Audio:
		if master_slider and Audio.has_method("get_master_volume"):
			master_slider.value = Audio.get_master_volume()
		if music_slider and Audio.has_method("get_music_volume"):
			music_slider.value = Audio.get_music_volume()
		if sfx_slider and Audio.has_method("get_sfx_volume"):
			sfx_slider.value = Audio.get_sfx_volume()
	
	_update_labels()

func _update_labels():
	"""Update volume percentage labels"""
	if master_label and master_slider:
		master_label.text = str(int(master_slider.value * 100)) + "%"
	if music_label and music_slider:
		music_label.text = str(int(music_slider.value * 100)) + "%"
	if sfx_label and sfx_slider:
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
	"""Test sound effect"""
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx("ui_select")

func _on_close_pressed():
	"""Close settings overlay"""
	settings_closed.emit()
	queue_free()

func _input(event):
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_close_pressed()