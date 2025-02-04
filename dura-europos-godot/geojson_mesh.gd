@tool
class_name GeoJSON_Mesh extends MeshInstance3D

var json_string : String
var json_contents = JSON.new()

func load_json_file(json_filepath):
	var json_file = FileAccess.open(json_filepath, FileAccess.READ)
	json_string = json_file.get_as_text()
	var error = json_contents.parse(json_string)
	if error != OK:
		print("Data not formatted correctly!")
		json_contents = JSON.new()
	#print(json_contents.data)

@export_file var json_path: String:
	set(json_filepath):
		load_json_file(json_filepath)
		json_path = json_filepath

@export var refresh : bool:
	set(new_val):
		load_json_file(json_path)
		generate_geojson_mesh()
		refresh = false

@export var clear_dots : bool:
	set(new_val):
		for temp_obj in $test.get_children(true):
			$test.remove_child(temp_obj)
		clear_dots = false


const center_loc = [34.74799827813365, 40.73026895370481]
#const center_loc = [34.748, 40.730]

#var temp_objs : Array[MeshInstance3D] = []


func lat_lon_to_cartesian2(loc):
	var radius = 6371 * 0.2 # meters
	
	#var loc1 = [rad_to_deg(center_loc[0]), rad_to_deg(center_loc[1])]
	#var loc2 = [rad_to_deg(loc[0]), rad_to_deg(loc[1])]
	#
	#var x1 = asin(cos())

func lat_lon_to_cartesian(loc):
	# Returns the lat/lon as a vector3 relative to the origin
	#return lat_lon_to_cartesian2(loc)
	#print(center_loc)
	
	var radius = 6371000 # meters, * 0.5 because our 
	
	var loc1 = [deg_to_rad(center_loc[0]), deg_to_rad(center_loc[1])]
	var loc2 = [deg_to_rad(loc[0]), deg_to_rad(loc[1])]

	
	var y = sin(loc2[1] - loc1[1]) * cos(loc2[0]) 
	var x = 	cos(loc1[0]) * sin(loc2[0]) - sin(loc1[0]) * cos(loc2[0]) \
		* cos(loc2[1] - loc1[1])
		
	return radius * Vector3(y, 0.0, -x)
	
func generate_geojson_mesh():
	
	for temp_obj in $test.get_children(true):
		$test.remove_child(temp_obj)
		
	var geojson = json_contents.data
	
	for feature in geojson["features"]:
		var feature_name = feature["properties"]["id"]
		if feature_name != null: 
			mesh.surface_set_name(0, feature_name)
		
		var coordinates = feature["geometry"]["coordinates"]
		
		#var i = 0
		for coordinate in coordinates[0]:
			#i += 1
			#if i > 10:
				#return
			var coordvec = [coordinate[1], coordinate[0]]
			#print("hi ", coordvec)
			var loc = lat_lon_to_cartesian(coordvec) + Vector3(0.0, 250.0, 0.0)
			print(loc)
			var new_sphere = $sphere.duplicate()
			#var new_sphere = MeshInstance3D.new()
			#new_sphere.mesh = new_sphere_mesh
			$test.add_child(new_sphere)
			new_sphere.global_position = loc
			#temp_objs.append(new_sphere)
			#print("\n")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
