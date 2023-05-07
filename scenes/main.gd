extends Control

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]
const FACE_MAPS = [[0,1,2,3,4,5],[0,2,3,5,4,1],[0,3,5,1,4,2],[0,5,1,2,4,3]] # G,B,O,Y
const EDGE_MAPS = [[0,1,2,3,4,5,6,7,8,9,10,11],[2,0,3,1,7,4,5,6,11,8,9,10],[3,2,1,0,6,7,4,5,10,11,8,9],[1,3,0,2,5,6,7,4,9,10,11,8]]
const CORNER_MAPS = [[0,1,2,3,4,5,6,7],[1,3,0,2,7,4,5,6],[3,2,1,0,6,7,4,5],[2,0,3,1,5,6,7,4]]

enum { STOPPED, PLAYING, STEPPING }

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
var play_state = STOPPED

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)
	bc = $C/SVP/VP/BigCube
	cmap = $C/ColorMap
	%Pivot.connect("rotation_complete", rotation_done)
	bc.connect("rotation_complete", rotation_done)
	%SUI.hide()
	call_deferred("set_sui_transform")


func set_sui_transform():
	%SUI.size = %SVP.size
	%SUI.position = %SVP.position


func rotation_done():
	rotation_completed = true
	copy_cube()
	if play_state == PLAYING:
		solve()


func _on_button_pressed(bname, shift, ctrl):
	if FACE_BUTTONS.has(bname):
		var button_idx = FACE_BUTTONS.find(bname)
		if ctrl:
			var face_weights = [0,0,0,0,0,0]
			face_weights[button_idx] = 1.0
			bc.get_node("Pivot").rotate_to_face(face_weights)
		else:
			var direction = -1 if shift else 1
			stop_solving()
			rotate_face(button_idx, direction, bc.get_node("Pivot").transform.basis)
	match bname:
		"Reset":
			bc.reset()
			copy_cube()
			stop_solving()
		"Scramble":
			for n in randi_range(10, 15):
				bc.rotate_face_immediate(randi() % 6, 1 if randf() > 0.5 else -1)
			copy_cube()
			stop_solving()
		"Solve":
			if rotation_completed:
				if solve_step < 0:
					solve_step = 1
					play_state = STEPPING
					%SUI.show()
				if play_state == PLAYING:
					stop_solving()
				else:
					solve()
			#$Support.popup_centered()
		"CopyCube":
			stop_solving()
			copy_cube()
		"CopyMap":
			stop_solving()
			bc.apply_map($C/ColorMap.get_data())
		"Help":
			$Info.popup_centered()


func rotate_face(face_idx, direction, bas = Basis()):
	bc.rotate_face(face_idx, direction, bas)
	rotation_completed = false


func copy_cube():
	$C/ColorMap.set_edge_colors(bc.get_edge_colors())
	$C/ColorMap.set_corner_colors(bc.get_corner_colors())


func move_white_edge_to_face():
	# Want to avoid disturbing already placed edges in the group: 8,9,10,11
	# Get the edge position where the piece is now
	var idx = get_edge_position(colors)
	# Move to front face
	# Map the idx depending on the front face
	idx = edge_map[idx]
	# set_moves will map the face index
	match idx:
		0, 2:
			set_moves([[0,1]])
		1:
			set_moves([[0,-1]])
		4:
			set_moves([[1,1],[0,-1],[1,-1]])
		8:
			set_moves([[1,-1]])
		7:
			set_moves([[3,-1],[0,1],[3,1]])
		11:
			set_moves([[5,1],[5,1]])
		10:
			set_moves([[3,1]])
		3, 5, 6, 9:
			# Now on wanted face
			solve_step += 1
			solve()


func move_white_edge_to_white_face():
	var idx = get_edge_position(colors)
	var aligned = is_edge_aligned(colors, idx)
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
			set_moves([[1,-1],[0,-1],[1,1]]) # Face color is forward
			solve_step += 1
		2:
			set_moves([[2,1],[0,1],[2,-1]]) # White is forward
			solve_step += 1


