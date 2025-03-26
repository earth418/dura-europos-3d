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


var waiting_for_texclick = false
var waiting_for_viewport = false

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("escape"):
		close_requested.emit()
	
	if event.is_action_pressed("adduv"):
		
		waiting_for_texclick = true
		
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_requested() -> void:
	hide()
	


func _on_texture_input(event: InputEvent) -> void:
	if event.is_action("left-click"):
		if waiting_for_texclick:
			
			var i = get_mouse_position()
			var base = $Control2/TextureRect.position
			var uv = (i - base) / $Control2/TextureRect.size
			print(uv)


func _on_viewport_container_input(event: InputEvent) -> void:
	
	#var root = $Control2/SubViewportContainer/SubViewport/Node3D
	#var camera = root.get_node("FreeLookCamera")
	
	pass # Replace with function body.
