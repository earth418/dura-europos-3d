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
@onready var polygon : Polygon2D = $Control2/TextureRect/Polygon2D
@onready var space: PhysicsDirectSpaceState3D = new_world.get_world_3d().direct_space_state

@onready var geojson_mesh = preload("res://scenes/geoJSON_mesh.tscn")
@onready var texture_mat  = preload("res://materials/white_standard_mat.tres")
@onready var highlight_mat = preload("res://materials/white_highlight_mat.tres")

@export var object : Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_centered_ratio(0.5)
	#priun$Control2.size
	$Control2/SubViewportContainer/SubViewport.size = $Control2.size * Vector2(0.5, 1.0)
	grab_focus()
	#var pos = Vector3(0, 0.0, 0)
	#camera.anchor_transform = Transform3D(Basis(), _object.center_loc)
	#world_3d = World3D.new()
	
	var new_obj : GeoJSON_Mesh
	
	if _object:
		#new_obj : GeoJSON_Mesh = _object.duplicate()
		#new_obj = _object.duplicate(DUPLICATE_SCRIPTS | DUPLICATE_GROUPS | DUPLICATE_SIGNALS)
		#add_child(new_obj)
		_object.global_position = -_object.mesh_location
		#camera.anchor_transform = Transform3D(Basis(), _object.mesh_location)
		_object.generate_collisions = true
		_object.refresh = true
		#print("Adding object...")
		#new_obj = geojson_mesh.instantiate()
		#new_obj.json_path = _object.json_path
		#add_child(new_obj)
		#new_obj.generate_collisions = true
		#new_obj.load_json_file(_object.json_path)
		#print(new_obj.json_contents)
		#new_obj.generate_geojson_mesh()
		##_object.refresh = true
		#
		#
		#print(new_obj)
		#print(new_obj.json_path)
		#new_obj.global_position = pos	
	else:
		object = new_world.get_node("Area3D")
		## debug
	#new_world.add_child(new_obj)
	if _picture:
		(texture_rect.texture as ImageTexture).set_image(_picture)
	else:
		texture_rect.texture = load("res://assets/satellite_color_square.png")
	
	uv_itemlist.item_selected.connect(list_item_clicked)


enum PickState {TEX, VIEWPORT, DONE}
var state : PickState = PickState.DONE

var working_uvs : Array[Vector2]
var working_pos : Array[Vector3]
var working_intersect : Dictionary

var selected_indices : Dictionary

