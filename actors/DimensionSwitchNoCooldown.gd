extends Area2D
class_name DimensionSwitchNoCooldown

signal dimension_switched(switch: DimensionSwitchNoCooldown, new_layer: String)

@export var switch_type: String = "specific"  # "toggle" or "specific"
@export var target_layer: String = "A"        # For specific switches, default to "A"
@export var no_visuals: bool = false          # If true, hide all visual elements

var player_in_area: bool = false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var switch_sprite: ColorRect = $SwitchSprite
@onready var layer_label: Label = $LayerLabel
@onready var graphic: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
    add_to_group("dimension_switches")
    add_to_group("interactive")

    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

    # Collision layers: interactive layer only collides with player
    collision_layer = 16
    collision_mask = 2

    _setup_visuals()

    if DimensionManager:
        DimensionManager.layer_changed.connect(_on_layer_changed)

func _setup_visuals():
    if no_visuals:
        if is_instance_valid(switch_sprite):
            switch_sprite.visible = false
        if is_instance_valid(layer_label):
            layer_label.visible = false
        if is_instance_valid(graphic):
            graphic.visible = false
        return
    var current_layer = DimensionManager.get_current_layer() if DimensionManager else "A"
    _update_visual_state(current_layer)

func _update_visual_state(current_layer: String):
    if no_visuals:
        return
    layer_label.text = "3D" if current_layer == "A" else "4D"
    layer_label.add_theme_font_size_override("font_size", 24)

    match current_layer:
        "A":
            switch_sprite.color = Color.CYAN
            layer_label.add_theme_color_override("font_color", Color.DARK_BLUE)
            graphic.play("left")
        "B":
            switch_sprite.color = Color.MAGENTA
            layer_label.add_theme_color_override("font_color", Color.DARK_RED)
            graphic.play("right")
        _:
            switch_sprite.color = Color.WHITE
            layer_label.add_theme_color_override("font_color", Color.BLACK)
            graphic.play("default")

    if not player_in_area:
        switch_sprite.modulate.a = 0.7
        layer_label.modulate.a = 0.7
    else:
        switch_sprite.modulate.a = 1.0
        layer_label.modulate.a = 1.0

func _on_body_entered(body):
    if not body.is_in_group("player"):
        return
    player_in_area = true
    _update_visual_state(DimensionManager.get_current_layer() if DimensionManager else "A")
    _activate_switch()

func _on_body_exited(body):
    if not body.is_in_group("player"):
        return
    player_in_area = false
    _update_visual_state(DimensionManager.get_current_layer() if DimensionManager else "A")

func _activate_switch():
    if not DimensionManager:
        return

    var new_layer: String
    if switch_type == "specific" and target_layer != "":
        new_layer = target_layer
    else:
        var current_layer = DimensionManager.get_current_layer()
        new_layer = "B" if current_layer == "A" else "A"

    if new_layer == DimensionManager.get_current_layer():
        return

    # Force switch without applying global cooldown
    DimensionManager.force_set_layer(new_layer, false)

    # Audio and simple pulse
    if Audio:
        Audio.play_sfx("dimension")
    var t = create_tween()
    t.set_parallel(true)
    t.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
    t.tween_property(self, "scale", Vector2.ONE, 0.15)

    dimension_switched.emit(self, new_layer)

func _on_layer_changed(new_layer: String):
    _update_visual_state(new_layer)

func set_target_layer(layer: String):
    target_layer = layer
    switch_type = "specific"
    _setup_visuals()

func set_toggle_mode():
    switch_type = "toggle"
    target_layer = ""
    _setup_visuals()
