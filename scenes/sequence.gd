extends PopupPanel

signal play_sequence(seq, repeat)

func _ready():
	for node in $M/VB.get_children():
		if node is HBoxContainer:
			var button: Button = node.get_child(1)
			button.connect("pressed", play.bind(node))


func play(node):
	hide()
	emit_signal("play_sequence", get_sequence(node), $M/VB/Repeat.button_pressed)


func get_sequence(node):
	return parse_sequence(get_sequence_string(node))


func get_sequence_string(node):
	var seq = ""
	if node.get_children().size() > 1:
		var txt: String = node.get_child(0).text
		# Get last line of text
		seq = txt.split("\n")[-1].to_upper()
	return seq


func parse_sequence(txt):
	var seq = []
	var length = txt.length()
	var idx = 0
	while idx < length:
		var dir = 1
		var face = "ULFRDB".find(txt[idx])
		idx += 1
		if face < 0:
			continue
		if idx < length:
			if txt[idx] == "2":
				seq.append([face, dir])
				idx += 1
			if txt[idx] == "'":
				dir = -1
				idx += 1
		seq.append([face, dir])
	return seq


func _on_close_pressed():
	hide()
