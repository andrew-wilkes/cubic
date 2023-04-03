extends Node3D

var shader = preload("res://assets/cube.gdshader")
var piece = preload("res://cube.tscn")
var cubes = []

@export_color_no_alpha var col1: Color
@export_color_no_alpha var col2: Color
@export_color_no_alpha var col3: Color
@export_color_no_alpha var col4: Color
@export_color_no_alpha var col5: Color
@export_color_no_alpha var col6: Color

func _ready():
	var colors = [col1, col2, col3, col4, col5, col6]
	var instance: Node3D = piece.instantiate()
	for idx in 6:
		instance.get_child(idx).material.set_shader_parameter("color", colors[idx])
	# Generate the cube
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				cubes.append(cube)
				add_child(cube)
