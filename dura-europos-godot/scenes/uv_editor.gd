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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	popup_centered_ratio(0.5)
	grab_focus()
	var pos = Vector3(0, 5000.0, 0)
	$Control2/SubViewportContainer/SubViewport/Node3D.position = pos
	$Control2/SubViewportContainer/SubViewport/FreeLookOrbitCamera.anchor_transform = Transform3D(Basis(), pos)
	var new_obj : GeoJSON_Mesh = _object.duplicate()
	add_child(new_obj)
	new_obj.global_position = pos
	print(_object)
	print(_object.json_path)
	(texture_rect.texture as ImageTexture).set_image(_picture)
	#pass # Replace with function body.

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("escape"):
		close_requested.emit()
	
	if event.is_action_pressed("adduv"):
		
		pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_requested() -> void:
	hide()
	
