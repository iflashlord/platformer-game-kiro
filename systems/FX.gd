extends Node

func shake(intensity_ms: float):
	var duration = intensity_ms / 1000.0
	var strength = intensity_ms / 10.0 # Convert ms to shake strength
	
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		return
	
	camera_shake(camera, strength, duration)

func camera_shake(camera: Camera2D, strength: float, duration: float):
	if camera == null:
		return
	
	var tween = create_tween()
	var original_offset = camera.offset if camera != null else Vector2.ZERO
	var shake_count = int(duration * 60) # 60 FPS
	# Improved shake: use random offset per frame, but interpolate smoothly
	for i in range(shake_count):
		var shake_offset = Vector2(
			randf_range(-strength, strength),
			randf_range(-strength, strength)
		)
		var target_offset = original_offset + shake_offset
		tween.tween_method(
			func(offset): if camera != null: camera.offset = offset,
			camera.offset if camera != null else Vector2.ZERO,
			target_offset,
			1.0 / 60.0
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
	# Return to original position
	tween.tween_method(
		func(offset): if camera != null: camera.offset = offset,
		camera.offset if camera != null else Vector2.ZERO,
		original_offset,
		0.1
	)

func screen_shake(duration: float = 0.3, strength: float = 10.0):
	var camera = get_viewport().get_camera_2d()
	camera_shake(camera, strength, duration)

func flash_screen(color: Color = Color.WHITE, duration: float = 0.1, start_alpha: float = 1.0):
	var flash = ColorRect.new()
	flash.color = color
	flash.modulate.a = start_alpha
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var scene = get_tree().current_scene
	if scene == null:
		return
	scene.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(flash.queue_free)

func fade_in(duration: float = 1.0):
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	get_tree().current_scene.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, duration)
	tween.tween_callback(fade.queue_free)

func fade_out(duration: float = 1.0):
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	get_tree().current_scene.add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, duration)

func hit_stop(duration_ms: float):
	var duration = duration_ms / 1000.0
	
	# Pause the game briefly for impact
	get_tree().paused = true
	
	# Create a timer to unpause
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.process_mode = Node.PROCESS_MODE_ALWAYS # Works during pause
	
	get_tree().current_scene.add_child(timer)
	timer.start()
	
	# Unpause when timer finishes
	timer.timeout.connect(func():
		get_tree().paused = false
		timer.queue_free()
	)
