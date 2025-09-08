@tool
extends Sprite2D
class_name HUDVisual

## Simple visual-only HUD sprite component.
## Lets you choose a preset HUD character (0-9, Multiply, Percent)
## or select a custom texture manually. No collisions or logic.

@export_group("HUD Visual")
@export_enum("Manual","0","1","2","3","4","5","6","7","8","9","Multiply","Percent") var preset: int = 1: set = set_preset
@export_enum("Default","Double") var variant: int = 0: set = set_variant
@export var custom_texture: Texture2D: set = set_custom_texture
@export var auto_scale_to_pixel_size: bool = false

@export_group("Dimension")
# 0=Both, 1=Only A, 2=Only B
@export_enum("Both","A","B") var visible_in_dimension: int = 0: set = set_visible_in_dimension

var _current_layer: String = "A"
@onready var _dimension_manager: Node = get_node("/root/DimensionManager")

func _ready():
    _apply_texture()
    _connect_dimension_manager()
    _update_dimension_visibility()

func _connect_dimension_manager() -> void:
    if _dimension_manager and _dimension_manager.has_signal("layer_changed"):
        if not _dimension_manager.layer_changed.is_connected(_on_layer_changed):
            _dimension_manager.layer_changed.connect(_on_layer_changed)
        if _dimension_manager.has_method("get_current_layer"):
            _current_layer = _dimension_manager.get_current_layer()

func _on_layer_changed(new_layer: String) -> void:
    _current_layer = new_layer
    _update_dimension_visibility()

func set_visible_in_dimension(value: int) -> void:
    visible_in_dimension = value
    _update_dimension_visibility()

func _update_dimension_visibility() -> void:
    # Always visible in the editor viewport
    if Engine.is_editor_hint():
        visible = true
        return
    match visible_in_dimension:
        0: # Both
            visible = true
        1: # A
            visible = (_current_layer == "A")
        2: # B
            visible = (_current_layer == "B")
        _:
            visible = true

func set_preset(value: int) -> void:
    preset = value
    _apply_texture()

func set_variant(value: int) -> void:
    variant = value
    _apply_texture()

func set_custom_texture(value: Texture2D) -> void:
    custom_texture = value
    if preset == 0:
        texture = custom_texture
        _maybe_auto_scale()

func _apply_texture() -> void:
    if preset == 0:
        # Manual
        texture = custom_texture
        _maybe_auto_scale()
        return

    var name_str := _preset_to_name(preset)
    if name_str == "":
        texture = null
        return

    var folder := ("Default" if variant == 0 else "Double")
    var path := "res://content/Graphics/Sprites/Tiles/%s/hud_character_%s.png" % [folder, name_str]
    var tex := load(path)
    if tex and tex is Texture2D:
        texture = tex
        _maybe_auto_scale()
    else:
        push_warning("HUDVisual: Could not load texture at %s" % path)

func _preset_to_name(p: int) -> String:
    # Inspector mapping: 0=Manual, 1..10 => digits 0..9, 11=Multiply, 12=Percent
    if p <= 0:
        return ""
    if p >= 1 and p <= 10:
        return str(p - 1)
    if p == 11:
        return "multiply"
    if p == 12:
        return "percent"
    return ""

func _maybe_auto_scale() -> void:
    if not auto_scale_to_pixel_size or texture == null:
        return
    # Set scale so that 1 texture pixel maps to 1 world unit if desired
    # Assuming project uses 1 unit = 1 pixel for HUD; otherwise user can adjust.
    scale = Vector2.ONE
