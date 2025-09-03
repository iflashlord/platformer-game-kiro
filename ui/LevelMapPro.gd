extends CanvasLayer
class_name LevelMapPro

# UI References
@onready var back_button: Button = $UI/Header/TitleContainer/BackButton
@onready var dev_button: Button = $UI/Header/TitleContainer/DevButton
@onready var progress_label: Label = $UI/Header/ProgressContainer/ProgressLabel
@onready var progress_bar: ProgressBar = $UI/Header/ProgressContainer/ProgressBar
@onready var level_grid: HBoxContainer = $UI/LevelsContainer/ScrollContainer/LevelGrid
@onready var scroll_container: ScrollContainer = $UI/LevelsContainer/ScrollContainer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Data
var map_config: Dictionary = {}
var levels_data: Dictionary = {}
var level_nodes_data: Array = []
var created_level_cards: Array[LevelCard] = []
var dev_mode: bool = false

# Navigation
var selected_index: int = 0
var cards_visible: float = 2.5  # Show 2.5 cards at once
var card_width: float = 480.0  # Width of each card

# Level Card Class
class LevelCard extends Control:
	var level_id: String
	var level_data: Dictionary
	var level_info: Dictionary
	var is_unlocked: bool = false
	var is_completed: bool = false
	var is_perfect: bool = false
	
	# UI Elements
	var main_panel: Panel
	var thumbnail: TextureRect
	var overlay: Control
	var title_label: Label
	var status_container: HBoxContainer
	var score_label: Label
	var hearts_container: HBoxContainer
	var lock_overlay: Control
	var focus_border: ColorRect
	
	# Animation management
	var focus_tween: Tween
	var hover_tween: Tween
	
	signal level_selected(level_id: String)
	
	func _init(id: String, node_data: Dictionary, game_data: Dictionary):
		level_id = id
		level_data = node_data
		level_info = game_data
		custom_minimum_size = Vector2(480, 320)  # Horizontal card size
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_create_ui()
	
	func _create_ui():
		# Main panel
		main_panel = Panel.new()
		main_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(main_panel)
		
		# Invisible button overlay for reliable clicking
		var click_button = Button.new()
		click_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_button.flat = true  # Make it invisible
		click_button.pressed.connect(_on_button_pressed)
		add_child(click_button)
		
		# Thumbnail container with clipping
		var thumbnail_container = Control.new()
		thumbnail_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		thumbnail_container.clip_contents = true  # Ensure no overflow
		thumbnail_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_panel.add_child(thumbnail_container)
		
		# Thumbnail
		thumbnail = TextureRect.new()
		thumbnail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		thumbnail.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		thumbnail.stretch_mode = TextureRect.STRETCH_KEEP
		thumbnail.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
		# Ensure the thumbnail doesn't exceed container bounds
		thumbnail.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		thumbnail.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		thumbnail_container.add_child(thumbnail)
		
		# Overlay for text and status
		overlay = Control.new()
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through
		main_panel.add_child(overlay)
		
		# Gradient background for text readability
		var text_bg = ColorRect.new()
		text_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		text_bg.offset_top = -80
		text_bg.color = Color(0, 0, 0, 0.7)
		text_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(text_bg)
		
		# Title
		title_label = Label.new()
		title_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		title_label.offset_top = -70
		title_label.offset_bottom = -45
		title_label.offset_left = 10
		title_label.offset_right = -10
		title_label.text = level_data.get("display_name", level_id)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_label.add_theme_font_size_override("font_size", 18)
		title_label.add_theme_color_override("font_color", Color.WHITE)
		title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(title_label)
		
		# Status container (score and hearts)
		status_container = HBoxContainer.new()
		status_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		status_container.offset_top = -40
		status_container.offset_bottom = -10
		status_container.offset_left = 10
		status_container.offset_right = -10
		status_container.alignment = BoxContainer.ALIGNMENT_CENTER
		status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		overlay.add_child(status_container)
		
		# Score label
		score_label = Label.new()
		score_label.add_theme_font_size_override("font_size", 14)
		score_label.add_theme_color_override("font_color", Color.YELLOW)
		score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_container.add_child(score_label)
		
		# Spacer
		var spacer = Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_container.add_child(spacer)
		
		# Hearts container
		hearts_container = HBoxContainer.new()
		hearts_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		status_container.add_child(hearts_container)
		
		# Lock overlay (for locked levels)
		lock_overlay = Control.new()
		lock_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_overlay.visible = false
		lock_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_panel.add_child(lock_overlay)
		
		var lock_bg = ColorRect.new()
		lock_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		lock_bg.color = Color(0, 0, 0, 0.8)
		lock_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_overlay.add_child(lock_bg)
		
		var lock_icon = Label.new()
		lock_icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		lock_icon.text = "🔒"
		lock_icon.add_theme_font_size_override("font_size", 48)
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock_overlay.add_child(lock_icon)
		
		# Focus border (initially hidden)
		focus_border = ColorRect.new()
		focus_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		focus_border.color = Color.TRANSPARENT
		focus_border.visible = false
		focus_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
		focus_border.offset_left = -3
		focus_border.offset_top = -3
		focus_border.offset_right = 3
		focus_border.offset_bottom = 3
		add_child(focus_border)
		
		# Connect hover events to the invisible button
		click_button.mouse_entered.connect(_on_mouse_entered)
		click_button.mouse_exited.connect(_on_mouse_exited)
		

	
	func update_status(unlocked: bool, completed: bool, perfect: bool = false):
		is_unlocked = unlocked
		is_completed = completed
		is_perfect = perfect
		
		# Update lock overlay
		lock_overlay.visible = !unlocked
		
		# Get completion data from Persistence
		var completion_data = {}
		var best_score = level_info.get("best_score", 0)
		
		if Persistence and Persistence.has_method("get_level_completion"):
			completion_data = Persistence.get_level_completion(level_id)
			# Use the score from completion data if available, otherwise fallback to level_info
			if completion_data.get("score", 0) > 0:
				best_score = completion_data.get("score", 0)
		
		# Update score display with latest and best
		if best_score > 0:
			var latest_score = completion_data.get("score", best_score)
			if latest_score == best_score:
				score_label.text = "Best: " + str(best_score)
			else:
				score_label.text = "Latest: " + str(latest_score) + " • Best: " + str(best_score)
		else:
			score_label.text = "Not Completed"
		
		# Update hearts display with actual completion data
		_update_hearts_display(completion_data)
		
		# Update visual effects
		if perfect:
			main_panel.modulate = Color(1.2, 1.1, 0.8)  # Golden tint
			_add_sparkle_effect()
		elif completed:
			main_panel.modulate = Color(1.1, 1.1, 1.0)  # Slight brightness
		elif unlocked:
			main_panel.modulate = Color.WHITE
		else:
			main_panel.modulate = Color(0.6, 0.6, 0.6)  # Dimmed
	
	func _update_hearts_display(completion_data: Dictionary = {}):
		# Clear existing hearts
		for child in hearts_container.get_children():
			child.queue_free()
		
		# Get hearts remaining from latest completion
		var hearts_remaining = completion_data.get("hearts_remaining", -1)
		var max_hearts = 5  # Game uses 5 hearts
		
		# If we have completion data, show hearts remaining from latest run
		if hearts_remaining >= 0:
			# Show hearts remaining from latest completion using actual heart assets
			for i in range(max_hearts):
				var heart_sprite = TextureRect.new()
				heart_sprite.custom_minimum_size = Vector2(16, 16)
				heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				heart_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				if i < hearts_remaining:
					# Full heart
					heart_sprite.texture = load("res://content/Graphics/Sprites/Tiles/Double/hud_heart.png")
				else:
					# Empty heart
					heart_sprite.texture = load("res://content/Graphics/Sprites/Tiles/Double/hud_heart_empty.png")
				
				hearts_container.add_child(heart_sprite)
			
			# Add text label showing hearts remaining
			var hearts_text = Label.new()
			hearts_text.text = " " + str(hearts_remaining) + "/5"
			hearts_text.add_theme_font_size_override("font_size", 12)
			hearts_text.add_theme_color_override("font_color", Color.WHITE)
			hearts_container.add_child(hearts_text)
		else:
			# Fallback: show 5 empty hearts to match the main game (no completion data available)
			for i in range(max_hearts):
				var heart_sprite = TextureRect.new()
				heart_sprite.custom_minimum_size = Vector2(16, 16)
				heart_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				heart_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				# Show all hearts as empty since no completion data is available
				heart_sprite.texture = load("res://content/Graphics/Sprites/Tiles/Double/hud_heart_empty.png")
				heart_sprite.modulate = Color.GRAY
				
				hearts_container.add_child(heart_sprite)
			
			# Add text label showing no completion data
			var hearts_text = Label.new()
			hearts_text.text = " --/5"
			hearts_text.add_theme_font_size_override("font_size", 12)
			hearts_text.add_theme_color_override("font_color", Color.GRAY)
			hearts_container.add_child(hearts_text)
	
	func _calculate_hearts_earned() -> int:
		var best_score = level_info.get("best_score", 0)
		if best_score <= 0:
			return 0
		
		var relic_thresholds = level_info.get("relic_thresholds", {})
		var bronze = relic_thresholds.get("bronze", 100)
		var silver = relic_thresholds.get("silver", 200)
		var gold = relic_thresholds.get("gold", 300)
		
		if best_score >= gold:
			return 3
		elif best_score >= silver:
			return 2
		elif best_score >= bronze:
			return 1
		else:
			return 1  # At least 1 heart for completion
	
	func _add_sparkle_effect():
		# Add subtle sparkle effect for perfect levels
		var sparkle_timer = Timer.new()
		sparkle_timer.wait_time = 2.0
		sparkle_timer.timeout.connect(_sparkle_pulse)
		sparkle_timer.autostart = true
		add_child(sparkle_timer)
	
	func _sparkle_pulse():
		var tween = create_tween()
		tween.tween_property(main_panel, "modulate", Color(1.4, 1.3, 1.0), 0.5)
		tween.tween_property(main_panel, "modulate", Color(1.2, 1.1, 0.8), 0.5)
	
	func load_thumbnail():
		var thumbnail_path = level_data.get("thumbnail", "")
		
		if thumbnail_path != "" and FileAccess.file_exists(thumbnail_path):
			var texture = load(thumbnail_path)
			if texture:
				var cropped_texture = _create_cropped_texture(texture)
				if cropped_texture:
					thumbnail.texture = cropped_texture
				else:
					thumbnail.texture = texture  # Fallback to original
			else:
				_create_placeholder_thumbnail()
		else:
			_create_placeholder_thumbnail()
	
	func _create_cropped_texture(original_texture: Texture2D) -> ImageTexture:
		"""Create a cropped version of the texture to fit the card aspect ratio"""
		if not original_texture:
			return null
		
		var card_size = Vector2(480, 320)  # Target card dimensions
		var original_image = original_texture.get_image()
		
		if not original_image:
			return null
		
		var original_size = original_image.get_size()
		
		# Calculate the crop area to maintain aspect ratio
		var card_aspect = card_size.x / card_size.y  # 1.5 (480/320)
		var original_aspect = float(original_size.x) / float(original_size.y)
		
		var crop_rect: Rect2i
		
		if original_aspect > card_aspect:
			# Original is wider - crop horizontally
			var new_width = int(original_size.y * card_aspect)
			var x_offset = (original_size.x - new_width) / 2
			crop_rect = Rect2i(x_offset, 0, new_width, original_size.y)
		else:
			# Original is taller - crop vertically
			var new_height = int(original_size.x / card_aspect)
			var y_offset = (original_size.y - new_height) / 2
			crop_rect = Rect2i(0, y_offset, original_size.x, new_height)
		
		# Create cropped image
		var cropped_image = original_image.get_region(crop_rect)
		
		if not cropped_image:
			return null
		
		# Resize to card dimensions for consistency
		cropped_image.resize(int(card_size.x), int(card_size.y), Image.INTERPOLATE_LANCZOS)
		
		# Create texture from cropped image
		var cropped_texture = ImageTexture.new()
		cropped_texture.set_image(cropped_image)
		
		return cropped_texture
	
	func _create_placeholder_thumbnail():
		var image = Image.create(480, 320, false, Image.FORMAT_RGB8)
		
		# Create gradient based on level theme
		var base_color = _get_level_theme_color()
		for y in range(320):
			for x in range(480):
				var gradient_factor = float(y) / 320.0
				var pixel_color = base_color.lerp(base_color.darkened(0.4), gradient_factor)
				image.set_pixel(x, y, pixel_color)
		
		var texture = ImageTexture.new()
		texture.set_image(image)
		thumbnail.texture = texture
	
	func _get_level_theme_color() -> Color:
		var level_name = level_id.to_lower()
		if "level00" in level_name:
			return Color.BLUE
		elif "level01" in level_name:
			return Color.BROWN
		elif "level02" in level_name:
			return Color.GOLD
		elif "level_giantboss" in level_name:
			return Color.PURPLE
		else:
			return Color.STEEL_BLUE
	
	func set_focused(focused: bool):
		# Kill any existing focus tween
		if focus_tween:
			focus_tween.kill()
		
		if focused:
			# Bring focused card to front
			z_index = 10
			
			# Show border with cyan color
			focus_border.visible = true
			focus_border.color = Color(0, 1, 1, 0.8)  # Cyan with transparency
			
			focus_tween = create_tween()
			focus_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.2)
			# Add cyan glow effect for focus
			focus_tween.parallel().tween_property(main_panel, "modulate", Color(1.2, 1.3, 1.4), 0.2)
			# Pulse effect on border
			focus_tween.tween_property(focus_border, "modulate", Color(1.0, 1.0, 1.0, 0.6), 0.4)
			focus_tween.tween_property(focus_border, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.4)
			focus_tween.set_loops()
		else:
			# Reset z-index and hide border
			z_index = 0
			focus_border.visible = false
			
			focus_tween = create_tween()
			focus_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
			# Reset glow
			var original_color = Color.WHITE
			if is_perfect:
				original_color = Color(1.2, 1.1, 0.8)
			elif is_completed:
				original_color = Color(1.1, 1.1, 1.0)
			elif !is_unlocked:
				original_color = Color(0.6, 0.6, 0.6)
			focus_tween.parallel().tween_property(main_panel, "modulate", original_color, 0.2)
	
	func activate():
		if is_unlocked:
			level_selected.emit(level_id)
		else:
			# Play locked sound or show message for locked levels
			print("🔒 Cannot select locked level: ", level_id)
	
	func _exit_tree():
		# Clean up tweens when card is destroyed
		if focus_tween:
			focus_tween.kill()
		if hover_tween:
			hover_tween.kill()
	
	func _on_button_pressed():
		activate()
	
	func _on_gui_input(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				print("🖱️ Mouse click detected on level card: ", level_id)
				activate()
	
	func _on_mouse_entered():
		if is_unlocked:
			# Kill any existing hover tween
			if hover_tween:
				hover_tween.kill()
			
			# Bring hovered card slightly forward
			z_index = 5
			
			hover_tween = create_tween()
			hover_tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)
			hover_tween.parallel().tween_property(main_panel, "modulate", Color(1.3, 1.3, 1.3), 0.1)
	
	func _on_mouse_exited():
		# Kill any existing hover tween
		if hover_tween:
			hover_tween.kill()
		
		# Reset z-index (unless focused)
		if z_index != 10:  # Don't reset if card is focused
			z_index = 0
		
		hover_tween = create_tween()
		hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
		# Reset to original color based on status
		var original_color = Color.WHITE
		if is_perfect:
			original_color = Color(1.2, 1.1, 0.8)
		elif is_completed:
			original_color = Color(1.1, 1.1, 1.0)
		elif !is_unlocked:
			original_color = Color(0.6, 0.6, 0.6)
		hover_tween.parallel().tween_property(main_panel, "modulate", original_color, 0.1)

