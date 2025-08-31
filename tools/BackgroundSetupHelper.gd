@tool
extends EditorScript
class_name BackgroundSetupHelper

## Utility script to help setup backgrounds in levels
## Run this script in the Godot editor to quickly add background systems

static func create_simple_background(parent: Node, texture_path: String = "") -> LoopingBackground:
	"""Create a simple looping background and add it to the parent node"""
	var bg = preload("res://actors/LoopingBackground.tscn").instantiate()
	bg.name = "LoopingBackground"
	
	if texture_path != "":
		var texture = load(texture_path)
		if texture:
			bg.texture = texture
	
	parent.add_child(bg)
	return bg

static func create_parallax_system(parent: Node) -> ParallaxBackgroundSystem:
	"""Create a parallax background system and add it to the parent node"""
	var system = preload("res://actors/ParallaxBackgroundSystem.tscn").instantiate()
	system.name = "ParallaxBackgroundSystem"
	
	parent.add_child(system)
	return system

static func create_default_parallax_layers() -> Array[BackgroundLayerConfig]:
	"""Create a set of default parallax layers with common settings"""
	var layers: Array[BackgroundLayerConfig] = []
	
	# Far background (sky/mountains)
	var far_layer = BackgroundLayerConfig.new()
	far_layer.scroll_speed = Vector2(-15, 0)
	far_layer.parallax_factor = Vector2(0.1, 0.1)
	far_layer.z_index = -30
	far_layer.layer_name = "Far Background"
	far_layer.modulate_color = Color(0.9, 0.95, 1.0)
	layers.append(far_layer)
	
	# Mid background (trees/buildings)
	var mid_layer = BackgroundLayerConfig.new()
	mid_layer.scroll_speed = Vector2(-30, 0)
	mid_layer.parallax_factor = Vector2(0.3, 0.3)
	mid_layer.z_index = -20
	mid_layer.layer_name = "Mid Background"
	layers.append(mid_layer)
	
	# Near background (foreground elements)
	var near_layer = BackgroundLayerConfig.new()
	near_layer.scroll_speed = Vector2(-45, 0)
	near_layer.parallax_factor = Vector2(0.6, 0.6)
	near_layer.z_index = -10
	near_layer.layer_name = "Near Background"
	layers.append(near_layer)
	
	return layers

static func setup_dimension_backgrounds(bg: LoopingBackground, layer_a_path: String, layer_b_path: String):
	"""Setup different textures for dimension layers A and B"""
	bg.use_different_textures_per_layer = true
	
	if layer_a_path != "":
		var texture_a = load(layer_a_path)
		if texture_a:
			bg.layer_a_texture = texture_a
	
	if layer_b_path != "":
		var texture_b = load(layer_b_path)
		if texture_b:
			bg.layer_b_texture = texture_b

# Editor script execution
func _run():
	"""Run this script in the editor to add backgrounds to the current scene"""
	var current_scene = EditorInterface.get_edited_scene_root()
	if not current_scene:
		print("❌ No scene is currently open")
		return
	
	print("🛠️ Adding background system to: ", current_scene.name)
	
	# Create parallax system
	var parallax_system = create_parallax_system(current_scene)
	parallax_system.background_layers = create_default_parallax_layers()
	
	print("✅ Background system added successfully!")
	print("📝 Configure textures in the inspector and adjust settings as needed")