extends Control
class_name SettingsMenu

@onready var master_slider: HSlider = $Panel/VBox/MasterVolume/Slider
@onready var music_slider: HSlider = $Panel/VBox/MusicVolume/Slider
@onready var sfx_slider: HSlider = $Panel/VBox/SFXVolume/Slider
@onready var master_label: Label = $Panel/VBox/MasterVolume/ValueLabel
@onready var music_label: Label = $Panel/VBox/MusicVolume/ValueLabel
@onready var sfx_label: Label = $Panel/VBox/SFXVolume/ValueLabel
@onready var test_sfx_button: Button = $Panel/VBox/TestSFX
@onready var back_button: Button = $Panel/VBox/BackButton

signal settings_closed

func _ready():
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect button signals
	test_sfx_button.pressed.connect(_on_test_sfx_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
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
	if Audio:
		master_slider.value = Audio.master_volume
		music_slider.value = Audio.music_volume
		sfx_slider.value = Audio.sfx_volume
		_update_labels()

func _update_labels():
	master_label.text = str(int(master_slider.value * 100)) + "%"
	music_label.text = str(int(music_slider.value * 100)) + "%"
	sfx_label.text = str(int(sfx_slider.value * 100)) + "%"

func _on_master_volume_changed(value: float):
	Audio.set_master_volume(value)
	_update_labels()

func _on_music_volume_changed(value: float):
	Audio.set_music_volume(value)
	_update_labels()

func _on_sfx_volume_changed(value: float):
	Audio.set_sfx_volume(value)
	_update_labels()

func _on_test_sfx_pressed():
	# Play a test sound effect
	Audio.play_sfx("test_beep")

func _on_back_pressed():
	hide_settings()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_settings()
		get_viewport().set_input_as_handled()
