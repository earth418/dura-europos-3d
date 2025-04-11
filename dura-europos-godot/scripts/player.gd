class_name Player extends Node3D

#var selected_objects = []
var selected_object : GeoJSON_Mesh = null
var selecting = true

@onready var wikigallery : WikiGallery = $Camera3D/Control/FocusedInfo/WikiGallery

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func get_pointed_object():
	
	var rc = $Camera3D/RayCast3D
	return rc.get_collider()
	

const white_mat = preload("res://materials/white_standard_mat.tres")
const highlight_mat = preload("res://materials/white_highlight_mat.tres")
const outline_mat = preload("res://materials/white_outline_mat.tres")

func save_to_file(object, path):
	
	# from godot wiki
	var gltf_document_save = GLTFDocument.new()
	var gltf_state_save = GLTFState.new()
	
	gltf_document_save.append_from_scene(object, gltf_state_save)
	gltf_document_save.write_to_filesystem(gltf_state_save, path)

var last_looked_at : GeoJSON_Mesh = null
func _process(delta: float) -> void:
	var new_obj = get_pointed_object() as GeoJSON_Mesh
	
	if last_looked_at and last_looked_at != selected_object:
		last_looked_at.material = white_mat
		if selecting:
			$Camera3D/Control/ClickedInfo.hide()
		#$Camera3D/Control/ClickedInfo/building_id.text = ""
		#$Camera3D/Control/ClickedInfo/building_description.text = ""
	
	if new_obj and new_obj != selected_object:
		new_obj.material = highlight_mat
		
		if selecting:
			var json_file = new_obj.json_contents.data
			$Camera3D/Control/ClickedInfo.show()
			$Camera3D/Control/ClickedInfo/building_id.text = "Object displayed: " + new_obj.get_building_id()
			
			#if "data" in json_file and "features" in json_file["data"] and "properties" in json_file["data"]["features"][0]:
			if "description" in json_file:
				#var obj_properties = json_file["data"]["features"][0]["properties"]
				#print(obj_properties)
				#$Camera3D/Control/ClickedInfo/building_description.text = "Title: " +\
				#obj_properties["title"] + "\nDescription: " + obj_properties["description"]
				#$Camera3D/Control/ClickedInfo/building_link.uri = obj_properties["link"]
				$Camera3D/Control/ClickedInfo/building_description.text = json_file["description"]["en"]
			else:
				$Camera3D/Control/ClickedInfo/building_description.text = ""
				$Camera3D/Control/ClickedInfo/building_link.uri = ""
		
	last_looked_at = new_obj
	
	var cam = $Camera3D
	var yaw = cam.rotation.y
	$Camera3D/Control/CompassControl/compass/arrow.rotation = yaw
	#var v = get_viewport()
	#var id = v.get_texture()
	#id.viewport_path
	#var id = RenderingServer.viewport_get_render_target(v)
	#print(id)


func display_info_for_object(obj):
	
	if not obj:
		return
		
	#$Camera3D/Control/FocusedInfo.visible = true
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	#var id = obj.json_path.split("/")[-1].split(".")[0]
	#$Camera3D/Control/FocusedInfo/RichTextLabel.text = "Object displayed: " + id
	
func un_display_object(obj):
	if not obj:
		return
	
	#$Camera3D/Control/FocusedInfo.visible = false
	#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#$Camera3D/Control/RichTextLabel.text = ""\
	
	#$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.FREELOOK



func _input(event):

	if event.is_action_pressed("save") and selected_object:
		print("pressed ctrlS and object selected")
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
		var f = FileDialog.new()
		f.use_native_dialog = true
		f.dialog_close_on_escape = true
		f.access = FileDialog.ACCESS_FILESYSTEM 
		f.add_filter("*.glb, *.gltf", "3D Model")
		var sv = func save_selected(path):
			var old_pos = selected_object.global_position
			selected_object.global_position = Vector3.ZERO
			save_to_file(selected_object, path)
			selected_object.global_position = old_pos
			
		add_child(f)
		f.file_selected.connect(sv)
		f.show()

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
			#print(new_obj.json_path)
			new_obj.material = outline_mat
			display_info_for_object(new_obj)
		#else:
			#print(object)
			
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
		#get_world_3d()
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
	
	$Camera3D/Control/FocusedInfo.visible = true
	$Camera3D._distance = global_position.distance_to(obj.mesh_location)
	$Camera3D.anchor_transform = Transform3D(Basis(), obj.mesh_location)
	$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.ORBIT
	
	#$Camera3D/Control/Button.text = "Click here to stop focusing on object"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	#$Camera3D/Control/WikiGallery.visible = true
	#var id = obj.json_path.split("/")[-1].split(".")[0]
	var id = (obj as GeoJSON_Mesh).get_building_id()
	wikigallery.get_pics_depicting_building(id)
	last_looked_at = null
	#obj = null


func defocus_on_object(obj):
	
	#$Camera3D/Control/Button.text = "Click here to focus on object"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	$Camera3D/Control/FocusedInfo.visible = false
	$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.FREELOOK
	last_looked_at = null
	#obj = null

func _on_focus_button_pressed() -> void:
	if not selected_object:
		return
	
	if selecting:
		wikigallery.clear_list()
		focus_on_object(selected_object)
	else:
		defocus_on_object(selected_object)
		wikigallery.clear_list()
	
	#$Camera3D/Control/Button.text = "Click here to stop focusing on 
		#object" if selecting else "Click here to focus on object"
	#
	#$Camera3D.camera_type = FreeLookOrbitCamera.CameraType.ORBIT if selecting \
			#else FreeLookOrbitCamera.CameraType.FREELOOK
	#if selecting:
		#$Camera3D.anchor_transform = Transform3D(Basis(), selected_object.mesh_location)

	selecting = !selecting


func _on_image_entry_text_submitted(new_text: String) -> void:
	wikigallery.add_custom_image(new_text)
