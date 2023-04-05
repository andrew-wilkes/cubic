extends Node3D

var face = 0

func _on_button_pressed():
	$BigCube.rotate_face(face)
	face = (face + 1) % 6


func _process(_delta):
	var vec = $OrbitingCamera/XAxis/YAxis/Camera.global_position.normalized()
	$C/UI/Label.text = str($BigCube.get_face(vec))
