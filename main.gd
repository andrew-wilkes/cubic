extends Node3D

var face = 0

func _on_button_pressed():
	face = (face + 1) % 6
	$BigCube.rotate_face(face)
	print($BigCube.solved())


func _process(_delta):
	var vec = $OrbitingCamera/XAxis/YAxis/Camera.global_position.normalized()
	$C/UI/Label.text = str($BigCube.get_face(vec))