func _ready():
	print("🗺️ LevelMapPro _ready() called")
	
	_load_configurations()
	_connect_signals()
	_setup_ui()
	_create_level_grid()
	_update_progress()
	_setup_keyboard_navigation()
	
	# Connect to level unlock events
	if EventBus and EventBus.has_signal("level_unlocked"):
		EventBus.level_unlocked.connect(_on_level_unlocked)
	
	# Start entrance animation
	if animation_player and animation_player.has_animation("slide_in"):
		animation_player.play("slide_in")
	
	print("✅ Professional Level Map initialized")

func _load_configurations():
	"""Load map configuration and levels data"""
	# Load map config
	var map_config_path = "res://data/level_map_config.json"
	if FileAccess.file_exists(map_config_path):
		var file = FileAccess.open(map_config_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				map_config = json.data
				level_nodes_data = map_config.get("level_nodes", [])
	
	# Load levels data
	var levels_path = "res://data/level_map_config.json"
	if FileAccess.file_exists(levels_path):
		var file = FileAccess.open(levels_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				levels_data = json.data.get("levels", {})
	
	# Check dev mode
	dev_mode = map_config.get("map_config", {}).get("dev_mode", {}).get("unlock_all", false)
	
	print("📊 Loaded ", level_nodes_data.size(), " level nodes")

func _connect_signals():
	"""Connect UI signals"""
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	if dev_button:
		dev_button.pressed.connect(_on_dev_pressed)

func _setup_ui():
	"""Setup UI elements"""
	# Update title
	var title_node = $UI/Header/TitleContainer/Title
	if title_node:
		title_node.text = "SELECT LEVEL"
	
	# Show/hide dev button based on debug mode
	if dev_button:
		dev_button.visible = map_config.get("map_config", {}).get("dev_mode", {}).get("show_debug_info", false)
		# Initialize button text based on current dev_mode state
		dev_button.text = "DEV: ON" if dev_mode else "DEV: OFF"
		dev_button.modulate = Color.YELLOW if dev_mode else Color.WHITE
	
	# Calculate card width based on viewport
	var viewport_width = get_viewport().get_visible_rect().size.x
	card_width = (viewport_width - 100) / cards_visible  # 100px for margins
	card_width = max(card_width, 400)  # Minimum card width

func _create_level_grid():
	"""Create the level grid"""
	print("🎨 Creating level grid...")
	
	# Clear existing cards
	for child in level_grid.get_children():
		child.queue_free()
	
	created_level_cards.clear()
	
	# Add left padding spacer
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(20, 1)
	level_grid.add_child(left_spacer)
	
	# Create level cards
	for node_data in level_nodes_data:
		_create_level_card(node_data)
	
	# Add right padding spacer
	var right_spacer = Control.new()
	right_spacer.custom_minimum_size = Vector2(20, 1)
	level_grid.add_child(right_spacer)
	
	print("✅ Level grid created with ", created_level_cards.size(), " cards")

func _create_level_card(node_data: Dictionary):
	"""Create a single level card"""
	var level_id = node_data.get("id", "")
	if level_id == "":
		return
	
	var level_info = levels_data.get(level_id, {})
	
	# Create level card
	var level_card = LevelCard.new(level_id, node_data, level_info)
	
	# Set consistent sizing for all cards
	level_card.custom_minimum_size = Vector2(card_width, 320)
	level_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	level_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	# Load thumbnail
	level_card.load_thumbnail()
	
	# Update status based on game progress
	var is_unlocked = _is_level_unlocked(level_id, node_data)
	
	# Get completion data from Persistence for more accurate status
	var completion_data = {}
	if Persistence and Persistence.has_method("get_level_completion"):
		completion_data = Persistence.get_level_completion(level_id)
	
	var is_completed = completion_data.get("completed", false) or level_info.get("best_score", 0) > 0
	var is_perfect = _is_level_perfect(level_info, completion_data)
	
	level_card.update_status(is_unlocked, is_completed, is_perfect)
	
	# Connect signal
	level_card.level_selected.connect(_on_level_selected)
	
	# Add to grid
	level_grid.add_child(level_card)
	created_level_cards.append(level_card)
	
	# Animate card entrance
	_animate_card_entrance(level_card, created_level_cards.size() - 1)

func _setup_keyboard_navigation():
	"""Setup keyboard navigation"""
	if created_level_cards.size() > 0:
		# Find the first uncompleted but unlocked level to auto-select
		selected_index = _find_next_recommended_level()
		_update_focus_display()
		_scroll_to_selected()

func _find_next_recommended_level() -> int:
	"""Find the first uncompleted but unlocked level to auto-select"""
	# First, try to find the first uncompleted but unlocked level
	for i in range(created_level_cards.size()):
		var card = created_level_cards[i]
		if card and is_instance_valid(card):
			if card.is_unlocked and not card.is_completed:
				print("🎯 Auto-selecting next uncompleted level: ", card.level_id, " at index ", i)
				return i
	
	# If all unlocked levels are completed, select the first unlocked level
	for i in range(created_level_cards.size()):
		var card = created_level_cards[i]
		if card and is_instance_valid(card):
			if card.is_unlocked:
				print("🎯 Auto-selecting first unlocked level: ", card.level_id, " at index ", i)
				return i
	
	# Fallback to first level if nothing is unlocked (shouldn't happen normally)
	print("🎯 Fallback: Auto-selecting first level at index 0")
	return 0

func _update_focus_display():
	"""Update visual focus indicators"""
	for i in range(created_level_cards.size()):
		var card = created_level_cards[i]
		if card and is_instance_valid(card):
			card.set_focused(i == selected_index)

func _is_level_unlocked(level_id: String, node_data: Dictionary) -> bool:
	"""Check if a level is unlocked"""
	
	# DEV MODE: Unlock all levels
	if dev_mode:
		print("🔧 DEV MODE: Level ", level_id, " force unlocked")
		return true
	
	# FIRST LEVEL: Always unlocked
	if level_id == "Level00":
		print("🌟 Level00 (First Steps) is always unlocked")
		return true
	
	# Check unlock requirements from level map config
	var requirements = node_data.get("unlock_requirements", {})
	
	# If no requirements but not Level00, should be locked by default
	if requirements.is_empty():
		print("🔒 Level ", level_id, " locked - no unlock requirements (not first level)")
		return false
	
	# Check previous level requirement
	if "previous_level" in requirements:
		var prev_level = requirements.previous_level
		var prev_completed = false
		var prev_score = 0
		
		# Check completion via Persistence first
		if Persistence and Persistence.has_method("is_level_completed"):
			prev_completed = Persistence.is_level_completed(prev_level)
			print("🔍 Persistence check: ", prev_level, " completed = ", prev_completed)
		
		# Get score data
		if Persistence and Persistence.has_method("get_level_completion"):
			var completion_data = Persistence.get_level_completion(prev_level)
			prev_score = completion_data.get("score", 0)
		
		# Fallback to levels.json data
		if not prev_completed or prev_score <= 0:
			var prev_info = levels_data.get(prev_level, {})
			prev_score = max(prev_score, prev_info.get("best_score", 0))
			prev_completed = prev_score > 0
		
		if not prev_completed:
			print("🔒 Level ", level_id, " locked - previous level ", prev_level, " not completed")
			return false
		
		# Check minimum score requirement if specified
		if "min_score" in requirements:
			var required_score = requirements.min_score
			if prev_score < required_score:
				print("🔒 Level ", level_id, " locked - insufficient score on ", prev_level, " (", prev_score, "/", required_score, ")")
				return false
			else:
				print("✅ Score requirement met: ", prev_score, "/", required_score)
	
	print("✅ Level ", level_id, " requirements met - UNLOCKED")
	return true

func _is_level_perfect(level_info: Dictionary, completion_data: Dictionary = {}) -> bool:
	"""Check if level was completed perfectly"""
	# Check completion data first for more accurate information
	var best_score = completion_data.get("score", level_info.get("best_score", 0))
	var hearts_remaining = completion_data.get("hearts_remaining", -1)
	var gems_found = completion_data.get("gems_found", 0)
	var total_gems = completion_data.get("total_gems", 0)
	
	# Perfect completion criteria:
	# 1. High score (above gold threshold)
	# 2. All or most hearts remaining (4-5 hearts)
	# 3. All gems collected (if any gems exist)
	
	var relic_thresholds = level_info.get("relic_thresholds", {})
	var gold_threshold = relic_thresholds.get("gold", 250)  # Default gold threshold
	
	var has_good_score = best_score >= gold_threshold
	var has_good_hearts = hearts_remaining >= 4 or hearts_remaining == -1  # -1 means no data, assume good
	var has_all_gems = total_gems == 0 or gems_found >= total_gems
	
	return best_score > 0 and has_good_score and has_good_hearts and has_all_gems

func _update_progress():
	"""Update overall progress display"""
	var total_levels = level_nodes_data.size()
	var completed_levels = 0
	var perfect_levels = 0
	var total_score = 0
	var total_hearts_remaining = 0
	var levels_with_heart_data = 0
	
	for node_data in level_nodes_data:
		var level_id = node_data.get("id", "")
		var level_info = levels_data.get(level_id, {})
		
		# Get completion data from Persistence
		var completion_data = {}
		if Persistence and Persistence.has_method("get_level_completion"):
			completion_data = Persistence.get_level_completion(level_id)
		
		var best_score = completion_data.get("score", level_info.get("best_score", 0))
		var is_completed = completion_data.get("completed", false) or best_score > 0
		
		if is_completed:
			completed_levels += 1
			total_score += best_score
			
			# Track hearts data if available
			var hearts_remaining = completion_data.get("hearts_remaining", -1)
			if hearts_remaining >= 0:
				total_hearts_remaining += hearts_remaining
				levels_with_heart_data += 1
			
			if _is_level_perfect(level_info, completion_data):
				perfect_levels += 1
	
	# Update progress label with more detail
	if progress_label:
		var progress_text = "Progress: %d/%d Complete" % [completed_levels, total_levels]
		if perfect_levels > 0:
			progress_text += " • %d Perfect" % perfect_levels
		if total_score > 0:
			progress_text += " • Total Score: %d" % total_score
		if levels_with_heart_data > 0:
			var avg_hearts = float(total_hearts_remaining) / float(levels_with_heart_data)
			progress_text += " • Avg Hearts: %.1f/5" % avg_hearts
		progress_label.text = progress_text
	
	# Update progress bar with smooth animation
	if progress_bar:
		var progress_percent = (float(completed_levels) / float(total_levels)) * 100.0
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", progress_percent, 0.5)
		tween.set_ease(Tween.EASE_OUT)

func _trigger_glitch_transition():
	"""Trigger dimension glitch effect for menu transitions"""
	if DimensionManager and DimensionManager.has_method("trigger_menu_glitch_effect"):
		DimensionManager.trigger_menu_glitch_effect()
		print("🌀 Triggered glitch transition effect")
	else:
		print("⚠️ DimensionManager not available for glitch effect")

# Signal handlers
func _on_back_pressed():
	"""Handle back button press"""
	print("🏠 Going back to main menu")
	_trigger_glitch_transition()
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")

func _on_dev_pressed():
	"""Toggle dev mode"""
	dev_mode = !dev_mode
	print("🔧 DEV MODE TOGGLED: ", "ON" if dev_mode else "OFF")
	
	# Update button text with visual feedback
	if dev_button:
		dev_button.text = "DEV: ON" if dev_mode else "DEV: OFF"
		dev_button.modulate = Color.YELLOW if dev_mode else Color.WHITE
	
	# Play feedback sound
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx("ui_select")
	
	# Refresh grid and selection
	print("🔧 Refreshing level grid with dev_mode = ", dev_mode)
	_create_level_grid()
	_setup_keyboard_navigation()
	
	# If we switched to normal mode and current selection is locked, find a valid selection
	if not dev_mode:
		var current_card = created_level_cards[selected_index] if selected_index < created_level_cards.size() else null
		if current_card and not current_card.is_unlocked:
			print("🔧 Current selection is now locked, finding valid level")
			selected_index = _find_next_recommended_level()
			_update_focus_display()
			_scroll_to_selected()
	
	print("🔧 Dev mode toggle complete")

func _on_level_selected(level_id: String):
	"""Handle level selection"""
	print("🎯 Level selected: ", level_id)
	_load_level(level_id)

func _load_level(level_id: String, time_trial: bool = false):
	"""Load a level"""
	print("🎮 Loading level: ", level_id, " (Time Trial: ", time_trial, ")")
	
	# Trigger glitch effect before level transition
	_trigger_glitch_transition()
	
	# First try to construct the scene path directly
	var scene_path = "res://levels/" + level_id + ".tscn"
	
	# Check if the scene file exists
	if FileAccess.file_exists(scene_path):
		print("✅ Found level scene: ", scene_path)
		# Update game state
		if Game:
			Game.current_level = level_id
		
		# Wait for glitch effect then load
		await get_tree().create_timer(0.3).timeout
		get_tree().change_scene_to_file(scene_path)
		return
	
	# Fallback: Try using LevelLoader if available
	if LevelLoader:
		if time_trial:
			LevelLoader.load_time_trial(level_id)
		else:
			LevelLoader.goto(level_id)
	else:
		# Last resort: check levels_data for scene path
		var level_info = levels_data.get(level_id, {})
		var fallback_scene_path = level_info.get("scene_path", "")
		if fallback_scene_path != "" and FileAccess.file_exists(fallback_scene_path):
			get_tree().change_scene_to_file(fallback_scene_path)
		else:
			print("❌ Level scene not found for: ", level_id)
			print("❌ Tried paths: ", scene_path, " and ", fallback_scene_path)

# Input handling
func _input(event):
	"""Handle input events"""
	if Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump"):
		if created_level_cards.size() > 0 and selected_index < created_level_cards.size():
			created_level_cards[selected_index].activate()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_right"):
		_navigate_selection(1)
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("move_left"):
		_navigate_selection(-1)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		# Handle mouse wheel for horizontal scrolling
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_navigate_selection(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_navigate_selection(1)
			get_viewport().set_input_as_handled()

func _navigate_selection(direction: int):
	"""Navigate selection with keyboard"""
	if created_level_cards.is_empty():
		return
	
	var new_index = selected_index
	var attempts = 0
	var max_attempts = created_level_cards.size()
	
	# Keep moving in the direction until we find an unlocked level or reach the end
	while attempts < max_attempts:
		new_index += direction
		
		# Wrap around or clamp to valid range
		if new_index < 0:
			new_index = created_level_cards.size() - 1
		elif new_index >= created_level_cards.size():
			new_index = 0
		
		# Check if this level is selectable
		var card = created_level_cards[new_index]
		if card and is_instance_valid(card):
			# In dev mode, all levels are selectable
			# In normal mode, only unlocked levels are selectable
			if dev_mode or card.is_unlocked:
				break
		
		attempts += 1
	
	# If we found a valid level, select it
	if new_index != selected_index and attempts < max_attempts:
		selected_index = new_index
		_update_focus_display()
		_scroll_to_selected()
		
		# Play navigation sound
		if Audio and Audio.has_method("play_sfx"):
			Audio.play_sfx("ui_focus")
	else:
		# Play error sound if no valid level found
		if Audio and Audio.has_method("play_sfx"):
			Audio.play_sfx("ui_error")

func _scroll_to_selected():
	"""Scroll to keep selected item visible"""
	if selected_index >= created_level_cards.size():
		return
	
	var selected_card = created_level_cards[selected_index]
	var card_rect = selected_card.get_rect()
	var scroll_rect = scroll_container.get_rect()
	
	# Calculate horizontal scroll position
	var scroll_pos = scroll_container.scroll_horizontal
	var card_left = card_rect.position.x
	var card_right = card_rect.position.x + card_rect.size.x
	var visible_width = scroll_rect.size.x
	
	# Smooth scroll to center the selected card
	var target_scroll = card_left - (visible_width - card_rect.size.x) / 2
	target_scroll = max(0, target_scroll)
	
	# Animate scroll
	var tween = create_tween()
	tween.tween_property(scroll_container, "scroll_horizontal", int(target_scroll), 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

func _animate_card_entrance(card: LevelCard, index: int):
	"""Animate card entrance with staggered timing"""
	# Simple fade in animation without position changes to avoid alignment issues
	card.modulate.a = 0.0
	card.scale = Vector2(0.8, 0.8)
	
	# Staggered animation delay using a timer
	var delay = index * 0.05
	
	await get_tree().create_timer(delay).timeout
	
	var tween = create_tween()
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.3)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

func _on_level_unlocked(level_id: String):
	"""Handle level unlock notification"""
	print("🔓 Level unlocked notification received: ", level_id)
	
	# Refresh the level grid to show newly unlocked levels
	_refresh_level_status()
	
	# Show unlock notification
	_show_unlock_notification(level_id)

func _refresh_level_status():
	"""Refresh the unlock status of all level cards"""
	print("🔄 Refreshing level status...")
	
	# Reload configurations to get latest data
	_load_configurations()
	
	# Update each card's status
	for i in range(created_level_cards.size()):
		var card = created_level_cards[i]
		if not card or not is_instance_valid(card):
			continue
		
		var level_id = card.level_id
		var node_data = null
		
		# Find the node data for this level
		for node in level_nodes_data:
			if node.get("id", "") == level_id:
				node_data = node
				break
		
		if not node_data:
			continue
		
		# Update card status
		var level_info = levels_data.get(level_id, {})
		var is_unlocked = _is_level_unlocked(level_id, node_data)
		
		# Get completion data from Persistence
		var completion_data = {}
		if Persistence and Persistence.has_method("get_level_completion"):
			completion_data = Persistence.get_level_completion(level_id)
		
		var is_completed = completion_data.get("completed", false) or level_info.get("best_score", 0) > 0
		var is_perfect = _is_level_perfect(level_info, completion_data)
		
		card.update_status(is_unlocked, is_completed, is_perfect)
	
	# Update progress display
	_update_progress()

func _show_unlock_notification(level_id: String):
	"""Show a notification that a level was unlocked"""
	# Find the display name for the level
	var display_name = level_id
	for node in level_nodes_data:
		if node.get("id", "") == level_id:
			display_name = node.get("display_name", level_id)
			break
	
	print("🎉 New level unlocked: ", display_name)
	
	# Play unlock sound
	if Audio and Audio.has_method("play_sfx"):
		Audio.play_sfx("ui_level_unlock")
	
	# TODO: Add visual notification popup if desired
