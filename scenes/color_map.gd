extends Control

const COLORS = [Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color.WHITE, Color.ORANGE]

# See coordinates diagram for index relationships in media folder
# The _FACE_MAP constants are indexing the faces
# Copies of the FACE_MAP constants are indexing the changing colors on the faces of the pieces
const CORNER_FACE_MAP = [[0,1,5],[0,5,3],[0,2,1],[0,3,2],[5,1,4],[1,2,4],[2,3,4],[3,5,4]]
const EDGE_FACE_MAP = [[5,0],[1,0],[3,0],[2,0],[5,1],[1,2],[3,2],[3,5],[1,4],[2,4],[3,4],[5,4]]
# FACE_ maps contain a list of edge/corner indices of parts on a face
const FACE_CORNER_MAP = [[0,1,2,3],[0,2,4,5],[2,3,5,6],[3,1,6,7],[5,6,4,7],[4,7,0,1]]
const FACE_EDGE_MAP = [[0,1,2,3],[1,4,5,8],[3,5,6,9],[2,6,7,10],[9,8,10,11],[11,4,7,0]]
# This indexes the positions of faces under the Grid node
const GRID_FACE_MAP = [1,3,4,5,7,10]

var source_tile = null
var edges = [] # 12 sets of 2 colors
var corners = [] # 8 sets of 3 colors

func _ready():
	# Set up the tiles
	var tile = ColorRect.new()
	tile.custom_minimum_size = Vector2(32, 32)
	var idx = 0
	for node in $Grid.get_children():
		if node is GridContainer:
			for n in 9:
				var new_tile = tile.duplicate()
				new_tile.set_meta("id", { "face": idx, "tile": n })
				if n != 4: # Don't connect the immovable middle cells
					new_tile.gui_input.connect(handle_click.bind(new_tile))
				node.add_child(new_tile)
			idx += 1
	reset()


func reset():
	# Need deep copy so that inner arrays may be modified
	edges = EDGE_FACE_MAP.duplicate(true)
	corners = CORNER_FACE_MAP.duplicate(true)
	var color_idx = 0
	for node in $Grid.get_children():
		if node is GridContainer:
			for tile in node.get_children():
				tile.color = COLORS[color_idx]
			color_idx += 1


func solved():
	return edges.hash() == EDGE_FACE_MAP.hash() && corners.hash() == CORNER_FACE_MAP.hash()


func handle_click(ev: InputEvent, clicked_tile):
	if ev is InputEventMouseButton and ev.pressed:
		if source_tile:
			source_tile.color = COLORS[source_tile.get_meta("id").face]
			try_move(source_tile, clicked_tile)
			source_tile = null
		else:
			source_tile = clicked_tile
			source_tile.color = clicked_tile.color.darkened(0.2)


func try_move(from_tile, to_tile):
	var from = from_tile.get_meta("id")
	var to = to_tile.get_meta("id")
	if from == to: return
	# if moving in same group of cells then rotating the colors
	# corners move to corners
	# edges move to edges
	# middle cells can't be moved
	if is_edge(from.tile) and is_edge(to.tile):
		var edge1 = get_edge(from.face, from.tile)
		var edge2 = get_edge(to.face, to.tile)
		if edge1 == edge2:
			# swap colors
			edges[edge1].reverse()
			for face_idx in 2:
				set_edge_color(edge1, face_idx)
		else:
			# Want from.face tile to move to to.face tile for a natural feel
			if EDGE_FACE_MAP[edge1].find(from.face) != EDGE_FACE_MAP[edge2].find(to.face):
				# swap colors
				edges[edge1].reverse()
			# swap edges
			var edge1_colors = edges[edge1]
			edges[edge1] = edges[edge2]
			edges[edge2] = edge1_colors
			for face_idx in 2:
				set_edge_color(edge1, face_idx)
				set_edge_color(edge2, face_idx)
	if is_corner(from.tile) and is_corner(to.tile):
		var corner1 = get_corner(from.face, from.tile)
		var corner2 = get_corner(to.face, to.tile)
		if corner1 == corner2:
			# rotate colors
			corners[corner1] = get_rotated_faces(corner1, from.face, corner1, to.face)
			for face_idx in 3:
				set_corner_color(corner1, face_idx)
		else:
			# swap corners
			var rotated_corner1 = get_rotated_faces(corner1, from.face, corner2, to.face)
			corners[corner1] = corners[corner2]
			corners[corner2] = rotated_corner1
			for face_idx in 3:
				set_corner_color(corner1, face_idx)
				set_corner_color(corner2, face_idx)


