extends Control

const colors = [Color.RED, Color.YELLOW, Color.GREEN, Color.BLUE, Color.WHITE, Color.ORANGE]

var source_tile = null

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
				new_tile.gui_input.connect(handle_click.bind(new_tile))
				node.add_child(new_tile)
			idx += 1


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
