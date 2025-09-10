extends Area2D
class_name TorchLight

@export var light_color: Color = Color(1.0, 0.85, 0.5, 1.0)
@export var light_energy: float = 1.2
@export var light_texture_scale: float = 1.5
@export_range(0.2, 0.95, 0.01) var edge_softness: float = 0.8 # where the falloff begins (fraction of radius)

@export var flicker_amount: float = 0.15 # 0..1 intensity variation
@export var flicker_speed: float = 8.0   # how fast the flicker animates

@export var wind_radius: float = 160.0
@export var wind_strength: float = 1.0   # 0..2 multiplier for wind influence

@export var touch_sfx: String = "sfx_magic"

# Flame particle controls
@export var flame_amount: int = 64
@export var flame_lifetime: float = 0.8
@export var flame_spread: float = 20.0
@export var flame_velocity_min: float = 45.0
@export var flame_velocity_max: float = 70.0
@export var flame_gravity: float = -50.0 # upward pull
@export var flame_scale_min: float = 0.5
@export var flame_scale_max: float = 1.0
@export var flame_color_ramp: GradientTexture1D

# Ember burst particle controls
@export var ember_enabled: bool = true
@export var ember_amount_base: int = 28
@export var ember_amount_min: int = 16
@export var ember_amount_max: int = 42
@export var ember_speed_divisor: float = 8.0 # higher = less extra from speed
@export var ember_lifetime: float = 0.9
@export var ember_spread: float = 45.0
@export var ember_velocity_min: float = 70.0
@export var ember_velocity_max: float = 120.0
@export var ember_gravity: float = -40.0
@export var ember_scale_min: float = 0.4
@export var ember_scale_max: float = 0.8
@export var ember_color_ramp: GradientTexture1D

@onready var point_light: PointLight2D = $PointLight2D
@onready var inner_light: PointLight2D = $InnerLight
@onready var flame_particles: GPUParticles2D = $FlameParticles
@onready var ember_burst: GPUParticles2D = $EmberBurst

var _flicker_t: float = 0.0
var _base_energy: float
var _player_ref: Player
var _current_layer: String = "A"
var _dimension_manager: Node = null

@export_group("Dimension")
# 0=Both, 1=Only A, 2=Only B
@export_enum("Both","A","B") var visible_in_dimension: int = 0: set = set_visible_in_dimension

func _ready():
	body_entered.connect(_on_body_entered)

	# Dimension integration like HUDVisual
	if _dimension_manager == null:
		_dimension_manager = get_node_or_null("/root/DimensionManager")
	_connect_dimension_manager()
	_update_dimension_visibility()

	# Initialize light
	if point_light:
		point_light.color = light_color
		point_light.energy = light_energy
		point_light.texture_scale = light_texture_scale
		point_light.blend_mode = PointLight2D.BLEND_MODE_ADD
	if inner_light:
		inner_light.color = light_color.lerp(Color(1.0, 0.95, 0.7), 0.6)
		inner_light.energy = light_energy * 0.75
		inner_light.texture_scale = max(0.5, light_texture_scale * 0.6)
		inner_light.blend_mode = PointLight2D.BLEND_MODE_ADD

	_setup_light_textures()

	_base_energy = light_energy

	# Particles baseline configuration
	if flame_particles:
		flame_particles.emitting = true
		flame_particles.amount = flame_amount
		flame_particles.lifetime = flame_lifetime
		var mat: ParticleProcessMaterial = flame_particles.process_material as ParticleProcessMaterial
		if mat == null:
			mat = ParticleProcessMaterial.new()
			flame_particles.process_material = mat
		# Base upward flame direction
		# In 2D we use X/Y of the 3D vector
		mat.direction = Vector3(0, -1, 0)
		mat.spread = flame_spread
		mat.initial_velocity_min = flame_velocity_min
		mat.initial_velocity_max = flame_velocity_max
		mat.gravity = Vector3(0, flame_gravity, 0)
		mat.scale_min = flame_scale_min
		mat.scale_max = flame_scale_max
		if flame_color_ramp:
			mat.color_ramp = flame_color_ramp

	# Try to find player once
	_player_ref = _find_player()

	# Setup ember burst material
	if ember_burst:
		var mat_burst: ParticleProcessMaterial = ember_burst.process_material as ParticleProcessMaterial
		if mat_burst == null:
			mat_burst = ParticleProcessMaterial.new()
			ember_burst.process_material = mat_burst
		ember_burst.lifetime = ember_lifetime
		mat_burst.direction = Vector3(0, -1, 0)
		mat_burst.spread = ember_spread
		mat_burst.initial_velocity_min = ember_velocity_min
		mat_burst.initial_velocity_max = ember_velocity_max
		mat_burst.gravity = Vector3(0, ember_gravity, 0)
		mat_burst.scale_min = ember_scale_min
		mat_burst.scale_max = ember_scale_max
		# Warm ember color ramp
		if ember_color_ramp:
			mat_burst.color_ramp = ember_color_ramp
		else:
			var grad := Gradient.new()
			grad.add_point(0.0, Color(1.0, 0.85, 0.4, 0.9))
			grad.add_point(0.5, Color(1.0, 0.5, 0.2, 0.6))
			grad.add_point(1.0, Color(0.4, 0.2, 0.1, 0.0))
			var ramp_tex := GradientTexture1D.new()
			ramp_tex.gradient = grad
			mat_burst.color_ramp = ramp_tex

