extends Node3D

var face = 0

func _on_button_pressed():
	$BigCube.rotate_face(face)
	face = (face + 1) % 6
