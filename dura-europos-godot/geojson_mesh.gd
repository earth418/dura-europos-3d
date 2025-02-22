@tool
class_name GeoJSON_Mesh extends Area3D

var json_string : String
var json_contents = JSON.new()
#var heightmap = preload("res://assets/heightmap.png")

@onready var mesh_parent : Node3D = $test
var spawned_meshes : Array[MeshInstance3D] = []

var material : Material = preload("res://white_standard_mat.tres")

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

@export var clear : bool:
	set(new_val):
		for temp_obj in $test.get_children(true):
			$test.remove_child(temp_obj)
		spawned_meshes = []
		clear = false

@export var debug_height = false

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
	#spawned_meshes = []
		
	var geojson = json_contents.data
	var heightmap = preload("res://assets/heightmap.png")
	
	if debug_height:
		for i in range(50):
			for j in range(50):
				var coords = Vector2i(i * 10, j * 10)
				
				var heightval = heightmap.get_pixelv(coords)
				#print(coords)
				var height = 174.5 + 57.3 * heightval.r
				
				var new_cube = $cube.duplicate()
				$test.add_child(new_cube)
				
				new_cube.global_position = Vector3(coords.x * 3.92 - 989, height, coords.y * 3.92 - 989)
				new_cube.global_scale(Vector3(15.0, 15.0, 15.0))
		return

	if "data" not in geojson:
		return
	
	for feature in geojson["data"]["features"]:
		#var feature_name = feature["properties"]["id"]
		#if feature_name != null: 
			#mesh.surface_set_name(0, feature_name)
		
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
			
			var heightval00 = heightmap.get_pixelv(pxcoord).r
			
			var heightval = 0
			
			if pxcoord.x < 504.0 and pxcoord.y < 504.0:
				var diff = pxcoord_loc - Vector2(pxcoord)
				var om_diff = Vector2.ONE - diff
				
				# Let's do some bilinear interpolation
				var heightval10 = heightmap.get_pixelv(pxcoord + Vector2i(1.0, 0.0)).r
				var heightval01 = heightmap.get_pixelv(pxcoord + Vector2i(0.0, 1.0)).r
				var heightval11 = heightmap.get_pixelv(pxcoord + Vector2i.ONE).r
			
				heightval = heightval00 * om_diff.x * om_diff.y + heightval10 * diff.x * om_diff.y + \
							heightval01 * om_diff.x * diff.y + heightval11 * diff.x * diff.y
			else:
				heightval = heightval00
				
			var height = 174.5 + 57.3 * heightval
			
			# I might go back to this raycast method, but the fact that this doesn't work is scaring me a bit
			# Maybe the blender model is wrong?
			# I probably should be making it from the heightmap directly, anyway, actually
			
			loc.y = height
			
			locations.append(loc)
			
		print("Creating model with ", len(locations), " locations")
		#var shape = $CollisionShape3D.shape as ConvexPolygonShape3D
		#shape.points = []
		#var collision_points = []
		#var minxz_maxxz = [2000, 2000, -2000, -2000]
		var emin = Vector3(2000, 200.0, 2000)
		var emax = Vector3(-2000.0, -200, -2000)
		# var new_material = $cube.mesh.surface_get_material(0).duplicate()
		
		for i in range(len(locations) - 1):
			
			var loc1 = locations[i + 0]
			var loc2 = locations[i + 1]
			
			var difference = loc2 - loc1
			var yaw = atan2(difference.z, difference.x)
			var xscale = difference.length()
			var height_scale = max(10.0, 1.5 * abs(loc1.y - loc2.y))
			
			emin = emin.min(loc1)
			emax = emax.max(loc1)
				
			#collision_points.append(loc1)
			#collision_points.append(loc1 + Vector3(0, height_scale, 0))
			
			var new_cube : MeshInstance3D = $cube.duplicate()
			$test.add_child(new_cube)
			#spawned_meshes.append(new_cube)
			
			#new_cube.mesh.surface_set_material(0, material)
			new_cube.position = (loc1 + loc2) / 2 + Vector3(0, height_scale, 0)
			new_cube.scale = Vector3(xscale, height_scale, 1.0)
			#(new_cube as MeshInstance3D).global_rotate()
			new_cube.quaternion = Quaternion(Vector3.UP, -yaw)
			
		
		#($CollisionShape3D.shape as BoxShape3D).size = emax - emin
		#$CollisionShape3D.global_position = (emax + emin) / 2 
		#($CollisionShape3D.shape as ConcavePolygonShape3D).points = collision_points

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
