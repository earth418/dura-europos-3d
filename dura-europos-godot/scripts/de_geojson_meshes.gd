@tool
class_name DE_Meshes extends Node3D
## A class that loads all buildings either directly from the wikidata or from cashed files
##
## The script contains several functions related to this functionality.

@export var refresh : bool:
	set(new_val):
		load_objects()
		#load_json_file(json_path)
		#generate_geojson_mesh()
		refresh = false

@export var clear : bool:
	set(new_val):
		for temp_obj in $test.get_children(true):
			$test.remove_child(temp_obj)
		clear = false

@export var should_generate_collisions : bool = true
#@export var pick_files : Array[String]

var json_list = []

## Dictionary with all building IDs generated
var object_list = {}

var httpr : HTTPRequest

var geojson_scene = preload("res://scenes/geoJSON_mesh.tscn")

func request_all_buildings():
	# Requests all buildings in the format {item, itemLabel, itemDescription, geoJSON}
	# from the link to geoJSON, you can get a link that you can request again with an httpr request
	
	var get_buildings_query = """
	SELECT ?item ?itemLabel ?itemDescription ?geoJSON
	{
	  ?item p:P31 ?statement0.
	  ?statement0 (ps:P31/(wdt:P279*)) wd:Q41176.
	  ?item p:P361 ?statement1.
	  ?statement1 (ps:P361/(wdt:P279*)) wd:Q464266.
	  ?item wdt:P3896 ?geoJSON.
	  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,en"  }
	}
	LIMIT 1000"""
	
	if httpr.request_completed.is_connected(_geojson_request_completed):
		httpr.request_completed.disconnect(_geojson_request_completed)
	httpr.request_completed.connect(_buildings_request_completed)
	
	var query = get_buildings_query.uri_encode()
	httpr.request("https://query.wikidata.org/sparql?query=" + query, ["Accept: application/sparql-results+json"], HTTPClient.METHOD_GET)

func create_object(filename : String):
	var new_mesh : GeoJSON_Mesh = geojson_scene.instantiate()
	new_mesh.json_path = filename
	new_mesh.generate_collisions = should_generate_collisions
	$test.add_child(new_mesh)
	new_mesh.load_json_file(filename)
	new_mesh.generate_geojson_mesh()
	return new_mesh

func create_object_from_json(json : JSON):
	var new_mesh : GeoJSON_Mesh = geojson_scene.instantiate()
	#new_mesh.json_path = filename
	new_mesh.generate_collisions = should_generate_collisions
	$test.add_child(new_mesh)
	new_mesh.json_contents = json
	#new_mesh.load_json_file(filename)
	new_mesh.generate_geojson_mesh()
	return new_mesh

func dissapear_all_except_id(building_id):
	
	var childs = $test.get_children()
	for child in childs:
		var gj = child as GeoJSON_Mesh 
		if gj and gj.get_building_id() != building_id:
			gj.hide()

func reappear_all():
	var childs = $test.get_children()
	for child in childs:
		var gj = child as GeoJSON_Mesh 
		if gj:
			gj.show()

func load_objects():
	
	object_list = {}
	
	# For loading a custom geoJSON file
	# Code has not been tested and likely will not be
	
	#if len(pick_files) < 1:
		#
		#for json_filename in pick_files:
			#var building_id = json_filename.split(".")[0]
			##print("building id", building_id)
			#if building_id in object_list:
				#print("repeated " + building_id + "!")
				#continue
			#
			#object_list[building_id] = create_object("res://assets/geojsons/" + json_filename)
			
		
	
	var geojson_dir = DirAccess.open("res://assets/geojsons")
	if geojson_dir:
		geojson_dir.list_dir_begin()
		var json_filename = geojson_dir.get_next()
		while json_filename != "":
			var building_id = json_filename.split(".")[0]
			#print("building id", building_id)
			if building_id in object_list:
				json_filename = geojson_dir.get_next()
				print("repeated " + building_id + "!")
				continue
			
			object_list[building_id] = create_object("res://assets/geojsons/" + json_filename)
			json_filename = geojson_dir.get_next()


# These values are for load_objects_wikidata, which seeks to load things dynamically instead of from files
var current_id : String = ""
var current_ind = 0

func load_objects_wikidata():
	if len(json_list) == 0:
		request_all_buildings()
		# this will call load_objects_wikidata again
	else:
		var building_json = json_list[current_ind]
		#print(building_json)
		var b_id = building_json["item"]["value"].split("/")[-1]
		current_id = b_id
		print(building_json["geoJSON"]["value"])
		httpr.request(building_json["geoJSON"]["value"])
			

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_objects()
	
	httpr = HTTPRequest.new()
	add_child(httpr)
	
	# Does not work (yet)	
	#load_objects_wikidata()

func _buildings_request_completed(r, r_code, h, result_body):
	# This function is unimplemented!
	# It should fill some array and then notify load_objects_wikidata()
	# that the data is available, and from there reconstruct the buildings.
	# probably just by calling it again, and have it check if the array is full 
	var json = JSON.new()
	json.parse(result_body.get_string_from_utf8())
	var response = json.get_data()
	
	var result = response["results"]["bindings"]
	# Should be a list in the format [{item, itemLabel, itemDescription, geoJSON}, {}, {}...]
	#print(result)
	json_list = result
	if httpr.request_completed.is_connected(_buildings_request_completed):
		httpr.request_completed.disconnect(_buildings_request_completed)
	# we have data
	#for building_json in json_list:
	httpr.request_completed.connect(_geojson_request_completed)
	
	current_ind = 0
	
	load_objects_wikidata()

func _geojson_request_completed(r, r_code, h, result_body):
	
	print("Result code: ", r_code)
	#print(h)
	print(result_body)
	current_ind += 1
	
	if result_body:
		var json = JSON.new()
		json.parse(result_body.get_string_from_utf8())
		var response = json.get_data()
		
		print(response)
		object_list[current_id] = create_object_from_json(response)
	
	if current_ind < len(json_list):
		load_objects_wikidata()
	#var id = h[0]
	#print(id)
	#object_list[id] = create_object_from_json(result_body)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
