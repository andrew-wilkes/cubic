extends Marker3D

@export var ROTATION_SPEED = 0.01
@export var PANNING_SPEED = 0.05
@export var ZOOMING_SPEED = 0.05

enum { ROTATING, PANNING, ZOOMING }

var moving = false

func _process(delta):
	delta *= 4
	if (Input.is_key_pressed(KEY_DOWN)):
		$XAxis.rotate_x(delta)
	if (Input.is_key_pressed(KEY_UP)):
		$XAxis.rotate_x(-delta)
	if (Input.is_key_pressed(KEY_RIGHT)):
		$XAxis/YAxis.rotate_y(delta)
	if (Input.is_key_pressed(KEY_LEFT)):
		$XAxis/YAxis.rotate_y(-delta)
	if (Input.is_key_pressed(KEY_Z)):
		$XAxis/YAxis/Camera.position.z += delta
	if (Input.is_key_pressed(KEY_X)):
		$XAxis/YAxis/Camera.position.z -= delta
	if (Input.is_key_pressed(KEY_W)):
		$XAxis/YAxis/Camera.position.y -= delta
	if (Input.is_key_pressed(KEY_A)):
		$XAxis/YAxis/Camera.position.x += delta
	if (Input.is_key_pressed(KEY_S)):
		$XAxis/YAxis/Camera.position.y += delta
	if (Input.is_key_pressed(KEY_D)):
		$XAxis/YAxis/Camera.position.x -= delta

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			moving = true
		else:
			moving = false
	if event is InputEventMouseMotion and moving:
		var mode = ROTATING
		if Input.is_key_pressed(KEY_SHIFT):
			mode = PANNING
		if Input.is_key_pressed(KEY_CTRL):
			mode = ZOOMING
		match mode:
			PANNING:
				$XAxis/YAxis/Camera.position.x += event.relative.x * PANNING_SPEED
				$XAxis/YAxis/Camera.position.y += event.relative.y * PANNING_SPEED
			ROTATING:
				$XAxis.rotate_x(event.relative.y * ROTATION_SPEED)
				$XAxis/YAxis.rotate_y(event.relative.x * ROTATION_SPEED)
			ZOOMING:
				$XAxis/YAxis/Camera.position.z += event.relative.y * ZOOMING_SPEED


func reset():
	$XAxis.transform.basis = Basis()
	$XAxis/YAxis.transform.basis = Basis()


func rotate_to_face(face_idx):
	reset()
	match face_idx:
		0:
			$XAxis.rotate_x(-PI/2)
		1:
			$XAxis/YAxis.rotate_y(-PI/2)
		3:
			$XAxis/YAxis.rotate_y(PI/2)
		4:
			$XAxis.rotate_x(PI/2)
		5:
			$XAxis/YAxis.rotate_y(PI)
