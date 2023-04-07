extends Node3D

const FACE_BUTTONS = ["U", "F", "R", "B", "L", "D"]

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)


func _on_button_pressed(bname, _shift):
	if FACE_BUTTONS.has(bname):
		# Rotate the relevant face
		pass
	match bname:
		"Reset":
			pass
		"Scramble":
			pass
		"Solve":
			pass
