extends Node3D

class_name BigCube

enum FACES { UP, FRONT, RIGHT, BACK, LEFT, DOWN }

const PIVOT_POSITIONS = [
	Vector3.UP,
	Vector3.BACK,
	Vector3.RIGHT,
	Vector3.FORWARD,
	Vector3.LEFT,
	Vector3.DOWN
]
const INITIAL_FACE_MAP = [
	FACES.UP,
	FACES.FRONT,
	FACES.RIGHT,
	FACES.BACK,
	FACES.LEFT,
	FACES.DOWN
]
const CUBE_IDXS = [-1, 0, 1]
const UPPERV = CUBE_IDXS[-1]
const LOWERV = CUBE_IDXS[0]

@export var rotation_speed = 3.0

var piece = preload("res://cube.tscn")
var pivot = self
var current_face = FACES.FRONT

# Keep a record of which of the 4 rotation positions each face is at
var face_rotations = [0, 0, 0, 0, 0, 0]
var face_rotating_idx := -1
var face_rotation_angle = 0
var face_rotation_direction := 1
var face_map = INITIAL_FACE_MAP

func rotate_face_map_up():
	face_map = [face_map[1], face_map[5], face_map[2], face_map[0], face_map[4], face_map[3]]


func rotate_face_map_down():
	face_map = [face_map[3], face_map[0], face_map[2], face_map[5], face_map[4], face_map[1]]


func rotate_face_map_right():
	face_map = [face_map[0], face_map[2], face_map[3], face_map[4], face_map[1], face_map[5]]


func rotate_face_map_left():
	face_map = [face_map[0], face_map[4], face_map[1], face_map[2], face_map[3], face_map[5]]


func _ready():
	# Generate the cube
	var instance: Node3D = piece.instantiate()
	for x in CUBE_IDXS:
		for y in CUBE_IDXS:
			for z in CUBE_IDXS:
				var cube = instance.duplicate()
				cube.position = Vector3(x, y, z)
				add_child(cube)
				# Set face visibility
				cube.get_child(FACES.UP).visible = y == UPPERV
				cube.get_child(FACES.DOWN).visible = y == LOWERV
				cube.get_child(FACES.RIGHT).visible = x == UPPERV
				cube.get_child(FACES.LEFT).visible = x == LOWERV
				cube.get_child(FACES.FRONT).visible = z == UPPERV
				cube.get_child(FACES.BACK).visible = z == LOWERV


# Animate the cube group rotation
func _process(delta):
	if face_rotating_idx > -1:
		var offset = face_rotations[face_rotating_idx]
		face_rotation_angle = clamp(face_rotation_angle + delta * rotation_speed, 0, PI / 2)
		rotate_group(face_rotating_idx, face_rotation_angle * face_rotation_direction + offset * PI / 2)
		if face_rotation_angle >= PI / 2:
			# Rotation complete
			face_rotation_angle = 0
			face_rotations[face_rotating_idx] = (offset + face_rotation_direction) % 4
			face_rotating_idx = -1
			reparent_to_origin()


func solved():
	return get_cube_state_signature() < 0.1


func get_cube_state_signature():
	var sum = Vector3.ZERO
	for cube in get_children():
		sum = cube.rotation + sum
	return sum.length_squared()


func rotate_face(idx, dir = 1):
	if face_rotating_idx < 0:
		var group = get_group(idx)
		reparent_to_pivot(group)
		face_rotating_idx = idx
		face_rotation_direction = dir


func rotate_group(idx, rot_angle):
	pivot.transform.basis = Basis() # reset rotation
	match idx:
		FACES.LEFT, FACES.RIGHT:
			pivot.rotate_x(rot_angle)
		FACES.UP, FACES.DOWN:
			pivot.rotate_y(rot_angle)
		FACES.FRONT, FACES.BACK:
			pivot.rotate_z(rot_angle)


func get_group(idx):
	var group = []
	for cube in get_children():
		if PIVOT_POSITIONS[idx] == cube.position:
			pivot = cube
		# Using the DOT product here to find cubes on the same face as the pivot cube
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
