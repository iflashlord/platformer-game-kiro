extends CanvasLayer
class_name LoadingScreen

@onready var loading_label: Label = $UI/CenterContainer/VBoxContainer/LoadingLabel
@onready var progress_bar: ProgressBar = $UI/CenterContainer/VBoxContainer/ProgressBar
@onready var status_label: Label = $UI/CenterContainer/VBoxContainer/StatusLabel

var target_scene: String = ""
var loading_thread: Thread

func _ready():
	set_process(false)

func show_loading(scene_path: String, initial_message: String = "Loading..."):
	target_scene = scene_path
	status_label.text = initial_message
	progress_bar.value = 0
	visible = true
	set_process(true)
	
	# Start loading in background
	_start_loading()

func _start_loading():
	loading_thread = Thread.new()
	loading_thread.start(_load_scene_threaded)

func _load_scene_threaded():
	# Simulate loading progress
	for i in range(101):
		call_deferred("_update_progress", i, _get_loading_message(i))
		OS.delay_msec(10)  # Small delay to show progress
	
	call_deferred("_loading_complete")

func _update_progress(value: int, message: String):
	progress_bar.value = value
	status_label.text = message

func _get_loading_message(progress: int) -> String:
	if progress < 20:
		return "Initializing..."
	elif progress < 40:
		return "Loading assets..."
	elif progress < 60:
		return "Setting up scene..."
	elif progress < 80:
		return "Preparing game systems..."
	elif progress < 95:
		return "Finalizing..."
	else:
		return "Ready!"

func _loading_complete():
	set_process(false)
	
	# Wait a moment then transition
	await get_tree().create_timer(0.5).timeout
	
	if FileAccess.file_exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		print("❌ Failed to load scene: ", target_scene)
		visible = false

func _exit_tree():
	if loading_thread and loading_thread.is_started():
		loading_thread.wait_to_finish()