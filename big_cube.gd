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
const FACE_MAP = {
	16: FACES.UP,
	22: FACES.FRONT,
	14: FACES.RIGHT,
	4: FACES.BACK,
	12: FACES.LEFT,
	10: FACES.DOWN
}
const CUBE_IDXS = [-1, 0, 1]
const UPPERV = CUBE_IDXS[-1]
const LOWERV = CUBE_IDXS[0]

@export var rotation_speed = 3.0

var piece = preload("res://cube.tscn")
var pivot = self
var current_face = FACES.FRONT

# Keep a record of which of the 4 positions each face it at
var face_rotations = [0, 0, 0, 0, 0, 0]
var face_rotating_idx := -1
var face_rotation_angle = 0
var face_rotation_direction := 1
var face_rotation_steps = 1

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


func _process(delta):
	if face_rotating_idx > -1:
		var offset = face_rotations[face_rotating_idx]
		face_rotation_angle = clamp(face_rotation_angle + delta * rotation_speed, 0, PI / 2)
		rotate_group(face_rotating_idx, face_rotation_angle * face_rotation_direction + offset * PI / 2)
		if face_rotation_angle >= PI * face_rotation_steps / 2:
			# Rotation complete
			face_rotation_angle = 0
			face_rotations[face_rotating_idx] = (offset + face_rotation_direction) % 4
			face_rotating_idx = -1
			reparent_to_origin()


func solved():
	return face_rotations.count(0) == 6


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


func get_face(vec):
	var sector = get_sector(vec.x) + 3 * get_sector(vec.y) + 9 * get_sector(vec.z)
	# There is a grey zone at cube edges so ignore spurious values
	if FACE_MAP.has(sector):
		current_face = FACE_MAP[sector]
	return current_face


func get_sector(x):
	if x < -0.7: return 0
	if x <= 0.7: return 1
	return 2
