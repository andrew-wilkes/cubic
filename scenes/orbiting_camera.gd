extends Marker3D

signal rotation_complete

@export var ROTATION_SPEED = 0.01
@export var PANNING_SPEED = 0.05
@export var ZOOMING_SPEED = 0.05

enum { ROTATING, PANNING, ZOOMING }

var moving = false
var rotating = false
var amount
var from_q
var to_q
var speed = 3

func _process(delta):
	delta *= (speed + 1)
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
			emit_signal("rotation_complete")


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


func rotate_to_face(vec: Vector2):
	rotating = true
	amount = 100.0
	from_q = Quaternion(transform.basis.orthonormalized())
	var node = Node3D.new()
	node.rotate_x(PI/2 * vec.x)
	node.rotate_y(PI/2 * vec.y)
	to_q = Quaternion(node.transform.basis)