func get_rotated_faces(corner1, from_idx, corner2, to_idx):
	var rot_step = wrapi(CORNER_FACE_MAP[corner1].find(from_idx) - CORNER_FACE_MAP[corner2].find(to_idx), -1, 2)
	return [corners[corner1][rot_step], corners[corner1][rot_step + 1], corners[corner1][wrapi(rot_step + 2, 0, 3)]]


func is_edge(n):
	return n % 2 == 1 # Odd number


func is_corner(n):
	return n % 2 == 0 # Even number


func get_edge(face, n):
	return FACE_EDGE_MAP[face][n / 2]


func get_corner(face, n):
	return FACE_CORNER_MAP[face][(n + 1) / 3]


func set_edge_color(edge_idx, face_idx):
	# Get the face of the grid
	var face = EDGE_FACE_MAP[edge_idx][face_idx]
	# Get the tile idx within the face
	var tile = FACE_EDGE_MAP[face].find(edge_idx) * 2 + 1
	var color = edges[edge_idx][face_idx]
	set_tile_color(face, tile, color)


func set_corner_color(corner_idx, face_idx):
	var face = CORNER_FACE_MAP[corner_idx][face_idx]
	var tile = FACE_CORNER_MAP[face].find(corner_idx) * 3 / 2 * 2
	var color = corners[corner_idx][face_idx]
	set_tile_color(face, tile, color)


func set_tile_color(face_idx, tile_idx, color_idx):
	$Grid.get_child(GRID_FACE_MAP[face_idx]).get_child(tile_idx).color = COLORS[color_idx]


# Input array of arrays of 6 cube face colors
func set_edge_colors(edge_cube_colors):
	var idx = 0
	for ec in edge_cube_colors:
		# We want to extract the 2 face colors of the edge from the 6 faces of the cube
		edges[idx] = []
		for n in 2:
			edges[idx].append(ec[EDGE_FACE_MAP[idx][n]])
			set_edge_color(idx, n)
		idx += 1


# Input array of arrays of 6 cube face colors
func set_corner_colors(corner_cube_colors):
	var idx = 0
	for cc in corner_cube_colors:
		corners[idx] = []
		# Extract 3 face colors for the corner
		for n in 3:
			corners[idx].append(cc[CORNER_FACE_MAP[idx][n]])
			set_corner_color(idx, n)
		idx += 1


# Search for the matching sets of colors to identify the edges
# The index of the initial edge position is stored in the new position
func get_edge_positions():
	var positions = []
	for n in 12:
		var cols = edges[n]
		positions.append(get_edge_position(cols))
	return positions


func get_edge_position(cols):
	if !EDGE_FACE_MAP.has(cols):
		cols = [cols[1], cols[0]]
	return EDGE_FACE_MAP.find(cols)


func get_corner_positions():
	var positions = []
	for n in 8:
		var cols = corners[n]
		if !CORNER_FACE_MAP.has(cols):
			cols = [cols[2], cols[0], cols[1]]
			if !CORNER_FACE_MAP.has(cols):
				cols = [cols[2], cols[0], cols[1]]
		positions.append(CORNER_FACE_MAP.find(cols))
	return positions


func get_data():
	return {
		"edge_positions": get_edge_positions(),
		"edge_colors": edges,
		"edge_face_map": EDGE_FACE_MAP,
		"corner_positions": get_corner_positions(),
		"corner_colors": corners,
		"corner_face_map": CORNER_FACE_MAP
	}
