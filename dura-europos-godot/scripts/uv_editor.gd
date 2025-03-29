class_name UVEditorWindow extends Window

var _object : GeoJSON_Mesh
var _picture : Image
var _pic_info 

@onready var texture_rect : TextureRect = $Control2/TextureRect
@onready var sub_viewport : SubViewport = $Control2/SubViewportContainer/SubViewport

const window_resource = preload("res://scenes/uv_editor.tscn")

static func create_editor(object, picture, pic_info):
	
	var window : Window = window_resource.instantiate()
	
	window._object = object
	window._picture = picture
	window._pic_info = pic_info
	return window

#const editor_scene = preload("res://scenes/uveditor_scene.tscn")

@onready var new_world = $Control2/SubViewportContainer/SubViewport/Node3D
@onready var camera : FreeLookOrbitCamera = new_world.get_node("FreeLookOrbitCamera")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_centered_ratio(0.5)
	#priun$Control2.size
	$Control2/SubViewportContainer/SubViewport.size = $Control2.size * Vector2(0.5, 1.0)
	grab_focus()
	var pos = Vector3(0, 0.0, 0)
	#$Control2/SubViewportContainer/SubViewport/Node3D.position = pos
	#$Control2/SubViewportContainer/SubViewport/FreeLookOrbitCamera.anchor_transform = Transform3D(Basis(), pos)
	
	#var new_world = editor_scene.instantiate()
	
	#$Control2/SubViewportContainer/SubViewport.add_child(new_world)
	
	camera.anchor_transform = Transform3D(Basis(), pos)
	#world_3d = World3D.new()
	
	var new_obj : Node3D
	
	if _object:
		#new_obj : GeoJSON_Mesh = _object.duplicate()
		new_obj = _object.duplicate()
		print(_object)
		print(_object.json_path)
		
	else:
		# debug
		new_obj = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(50, 50, 50)
		new_obj.mesh = box
		
	new_world.add_child(new_obj)
	new_obj.global_position = pos
	if _picture:
		(texture_rect.texture as ImageTexture).set_image(_picture)
	else:
		texture_rect.texture = load("res://assets/satellite_color_square.png")
	#pass # Replace with function body.


enum PickState {TEX, VIEWPORT, DONE}
var state : PickState = PickState.DONE
var uv : Vector2

func _input(event: InputEvent) -> void:
	
	
	if event.is_action_pressed("left-click"):
		var x =get_mouse_point()
		#print(x)
		
	if event.is_action_pressed("escape"):
		close_requested.emit()
	
	if event.is_action_pressed("adduv"):
		
		state = PickState.TEX
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	#var sub_vp = $Control2/SubViewportContainer/SubViewport
	#var vp_texture : ViewportTexture = sub_vp.get_texture()
	#texture_rect.texture = vp_texture
	#var vp_image = vp_texture.get_image()
	#(texture_rect.texture as ImageTexture).set_image(vp_image)


func _on_close_requested() -> void:
	hide()
	


func _on_texture_input(event: InputEvent) -> void:
	if event.is_action("left-click"):
		if state == PickState.TEX:
			
			var i = get_mouse_position()
			var base = texture_rect.position
			uv = (i - base) / texture_rect.size
			print(uv)
			state = PickState.VIEWPORT
			

@onready var space: PhysicsDirectSpaceState3D = new_world.get_world_3d().direct_space_state

func get_mouse_point():
	var sub_vp_container = $Control2/SubViewportContainer
	var sub_vp = new_world.get_node("SubViewport")
	var depth_camera = sub_vp.get_node("depth_cam")
	
	# taken with help from https://github.com/bikemurt/godot-vertex-painter/blob/main/addons/vertex_painter/v2/vertex_painter_3d.gd
	var mouse_loc = sub_vp_container.get_local_mouse_position()
	#print(mouse_loc)
	
	var src_pos = camera.project_ray_origin(mouse_loc)
	var cam_dir = camera.project_ray_normal(mouse_loc).normalized()
	
	#print(cam_dir)
	depth_camera.global_position = src_pos - cam_dir
	
	var point : Vector3
	if is_zero_approx((cam_dir - Vector3(0, -1, 0)).length_squared()):
		depth_camera.rotation_degrees = Vector3(-90.0, 0, 0)
		point = src_pos
		#print(cam_dir)
	else:
		depth_camera.look_at(depth_camera.global_position + cam_dir, Vector3.UP)
		sub_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		var vp_texture : ViewportTexture = sub_vp.get_texture()
		texture_rect.texture = vp_texture
		var vp_image = vp_texture.get_image()
		
		
		var depth_color = vp_image.get_pixel(0, 0).srgb_to_linear()
		var depth_vec = Vector2(depth_color.r, depth_color.g)
		var normalized_distance = depth_vec.dot(Vector2(1, 1.0/255.0))
		#var normalized_distance = depth_color.r + depth_color.g / 255.0
		#print(depth_color.r + depth_color.g / 255.0)
		
		if is_zero_approx(normalized_distance):
			return -Vector3.INF
		
		if normalized_distance > 0.9999:
			normalized_distance = 1
		
		var depth = normalized_distance * depth_camera.far
		print(depth)
		point = depth_camera.global_position + cam_dir * depth
	
	print(point)
	#depth_camera.get_node("MeshInstance3D")
	new_world.get_node("MeshInstance3D2").global_position = point
	return point

func _on_viewport_container_input(event: InputEvent) -> void:
	return
	#var root = $Control2/SubViewportContainer/SubViewport/Node3D
	#var camera = root.get_node("FreeLookCamera")
	if event.is_action("left-click"):
		if state == PickState.VIEWPORT:
			var point = get_mouse_point()
			apply_texture(uv, point)
	
func apply_texture(uv, clicked_point):
	
	print("associating uv ", uv, " with 3d point ", clicked_point)
	state = PickState.DONE
	#pass