var _mouse_position : Vector2

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		_mouse_position = event.relative
	
	#if event.is_action_pressed("left-click"):	
		#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		#var x =get_mouse_point()
	
	if event.is_action_pressed("right-click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event.is_action_pressed("escape"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		#close_requested.emit()
	
	if event.is_action_pressed("adduv"):
		working_intersect = {}
		working_pos = []
		working_uvs = []
		state = PickState.TEX

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == PickState.TEX:
		#var panel : Panel = $Control2/TextureRect/Panel
		
		
		if len(working_uvs) > 0:
			var pts = PackedVector2Array()
			for i in working_uvs:
				pts.append(i * texture_rect.size)
			var mp = get_mouse_position() - texture_rect.position
			pts.append(mp)
			polygon.polygon = pts
		else:
			polygon.polygon.clear()
	else:
		if state == PickState.VIEWPORT:
			var pts = PackedVector2Array()
			for i in working_uvs:
				pts.append(i * texture_rect.size)
			polygon.polygon = pts
		

func _on_close_requested() -> void:
	hide()
	
func _on_texture_input(event: InputEvent) -> void:
	if event.is_action_pressed("left-click") and state == PickState.TEX:
		
		var i = get_mouse_position()
		var base = texture_rect.position
		working_uvs.append((i - base) / texture_rect.size)
		#print(uv)
		print(len(working_uvs), " uvs clicked out of 4!!")
		if len(working_uvs) == 4:
			state = PickState.VIEWPORT


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

func _on_viewport_container_input(event: InputEvent) -> void:
	#return
	#var root = $Control2/SubViewportContainer/SubViewport/Node3D
	#var camera = root.get_node("FreeLookCamera")
	if event.is_action_pressed("left-click") and state == PickState.VIEWPORT:
		var intersect = get_mouse_point()
		if intersect:
			if not working_intersect:
				working_intersect = intersect
			
			if intersect["normal"].dot(working_intersect["normal"]) > 0.95:
				working_pos.append(intersect["position"])
				print(len(working_pos), " points clicked out of 4!!")
				if len(working_pos) == 4:
					apply_texture()
			else:
				print("Click the same surface please!")

func get_2d(pt : Vector3, normal : Vector3):
	var dots = [Vector3.UP, Vector3.LEFT, Vector3.FORWARD, Vector3.DOWN, Vector3.RIGHT, Vector3.BACK].map(normal.dot)
	#print(dots)
	var ind = dots.find(dots.max())
	
	match ind:
		0:
			return Vector2(pt.x, pt.z)
		1:
			return Vector2(pt.y, pt.z)
		2:
			return Vector2(pt.x, pt.y)
		3:
			return Vector2(pt.z, pt.x)
		4:
			return Vector2(pt.z, pt.y)
		5:
			return Vector2(pt.y, pt.x)
	
	#if normal.dot(Vector3.UP) > 0.99:
		#return Vector2(pt.x, pt.z)
	#elif abs(normal.dot(Vector3.LEFT)) > 0.99:
		#return Vector2(pt.y, pt.z)
	#elif abs(normal.dot(Vector3.FORWARD)) > 0.99:
		#return Vector2(pt.x, pt.y)
	#else:
		#print("Damn. Can't do that, sorry")
		#return -Vector2.INF


func apply_texture():
	var clicked_object : Node3D = working_intersect["collider"]
	#var clicked_point : Vector3 = working_intersect["position"]
	var clicked_normal : Vector3 = working_intersect["normal"]
	for i in range(len(working_pos)):
		print("associating uv ", working_uvs[i], " with 3d point ", working_pos[i])
	#uv_list[uv] = clicked_point
	
	var material : StandardMaterial3D = texture_mat.duplicate()
	material.albedo_texture = texture_rect.texture

	var new_mesh : ArrayMesh
	var new_meshinstance : MeshInstance3D
	
	if clicked_object.has_node("addeds"):
		new_meshinstance = clicked_object.get_node("addeds") as MeshInstance3D
		new_mesh = new_meshinstance.mesh
	else:
		new_meshinstance = MeshInstance3D.new()
		new_meshinstance.name = "addeds"
		
		new_mesh = ArrayMesh.new()
		new_meshinstance.mesh = new_mesh
		
		clicked_object.add_child(new_meshinstance)
	
	var arrays = []
	
	var planemesh = PlaneMesh.new()
	var plane_arrays = planemesh.get_mesh_arrays()
	#ArrayMesh.new()
	
	arrays.resize(ArrayMesh.ARRAY_MAX)
	
	var sort_2d = func(v1 : Vector3, v2 : Vector3):
		var _v1 = get_2d(v1, clicked_normal)
		var _v2 = get_2d(v2, clicked_normal)
		
		if _v1.x < _v2.x:
			return true
		else:
			return _v1.y < _v2.y
	
	working_pos.sort_custom(sort_2d)
	
	#	[(1.0, 0.0, 1.0), (-1.0, 0.0, 1.0), (1.0, 0.0, -1.0), (-1.0, 0.0, -1.0)]
	
	var area = -1.0
	var triangle_1 = [2, 1, 0]
	
	while area < 0:
		triangle_1.shuffle()
		var t1v1 = working_pos[triangle_1[0]] - working_pos[triangle_1[1]]
		var t1v2 = working_pos[triangle_1[1]] - working_pos[triangle_1[2]]
		
		area = t1v1.cross(t1v2).dot(clicked_normal) # 2x area
		
		#if area < 0:
			#triangle_1.reverse()
	
	var triangle_2 = [3, 0, 2]
	
	area = -1
	while area < 0:
		triangle_2.shuffle()
		var t2v1 = working_pos[triangle_2[0]] - working_pos[triangle_2[1]]
		var t2v2 = working_pos[triangle_2[1]] - working_pos[triangle_2[2]]
		
		area = t2v1.cross(t2v2).dot(clicked_normal) # 2x area
	
	arrays[ArrayMesh.ARRAY_TEX_UV] = PackedVector2Array(working_uvs)
	arrays[ArrayMesh.ARRAY_VERTEX] = PackedVector3Array(working_pos.map(func(v): return v + clicked_normal * 0.05))
	arrays[ArrayMesh.ARRAY_NORMAL] = PackedVector3Array([clicked_normal, clicked_normal, clicked_normal, clicked_normal])
	
	#var pos_2d = working_pos.map(_get_2d)
	# 0, 1, 2, 0, 2, 3
	
	var indices = triangle_2 + triangle_1
	#var indices = [2, 1, 0, 3, 2, 0] # if clicked_normal.dot(Vector3.UP) > 0.95 else [0, 1, 2, 0, 2, 3]
	#arrays[ArrayMesh.ARRAY_INDEX] = PackedInt32Array(indices)
	
	var surface_idx = new_mesh.get_surface_count()
	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arrays)
	new_mesh.surface_set_material(surface_idx, material)
	
	
	
	uv_pos_list.append([working_uvs, working_pos, new_mesh, surface_idx])
	uv_itemlist.add_item("Decal " + str(uv_itemlist.item_count + 1))
	
	#new_plane_mesh.basis.from_euler()
	#new_plane_mesh.global_position = center
	#new_plane_mesh.quaternion = Quaternion(clicked_normal, 0.0)
	#new_meshinstance.look_at_from_position(center, center + Vector3.FORWARD, clicked_normal)
	#new_meshinstance.rotate(clicked_normal.cross(Vector3.UP), PI / 2.0)
	#new_meshinstance.position += clicked_normal * 0.05
	#new_meshinstance.set_surface_override_material(0, material)
		#new_plane_mesh.po
	
	state = PickState.DONE
	working_intersect = {}
	working_pos = []
	working_uvs = []

func list_item_clicked(index : int):
	return
	#var new_mat : Material
	#if index in selected_indices:
		#new_mat = texture_mat
		#selected_indices.erase(index)
	#else:
		#new_mat = highlight_mat
		#selected_indices[index] = 1
		#
	#var mesh : ArrayMesh = uv_pos_list[index][2]
	#var surface_idx = uv_pos_list[index][3]
	#new_mat.albedo_texture = texture_rect.texture
	#mesh.surface_set_material(surface_idx, new_mat)
