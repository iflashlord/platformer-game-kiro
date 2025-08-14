extends Control

@onready var fps_label: Label = $VBox/FPSLabel
@onready var memory_label: Label = $VBox/MemoryLabel
@onready var objects_label: Label = $VBox/ObjectsLabel
@onready var spawn_button: Button = $VBox/SpawnButton
@onready var clear_button: Button = $VBox/ClearButton
@onready var atlas_test_button: Button = $VBox/AtlasTestButton

var spawned_objects: Array = []
var frame_times: Array = []
var max_frame_samples: int = 60

func _ready():
	# Connect buttons
	spawn_button.pressed.connect(_on_spawn_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	atlas_test_button.pressed.connect(_on_atlas_test_pressed)
	
	# Connect to event bus for performance monitoring
	EventBus.fruit_collected.connect(_on_fruit_collected)
	EventBus.crate_destroyed.connect(_on_crate_destroyed)

func _process(delta):
	_update_performance_stats(delta)

func _update_performance_stats(delta):
	# Track frame times
	frame_times.append(delta)
	if frame_times.size() > max_frame_samples:
		frame_times.pop_front()
	
	# Calculate average FPS
	var avg_delta = 0.0
	for time in frame_times:
		avg_delta += time
	avg_delta /= frame_times.size()
	var fps = 1.0 / avg_delta if avg_delta > 0 else 0
	
	# Update labels
	fps_label.text = "FPS: %.1f (%.2fms)" % [fps, avg_delta * 1000]
	memory_label.text = "Memory: %.1f MB" % (OS.get_static_memory_usage() / 1024.0 / 1024.0)
	objects_label.text = "Spawned Objects: %d" % spawned_objects.size()

func _on_spawn_pressed():
	# Spawn test objects using object pool
	for i in range(20):
		var pos = Vector2(randf_range(100, 1180), randf_range(100, 620))
		
		# Spawn fruits
		if i % 3 == 0:
			ObjectPool.spawn_fruit(pos, ["apple", "banana", "cherry"][randi() % 3])
		
		# Spawn shards
		elif i % 3 == 1:
			ObjectPool.spawn_shards(pos, 3, Color(randf(), randf(), randf()))
		
		# Spawn explosions
		else:
			ObjectPool.spawn_explosion(pos, randf_range(50, 100), 1.0)

func _on_clear_pressed():
	# Clear all spawned objects
	for obj in spawned_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	spawned_objects.clear()

func _on_atlas_test_pressed():
	# Test sprite atlas performance
	var atlas = SpriteAtlas.new()
	
	# Create multiple sprites using atlas
	for i in range(50):
		var sprite = atlas.create_atlas_sprite("fruit_apple")
		add_child(sprite)
		sprite.position = Vector2(randf_range(100, 1180), randf_range(100, 620))
		spawned_objects.append(sprite)

func _on_fruit_collected(fruit_type: String, position: Vector2):
	print("Performance Test: Fruit collected via EventBus - ", fruit_type)

func _on_crate_destroyed(crate_type: String, position: Vector2):
	print("Performance Test: Crate destroyed via EventBus - ", crate_type)

func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()