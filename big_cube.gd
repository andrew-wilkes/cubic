extends Node3D

const PIVOT_POSITIONS = [
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.UP,
	Vector3.FORWARD,
	Vector3.BACK
]

enum FACES { UP, FRONT, RIGHT, BACK, LEFT, DOWN }

var piece = preload("res://cube.tscn")
var pivot = self

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
				cube.get_child(FACES.UP).visible = y == 1
				cube.get_child(FACES.DOWN).visible = y == -1
				cube.get_child(FACES.RIGHT).visible = x == 1
				cube.get_child(FACES.LEFT).visible = x == -1
				cube.get_child(FACES.FRONT).visible = z == 1
				cube.get_child(FACES.BACK).visible = z == -1


func solved():
	return get_cube_state_signature() < 0.1


func get_cube_state_signature():
	var sum = Vector3.ZERO
	for cube in get_children():
		sum = cube.rotation + sum
	return sum.length_squared()


func rotate_face(idx, dir = 1):
	var group = get_group(idx)
	reparent_to_pivot(group)
	rotate_group(idx, dir)
	reparent_to_origin()


# TODO: Animate the rotations
func rotate_group(idx, dir):
	var rot_angle = PI / 2 * dir
	match idx:
		0, 1:
			pivot.rotate_x(rot_angle)
		2, 3:
			pivot.rotate_y(rot_angle)
		4, 5:
			pivot.rotate_z(rot_angle)


func get_group(idx):
	var group = []
	for cube in get_children():
		if PIVOT_POSITIONS[idx] == cube.position:
			pivot = cube
		# Using the DOT product here
		if cube.position.dot(PIVOT_POSITIONS[idx]) > 0.5:
			group.append(cube)
	return group


func reparent_to_pivot(group):
	var node = pivot.get_node("Cubes")
	for cube in group:
		if cube != pivot:
			cube.reparent(node)


func reparent_to_origin():
	if pivot != self:
		# Reparent previously rotated child cubes to self
		for cube in pivot.get_node("Cubes").get_children():
			cube.reparent(self)