func move_mid_edge():
	var idx = get_edge_position(colors)
	var aligned = is_edge_aligned(colors, idx)
	var eidx = [5,6,7,4].find(idx)
	idx = edge_map[idx]
	if aligned and idx == 5:
		solve_step += 1
		solve()
		return
	var moves1 = [[0,-1],[1,-1],[0,1],[1,1],[0,1],[2,1],[0,-1],[2,-1]]
	if eidx > -1:
		# Move to top layer (left side to top)
		face_map = FACE_MAPS[eidx]
		set_moves(moves1)
	else:
		match idx:
				0, 1:
					set_moves([[0, -1]])
				2:
					set_moves([[0, 1]])
				3:
					if aligned:
						set_moves(moves1)
					else:
						set_moves([[0,1],[0,1],[2,1],[0,-1],[2,-1],[0,-1],[1,-1],[0,1],[1,1]])


func form_top_cross():
	var pattern = [0,0,0,0]
	for idx in 4:
		pattern[idx] = clampi(cmap.edges[idx][1], 0, 1)
	match pattern:
		[0,0,0,0]:
			solve_step += 1
			solve()
		[0,1,0,1]:
			set_moves([[0,-1]])
		[1,1,0,0]:
			set_moves([[0,1],[0,1]])
		[0,1,1,0]:
			set_moves([[0,-1]])
		_:
			set_moves([[2,1],[3,1],[0,1],[3,-1],[0,-1],[2,-1]])


func align_top_edges():
	var pattern = [0,0,0,0]
	for idx in 4:
		# Map idx to one of the top edges in order of traversal of the top rim
		pattern[idx] = cmap.edges[[0,1,3,2][idx]][0]
	# Check if all correct or correct but need to rotate top
	match pattern:
		[5,1,2,3]:
			solve_step += 1
			solve()
		[1,2,3,5]:
			set_moves([[0,-1]])
		[2,3,5,1]:
			set_moves([[0,1],[0,1]])
		[3,5,1,2]:
			set_moves([[0,1]])
		_:
			# move correct adjacent pair to back right (pos idx 3)
			var pairs = [[0,1],[1,2],[2,3],[3,0]]
			var faces = [[5,1],[1,2],[2,3],[3,5]]
			var pos = -1
			var idx = 0
			for pair in pairs:
				if faces.find([pattern[pair[0]], pattern[pair[1]]]) > -1:
					pos = idx
					break
				idx += 1
			match pos:
				0:
					set_moves([[0,1]])
				1:
					set_moves([[0,1],[0,1]])
				2:
					set_moves([[0,-1]])
				_:
					# Apply moves even if there was no adjacent correct pair
					set_moves([[3,1],[0,1],[3,-1],[0,1],[3,1],[0,1],[0,1],[3,-1]])


func position_top_corners():
	var correct_corners = []
	for idx in 4:
		if get_corner_position(cmap.CORNER_FACE_MAP[idx]) == idx:
			correct_corners.append(idx)
	if correct_corners.size() == 4:
		solve_step += 1
		solve()
	else:
		if correct_corners.size() > 0:
			face_map = FACE_MAPS[[2,1,3,0][correct_corners[0]]]
		else:
			face_map = FACE_MAPS[2]
		set_moves([[0,1],[3,1],[0,-1],[1,-1],[0,1],[3,-1],[0,-1],[1,1]])


func rotate_top_right_corner():
	if cmap.CORNER_FACE_MAP[3][0] == cmap.corners[3][0]:
		solve_step += 1
		solve()
	else:
		set_moves([[3,-1],[4,-1],[3,1],[4,1],[3,-1],[4,-1],[3,1],[4,1]])


