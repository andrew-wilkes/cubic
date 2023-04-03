extends Node3D

var shader = preload("res://assets/cube.gdshader")
var piece = preload("res://cube.tscn")

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
	# Generate the cube
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				add_child(cube)
				# Hide unseen faces
				cube.get_child(0).visible = y == 1
				cube.get_child(5).visible = y == -1
				cube.get_child(2).visible = x == 1
				cube.get_child(4).visible = x == -1
				cube.get_child(1).visible = z == 1
				cube.get_child(3).visible = z == -1
	var group_idx = 5
	var group = get_group(group_idx)
	reparent_to_pivot(group)
	rotate_group(group_idx, group)


func rotate_group(idx, group, dir = 1):
	match idx:
		0,1:
			group[4].rotate_x(PI / 4 * dir)
		2,3:
			group[4].rotate_y(PI / 4 * dir)
		4,5:
			group[4].rotate_z(PI / 4 * dir)


func get_group(idx):
	var pivot_pos = [Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,-1,0),Vector3(0,1,0),Vector3(0,0,-1),Vector3(0,0,1)]
	var group = []
	for cube in get_children():
		if (cube.position.dot(pivot_pos[idx]) > 0.5):
			group.append(cube)
	return group


func reparent_to_pivot(group):
	var pivot = group[4]
	for idx in [0,1,2,3,5,6,7,8]:
		group[idx].reparent(pivot)
