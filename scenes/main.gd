extends Node3D

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(bname, shift):
	if FACE_BUTTONS.has(bname):
		var direction = -1 if shift else 1
		var x_rot = get_rounded_rotation_value($OrbitingCamera/XAxis.rotation.x)
		var y_rot = get_rounded_rotation_value($OrbitingCamera/XAxis/YAxis.rotation.y)
		$BigCube.rotate_face(FACE_BUTTONS.find(bname), direction, x_rot, y_rot)
	match bname:
		"Reset":
			$BigCube.reset()
		"Scramble":
			for n in randi_range(10, 15):
				$BigCube.rotate_face_immediate(randi() % 6, 1 if randf() > 0.5 else -1)
		"Solve":
			pass


func get_rounded_rotation_value(angle):
	# Convert -PI .. PI to 0/1/2/3
	# The offset aligns the value with the correct face index
	return int(round(angle / PI * 2) + 4) % 4
