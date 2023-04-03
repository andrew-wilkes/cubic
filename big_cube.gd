extends Node3D

var piece = preload("res://cube.tscn")

func _ready():
	# Generate the cube
	var instance: Node3D = piece.instantiate()
	for x in [-1, 0, 1]:
		for y in [-1, 0, 1]:
			for z in [-1, 0, 1]:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				add_child(cube)
				# Set face visibility
				cube.get_child(0).visible = y == 1
				cube.get_child(5).visible = y == -1
				cube.get_child(2).visible = x == 1
				cube.get_child(4).visible = x == -1
				cube.get_child(1).visible = z == 1
				cube.get_child(3).visible = z == -1
	
	# Test
	var group_idx = 0
	var group = get_group(group_idx)
	reparent_to_pivot(group)
	rotate_group(group_idx, group)
	for cube in get_children():
		print(cube.position)
	#group_idx = 5
	#group = get_group(group_idx)
	#reparent_to_pivot(group)
	#rotate_group(group_idx, group)


func rotate_group(idx, group, dir = 1):
	var rot_angle = PI / 2 * dir
	match idx:
		0,1:
			group[4].rotate_x(rot_angle)
		2,3:
			group[4].rotate_y(rot_angle)
		4,5:
			group[4].rotate_z(rot_angle)


func get_group(idx):
	var pivot_pos = [Vector3(-1,0,0),Vector3(1,0,0),Vector3(0,-1,0),Vector3(0,1,0),Vector3(0,0,-1),Vector3(0,0,1)]
	var group = []
	for cube in get_children():
		cube.reparent(self)
		print(cube.position)
		if (cube.position.dot(pivot_pos[idx]) > 0.5):
			group.append(cube)
	print("---")
	return group


func reparent_to_pivot(group):
	var pivot = group[4]
	for idx in [0,1,2,3,5,6,7,8]:
		group[idx].reparent(pivot)
