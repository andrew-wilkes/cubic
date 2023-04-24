extends Marker3D

signal has_reset

@export var ROTATION_SPEED = 0.01
@export var PANNING_SPEED = 0.05
@export var ZOOMING_SPEED = 0.05

enum { ROTATING, PANNING, ZOOMING }

var moving = false
var rotating = false
var amount
var from_q
var to_q

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
	if rotating:
		transform.basis = Basis(to_q.slerp(from_q, amount / 100.0))
		amount -= delta * 30
		if amount < 0.1:
			transform.basis = Basis(to_q)
			rotating = false


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


func rotate_to_face(face_idx):
	rotating = true
	amount = 100.0
	from_q = Quaternion(transform.basis)
	var node = Node3D.new()
	match face_idx:
		0:
			node.rotate_x(-PI/2)
		1:
			node.rotate_y(-PI/2)
		3:
			node.rotate_y(PI/2)
		4:
			node.rotate_x(PI/2)
		5:
			node.rotate_y(PI)
	to_q = Quaternion(node.transform.basis)
