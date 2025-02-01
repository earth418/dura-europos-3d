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

var center_loc = [34.74799827813365, 40.73026895370481]

func lat_lon_to_cartesian(loc):
	# Returns the lat/lon as a vector3 relative to the origin
	
	#print(loc)
	
	var radius = 6371000 # meters
	
	var loc1 = [rad_to_deg(center_loc[0]), rad_to_deg(center_loc[1])]
	var loc2 = [rad_to_deg(loc[0]), rad_to_deg(loc[1])]

	
	var y = sin(loc2[1] - loc1[1]) * cos(loc2[0]) 
	var x = 	cos(loc1[0]) * sin(loc2[0]) - sin(loc1[0]) * cos(loc2[0]) \
		* cos(loc2[1] - loc1[1])
		
	return radius * Vector3(x, y, 0.0)
	
func generate_geojson_mesh():
	#load_json_file()
	var geojson = json_contents.data
	#mesh = ArrayMesh.new()
	
	for feature in geojson["features"]:
		var feature_name = feature["properties"]["id"]
		if feature_name != null: 
			mesh.surface_set_name(0, feature_name)
		
		var coordinates = feature["geometry"]["coordinates"]
		
		for coordinate in coordinates[0]:
			print("hi ", coordinate)
			#print(lat_lon_to_cartesian([coordinate[0], coordinate[1]]))
	
	pass

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
