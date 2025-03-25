class_name UVEditorWindow extends Window

var _object : GeoJSON_Mesh
var _picture : Image
var _pic_info 

@onready var texture_rect : TextureRect = $FreeLookOrbitCamera/Control/TextureRect

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
	$Node3D.position = Vector3(0, 5000.0, 0)
	$FreeLookOrbitCamera.anchor_transform = Transform3D(Basis(), Vector3(0, 5000.0, 0))
	add_child(_object.duplicate())
	print(_object)
	print(_object.json_path)
	(texture_rect.texture as ImageTexture).set_image(_picture)
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_close_requested() -> void:
	hide()
	
