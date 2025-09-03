extends Area2D
class_name SectionMarker

@export var section_name: String = "Section 1"
@export var checkpoint: bool = false
@export var music_track: String = ""

var activated: bool = false

signal section_entered(marker: SectionMarker)

func _ready():
	# Set up collision detection
	body_entered.connect(_on_body_entered)
	
	# Set collision layers
	collision_layer = 32  # Section marker layer
	collision_mask = 2    # Player layer
	
	# Visual setup (invisible trigger)
	modulate.a = 0.0 if not checkpoint else 0.3

func _on_body_entered(body):
	if body.is_in_group("player") and not activated:
		_activate_section()

func _activate_section():
	activated = true
	section_entered.emit(self)
	
	# Update game state
	Game.current_section = section_name
	
	# Set checkpoint if enabled
	if checkpoint:
		Respawn.set_checkpoint(global_position)
		
		# Visual feedback for checkpoint
		var tween = create_tween()
		tween.tween_property(self, "modulate:a", 1.0, 0.2)
		tween.tween_property(self, "modulate:a", 0.3, 0.3)
		
		Audio.play_sfx("checkpoint")
	
	# Change music if specified
	if music_track != "":
		Audio.play_music(music_track)
	
	print("Entered section: ", section_name)
