extends Control

const colors = [Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color.WHITE, Color.ORANGE]

const CORNER_FACE_MAP = [[0,1,5],[0,3,5],[0,1,2],[0,2,3],[1,2,4],[2,3,4],[1,4,5],[3,4,5]]
const EDGE__FACE_MAP = []
var source_tile = null
var edges = [] # 12 sets of 3 colors
var corners = [] # 8 sets of 2 colors

func _ready():
	# Set up the tiles
	var tile = ColorRect.new()
	tile.custom_minimum_size = Vector2(32, 32)
	var idx = 0
	for node in $Grid.get_children():
		if node is GridContainer:
			for n in 9:
				var new_tile = tile.duplicate()
				new_tile.color = colors[idx]
				new_tile.set_meta("id", { "face": idx, "tile": n })
				if n != 4: # Don't connect the immovable middle cells
					new_tile.gui_input.connect(handle_click.bind(new_tile))
				node.add_child(new_tile)
			idx += 1
	# Set up corner data
	for a in 2:
		for b in 2:
			for c in 2:
				corners.append([])
		


func handle_click(ev: InputEvent, clicked_tile):
	if ev is InputEventMouseButton and ev.pressed:
		if source_tile:
			source_tile.color = colors[source_tile.get_meta("id").face]
			try_move(source_tile, clicked_tile)
			source_tile = null
		else:
			source_tile = clicked_tile
			source_tile.color = clicked_tile.color.darkened(0.2)


func try_move(from_tile, to_tile):
	var from = from_tile.get_meta("id")
	var to = to_tile.get_meta("id")
	if from == to: return
	# if moving in same group of cells then rotating
	# corners move to corners
	# edges move to edges
	# middle cells can't be moved
	
	pass


func is_edge(n):
	return n % 2 == 1 # Odd number

func is_corner(n):
	return n % 2 == 0 # Even number

func is_same_piece(from, to):
	pass
