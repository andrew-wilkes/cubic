extends Control

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]

var bc
var cmap
var solve_step = -1
var move_step = -1
var moves = []
var colors
var face_map
var edge_map
var corner_map
var rotation_completed = true

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)
	bc = $C/SVP/VP/BigCube
	cmap = $C/ColorMap
	%Pivot.connect("rotation_complete", rotation_done)
	bc.connect("rotation_complete", rotation_done)


func rotation_done():
	rotation_completed = true
	copy_cube()


func _on_button_pressed(bname, shift, ctrl):
	if FACE_BUTTONS.has(bname):
		var button_idx = FACE_BUTTONS.find(bname)
		if ctrl:
			bc.get_node("Pivot").rotate_to_face(button_idx)
		else:
			var direction = -1 if shift else 1
			solve_step = -1
			rotate_face(button_idx, direction, bc.get_node("Pivot").transform.basis)
	match bname:
		"Reset":
			bc.reset()
			copy_cube()
			solve_step = -1
		"Scramble":
			for n in randi_range(10, 15):
				bc.rotate_face_immediate(randi() % 6, 1 if randf() > 0.5 else -1)
			copy_cube()
			solve_step = -1
		"Solve":
			if rotation_completed:
				if solve_step < 0:
					solve_step = 1
					print("Solving")
				solve()
			#$Support.popup_centered()
		"CopyCube":
			copy_cube()
		"CopyMap":
			bc.apply_map($C/ColorMap.get_data())
		"Help":
			$Info.popup_centered()


func rotate_face(face_idx, direction, bas = Basis()):
	prints(face_idx, direction)
	bc.rotate_face(face_idx, direction, bas)
	rotation_completed = false


func copy_cube():
	$C/ColorMap.set_edge_colors(bc.get_edge_colors())
	$C/ColorMap.set_corner_colors(bc.get_corner_colors())


func move_white_edge_to_face():
	# Want to avoid disturbing already placed edges in the group: 8,9,10,11
	# Get the edge position where the piece is now
	var idx = get_edge_position(colors)
	prints("Edge:", idx)
	# Move to front face
	# Map the idx depending on the front face
	idx = edge_map[idx]
	match idx:
		0, 2:
			set_moves([[0,1]])
		1:
			set_moves([[0,-1]])
		4:
			set_moves([[4,-1],[1,-1],[4,1]])
		8:
			set_moves([[1,-1]])
		7:
			set_moves([[4,1],[3,1],[4,-1]])
		11:
			set_moves([[5,1]])
		10:
			set_moves([[3,1]])
		3, 5, 6, 9:
			# Now on wanted face
			solve_step += 1


func move_white_edge_to_white_face():
	var idx = get_edge_position(colors)
	var aligned = is_edge_aligned(colors, idx)
	prints("Edge:", idx, "Aligned:", aligned)
	idx = edge_map[idx]
	match idx:
		3:
			set_moves([[2,1]])
		6:
			if aligned:
				set_moves([[2,1]])
			else:
				set_moves([[4,1],[3,-1],[4,-1]])
		5:
			if aligned:
				set_moves([[2,-1]])
			else:
				set_moves([[4,-1],[1,1],[4,1]])
		9:
			if aligned:
				solve_step += 1
				solve()
			else:
				set_moves([[2,-1]])


func move_corner_to_p2():
	var idx = get_corner_position(colors)
	prints("Corner:", idx)
	var aligned = is_corner_aligned(colors, idx)
	idx = corner_map[idx]
	if aligned and idx == 5:
		solve_step += 2
		solve()
	else:
		match idx:
			4:
				set_moves([[1,1],[0,1],[1,-1]]) # 4 > 1
			5:
				set_moves([[1,-1],[0,-1],[1,1]]) # 5 > 3
			6:
				set_moves([[3,1],[0,1],[3,-1]]) # 6 > 2
			7:
				set_moves([[3,-1],[0,-1],[3,1]]) # 7 > 0
			0:
				set_moves([[0,-1]]) # 0 > 2
			1:
				set_moves([[0,-1],[0,-1]]) # 1 > 2
			3:
				set_moves([[0,1]]) # 3 > 2
			2:
				solve_step += 1
				solve()


func move_corner_to_white_face():
	# On which face is the face color tile?
	match colors.find(cmap.corners[corner_map.find(2)][1]):
		0:
			set_moves([[1,-1],[0,-1],[0,-1],[1,1],[0,1]])
		1:
			set_moves([[1,-1],[0,-1],[1,1]])
			solve_step += 1
		2:
			set_moves([[2,1],[0,1],[2,-1]])
			solve_step += 1


