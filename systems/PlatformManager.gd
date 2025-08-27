extends Node
class_name PlatformManager

# Manages dynamic platform creation and pooling for performance

signal platform_created(platform: DynamicPlatform)
signal platform_destroyed(platform: DynamicPlatform)

@export var dynamic_platform_scene: PackedScene = preload("res://actors/DynamicPlatform.tscn")
@export var max_pooled_platforms: int = 20

var platform_pool: Array[DynamicPlatform] = []
var active_platforms: Array[DynamicPlatform] = []
var platforms_created_total: int = 0

func _ready():
	print("🏭 PlatformManager initialized")

# Create a platform with the given configuration
func create_platform(config: Dictionary, parent: Node = null) -> DynamicPlatform:
	var platform = _get_platform_from_pool()
	
	if not platform:
		platform = _create_new_platform()
	
	if not platform:
		print("❌ Failed to create platform")
		return null
	
	# Add to parent or current scene
	if parent:
		parent.add_child(platform)
	else:
		get_tree().current_scene.add_child(platform)
	
	# Configure the platform
	platform.configure_platform(config)
	
	# Track active platform
	active_platforms.append(platform)
	platforms_created_total += 1
	
	# Connect to platform events
	if platform.breakable_component:
		platform.breakable_component.break_completed.connect(_on_platform_broken.bind(platform))
	
	platform_created.emit(platform)
	print("🧱 Platform created (Active: ", active_platforms.size(), ", Pooled: ", platform_pool.size(), ")")
	
	return platform

# Return a platform to the pool
func return_platform_to_pool(platform: DynamicPlatform):
	if not platform or not platform in active_platforms:
		return
	
	# Remove from active list
	active_platforms.erase(platform)
	
	# Disconnect signals
	if platform.breakable_component and platform.breakable_component.break_completed.is_connected(_on_platform_broken):
		platform.breakable_component.break_completed.disconnect(_on_platform_broken)
	
	# Remove from scene
	if platform.get_parent():
		platform.get_parent().remove_child(platform)
	
	# Reset platform state
	platform.reset_platform()
	
	# Add to pool if there's space
	if platform_pool.size() < max_pooled_platforms:
		platform_pool.append(platform)
		print("♻️ Platform returned to pool (Active: ", active_platforms.size(), ", Pooled: ", platform_pool.size(), ")")
	else:
		platform.queue_free()
		print("🗑️ Platform destroyed (pool full)")
	
	platform_destroyed.emit(platform)

# Get a platform from the pool or create new one
func _get_platform_from_pool() -> DynamicPlatform:
	if platform_pool.size() > 0:
		return platform_pool.pop_back()
	return null

# Create a new platform instance
func _create_new_platform() -> DynamicPlatform:
	if not dynamic_platform_scene:
		print("❌ DynamicPlatform scene not loaded")
		return null
	
	var platform = dynamic_platform_scene.instantiate() as DynamicPlatform
	if not platform:
		print("❌ Failed to instantiate DynamicPlatform")
		return null
	
	return platform

# Handle platform breaking
func _on_platform_broken(platform: DynamicPlatform):
	print("💥 Platform broken, scheduling removal...")
	
	# Wait a bit for particles/effects, then return to pool
	await get_tree().create_timer(2.0).timeout
	
	if is_instance_valid(platform):
		return_platform_to_pool(platform)

# Utility methods
func get_active_platform_count() -> int:
	return active_platforms.size()

func get_pooled_platform_count() -> int:
	return platform_pool.size()

func get_total_platforms_created() -> int:
	return platforms_created_total

# Clean up all platforms
func clear_all_platforms():
	print("🧹 Clearing all platforms...")
	
	# Clear active platforms
	for platform in active_platforms.duplicate():
		return_platform_to_pool(platform)
	
	# Clear pool
	for platform in platform_pool:
		if is_instance_valid(platform):
			platform.queue_free()
	platform_pool.clear()
	
	print("✅ All platforms cleared")

# Create multiple platforms from an array of configs
func create_platforms_batch(configs: Array[Dictionary], parent: Node = null) -> Array[DynamicPlatform]:
	var created_platforms: Array[DynamicPlatform] = []
	
	for config in configs:
		var platform = create_platform(config, parent)
		if platform:
			created_platforms.append(platform)
	
	print("📦 Batch created ", created_platforms.size(), " platforms")
	return created_platforms

# Helper method to create platform config dictionary
static func create_platform_config(
	position: Vector2,
	type: DynamicPlatform.PlatformType = DynamicPlatform.PlatformType.YELLOW,
	width: float = 96.0,
	height: float = 32.0,
	breakable: bool = false,
	break_delay: float = 3.0,
	shake_duration: float = 2.0,
	target_layer: String = "A"
) -> Dictionary:
	return {
		"position": position,
		"type": type,
		"width": width,
		"height": height,
		"breakable": breakable,
		"break_delay": break_delay,
		"shake_duration": shake_duration,
		"target_layer": target_layer
	}