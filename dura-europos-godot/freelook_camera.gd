class_name FreeLookOrbitCamera extends Camera3D

enum CameraType {FREELOOK, ORBIT}
var camera_type : CameraType = CameraType.FREELOOK

# NOT MY CODE
# GOTTEN FROM 
# https://github.com/adamviola/simple-free-look-camera/

# Modifier keys' speed multiplier
const SHIFT_MULTIPLIER = 2.5
const ALT_MULTIPLIER = 1.0 / SHIFT_MULTIPLIER

@export_category("Freelook Camera")
@export_range(0.0, 1.0) var freelook_sensitivity: float = 0.25

# NOT MY CODE
# TAKEN FROM
# https://github.com/unovafr/Godot-Orbit-Camera/

# External var
@export_category("Orbit Camera")
@export var SCROLL_SPEED: float = 25 # Speed when use scroll mouse
@export var ZOOM_SPEED: float = 15 # Speed use when is_zoom_in or is_zoom_out is true
@export var DEFAULT_DISTANCE: float = 100 # Default distance of the Node
@export var ROTATE_SPEED: float = 1
#@export var ANCHOR_NODE_PATH: NodePath
var anchor_transform : Transform3D :
	set(new_transform):
		_rotation = new_transform.basis.get_rotation_quaternion().get_euler()
		anchor_transform = new_transform
@export var MOUSE_ZOOM_SPEED: float = 10
@export var TOUCH_INVERT_ZOOM: bool = false

# Event var
var _move_speed: Vector2
var _scroll_speed: float
var _touches: Dictionary
var _old_touche_dist: float
# Use to add posibility to updated zoom with external script
var is_zoom_in: bool
var is_zoom_out: bool

# Transform var
var _rotation: Vector3
var _distance: float
#var _anchor_node: Node3D


# State for freelook

# Mouse state
var _mouse_position = Vector2(0.0, 0.0)
var _total_pitch = 0.0

# Movement state
var _direction = Vector3(0.0, 0.0, 0.0)
var _velocity = Vector3(0.0, 0.0, 0.0)
var _acceleration = 30
var _deceleration = -10
var _vel_multiplier = 4

# Keyboard state
var _w = false
var _s = false
var _a = false
var _d = false
var _q = false
var _e = false
var _shift = false
var _alt = false

func _ready() -> void:
	_distance = DEFAULT_DISTANCE
	#_anchor_node = self.get_node(ANCHOR_NODE_PATH)
	#_rotation = _anchor_node.transform.basis.get_rotation_quaternion().get_euler()
	#_rotation = anchor_transform.basis.get_rotation_quaternion().get_euler()


func _input(event):
	if event is InputEventMouseMotion:
		_process_mouse_rotation_event(event)
	elif event is InputEventMouseButton:
		_process_mouse_scroll_event(event)
	
	# Receives mouse motion
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	# Receives mouse button input
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT: # Only allows rotation if right click down
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)
			MOUSE_BUTTON_WHEEL_UP: # Increases max velocity
				_vel_multiplier = clamp(_vel_multiplier * 1.1, 0.2, 20)
			MOUSE_BUTTON_WHEEL_DOWN: # Decereases max velocity
				_vel_multiplier = clamp(_vel_multiplier / 1.1, 0.2, 20)

	# Receives key input
	if event is InputEventKey:
		match event.keycode:
			KEY_W:
				_w = event.pressed
			KEY_S:
				_s = event.pressed
			KEY_A:
				_a = event.pressed
			KEY_D:
				_d = event.pressed
			KEY_Q:
				_q = event.pressed
			KEY_E:
				_e = event.pressed
			KEY_SHIFT:
				_shift = event.pressed
			KEY_ALT:
				_alt = event.pressed

# Updates mouselook and movement every frame
func _process(delta):
	if camera_type == CameraType.FREELOOK:
		_freelook_update_mouselook()
		_freelook_update_movement(delta)
	elif camera_type == CameraType.ORBIT:
		if is_zoom_in:
			_scroll_speed = -1 * ZOOM_SPEED
		if is_zoom_out:
			_scroll_speed = 1 * ZOOM_SPEED
		_orbit_process_transformation(delta)

# Updates camera movement
func _freelook_update_movement(delta):
	# Computes desired direction from key states
	_direction = Vector3(
		(_d as float) - (_a as float), 
		(_e as float) - (_q as float),
		(_s as float) - (_w as float)
	)
	
	# Computes the change in velocity due to desired direction and "drag"
	# The "drag" is a constant acceleration on the camera to bring it's velocity to 0
	var offset = _direction.normalized() * _acceleration * _vel_multiplier * delta \
		+ _velocity.normalized() * _deceleration * _vel_multiplier * delta
	
	# Compute modifiers' speed multiplier
	var speed_multi = 2 * sqrt(10 + abs(position.y))
	if _shift: speed_multi *= SHIFT_MULTIPLIER
	if _alt: speed_multi *= ALT_MULTIPLIER
	
	# Checks if we should bother translating the camera
	if _direction == Vector3.ZERO and offset.length_squared() > _velocity.length_squared():
		# Sets the velocity to 0 to prevent jittering due to imperfect deceleration
		_velocity = Vector3.ZERO
	else:
		# Clamps speed to stay within maximum value (_vel_multiplier)
		_velocity.x = clamp(_velocity.x + offset.x, -_vel_multiplier, _vel_multiplier)
		_velocity.y = clamp(_velocity.y + offset.y, -_vel_multiplier, _vel_multiplier)
		_velocity.z = clamp(_velocity.z + offset.z, -_vel_multiplier, _vel_multiplier)
	
		translate(_velocity * delta * speed_multi)

# Updates mouse look 
func _freelook_update_mouselook():
	# Only rotates mouse if the mouse is captured
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_mouse_position *= freelook_sensitivity
		var yaw = _mouse_position.x
		var pitch = _mouse_position.y
		_mouse_position = Vector2(0, 0)
		
		# Prevents looking up/down too far
		pitch = clamp(pitch, -90 - _total_pitch, 90 - _total_pitch)
		_total_pitch += pitch
	
		rotate_y(deg_to_rad(-yaw))
		rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))


func _orbit_process_transformation(delta: float):
	# Update rotation
	_rotation.x += -_move_speed.y * delta * ROTATE_SPEED
	_rotation.y += _move_speed.x * delta * ROTATE_SPEED
	if _rotation.x < 0.05:
		_rotation.x = 0.05
	if _rotation.x > PI:
		_rotation.x = PI
		
	#print(_rotation.x)
	_move_speed = Vector2()
	
	# Update distance
	_distance += _scroll_speed * delta
	if _distance < 0:
		_distance = 0
	_scroll_speed = 0
	
	var x = sin(_rotation.x) * cos(_rotation.y)
	var y = cos(_rotation.x)
	var z = sin(_rotation.x) * sin(_rotation.y)
	
	global_position = anchor_transform.origin + _distance * Vector3(x, y, z)
	look_at(anchor_transform.origin)
	
	if global_position.y < 200:
		global_position.y = 200
	#self.set_identity()
	#self.translate_object_local(Vector3(0,0,_distance))
	#_anchor_node.set_identity()
	#_anchor_node.transform.basis = Basis(Quaternion.from_euler(_rotation))


func _process_mouse_rotation_event(e: InputEventMouseMotion):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_move_speed = e.relative

func _process_mouse_scroll_event(e: InputEventMouseButton):
	if e.button_index == MOUSE_BUTTON_WHEEL_UP:
		_scroll_speed = -1 * SCROLL_SPEED
	elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_scroll_speed = 1 * SCROLL_SPEED
