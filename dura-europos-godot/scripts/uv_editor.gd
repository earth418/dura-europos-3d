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

#var uv_list : Dictionary = {}
var uv_pos_list : Array = []

@onready var uv_itemlist : ItemList = camera.get_node("Control/ItemList")

@onready var geojson_mesh = preload("res://scenes/geoJSON_mesh.tscn")
@onready var texture_mat  = preload("res://materials/tex_display.tres")

@export var object : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_centered_ratio(0.5)
	#priun$Control2.size
	$Control2/SubViewportContainer/SubViewport.size = $Control2.size * Vector2(0.5, 1.0)
	grab_focus()
	var pos = Vector3(0, 0.0, 0)
	#$Control2/SubViewportContainer/SubViewport/Node3D.position = pos
	#$Control2/SubViewportContainer/SubViewport/FreeLookOrbitCamera.anchor_transform = Transform3D(Basis(), pos)
	
	camera.anchor_transform = Transform3D(Basis(), pos)
	#world_3d = World3D.new()
	
	var new_obj : GeoJSON_Mesh
	
	if _object:
		#new_obj : GeoJSON_Mesh = _object.duplicate()
		#new_obj = _object.duplicate()
		print("Adding object...")
		new_obj = geojson_mesh.instantiate()
		new_obj.json_path = _object.json_path
		add_child(new_obj)
		new_obj.generate_collisions = true
		new_obj.load_json_file(_object.json_path)
		print(new_obj.json_contents)
		new_obj.generate_geojson_mesh()
		#_object.refresh = true
		
		
		print(new_obj)
		print(new_obj.json_path)
		new_obj.global_position = pos
		
	else:
		object = new_world.get_node("Area3D")
		## debug
		#new_obj = MeshInstance3D.new()
		#var box = BoxMesh.new()
		#box.size = Vector3(50, 50, 50)
		#new_obj.mesh = box
		
	#new_world.add_child(new_obj)
	if _picture:
		(texture_rect.texture as ImageTexture).set_image(_picture)
	else:
		texture_rect.texture = load("res://assets/satellite_color_square.png")
	#pass # Replace with function body.


enum PickState {TEX, VIEWPORT, DONE}
var state : PickState = PickState.DONE

var working_uvs : Array[Vector2]
var working_pos : Array[Vector3]
var working_intersect : Dictionary

var _mouse_position : Vector2

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	#if event.is_action_pressed("left-click"):
		#var x =get_mouse_point()
		#print(x)
		
	if event.is_action_pressed("escape"):
		close_requested.emit()
	
	if event.is_action_pressed("adduv"):
		
		state = PickState.TEX
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == PickState.TEX:
		var panel : Panel = $Control2/TextureRect/Panel
		if len(uv_pos_list) > 0:
			var last_uv = uv_pos_list[-1][0]
			panel.position = last_uv
			panel.size = _mouse_position - last_uv
		
	#var sub_vp = $Control2/SubViewportContainer/SubViewport
	#var vp_texture : ViewportTexture = sub_vp.get_texture()
	#texture_rect.texture = vp_texture
	#var vp_image = vp_texture.get_image()
	#(texture_rect.texture as ImageTexture).set_image(vp_image)

func _on_close_requested() -> void:
	hide()
	
func _on_texture_input(event: InputEvent) -> void:
	if event.is_action("left-click") and state == PickState.TEX:
		
		var i = get_mouse_position()
		var base = texture_rect.position
		working_uvs.append((i - base) / texture_rect.size)
		#print(uv)
		if len(working_uvs) == 4:
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
	
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.collide_with_areas = true
	#ray_query.collision_mask =
	ray_query.from = src_pos
	ray_query.to = src_pos + 1000.0 * cam_dir
	#var intersect = space.intersect_ray(ray_query)
	return space.intersect_ray(ray_query)
	#if intersect:
		#var point = intersect["position"]
		#var normal = intersect["normal"]
		#
		##print(point)
		##new_world.get_node("MeshInstance3D2").global_position = point
		#return point
	#else:
		#return -Vector3.INF

