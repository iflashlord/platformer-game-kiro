extends Node
class_name LayerObject

@export var target_layer: String = "A"
@export var auto_register: bool = true

var dimension_manager: Node

func _ready():
	if auto_register:
		_find_and_register()

func _find_and_register():
	# Try to find DimensionManager
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	
	if not dimension_manager:
		# Try as autoload
		if has_node("/root/DimensionManager"):
			dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager and dimension_manager.has_method("register_layer_object"):
		dimension_manager.register_layer_object(get_parent(), target_layer)
		print("🌀 LayerObject registered parent ", get_parent().name, " to layer ", target_layer)
	else:
		print("⚠️ LayerObject: No DimensionManager found")

func set_layer(layer: String):
	target_layer = layer
	if dimension_manager:
		dimension_manager.unregister_layer_object(get_parent(), target_layer)
		dimension_manager.register_layer_object(get_parent(), layer)

func _exit_tree():
	if dimension_manager and dimension_manager.has_method("unregister_layer_object"):
		dimension_manager.unregister_layer_object(get_parent(), target_layer)
