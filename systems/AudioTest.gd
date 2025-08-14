extends Control

@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var play_music_button: Button = $VBox/PlayMusicButton
@onready var stop_music_button: Button = $VBox/StopMusicButton
@onready var play_sfx_button: Button = $VBox/PlaySFXButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var status_label: Label = $VBox/StatusLabel

func _ready():
	# Connect button signals
	play_music_button.pressed.connect(_on_play_music_pressed)
	stop_music_button.pressed.connect(_on_stop_music_pressed)
	play_sfx_button.pressed.connect(_on_play_sfx_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	
	# Connect settings menu signal
	settings_menu.settings_closed.connect(_on_settings_closed)
	
	_update_status()

func _update_status():
	var text = "Audio System Test\n\n"
	text += "Master Volume: " + str(int(Audio.master_volume * 100)) + "%\n"
	text += "Music Volume: " + str(int(Audio.music_volume * 100)) + "%\n"
	text += "SFX Volume: " + str(int(Audio.sfx_volume * 100)) + "%\n"
	status_label.text = text

func _on_play_music_pressed():
	Audio.play_music("test_music")
	_update_status()

func _on_stop_music_pressed():
	Audio.stop_music()
	_update_status()

func _on_play_sfx_pressed():
	Audio.play_sfx("test_beep")
	_update_status()

func _on_settings_pressed():
	settings_menu.show_settings()

func _on_settings_closed():
	_update_status()

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel") and not settings_menu.visible:
		get_tree().quit()