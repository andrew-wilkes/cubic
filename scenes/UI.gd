extends Control

signal button_pressed(id, shift, ctrl)

# Connect the signal to all of the buttons
func _ready():
	var nodes = $Grid.get_children()
	nodes.append_array(self.get_children())
	for node in nodes:
		if node is Button:
			node.button_down.connect(_on_button_down.bind(node.name))


func _on_button_down(bname: String):
	# Shift will be used to indicate a reverse rotation direction request
	var shift = Input.is_key_pressed(KEY_SHIFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	# Ctrl is used to change the function of buttons to align the cube with a face
	var ctrl = Input.is_key_pressed(KEY_CTRL) or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)
	emit_signal("button_pressed", bname, shift, ctrl)


func _unhandled_input(_event):
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().quit()
