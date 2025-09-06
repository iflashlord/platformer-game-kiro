extends StaticBody2D
class_name LayerPlatform

@export var target_layer: String = "A"
@export var ghost_in_other_layer: bool = false  # If true, becomes non-solid instead of invisible

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

var dimension_manager: Node
var original_modulate: Color

func _ready():
	original_modulate = sprite.modulate if sprite else Color.WHITE
	
	# Find dimension manager
	dimension_manager = get_tree().get_first_node_in_group("dimension_managers")
	if not dimension_manager and has_node("/root/DimensionManager"):
		dimension_manager = get_node("/root/DimensionManager")
	
	if dimension_manager:
		dimension_manager.layer_changed.connect(_on_layer_changed)
		_update_for_layer(dimension_manager.get_current_layer())
	
	print("🧱 LayerPlatform created for layer: ", target_layer)

func _on_layer_changed(new_layer: String):
	_update_for_layer(new_layer)

func _update_for_layer(current_layer: String):
	var is_active = (current_layer == target_layer)
	
	if ghost_in_other_layer:
		# Ghost mode: visible but non-solid
		visible = true
		collision.disabled = not is_active
		
		if sprite:
			sprite.modulate = original_modulate if is_active else Color(original_modulate.r, original_modulate.g, original_modulate.b, 0.3)
	else:
		# Standard mode: completely hidden
		visible = is_active
		collision.disabled = not is_active
