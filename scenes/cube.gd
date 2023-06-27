extends CSGBox3D


func _ready():
	# Make the shaders unique
	for face in get_children():
		if face is CSGBox3D:
			var shader = face.get_material().duplicate()
			face.set_material(shader)


func set_grey(make_grey):
	for face in get_children():
		if face is CSGBox3D:
			face.get_material().set_shader_parameter("grey", make_grey)