func solve():
	# https://www.speedcube.com.au/pages/how-to-solve-a-rubiks-cube
	if move_step > -1:
		# We are in a rotation sequence
		apply_move()
		return
	match solve_step:
		1:
			%Pivot.rotate_to_face([0,0,1.0,0,0,0])
			solve_step += 1
			add_note("Solving")
		2:
			if move_step < 0:
				face_map = FACE_MAPS[0]
				edge_map = EDGE_MAPS[0]
				colors = [2,4]
				# GREEN/ WHITE edge piece
			move_white_edge_to_face()
			add_note("Moving green/white edge to green face")
		3:
			move_white_edge_to_white_face()
			add_note("Making white cross\nMoving green/white edge to white face")
		4:
			%Pivot.rotate_to_face([0,0,0,1.0,0,0])
			solve_step += 1
		5:
			if move_step < 0:
				face_map = FACE_MAPS[1]
				edge_map = EDGE_MAPS[1]
				colors = [3,4]
				# BLUE/ WHITE edge piece
			# Don't move edge 9
			move_white_edge_to_face()
			add_note("Moving blue/white edge to blue face")
		6:
			move_white_edge_to_white_face()
			add_note("Moving blue/white edge to white face")
		7:
			%Pivot.rotate_to_face([0,0,0,0,0,1.0])
			solve_step += 1
		8:
			if move_step < 0:
				face_map = FACE_MAPS[2]
				edge_map = EDGE_MAPS[2]
				colors = [5,4]
				# ORANGE / WHITE edge piece
				# Avoid moving edges 9,10
			move_white_edge_to_face()
			add_note("Moving orange/white edge to orange face")
		9:
			move_white_edge_to_white_face()
			add_note("Moving orange/white edge to white face")
		10:
			%Pivot.rotate_to_face([0,1.0,0,0,0,0])
			solve_step += 1
		11:
			if move_step < 0:
				face_map = FACE_MAPS[3]
				edge_map = EDGE_MAPS[3]
				colors = [1,4]
				# YELLOW / WHITE edge piece
				# Avoid moving edges 9,10,11
			move_white_edge_to_face()
			add_note("Moving yellow/white edge to yellow face")
		12:
			move_white_edge_to_white_face()
			add_note("Moving yellow/white edge to white face")
		13:
			# White corners
			%Pivot.rotate_to_face([0,0,1.0,0,0,0])
			solve_step += 1
			add_note("Placing white corners")
		14:
			# Move the YELLOW/GREEN/WHITE corner to the top face
			colors = cmap.CORNER_FACE_MAP[5]
			corner_map = CORNER_MAPS[0]
			face_map = FACE_MAPS[0]
			move_corner_to_p2()
			add_note("Moving yellow/green/white corner\n to top/left corner")
		15:
			move_corner_to_white_face()
			add_note("Moving yellow/green/white corner\n to bottom/left corner")
		16:
			%Pivot.rotate_to_face([0,0,0,1.0,0,0])
			solve_step += 1
		17:
			colors = cmap.CORNER_FACE_MAP[6]
			corner_map = CORNER_MAPS[1]
			face_map = FACE_MAPS[1]
			move_corner_to_p2()
			add_note("Moving green/blue/white corner\n to top/left corner")
		18:
			move_corner_to_white_face()
			add_note("Moving green/blue/white corner\n to bottom/left corner")
		19:
			%Pivot.rotate_to_face([0,0,0,0,0,1.0])
			solve_step += 1
		20:
			colors = cmap.CORNER_FACE_MAP[7]
			corner_map = CORNER_MAPS[2]
			face_map = FACE_MAPS[2]
			move_corner_to_p2()
			add_note("Moving blue/orange/white corner\n to top/left corner")
		21:
			move_corner_to_white_face()
			add_note("Moving blue/orange/white corner\n to bottom/left corner")
		22:
			%Pivot.rotate_to_face([0,1.0,0,0,0,0])
			solve_step += 1
		23:
			colors = cmap.CORNER_FACE_MAP[4]
			corner_map = CORNER_MAPS[3]
			face_map = FACE_MAPS[3]
			move_corner_to_p2()
			add_note("Moving orange/yellow/white corner\n to top/left corner")
		24:
			move_corner_to_white_face()
			add_note("Moving orange/yellow/white corner\n to bottom/left corner")
		25:
			%Pivot.rotate_to_face([0,1.0,0,0,0,0])
			solve_step += 1
			add_note("Complete middle layer")
		26:
			face_map = FACE_MAPS[3]
			edge_map = EDGE_MAPS[3]
			colors = cmap.EDGE_FACE_MAP[4]
			move_mid_edge()
			add_note("Move orange/yellow edge")
		27:
			%Pivot.rotate_to_face([0,0,1.0,0,0,0])
			solve_step += 1
		28:
			face_map = FACE_MAPS[0]
			edge_map = EDGE_MAPS[0]
			colors = cmap.EDGE_FACE_MAP[5]
			move_mid_edge()
			add_note("Move yellow/green edge")
		29:
			%Pivot.rotate_to_face([0,0,0,1.0,0,0])
			solve_step += 1
		30:
			face_map = FACE_MAPS[1]
			edge_map = EDGE_MAPS[1]
			colors = cmap.EDGE_FACE_MAP[6]
			move_mid_edge()
			add_note("Move green/blue edge")
		31:
			%Pivot.rotate_to_face([0,0,0,0,0,1.0])
			solve_step += 1
		32:
			face_map = FACE_MAPS[2]
			edge_map = EDGE_MAPS[2]
			colors = cmap.EDGE_FACE_MAP[7]
			move_mid_edge()
			add_note("Move blue/orange edge")
		33:
			%Pivot.rotate_to_face([0,0,1.0,0,0,0])
			solve_step += 1
			add_note("Form top cross")
		34:
			face_map = FACE_MAPS[0]
			form_top_cross()
			add_note("Now 2/4 edge pieces are\n in the correct position.\nAlign them.")
		35:
			face_map = FACE_MAPS[0]
			align_top_edges()
		36:
			position_top_corners()
			add_note("Position top corners")
		37:
			%Pivot.rotate_to_face([0,0,1.0,0,0,0])
			face_map = FACE_MAPS[0]
			solve_step += 1
		38:
			set_moves([[0,-1]])
			solve_step += 1
		39:
			rotate_top_right_corner()
			add_note("Rotate top-right corner 1")
		40:
			set_moves([[0,-1]])
			solve_step += 1
		41:
			rotate_top_right_corner()
			add_note("Rotate top-right corner 2")
		42:
			set_moves([[0,-1]])
			solve_step += 1
		43:
			rotate_top_right_corner()
			add_note("Rotate top-right corner 3")
		44:
			set_moves([[0,-1]])
			solve_step += 1
		45:
			rotate_top_right_corner()
			add_note("Rotate top-right corner 4")
		46:
			# Not sure why, but this delay is needed in order to see the next message
			await get_tree().create_timer(0.5).timeout
			add_note("Completed!")
			await get_tree().create_timer(3.0).timeout
			stop_solving()


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


func add_note(txt):
	%Note.text = txt
	%Note.show()
	$NoteTimer.stop()
	$NoteTimer.start()


func hide_note():
	%Note.hide()


func _on_note_timer_timeout():
	hide_note()


func _on_step_pressed():
	solve()


func _on_play_pressed():
	if play_state == PLAYING:
		%Play.text = "Play"
		%Step.disabled = false
		play_state = STEPPING
	else:
		%Play.text = "Pause"
		%Step.disabled = true
		play_state = PLAYING
	solve()


func _on_stop_pressed():
	%SUI.hide()
	play_state = STOPPED
	stop_solving()


func stop_solving():
	solve_step = -1
	play_state = STOPPED
	%SUI.hide()
	%Play.text = "Play"
	%Step.disabled = false
