class_name Player extends Node3D

#var selected_objects = []
var selected_object : GeoJSON_Mesh = null
var selecting = true

@onready var wikigallery : WikiGallery = $Camera3D/Control/FocusedInfo/WikiGallery

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.

func get_pointed_object():
	
	var rc = $Camera3D/RayCast3D
	return rc.get_collider()
	

const white_mat = preload("res://materials/white_standard_mat.tres")
const highlight_mat = preload("res://materials/white_highlight_mat.tres")
const outline_mat = preload("res://materials/white_outline_mat.tres")

var last_looked_at : GeoJSON_Mesh = null
func _process(delta: float) -> void:
	var new_obj = get_pointed_object() as GeoJSON_Mesh
	
	if last_looked_at and last_looked_at != selected_object:
		last_looked_at.material = white_mat
	if new_obj and new_obj != selected_object:
		new_obj.material = highlight_mat
	last_looked_at = new_obj
	
	#var v = get_viewport()
	#var id = v.get_texture()
	#id.viewport_path
	#var id = RenderingServer.viewport_get_render_target(v)
	#print(id)


func display_info_for_object(obj):
	
	if not obj:
		return
		
	$Camera3D/Control/FocusedInfo.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	var id = obj.json_path.split("/")[-1].split(".")[0]
	$Camera3D/Control/FocusedInfo/RichTextLabel.text = id
	
func un_display_object(obj):
	if not obj:
		return
	
	$Camera3D/Control/FocusedInfo.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Camera3D/Control/RichTextLabel.text = ""\
	
	#$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.FREELOOK
	
func _input(event):

	# My code!!!
	if event.is_action_pressed("left-click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return
		
		if not selecting:
			return
			
		var object = get_pointed_object()
		#for selected_obj in selected_objects:
		if selected_object:
			#print(selected_object.json_path)
			un_display_object(selected_object)
			selected_object.material = white_mat

		var new_obj = object as GeoJSON_Mesh
		if new_obj:
			print(new_obj.json_path)
			new_obj.material = outline_mat
			display_info_for_object(new_obj)
		else:
			print(object)
			
		selected_object = new_obj

	if event.is_action_pressed("right-click"):
		
		if not selecting:
			return
		
		if selected_object:
			#print(selected_object.json_path)
			un_display_object(selected_object)
			selected_object.material = white_mat

	#if event.is_action_pressed("shift-click"):
		#selected_objects.append(get_pointed_object())
		#for object in selected_objects:
			#var obj = object as GeoJSON_Mesh
			#if obj:
				#print(obj.json_path)
				#obj.material = load("res://white_outline_mat.tres")
			#else:
				#print(object)
	
	if event.is_action_pressed("focus"):
		_on_focus_button_pressed()

	if event.is_action_pressed("edit"):
		open_uv_editor(selected_object, wikigallery.loaded_picture, wikigallery.loaded_picture_info)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

var uv_window : UVEditorWindow = null

func open_uv_editor(obj, photo, photo_info = null):
	
	if !uv_window or !uv_window.visible:
		uv_window = UVEditorWindow.create_editor(obj, photo, photo_info)
		add_child(uv_window)
	#add_child(window)
	# var v = Viewport.new()
	#var w = Window.new()
	#w.size = Vector2i(500, 500)
	##var w = Popup.new()
	#w.add_child(obj.duplicate())
	#var new_camera : FreeLookOrbitCamera = $Camera3D.duplicate()
	#
	#new_camera.anchor_transform = Transform3D()
	#new_camera.camera_type = FreeLookOrbitCamera.CameraType.ORBIT
	#w.add_child(new_camera)
	#
	#w.popup_centered_ratio() # 80% of the default window size
	#w.grab_focus()
	#w.visible = true
	#var s = SceneTree.new()
	#s
	#var new_world = World3D.new()
	#new_world
	#w.world_3d = new_world

#var is_focused = false

func focus_on_object(obj):
	
	
	$Camera3D._distance = global_position.distance_to(obj.mesh_location)
	$Camera3D.anchor_transform = Transform3D(Basis(), obj.mesh_location)
	$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.ORBIT
	
	#$Camera3D/Control/Button.text = "Click here to stop focusing on object"
	
	#$Camera3D/Control/WikiGallery.visible = true
	var id = obj.json_path.split("/")[-1].split(".")[0]
	wikigallery.get_pics_depicting_building(id)


func defocus_on_object(obj):
	
	#$Camera3D/Control/Button.text = "Click here to focus on object"
	$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.FREELOOK

func _on_focus_button_pressed() -> void:
	if not selected_object:
		return
	
	if selecting:
		wikigallery.find_child("ItemList").clear()
		#$Camera3D/Control/FocusedInfo/WikiGallery/ItemList.clear()
		focus_on_object(selected_object)
	else:
		defocus_on_object(selected_object)
	
	#$Camera3D/Control/Button.text = "Click here to stop focusing on 
		#object" if selecting else "Click here to focus on object"
	#
	#$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.ORBIT if selecting \
			#else FreeLookOrbitCamera.CameraType.FREELOOK
	#if selecting:
		#$Camera3D.anchor_transform = Transform3D(Basis(), selected_object.mesh_location)

	selecting = !selecting
