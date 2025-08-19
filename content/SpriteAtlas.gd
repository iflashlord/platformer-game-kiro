extends Resource
class_name SpriteAtlas

# Atlas management for optimized sprite rendering
@export var player_texture: Texture2D
@export var enemy_texture: Texture2D
@export var collectible_texture: Texture2D
@export var hazard_texture: Texture2D
@export var ui_texture: Texture2D
@export var sprite_regions: Dictionary = {}
@export var texture_map: Dictionary = {}

# Common sprite sizes
const TILE_SIZE = 32
const ACTOR_SIZE = 32
const UI_SIZE = 64

func _init():
	# Define sprite regions and texture mappings
	_setup_regions()
	_setup_texture_map()

func _setup_regions():
	# Player sprites
	sprite_regions["player_idle"] = Rect2(0, 0, ACTOR_SIZE, ACTOR_SIZE)
	sprite_regions["player_run1"] = Rect2(32, 0, ACTOR_SIZE, ACTOR_SIZE)
	sprite_regions["player_run2"] = Rect2(64, 0, ACTOR_SIZE, ACTOR_SIZE)
	sprite_regions["player_jump"] = Rect2(96, 0, ACTOR_SIZE, ACTOR_SIZE)
	sprite_regions["player_fall"] = Rect2(128, 0, ACTOR_SIZE, ACTOR_SIZE)
	
	# Enemy sprites
	sprite_regions["enemy_patrol"] = Rect2(0, 32, ACTOR_SIZE, ACTOR_SIZE)
	sprite_regions["enemy_charger"] = Rect2(32, 32, ACTOR_SIZE, ACTOR_SIZE)
	
	# Collectibles
	sprite_regions["fruit_apple"] = Rect2(0, 64, 16, 16)
	sprite_regions["fruit_banana"] = Rect2(16, 64, 16, 16)
	sprite_regions["fruit_cherry"] = Rect2(32, 64, 16, 16)
	sprite_regions["fruit_orange"] = Rect2(48, 64, 16, 16)
	sprite_regions["fruit_grape"] = Rect2(64, 64, 16, 16)
	
	# Crates
	sprite_regions["crate_normal"] = Rect2(0, 96, TILE_SIZE, TILE_SIZE)
	sprite_regions["crate_bounce"] = Rect2(32, 96, TILE_SIZE, TILE_SIZE)
	sprite_regions["crate_tnt"] = Rect2(64, 96, TILE_SIZE, TILE_SIZE)
	sprite_regions["crate_nitro"] = Rect2(96, 96, TILE_SIZE, TILE_SIZE)
	
	# Hazards
	sprite_regions["spike_up"] = Rect2(0, 128, TILE_SIZE, TILE_SIZE)
	sprite_regions["spike_down"] = Rect2(32, 128, TILE_SIZE, TILE_SIZE)
	sprite_regions["spike_left"] = Rect2(64, 128, TILE_SIZE, TILE_SIZE)
	sprite_regions["spike_right"] = Rect2(96, 128, TILE_SIZE, TILE_SIZE)
	
	# Tiles
	sprite_regions["tile_ground"] = Rect2(0, 160, TILE_SIZE, TILE_SIZE)
	sprite_regions["tile_platform"] = Rect2(32, 160, TILE_SIZE, TILE_SIZE)
	sprite_regions["tile_wall"] = Rect2(64, 160, TILE_SIZE, TILE_SIZE)

func get_sprite_region(sprite_name: String) -> Rect2:
	if sprite_name in sprite_regions:
		return sprite_regions[sprite_name]
	
	print("Warning: Sprite region not found: ", sprite_name)
	return Rect2(0, 0, TILE_SIZE, TILE_SIZE)

func _setup_texture_map():
	# Map sprite names to their textures
	texture_map["player_idle"] = player_texture
	texture_map["player_run1"] = player_texture
	texture_map["player_run2"] = player_texture
	texture_map["player_jump"] = player_texture
	texture_map["player_fall"] = player_texture
	
	texture_map["enemy_patrol"] = enemy_texture
	texture_map["enemy_charger"] = enemy_texture
	
	texture_map["fruit_apple"] = collectible_texture
	texture_map["fruit_banana"] = collectible_texture
	texture_map["fruit_cherry"] = collectible_texture
	texture_map["fruit_orange"] = collectible_texture
	texture_map["fruit_grape"] = collectible_texture
	
	texture_map["gem_ruby"] = collectible_texture
	texture_map["gem_emerald"] = collectible_texture
	texture_map["gem_sapphire"] = collectible_texture
	texture_map["gem_diamond"] = collectible_texture
	texture_map["gem_amethyst"] = collectible_texture
	
	texture_map["crate_normal"] = hazard_texture
	texture_map["crate_bounce"] = hazard_texture
	texture_map["crate_tnt"] = hazard_texture
	texture_map["crate_nitro"] = hazard_texture
	
	texture_map["spike_up"] = hazard_texture
	texture_map["spike_down"] = hazard_texture
	texture_map["spike_left"] = hazard_texture
	texture_map["spike_right"] = hazard_texture
	
	texture_map["tile_ground"] = hazard_texture
	texture_map["tile_platform"] = hazard_texture
	texture_map["tile_wall"] = hazard_texture

func get_texture_for_sprite(sprite_name: String) -> Texture2D:
	return texture_map.get(sprite_name, player_texture)

func create_atlas_sprite(sprite_name: String) -> Sprite2D:
	var sprite = Sprite2D.new()
	sprite.texture = get_texture_for_sprite(sprite_name)
	sprite.region_enabled = true
	sprite.region_rect = get_sprite_region(sprite_name)
	return sprite

func apply_to_sprite(sprite: Sprite2D, sprite_name: String):
	sprite.texture = get_texture_for_sprite(sprite_name)
	sprite.region_enabled = true
	sprite.region_rect = get_sprite_region(sprite_name)
