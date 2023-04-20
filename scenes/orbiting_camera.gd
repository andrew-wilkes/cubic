extends Marker3D

@export var ROTATION_SPEED = 0.01
@export var PANNING_SPEED = 0.05
@export var ZOOMING_SPEED = 0.05

enum { ROTATING, PANNING, ZOOMING }

var moving = false

func _process(delta):
	delta *= 4
	var b = transform.basis
	if (Input.is_key_pressed(KEY_DOWN)):
		rotate(b.x.normalized(), delta)
	if (Input.is_key_pressed(KEY_UP)):
		rotate(b.x.normalized(), -delta)
	if (Input.is_key_pressed(KEY_RIGHT)):
		rotate(b.y.normalized(), delta)
	if (Input.is_key_pressed(KEY_LEFT)):
		rotate(b.y.normalized(), -delta)
	if (Input.is_key_pressed(KEY_Z)):
		$Camera.position.z += delta
	if (Input.is_key_pressed(KEY_X)):
		$Camera.position.z -= delta


func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			moving = true
		else:
			moving = false
	if event is InputEventMouseMotion and moving:
		var mode = ROTATING
		if Input.is_key_pressed(KEY_CTRL):
			mode = ZOOMING
		match mode:
			ROTATING:
				var b = transform.basis
				rotate(b.x.normalized(), event.relative.y * ROTATION_SPEED)
				rotate(b.y.normalized(), event.relative.x * ROTATION_SPEED)
			ZOOMING:
				$Camera.position.z += event.relative.y * ZOOMING_SPEED


func reset():
	transform.basis = Basis()


func rotate_to_face(face_idx):
	reset()
	match face_idx:
		0:
			rotate_x(-PI/2)
		1:
			rotate_y(-PI/2)
		3:
			rotate_y(PI/2)
		4:
			rotate_x(PI/2)
		5:
			rotate_y(PI)
