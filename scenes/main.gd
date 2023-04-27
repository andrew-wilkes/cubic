extends Control

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]

var bc
var cmap
var solve_step = -1
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


func solve():
	# https://www.speedcube.com.au/pages/how-to-solve-a-rubiks-cube
	match solve_step:
		1:
			%Pivot.rotate_to_face(2)
			solve_step = 2
		2:
			# GREEN/ WHITE edge piece
			print("GW")
			var cols = [2,4]
			# Get the edge position where it is now
			var idx = get_edge_position(cols)
			print(idx)
			# Move to green face
			match idx:
				0, 2:
					rotate_face(0, 1)
				1:
					rotate_face(0, -1)
				4:
					rotate_face(1, -1)
				7:
					rotate_face(3, 1)
				8, 11:
					rotate_face(4, 1)
				10:
					rotate_face(4, -1)
				3, 5, 6, 9:
					# Now on wanted face
					solve_step = 3
					solve()
		3:
			var cols = [2,4]
			var idx = get_edge_position(cols)
			var aligned = is_edge_aligned(cols, idx)
			prints(idx, aligned)
			match idx:
				3:
					rotate_face(2, 1)
				6:
					if aligned:
						rotate_face(2, 1)
					else:
						rotate_face(4, 1)
						solve_step = 4
				5:
					if aligned:
						rotate_face(2, -1)
					else:
						rotate_face(4, -1)
						solve_step = 6
				9:
					if aligned:
						solve_step = 8
						solve()
					else:
						rotate_face(2, -1)
		4:
			rotate_face(3, -1)
			solve_step = 5
		5:
			rotate_face(4, -1)
			solve_step = 8
		6:
			rotate_face(1, 1)
			solve_step = 7
		7:
			rotate_face(4, 1)
			solve_step = 8
		8:
			%Pivot.rotate_to_face(3)
			solve_step = 9
		9:
			# BLUE/ WHITE edge piece
			print("BW")
			var cols = [3,4]
			# Get the edge position where it is now
			var idx = get_edge_position(cols)
			print(idx)
			# Move to blue face
			# Don't move edge 9
			match idx:
				0, 1:
					rotate_face(0, 1)
				3:
					rotate_face(0, -1)
				4, 8:
					rotate_face(1, 1)
				5:
					rotate_face(1, -1)
				11:
					rotate_face(5, 1)
				2, 6, 7, 10:
					# Now on wanted face
					solve_step = 10
					solve()
		10:
			var cols = [3,4]
			var idx = get_edge_position(cols)
			var aligned = is_edge_aligned(cols, idx)
			prints(idx, aligned)
			match idx:
				2:
					rotate_face(3, 1)
				6:
					if aligned:
						rotate_face(3, -1)
					else:
						rotate_face(4, -1)
						solve_step = 11
				7:
					if aligned:
						rotate_face(3, 1)
					else:
						rotate_face(4, 1)
						solve_step = 13
				10:
					if aligned:
						solve_step = 15
						solve()
					else:
						rotate_face(3, 1)
		11:
			rotate_face(2, 1)
			solve_step = 12
		12:
			rotate_face(4, 1)
			solve_step = 15
		13:
			rotate_face(5, -1)
			solve_step = 14
		14:
			rotate_face(4, -1)
			solve_step = 15
		15:
			%Pivot.rotate_to_face(5)
			solve_step = 16
		16:
			# ORANGE / WHITE edge piece
			var cols = [5,4]
			print("OW")
			# Get the edge position where it is now
			var idx = get_edge_position(cols)
			print(idx)
			# Avoid moving edges 9,10
			# Move to orange face
			match idx:
				1, 3:
					rotate_face(0, 1)
				2:
					rotate_face(0, -1)
				5, 8:
					rotate_face(1, 1)
				6:
					rotate_face(2, -1)
					solve_step = 17
				0, 4, 7, 11:
					# Now on wanted face
					solve_step = 19
					solve()
		17:
			rotate_face(0, 1)
			solve_step = 18
		18:
			rotate_face(2, 1)
			solve_step = 16
		19:
			var cols = [5,4]
			var idx = get_edge_position(cols)
			var aligned = is_edge_aligned(cols, idx)
			prints(idx, aligned)
			match idx:
				0:
					rotate_face(5, 1)
				4:
					if aligned:
						rotate_face(5, 1)
					else:
						rotate_face(4, 1)
						solve_step = 20
				7:
					rotate_face(2, -1)
				11:
					if aligned:
						solve_step = 22
						solve()
					else:
						rotate_face(5, -1)
		20:
			rotate_face(1, -1)
			solve_step = 21
		21:
			rotate_face(4, -1)
			solve_step = 22
		22:
			%Pivot.rotate_to_face(1)
			solve_step = 23
		23:
			# YELLOW / WHITE edge piece
			var cols = [1,4]
			print("YW")
			# Get the edge position where it is now
			var idx = get_edge_position(cols)
			print(idx)
			# Move to yellow face
			# Avoid moving edges 9,10,11
			match idx:
				0, 2:
					rotate_face(0, -1)
				3:
					rotate_face(0, 1)
				6:
					rotate_face(3, 1)
					solve_step = 24
				7:
					rotate_face(3, -1)
					solve_step = 26
				1, 4, 5, 8:
					# Now on wanted face
					solve_step = 28
					solve()
		24:
			rotate_face(0, 1)
			solve_step = 25
		25:
			rotate_face(3, -1)
			solve_step = 23
		26:
			rotate_face(0, 1)
			solve_step = 27
		27:
			rotate_face(3, 1)
			solve_step = 23
		28:
			var cols = [1,4]
			var idx = get_edge_position(cols)
			var aligned = is_edge_aligned(cols, idx)
			prints(idx, aligned)
			match idx:
				1:
					rotate_face(1, 1)
				5:
					if aligned:
						rotate_face(1, 1)
					else:
						rotate_face(4, 1)
						solve_step = 29
				4:
					rotate_face(1, -1)
				8:
					if aligned:
						solve_step = -1
						solve()
					else:
						rotate_face(1, -1)
		29:
			rotate_face(2, -1)
			solve_step = 30
		30:
			rotate_face(4, -1)
			solve_step = 31


func get_edge_position(cols):
	var idx = 0
	for edge in cmap.get_edge_positions():
		if cmap.edges[idx].has(cols[0]) and cmap.edges[idx].has(cols[1]):
			break
		idx += 1
	return idx


func is_edge_aligned(cols, idx):
	# The face color is the common color
	var fc = cols[0] if cmap.EDGE_FACE_MAP[idx].has(cols[0]) else cols[1]
	return cmap.EDGE_FACE_MAP[idx].find(fc) == cmap.edges[idx].find(fc)
