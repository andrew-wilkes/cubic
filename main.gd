extends Node3D

var face = 0

func _on_button_pressed():
	$BigCube.rotate_face(face)
	face = (face + 1) % 6


func camera_pos():
	pass


func _process(_delta):
	var vec = Vector3i($OrbitingCamera/XAxis/YAxis.global_rotation / PI * 8) # + Vector3(1,1,1)) / 2) 
	$C/UI/Label.text = str(vec)
