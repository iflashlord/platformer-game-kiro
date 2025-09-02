extends Node
class_name ScreenShakeComponent

func shake(intensity: float = 1.0):
	# Simple screen shake implementation
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		var original_pos = camera.global_position
		
		for i in range(10):
			var shake_offset = Vector2(
				randf_range(-intensity * 5, intensity * 5),
				randf_range(-intensity * 5, intensity * 5)
			)
			tween.tween_property(camera, "global_position", original_pos + shake_offset, 0.05)
		
		tween.tween_property(camera, "global_position", original_pos, 0.05)
