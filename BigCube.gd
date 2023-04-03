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
	# Apply colors to faces
	for idx in 6:
		instance.get_child(idx).material.set_shader_parameter("color", colors[idx])
	# Init the cubes array to store groups of cubes
	cubes.resize(9)
	for idx in 9:
		cubes[idx] = []
	# Generate the cube
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				# Add cube to group
				cubes[x + 1].append(cube)
				cubes[y + 4].append(cube)
				cubes[z + 7].append(cube)
				add_child(cube)
				# Hide unseen faces
				cube.get_child(0).visible = y == 1
				cube.get_child(5).visible = y == -1
				cube.get_child(2).visible = x == 1
				cube.get_child(4).visible = x == -1
				cube.get_child(1).visible = z == 1
				cube.get_child(3).visible = z == -1
	print(cubes)
