extends Node3D

class_name BigCube

enum FACES { UP, LEFT, FRONT, RIGHT, DOWN, BACK }

const PIVOT_POSITIONS = [
	Vector3.UP,
	Vector3.LEFT,
	Vector3.BACK,
	Vector3.RIGHT,
	Vector3.DOWN,
	Vector3.FORWARD
]
const INITIAL_FACE_MAP = [
	FACES.UP,
	FACES.LEFT,
	FACES.FRONT,
	FACES.RIGHT,
	FACES.DOWN,
	FACES.BACK
]
const CUBE_IDXS = [-1, 0, 1]
const UPPERV = CUBE_IDXS[-1]
const LOWERV = CUBE_IDXS[0]
const X_AXIS_FACES = [FACES.UP, FACES.FRONT, FACES.DOWN, FACES.BACK]
const Y_AXIS_FACES = [FACES.LEFT, FACES.FRONT, FACES.RIGHT, FACES.BACK]

const EDGE_POSITIONS = [[0,1,-1],[-1,1,0],[1,1,0],[0,1,1],[-1,0,-1],[-1,0,1],[1,0,1],[1,0,-1],[-1,-1,0],[0,-1,1],[1,-1, 0],[0,-1,-1]]
const CORNER_POSITIONS = [[-1,1,-1],[1,1,-1],[-1,1,1],[1,1,1],[-1,-1,-1],[-1,-1,1],[1,-1,1],[1,-1,-1]]

const ROTATIONS = [0, 1, 2, -1]

@export var rotation_speed = 3.0

var piece = preload("res://scenes/cube.tscn")
var pivot = self

# Keep a record of which of the 4 rotation positions each face is at
var face_rotations = [0, 0, 0, 0, 0, 0]
var face_rotating_idx := -1
var face_rotation_angle = 0
var face_rotation_direction := 1
var rotation_dict = {}

func _ready():
	# Generate the cube
	var cube_instance: Node3D = piece.instantiate()
	for x in CUBE_IDXS:
		for y in CUBE_IDXS:
			for z in CUBE_IDXS:
				var cube = cube_instance.duplicate()
				cube.position = Vector3(x, y, z)
				cube.set_meta("initial_position", cube.position) # Useful when resetting
				add_child(cube)
				# Set face visibility
				cube.get_child(FACES.UP).visible = y == UPPERV
				cube.get_child(FACES.DOWN).visible = y == LOWERV
				cube.get_child(FACES.RIGHT).visible = x == UPPERV
				cube.get_child(FACES.LEFT).visible = x == LOWERV
				cube.get_child(FACES.FRONT).visible = z == UPPERV
				cube.get_child(FACES.BACK).visible = z == LOWERV
	fill_rotation_dict(cube_instance)


func reset():
	face_rotations = [0, 0, 0, 0, 0, 0]
	for cube in get_children():
		cube.transform.basis = Basis()
		cube.position = cube.get_meta("initial_position")


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
		var face_map = rotate_faces_in_map(INITIAL_FACE_MAP, X_AXIS_FACES, x_rot) 
		face_map = rotate_faces_in_map(face_map, Y_AXIS_FACES, y_rot)
		idx = face_map[idx]
		var group = get_group(idx)
		reparent_to_pivot(group)
		face_rotating_idx = idx
		# Correct the rotation direction according to the front face orientation
		face_rotation_direction = dir if idx in [FACES.BACK, FACES.DOWN, FACES.LEFT] else -dir


func rotate_face_immediate(idx, dir):
	var group = get_group(idx)
	reparent_to_pivot(group)
	rotate_group(idx, PI / 2 * dir)
	reparent_to_origin()


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

###################################################
# Functions to use with mapping colors to/from cube

func get_edge_colors():
	var edge_colors = []
	for node in get_edge_nodes():
		edge_colors.append(get_colors_of_cube(node))
	return edge_colors


func get_corner_colors():
	var corner_colors = []
	for node in get_corner_nodes():
		corner_colors.append(get_colors_of_cube(node))
	return corner_colors


func get_edge_nodes():
	var edge_nodes = []
	for pos in EDGE_POSITIONS:
		for node in get_children():
			if (node.position - Vector3(pos[0], pos[1], pos[2])).length_squared() < 0.1:
				edge_nodes.append(node)
	return edge_nodes


func get_corner_nodes():
	var corner_nodes = []
	for pos in CORNER_POSITIONS:
		for node in get_children():
			if (node.position - Vector3(pos[0], pos[1], pos[2])).length_squared() < 0.1:
				corner_nodes.append(node)
	return corner_nodes


func get_colors_of_cube(node):
	var colors = []
	for tile_idx in 6:
		var tile_pos = PIVOT_POSITIONS[tile_idx]
		for color_idx in 6:
			var pos = get_tile_position(node, color_idx)
			if pos.dot(tile_pos) > 0.5:
				colors.append(color_idx)
	return colors


func get_tile_position(node, color_idx):
	return (node.get_child(color_idx).global_position - node.global_position).normalized()


func set_edges(map_data):
	var idx = 0
	for node in get_edge_nodes():
		# Find out where this node should be moved to
		var edge_idx = map_data.edge_positions.find(idx)
		var pos = EDGE_POSITIONS[edge_idx]
		node.transform.basis = Basis()
		node.position = Vector3(pos[0], pos[1], pos[2])
		# Rotate the cube to align the faces correctly
		rotate_cube(node, map_data.edge_colors[edge_idx], map_data.edge_face_map[edge_idx])
		idx += 1


func rotate_cube(node, colors, faces):
	# Form the key array
	# Loopkup the rotation info
	# Rotate the node
	pass


func set_corners(map_data):
	var idx = 0
	for node in get_corner_nodes():
		var pos = CORNER_POSITIONS[map_data.corner_positions[idx]]
		node.position = Vector3(pos[0], pos[1], pos[2])
		idx += 1


func apply_map(map_data):
	set_edges(map_data)
	set_corners(map_data)
	# Rotate the cubes to align the colors


func get_face_color(node, face_idx):
	var face_normal = (node.get_child(face_idx).global_position - node.global_position).normalized()
	for idx in 6:
		if face_normal.dot(PIVOT_POSITIONS[idx]) > 0.5:
			return idx


# Make lookup dictionary of face orientations vs rotations (in XYZ order)
# There are 24 possible permutations of cube faces
func fill_rotation_dict(cube):
	add_child(cube)
	for x in ROTATIONS:
		for y in ROTATIONS:
			for z in ROTATIONS:
				cube.transform.basis = Basis() # reset rotation
				cube.rotate_x(x * PI/2)
				cube.rotate_y(y * PI/2)
				cube.rotate_z(z * PI/2)
				var faces = []
				for idx in 6:
					faces.append(get_face_color(cube, idx))
				if not rotation_dict.has(faces):
					rotation_dict[faces] = [x,y,z]
	remove_child(cube)
