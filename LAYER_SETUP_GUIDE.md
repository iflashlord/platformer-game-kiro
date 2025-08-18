# Layer System Setup Guide

## Method 1: Simple Visibility Toggle (Easiest)

### Step 1: Add DimensionManager to your level
```gdscript
# In your level script _ready() function
var dimension_manager = preload("res://systems/DimensionManager.gd").new()
dimension_manager.name = "DimensionManager"
add_child(dimension_manager)
```

### Step 2: Group your objects by layer
In the Godot editor:
1. Select objects that should only appear in Layer A
2. In the Groups tab, add them to group "layer_a"
3. Select objects for Layer B, add to group "layer_b"

### Step 3: Connect the groups to the system
```gdscript
# In your level script
func _ready():
	# ... dimension manager setup ...
	
	# Register all layer A objects
	var layer_a_objects = get_tree().get_nodes_in_group("layer_a")
	for obj in layer_a_objects:
		dimension_manager.register_layer_object(obj, "A")
	
	# Register all layer B objects  
	var layer_b_objects = get_tree().get_nodes_in_group("layer_b")
	for obj in layer_b_objects:
		dimension_manager.register_layer_object(obj, "B")
```

## Method 2: Using LayerObject Component (Recommended)

### Step 1: Add LayerObject to any node
1. Add `LayerObject.tscn` as a child to any node you want layer-controlled
2. Set the `target_layer` to "A" or "B" in the inspector
3. It will automatically register with DimensionManager

### Step 2: Use LayerPlatform for platforms
1. Replace regular StaticBody2D platforms with `LayerPlatform.tscn`
2. Set `target_layer` to "A" or "B"
3. Enable `ghost_in_other_layer` if you want semi-transparent instead of invisible

## Method 3: Custom Layer Behavior

### Create custom layer-aware objects:
```gdscript
extends StaticBody2D

@export var target_layer: String = "A"
@export var layer_behavior: String = "hide"  # "hide", "ghost", "disable"

func _ready():
	var dim_manager = get_tree().get_first_node_in_group("dimension_managers")
	if dim_manager:
		dim_manager.layer_changed.connect(_on_layer_changed)

func _on_layer_changed(new_layer: String):
	var is_active = (new_layer == target_layer)
	
	match layer_behavior:
		"hide":
			visible = is_active
		"ghost":
			modulate.a = 1.0 if is_active else 0.3
			collision_layer = 1 if is_active else 0
		"disable":
			set_physics_process(is_active)
			set_process(is_active)
```

## Example Level Setup

### 1. Basic Platform Switching
```
Layer A: Ground platforms, normal enemies
Layer B: Floating platforms, ghost enemies
```

### 2. Puzzle Elements
```
Layer A: Switches and doors
Layer B: Keys and hidden passages
```

### 3. Environmental Changes
```
Layer A: Day time, water obstacles
Layer B: Night time, fire obstacles
```

## FlipGate Configuration

### Toggle Gate (switches between layers)
```
target_layer = ""  # Empty = toggle mode
```

### Fixed Gates (always go to specific layer)
```
Gate 1: target_layer = "A"  # Always switches to A
Gate 2: target_layer = "B"  # Always switches to B
```

## Testing Your Layers

1. Add FlipGate to your level
2. Add some objects to different layers
3. Run the level and walk through the gate
4. Objects should appear/disappear based on current layer

## Advanced Features

### Listen to layer changes globally:
```gdscript
func _ready():
	var dim_manager = get_tree().get_first_node_in_group("dimension_managers")
	dim_manager.layer_changed.connect(_on_global_layer_change)

func _on_global_layer_change(new_layer: String):
	# Change music, lighting, physics, etc.
	pass
```

### Check current layer:
```gdscript
var dim_manager = get_tree().get_first_node_in_group("dimension_managers")
var current = dim_manager.get_current_layer()
```

### Force layer switch:
```gdscript
var dim_manager = get_tree().get_first_node_in_group("dimension_managers")
dim_manager.set_layer("B")
```