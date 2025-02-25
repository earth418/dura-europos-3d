class_name Player extends Node3D

#var selected_objects = []
var selected_object : GeoJSON_Mesh = null

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.

func get_pointed_object():
	
	var rc = $Camera3D/RayCast3D
	return rc.get_collider()
	

const white_mat = preload("res://white_standard_mat.tres")
const highlight_mat = preload("res://white_highlight_mat.tres")
const outline_mat = preload("res://white_outline_mat.tres")

var last_looked_at : GeoJSON_Mesh = null
func _process(delta: float) -> void:
	var new_obj = get_pointed_object() as GeoJSON_Mesh
	
	if last_looked_at and last_looked_at != selected_object:
		last_looked_at.material = white_mat
	if new_obj and new_obj != selected_object:
		new_obj.material = highlight_mat
	last_looked_at = new_obj


func display_info_for_object():
	
	if selected_object:
		pass
	
	pass

func _input(event):

	# My code!!!
	if event.is_action_pressed("click"):
		var object = get_pointed_object()
		#for selected_obj in selected_objects:
		if selected_object:
			print(selected_object.json_path)
			selected_object.material = white_mat

		var new_obj = object as GeoJSON_Mesh
		if new_obj:
			print(new_obj.json_path)
			new_obj.material = outline_mat
		else:
			print(object)
			
		selected_object = new_obj
		
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	#if event.is_action_pressed("shift-click"):
		#selected_objects.append(get_pointed_object())
		#for object in selected_objects:
			#var obj = object as GeoJSON_Mesh
			#if obj:
				#print(obj.json_path)
				#obj.material = load("res://white_outline_mat.tres")
			#else:
				#print(object)
	

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
