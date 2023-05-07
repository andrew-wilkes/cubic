extends PopupPanel

var button: Button

func _ready():
	button = get_parent().find_child("Coffee")
	if button:
		button.connect("pressed", show_popup)


func show_popup():
	button.release_focus()
	popup_centered()


func _on_text_meta_clicked(_meta):
	var _e = OS.shell_open("https://buymeacoffee.com/gdscriptdude")
