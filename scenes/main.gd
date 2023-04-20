extends Node3D

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(bname, shift, ctrl):
	if FACE_BUTTONS.has(bname):
		var button_idx = FACE_BUTTONS.find(bname)
		if ctrl:
			$BigCube/Pivot.rotate_to_face(button_idx)
		else:
			var direction = -1 if shift else 1
			$BigCube.rotate_face(button_idx, direction, $BigCube/Pivot.transform.basis)
	match bname:
		"Reset":
			$BigCube.reset()
		"Scramble":
			for n in randi_range(10, 15):
				$BigCube.rotate_face_immediate(randi() % 6, 1 if randf() > 0.5 else -1)
		"Solve":
			pass
		"CopyCube":
			$C/ColorMap.set_edge_colors($BigCube.get_edge_colors())
			$C/ColorMap.set_corner_colors($BigCube.get_corner_colors())
		"CopyMap":
			$BigCube.apply_map($C/ColorMap.get_data())


func get_rounded_rotation_value(angle):
	# Convert -PI .. PI to 0/1/2/3
	# The offset aligns the value with the correct face index
	return int(round(angle / PI * 2) + 4) % 4
