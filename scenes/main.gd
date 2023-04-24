extends Control

const FACE_BUTTONS = ["U", "L", "F", "R", "D", "B"]

var bc
var cmap
var solve_step = 0

func _ready():
	$C/UI.button_pressed.connect(_on_button_pressed)
	bc = $C/SVP/VP/BigCube
	cmap = $C/ColorMap
	%Pivot.connect("rotation_complete", solve)
	bc.connect("rotation_complete", solve)


func _on_button_pressed(bname, shift, ctrl):
	if FACE_BUTTONS.has(bname):
		var button_idx = FACE_BUTTONS.find(bname)
		if ctrl:
			bc.get_node("Pivot").rotate_to_face(button_idx)
		else:
			var direction = -1 if shift else 1
			rotate_face(button_idx, direction)
	match bname:
		"Reset":
			bc.reset()
		"Scramble":
			for n in randi_range(10, 15):
				bc.rotate_face_immediate(randi() % 6, 1 if randf() > 0.5 else -1)
		"Solve":
			solve_step = 1
			solve()
			#$Support.popup_centered()
		"CopyCube":
			copy_cube()
		"CopyMap":
			bc.apply_map($C/ColorMap.get_data())
		"Help":
			$Info.popup_centered()


func rotate_face(face_idx, direction):
	bc.rotate_face(face_idx, direction, bc.get_node("Pivot").transform.basis)


func copy_cube():
	$C/ColorMap.set_edge_colors(bc.get_edge_colors())
	$C/ColorMap.set_corner_colors(bc.get_corner_colors())


func solve():
	# https://www.speedcube.com.au/pages/how-to-solve-a-rubiks-cube
	copy_cube()
	match solve_step:
		1:
			%Pivot.rotate_to_face(2)
			solve_step = 2
		2:
			# GREEN/ WHITE edge piece
			var cols = [2,4]
			# Get the edge position where it is now
			var idx = get_edge_position(cols)
			# Do something based on what edge it is on
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
					rotate_face(2, -1)
				9:
					if aligned:
						solve_step = -1
						solve()
					else:
						rotate_face(2, -1)
		4:
			rotate_face(3, -1)
			solve_step = 5
		5:
			rotate_face(4, -1)
			solve_step = 6

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
