extends CanvasLayer

@onready var master_slider: HSlider = $UI/SettingsContainer/MasterVolume/Slider
@onready var music_slider: HSlider = $UI/SettingsContainer/MusicVolume/Slider
@onready var sfx_slider: HSlider = $UI/SettingsContainer/SFXVolume/Slider
@onready var master_label: Label = $UI/SettingsContainer/MasterVolume/ValueLabel
@onready var music_label: Label = $UI/SettingsContainer/MusicVolume/ValueLabel
@onready var sfx_label: Label = $UI/SettingsContainer/SFXVolume/ValueLabel
@onready var test_sfx_button: Button = $UI/SettingsContainer/TestSFX
@onready var reset_progress_button: Button = $UI/SettingsContainer/ResetProgress
@onready var back_button: Button = $UI/BackButton

func _ready():
	# Connect slider signals
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# Connect button signals
	test_sfx_button.pressed.connect(_on_test_sfx_pressed)
	reset_progress_button.pressed.connect(_on_reset_progress_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Load current settings
	_load_settings()
	
	# Focus back button
	back_button.grab_focus()

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
	Audio.play_sfx("ui_cancel")

func _on_reset_progress_pressed():
	# Show confirmation dialog
	_show_reset_confirmation()

func _show_reset_confirmation():
	# Create confirmation dialog
	var dialog = AcceptDialog.new()
	dialog.title = "Reset All Progress"
	dialog.dialog_text = "Are you sure you want to reset ALL game progress?\n\nThis will delete:\n• All level completions\n• All scores and times\n• All unlocked levels\n• All statistics\n\nThis action cannot be undone!"
	
	# Add custom buttons
	dialog.add_cancel_button("Cancel")
	var confirm_button = dialog.add_button("RESET ALL PROGRESS", true, "confirm")
	confirm_button.modulate = Color.RED  # Make it red to indicate danger
	
	# Connect signals
	dialog.custom_action.connect(_on_reset_confirmed)
	dialog.confirmed.connect(_on_reset_confirmed)
	
	# Add to scene and show
	add_child(dialog)
	dialog.popup_centered()

func _on_reset_confirmed(action: String = ""):
	# Only proceed if this is the confirm action or confirmed signal
	if action == "confirm" or action == "":
		print("🔄 Resetting all game progress...")
		
		# Reset all persistent data
		if Persistence:
			# Reset level progress
			Persistence.reset_level_progress()
			
			# Reset profile to defaults (this will clear everything)
			Persistence.reset_profile()
			
			print("✅ All game progress has been reset")
			
			# Show success message
			_show_reset_success()
		else:
			print("❌ Persistence system not available")
			_show_reset_error()

func _show_reset_success():
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Complete"
	dialog.dialog_text = "All game progress has been successfully reset.\n\nYou can now start fresh from the beginning!"
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Auto-close after showing
	dialog.confirmed.connect(func(): dialog.queue_free())

func _show_reset_error():
	var dialog = AcceptDialog.new()
	dialog.title = "Reset Failed"
	dialog.dialog_text = "Failed to reset game progress.\n\nPlease try again or restart the game."
	
	add_child(dialog)
	dialog.popup_centered()
	
	# Auto-close after showing
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_back_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		_on_back_pressed()
