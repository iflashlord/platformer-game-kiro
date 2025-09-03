@tool
extends EditorScript

# Thumbnail Generator for Level Map
# Generates placeholder thumbnails for levels

func _run():
	print("🖼️ Thumbnail Generator - Creating placeholder thumbnails")
	print("====================================================")
	
	var levels = [
		{"id": "tutorial", "color": Color.BLUE, "icon": "🎓"},
		{"id": "crate_test", "color": Color.BROWN, "icon": "📦"},
		{"id": "collectible_test", "color": Color.GOLD, "icon": "💎"},
		{"id": "dimension_test", "color": Color.PURPLE, "icon": "🌀"},
		{"id": "enemy_gauntlet", "color": Color.RED, "icon": "⚔️"},
		{"id": "level01", "color": Color.GREEN, "icon": "🌲"},
		{"id": "level02", "color": Color.DARK_GREEN, "icon": "🍃"},
		{"id": "level03", "color": Color.GRAY, "icon": "🏔️"},
		{"id": "chase01", "color": Color.ORANGE, "icon": "🏃"}
	]
	
	var thumbnail_dir = "res://content/thumbnails/"
	
	for level_data in levels:
		_create_thumbnail(level_data, thumbnail_dir)
	
	print("✅ Thumbnail generation completed")

func _create_thumbnail(level_data: Dictionary, output_dir: String):
	"""Create a placeholder thumbnail for a level"""
	var level_id = level_data.get("id", "unknown")
	var color = level_data.get("color", Color.GRAY)
	var icon = level_data.get("icon", "?")
	
	# Create image
	var image = Image.create(120, 80, false, Image.FORMAT_RGBA8)
	
	# Fill background with gradient
	for y in range(80):
		for x in range(120):
			var gradient_factor = float(y) / 80.0
			var pixel_color = color.lerp(color.darkened(0.3), gradient_factor)
			image.set_pixel(x, y, pixel_color)
	
	# Add border
	_add_border(image, Color.WHITE, 2)
	
	# Save as PNG
	var output_path = output_dir + level_id + ".png"
	var result = image.save_png(output_path)
	
	if result == OK:
		print("✅ Created thumbnail: ", output_path)
	else:
		print("❌ Failed to create thumbnail: ", output_path)

func _add_border(image: Image, border_color: Color, border_width: int):
	"""Add a border to an image"""
	var width = image.get_width()
	var height = image.get_height()
	
	# Top and bottom borders
	for x in range(width):
		for y in range(border_width):
			image.set_pixel(x, y, border_color)
			image.set_pixel(x, height - 1 - y, border_color)
	
	# Left and right borders
	for y in range(height):
		for x in range(border_width):
			image.set_pixel(x, y, border_color)
			image.set_pixel(width - 1 - x, y, border_color)