func _on_viewport_container_input(event: InputEvent) -> void:
	#return
	#var root = $Control2/SubViewportContainer/SubViewport/Node3D
	#var camera = root.get_node("FreeLookCamera")
	if event.is_action("left-click"):
		if state == PickState.VIEWPORT:
			var intersect = get_mouse_point()
			if intersect:
				if not working_intersect:
					working_intersect = intersect
				
				if intersect["normal"].dot(working_intersect["normal"]) > 0.95:
					working_pos.append(intersect["position"])
					if len(working_pos) == 4:
						apply_texture()
				else:
					print("Click the same surface please!")
				
				
func apply_texture():
	
	var clicked_object = working_intersect["collider"]
	#var clicked_point : Vector3 = working_intersect["position"]
	var clicked_normal : Vector3 = working_intersect["normal"]
	for i in range(len(working_pos)):
		print("associating uv ", working_uvs[i], " with 3d point ", working_pos[i])
	#uv_list[uv] = clicked_point
	uv_pos_list.append([working_uvs, working_pos])
	uv_itemlist.add_item("texture 1")
	
	for i in range(0, len(uv_pos_list) - 1, 2):
		
		var c1 = uv_pos_list[i] # c1[0] is the UV, c1[1] is the vector
		var c2 = uv_pos_list[i + 1] # c2[0] is the UV, c2[1] is the vector
		
		#var old_tex = texture_rect.texture.get_image()
		##old_tex.crop()
		#var old_tex_size = Vector2(old_tex.get_size())
		
		# making the material
		#var min_uv = Vector2i(c1[0].min(c2[0]) * old_tex_size)
		#var max_uv = Vector2i(c1[0].max(c2[0]) * old_tex_size)
		##var offset = min_uv 
		#var scale = (max_uv - min_uv)
		
		var material : StandardMaterial3D = texture_mat.duplicate()
		#var region = Rect2i(offset, scale) 
		
		#var new_tex_data = []
		##
		#var old_tex_data = old_tex.get_data()
		#var start_index : int = int(offset.y) * old_tex_size.x + int(offset.x)
		#var end_index : int = start_index + int(scale.y) * old_tex_size.x + int(scale.x)
		
		#for row in range(min_uv.x, max_uv.x):
			#var row_start_index = row * scale.y
			#new_tex_data.append_array(old_tex_data.slice(row_start_index, row_start_index + scale.y))
		#print(len(old_tex.data["data"]))
		#print(old_tex.data)
		
		#var new_tex_data = old_tex_data.slice(start_index, end_index)
		#print("Starting at i=",start_index," until i=", end_index)
		#print("new data: ", new_tex_data)
		#var tex_img = old_tex.get_region(region)
		#print(len(new_tex_data))
		#print("new image: ( ", scale.x, " x ", scale.y ," )")
		
		#var tex_img = Image.create_from_data(scale.x, scale.y, true, old_tex.get_format(), new_tex_data)
		#print(region)
		#var new_tex = ImageTexture.create_from_image(tex_img)
		#new_tex.set_image(tex_img)
		material.albedo_texture = texture_rect.texture
		
		var center = (c1[1] + c2[1]) / 2.0
		var extent = c2[1] - c1[1]
		var side_length = (extent.length() * sqrt(2.0)) / 2.0
		
		var new_plane = PlaneMesh.new()
		new_plane.size = Vector2.ONE * side_length
		var new_plane_mesh = MeshInstance3D.new()
		clicked_object.add_child(new_plane_mesh)
		new_plane_mesh.mesh = new_plane
		#new_plane_mesh.basis.from_euler()
		#new_plane_mesh.global_position = center
		#new_plane_mesh.quaternion = Quaternion(clicked_normal, 0.0)
		new_plane_mesh.look_at_from_position(center, center + Vector3.FORWARD, clicked_normal)
		new_plane_mesh.rotate(clicked_normal.cross(Vector3.UP), PI / 2.0)
		new_plane_mesh.position += clicked_normal * 1.01
		new_plane_mesh.set_surface_override_material(0, material)
		#new_plane_mesh.po
	
	state = PickState.DONE
	working_intersect = {}
	working_pos = []
	working_uvs = []
