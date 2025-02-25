class_name Player extends Node3D

#var selected_objects = []
var selected_object = null

	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass




func get_pointed_object():
	
	var rc = $Camera3D/RayCast3D
	return rc.get_collider()
	


func _input(event):

	# My code!!!
	if event.is_action_pressed("click"):
		var object = get_pointed_object()
		#for selected_obj in selected_objects:
		var obj = selected_object as GeoJSON_Mesh
		if obj:
			print(obj.json_path)
			obj.material = load("res://white_standard_mat.tres")
				#for cube_obj in obj.spawned_meshes:
					#cube_obj.get_active_material(0).next_pass = null
		#selected_objects = []

		var new_obj = object as GeoJSON_Mesh
		if new_obj:
			print(new_obj.json_path)
			new_obj.material = load("res://white_outline_mat.tres")
		else:
			print(object)
		
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
