extends Control

signal button_pressed(id, shift)

# Connect the signal to all of the buttons
func _ready():
	var nodes = $Grid.get_children()
	nodes.append_array(self.get_children())
	for node in nodes:
		if node is Button:
			node.pressed.connect(_on_button_pressed.bind(node.name))


func _on_button_pressed(bname: String):
	# Shift will be used to indicate a reverse rotation direction request
	var shift = Input.is_key_pressed(KEY_SHIFT) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	emit_signal("button_pressed", bname, shift)
