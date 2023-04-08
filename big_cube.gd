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


func reset():
	var idx = 0
	var cubes = get_children()
	cubes.sort_custom(func(a, b): return a.get_instance_id() < b.get_instance_id())
	for x in CUBE_IDXS:
		for y in CUBE_IDXS:
			for z in CUBE_IDXS:
				var cube = cubes[idx]
				cube.transform.basis = Basis()
				cube.position = Vector3(x, y, z)
				idx += 1


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


func rotate_faces_in_map(old_map, faces, offset):
	var new_map = old_map.duplicate()
	if offset > 0:
		for idx in faces.size():
			new_map[faces[idx]] = old_map[faces[(idx + offset) % 4]]
	return new_map


func rotate_face(idx, dir, x_rot, y_rot):
	if face_rotating_idx < 0:
		# Match the face map with the camera rotation
		var face_map = rotate_faces_in_map(INITIAL_FACE_MAP, [FACES.UP, FACES.FRONT, FACES.DOWN, FACES.BACK], x_rot) 
		face_map = rotate_faces_in_map(face_map, [FACES.LEFT, FACES.FRONT, FACES.RIGHT, FACES.BACK], y_rot)
		idx = face_map[idx]
		# Correct the rotation direction according to the front face
		dir *= [-1, -1, -1, 1, 1, 1][idx]
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
