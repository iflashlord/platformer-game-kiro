@tool
extends EditorScript

# This script generates basic placeholder textures for the game
# Run this from the Godot editor: Tools > Execute Script

func _run():
	print("Generating placeholder textures...")
	
	# Create basic colored rectangles as placeholder textures
	create_player_texture()
	create_enemy_texture()
	create_collectible_texture()
	create_hazard_texture()
	create_ui_texture()
	
	print("Placeholder textures generated!")
	print("Replace these with actual artwork when available.")

func create_player_texture():
	var image = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.2, 0.8, 0.2, 1.0))  # Green player
	
	# Add simple details
	for x in range(8, 24):
		for y in range(8, 16):
			image.set_pixel(x, y, Color(0.1, 0.6, 0.1, 1.0))  # Darker green for body
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://content/PlayerSprite_generated.tres")
	print("Generated PlayerSprite placeholder")

func create_enemy_texture():
	var image = Image.create(64, 32, false, Image.FORMAT_RGBA8)
	
	# Patrol enemy (left half)
	for x in range(0, 32):
		for y in range(0, 32):
			image.set_pixel(x, y, Color(0.8, 0.2, 0.2, 1.0))  # Red
	
	# Charger enemy (right half)
	for x in range(32, 64):
		for y in range(0, 32):
			image.set_pixel(x, y, Color(0.6, 0.1, 0.1, 1.0))  # Dark red
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://content/EnemySprites_generated.tres")
	print("Generated EnemySprites placeholder")

func create_collectible_texture():
	var image = Image.create(80, 32, false, Image.FORMAT_RGBA8)
	
	# Fruits (top row)
	var fruit_colors = [
		Color(1.0, 0.2, 0.2, 1.0),  # Apple - red
		Color(1.0, 1.0, 0.2, 1.0),  # Banana - yellow
		Color(0.8, 0.1, 0.3, 1.0),  # Cherry - dark red
		Color(1.0, 0.6, 0.2, 1.0),  # Orange - orange
		Color(0.6, 0.2, 0.8, 1.0)   # Grape - purple
	]
	
	for i in range(5):
		for x in range(i * 16, (i + 1) * 16):
			for y in range(0, 16):
				image.set_pixel(x, y, fruit_colors[i])
	
	# Gems (bottom row)
	var gem_colors = [
		Color(1.0, 0.1, 0.1, 1.0),  # Ruby - bright red
		Color(0.1, 1.0, 0.1, 1.0),  # Emerald - bright green
		Color(0.1, 0.1, 1.0, 1.0),  # Sapphire - bright blue
		Color(1.0, 1.0, 1.0, 1.0),  # Diamond - white
		Color(0.8, 0.2, 1.0, 1.0)   # Amethyst - purple
	]
	
	for i in range(5):
		for x in range(i * 16, (i + 1) * 16):
			for y in range(16, 32):
				image.set_pixel(x, y, gem_colors[i])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://content/CollectibleSprites_generated.tres")
	print("Generated CollectibleSprites placeholder")

func create_hazard_texture():
	var image = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	
	# Spikes (top row) - gray
	for x in range(0, 128):
		for y in range(0, 32):
			image.set_pixel(x, y, Color(0.5, 0.5, 0.5, 1.0))
	
	# Crates (bottom row)
	var crate_colors = [
		Color(0.6, 0.4, 0.2, 1.0),  # Normal - brown
		Color(0.2, 0.6, 0.8, 1.0),  # Bounce - blue
		Color(0.8, 0.2, 0.2, 1.0),  # TNT - red
		Color(0.2, 0.8, 0.2, 1.0)   # Nitro - green
	]
	
	for i in range(4):
		for x in range(i * 32, (i + 1) * 32):
			for y in range(32, 64):
				image.set_pixel(x, y, crate_colors[i])
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://content/HazardSprites_generated.tres")
	print("Generated HazardSprites placeholder")

func create_ui_texture():
	var image = Image.create(128, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.3, 0.3, 0.4, 1.0))  # Gray UI background
	
	# Add some simple UI elements
	for x in range(10, 54):
		for y in range(10, 22):
			image.set_pixel(x, y, Color(0.4, 0.4, 0.5, 1.0))  # Button
	
	var texture = ImageTexture.new()
	texture.set_image(image)
	
	ResourceSaver.save(texture, "res://content/UISprites_generated.tres")
	print("Generated UISprites placeholder")