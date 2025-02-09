@tool
class_name GeoJSON_Mesh extends MeshInstance3D

var json_string : String
var json_contents = JSON.new()
#var heightmap = preload("res://assets/heightmap.png")

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

func lat_lon_to_cartesian(loc):
	# Returns the lat/lon as a vector3 relative to the origin
	var radius = 6371000 # meters
	
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
	var heightmap = preload("res://assets/heightmap.png")

	
	for feature in geojson["features"]:
		var feature_name = feature["properties"]["id"]
		if feature_name != null: 
			mesh.surface_set_name(0, feature_name)
		
		var coordinates = feature["geometry"]["coordinates"]
		var locations : Array[Vector3] = []	
		
		for coordinate in coordinates[0]:
			
			var coordvec = [coordinate[1], coordinate[0]]
			#print("hi ", coordvec)
			var loc = lat_lon_to_cartesian(coordvec)
			#print(loc / 3.92 + Vector3.ONE * 252.5)
			# total size is ~1979.6
			var pxcoord_loc = (Vector2(loc.x, loc.z) + Vector2(989.8, 989.8)) / (3.92)
			var pxcoord = Vector2i(pxcoord_loc)
			#pxcoord += Vector2i(252, 252)
			var heightval = heightmap.get_pixelv(pxcoord)
			print(pxcoord)
			var height = 174.5 + 57.3 * heightval.r
			#print(height)
			
			#var ray_query = PhysicsRayQueryParameters3D.new()
			#ray_query.from = loc + Vector3.UP * 235
			#ray_query.to = loc + Vector3.UP * 170
			
			loc.y = height
			
			locations.append(loc)
			
		for i in range(len(locations) - 1):
			
			var loc1 = locations[i + 0]
			var loc2 = locations[i + 1]
			
			var difference = loc2 - loc1
			var yaw = atan2(difference.z, difference.x)
			var scale = difference.length()

			var new_cube = $cube.duplicate()
			$test.add_child(new_cube)
			
			new_cube.global_position = (loc1 + loc2) / 2 + Vector3(0, 5, 0)
			new_cube.global_scale(Vector3(scale, 10.0, 1.0))
			new_cube.global_rotate(Vector3.UP, -yaw)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
