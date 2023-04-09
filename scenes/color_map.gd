extends Control

const COLORS = [Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color.WHITE, Color.ORANGE]

# See coordinates diagram for index relationships
const CORNER_FACE_MAP = [[0,1,5],[0,5,3],[0,2,1],[0,3,2],[1,4,5],[1,2,4],[2,3,4],[3,5,4]]
const EDGE_FACE_MAP = [[0,5],[0,1],[0,3],[0,2],[1,5],[1,2],[2,3],[3,5],[1,4],[2,4],[3,4],[4,5]]
const FACE_CORNER_MAP = [[0,1,2,3],[0,2,4,5],[2,3,5,6],[3,1,6,7],[5,6,4,7],[4,7,0,1]]
const FACE_EDGE_MAP = [[0,1,2,3],[1,4,5,8],[3,5,6,9],[2,6,7,10],[9,8,10,11],[11,4,7,0]]
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
	var idx = 0
	for node in $Grid.get_children():
		if node is GridContainer:
			for tile in node.get_children():
				tile.color = COLORS[idx]
			idx += 1


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
			set_edge_color(edge1, 0)
			set_edge_color(edge1, 1)
		else:
			if EDGE_FACE_MAP[edge1].find(from.face) != EDGE_FACE_MAP[edge2].find(to.face):
				# swap colors
				edges[edge1].reverse()
			# swap edges
			var edge1_colors = edges[edge1]
			edges[edge1] = edges[edge2]
			edges[edge2] = edge1_colors
			set_edge_color(edge1, 0)
			set_edge_color(edge1, 1)
			set_edge_color(edge2, 0)
			set_edge_color(edge2, 1)
	if is_corner(from.tile) and is_corner(to.tile):
		var corner1 = get_corner(from.face, from.tile)
		var corner2 = get_corner(to.face, to.tile)
		var rot_step = wrapi(CORNER_FACE_MAP[corner1].find(from.face) - CORNER_FACE_MAP[corner1].find(to.face), -1, 2)
		# rotate colors
		var rotated_values = [corners[corner1][rot_step], corners[corner1][rot_step + 1], corners[corner1][wrapi(rot_step + 2, 0, 3)]]
		if corner1 == corner2:
			corners[corner1] = rotated_values
			for face_idx in 3:
				set_corner_color(corner1, face_idx)
		else:
			# swap corners
			corners[corner1] = corners[corner2]
			corners[corner2] = rotated_values
			for face_idx in 3:
				set_corner_color(corner1, face_idx)
				set_corner_color(corner2, face_idx)


func is_edge(n):
	return n % 2 == 1 # Odd number

func is_corner(n):
	return n % 2 == 0 # Even number

func is_same_piece(from, to):
	pass

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
	print(tile)
	var color = corners[corner_idx][face_idx]
	set_tile_color(face, tile, color)

func set_tile_color(face_idx, tile_idx, color_idx):
	$Grid.get_child(GRID_FACE_MAP[face_idx]).get_child(tile_idx).color = COLORS[color_idx]
