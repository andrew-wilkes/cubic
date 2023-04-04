extends Node3D

enum { READY, ROTATING, RESETTING, NONE, ROTATE }

var state = READY
var action = NONE
var face = 0

func _on_button_pressed():
	action = ROTATE


func _process(_delta):
	match state:
		READY:
			if action == ROTATE:
				state = ROTATING
				action = NONE
				$BigCube.rotate_face(face)
				face = (face + 1) % 6
		ROTATING:
			if $BigCube.cubes_at_pivot():
				prints("Rotating done", str(Time.get_ticks_msec()))
				$BigCube.reparent_to_origin()
				state = RESETTING
		RESETTING:
			if $BigCube.cubes_at_origin():
				state = READY