func _process(delta: float) -> void:
	_flicker_t += delta * flicker_speed
	_apply_flicker()
	_apply_wind_effect(delta)
	# Update visibility guard in case layer changed without signal (rare)
	# Keeps runtime consistent if DimensionManager swaps late
	_update_dimension_visibility()

func _apply_flicker():
	if not point_light:
		return
	# Sinusoidal + subtle noise for natural flicker
	var s: float = sin(_flicker_t) * 0.5 + 0.5
	var n: float = randf() * 0.2 # small random jitter
	var intensity: float = float(clamp(1.0 - flicker_amount * (0.6 * s + 0.4 * n), 0.0, 2.0))
	point_light.energy = _base_energy * intensity
	if inner_light:
		inner_light.energy = (_base_energy * 0.75) * (0.9 + 0.1 * s)

func _apply_wind_effect(delta: float):
	if not flame_particles:
		return

	# Lazy-reacquire player if null
	if _player_ref == null or not is_instance_valid(_player_ref):
		_player_ref = _find_player()
		if _player_ref == null:
			return

	var to_player: Vector2 = _player_ref.global_position - global_position
	var dist: float = to_player.length()
	if dist > wind_radius:
		_reset_particles_direction()
		return

	# Wind strength scales by proximity and player speed
	var proximity: float = 1.0 - (dist / wind_radius)
	var speed: float = abs(_player_ref.velocity.x)
	var speed_factor: float = float(clamp(speed / 200.0, 0.0, 1.5))

	# Wind direction pushes flame away from player
	var away: Vector2 = -to_player.normalized()
	var wind_vec: Vector2 = away * float(proximity * speed_factor * wind_strength)

	var mat: ParticleProcessMaterial = flame_particles.process_material as ParticleProcessMaterial
	if mat:
		var dir: Vector2 = (Vector2(0, -1) * 1.0 + wind_vec).normalized()
		mat.direction = Vector3(dir.x, dir.y, 0)
		# Subtle increase in spread under wind
		mat.spread = flame_spread + 20.0 * proximity

func _reset_particles_direction():
	var mat: ParticleProcessMaterial = flame_particles.process_material as ParticleProcessMaterial
	if mat:
		mat.direction = Vector3(0, -1, 0)
		mat.spread = flame_spread

func _on_body_entered(body: Node):
	if body is Player or ("player" in body.get_groups()):
		if Audio:
			Audio.play_sfx(touch_sfx)
		# Add a momentary stronger flicker on touch
		_flicker_t += 1.2
		# Brief energy punch for both lights
		if point_light:
			var tw = create_tween()
			tw.tween_property(point_light, "energy", point_light.energy + 0.5, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw.tween_property(point_light, "energy", max(_base_energy * 0.9, _base_energy), 0.18)
		if inner_light:
			var tw2 = create_tween()
			tw2.tween_property(inner_light, "energy", inner_light.energy + 0.3, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			tw2.tween_property(inner_light, "energy", (_base_energy * 0.75), 0.18)
		# Ember burst upward
		_emit_ember_burst()

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

func _emit_ember_burst():
	if ember_burst == null:
		return
	# Optionally scale amount by player speed if available
	if not ember_enabled:
		return
	var amt: int = ember_amount_base
	if _player_ref:
		var speed: float = abs(_player_ref.velocity.x)
		amt = int(clamp(ember_amount_base + speed / max(1.0, ember_speed_divisor), ember_amount_min, ember_amount_max))
	ember_burst.amount = amt
	ember_burst.emitting = false
	ember_burst.restart()
	ember_burst.emitting = true

func _setup_light_textures():
	# Create a soft radial gradient texture for smoother falloff and round shape
	var grad := Gradient.new()
	grad.colors = PackedColorArray() # clear
	# Bright center with slight rolloff before soft edges
	grad.add_point(0.0, Color(1, 1, 1, 1.0))
	grad.add_point(edge_softness * 0.6, Color(1, 1, 1, 0.9))
	grad.add_point(edge_softness, Color(1, 1, 1, 0.25))
	grad.add_point(1.0, Color(1, 1, 1, 0.0))

	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.width = 512
	gt.height = 512
	gt.fill = GradientTexture2D.FILL_RADIAL
	# Center the radial gradient; radius goes from center to right edge
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.repeat = 0
	if point_light:
		point_light.texture = gt
	if inner_light:
		inner_light.texture = gt

func _find_player() -> Player:
	# Prefer first node in the 'player' group
	var candidates := get_tree().get_nodes_in_group("player")
	if candidates.size() > 0 and candidates[0] is Player:
		return candidates[0]
	# Fallback: find by class
	return get_tree().get_first_node_in_group("player") as Player