func solve():
	# https://www.speedcube.com.au/pages/how-to-solve-a-rubiks-cube
	if move_step > -1:
		apply_move()
		return
	match solve_step:
		1:
			%Pivot.rotate_to_face(2)
			solve_step = 2
		2:
			if move_step < 0:
				face_map = [0,1,2,3,4,5]
				edge_map = [0,1,2,3,4,5,6,7,8,9,10,11]
				colors = [2,4]
				# GREEN/ WHITE edge piece
				print("GW")
			move_white_edge_to_face()
		3:
			move_white_edge_to_white_face()
		4:
			%Pivot.rotate_to_face(3)
			solve_step = 5
		5:
			if move_step < 0:
				face_map = [0,2,3,5,4,1]
				edge_map = [2,0,3,1,7,4,5,6,11,8,9,10]
				colors = [3,4]
				# BLUE/ WHITE edge piece
				print("BW")
			# Don't move edge 9
			move_white_edge_to_face()
		6:
			move_white_edge_to_white_face()
		7:
			%Pivot.rotate_to_face(5)
			solve_step = 8
		8:
			if move_step < 0:
				face_map = [0,3,5,1,4,2]
				edge_map = [3,2,1,0,6,7,4,5,10,11,8,9]
				colors = [5,4]
				# ORANGE / WHITE edge piece
				print("OW")
				# Avoid moving edges 9,10
			move_white_edge_to_face()
		9:
			move_white_edge_to_white_face()
		10:
			%Pivot.rotate_to_face(1)
			solve_step = 11
		11:
			if move_step < 0:
				face_map = [0,5,1,2,4,3]
				edge_map = [1,3,0,2,5,6,7,4,9,10,11,8]
				colors = [1,4]
				# YELLOW / WHITE edge piece
				print("YW")
				# Avoid moving edges 9,10,11
			move_white_edge_to_face()
		12:
			move_white_edge_to_white_face()
		13:
			# White corners
			%Pivot.rotate_to_face(2)
			solve_step = 14
		14:
			# Move the YELLOW/GREEN/WHITE corner to the top face
			colors = cmap.CORNER_FACE_MAP[5]
			corner_map = [0,1,2,3,4,5,6,7]
			face_map = [0,1,2,3,4,5]
			print("YGW")
			move_corner_to_p2()
		15:
			move_corner_to_white_face()
		16:
			%Pivot.rotate_to_face(3)
			solve_step = 17
		17:
			colors = cmap.CORNER_FACE_MAP[6]
			corner_map = [1,3,0,2,7,4,5,6]
			face_map = [0,2,3,5,4,1]
			print("GBW")
			move_corner_to_p2()
		18:
			move_corner_to_white_face()
		19:
			%Pivot.rotate_to_face(5)
			solve_step = 20
		20:
			colors = cmap.CORNER_FACE_MAP[7]
			corner_map = [3,2,1,0,6,7,4,5]
			face_map = [0,3,5,1,4,2]
			print("BOW")
			move_corner_to_p2()
		21:
			move_corner_to_white_face()
		22:
			%Pivot.rotate_to_face(1)
			solve_step = 23
		23:
			colors = cmap.CORNER_FACE_MAP[4]
			corner_map = [2,0,3,1,5,6,7,4]
			face_map = [0,5,1,2,4,3]
			print("YGW")
			move_corner_to_p2()
		24:
			move_corner_to_white_face()
		25:
			print("Done")
			solve_step = -1


func get_edge_position(cols):
	var idx = 0
	for n in 12:
		if cmap.edges[idx].has(cols[0]) and cmap.edges[idx].has(cols[1]):
			break
		idx += 1
	return idx


func is_edge_aligned(cols, idx):
	# The face color is the common color
	var fc = cols[0] if cmap.EDGE_FACE_MAP[idx].has(cols[0]) else cols[1]
	return cmap.EDGE_FACE_MAP[idx].find(fc) == cmap.edges[idx].find(fc)


func get_corner_position(cols):
	var idx = 0
	for n in 8:
		if cmap.corners[idx].has(cols[0]) and cmap.corners[idx].has(cols[1]) and cmap.corners[idx].has(cols[2]):
			break
		idx += 1
	return idx


func is_corner_aligned(cols, idx):
	# The face color is the common color
	var fc = cols[0] if cmap.CORNER_FACE_MAP[idx].has(cols[0]) else cols[1] if cmap.CORNER_FACE_MAP[idx].has(cols[1]) else cols[2]
	return cmap.CORNER_FACE_MAP[idx].find(fc) == cmap.corners[idx].find(fc)


func set_moves(seq):
	moves = seq
	move_step = 0
	apply_move()


func apply_move():
	var move = moves[move_step]
	rotate_face(face_map[move[0]], move[1])
	move_step += 1
	if move_step == moves.size():
		move_step = -1 # Indicate end of move sequence
