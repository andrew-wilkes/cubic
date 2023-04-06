extends Node3D

var face = 0
var rotating = true

func _on_button_pressed():
	rotating = !rotating
	#$BigCube.rotate_face(face)
	#face = (face + 1) % 6


func _process(_delta):
	var vec = $OrbitingCamera/XAxis/YAxis/Camera.global_position.normalized()
	$C/UI/Label.text = str($BigCube.get_face(vec))
	if rotating: $BigCube.rotate_face(BigCube.FACES.FRONT)
