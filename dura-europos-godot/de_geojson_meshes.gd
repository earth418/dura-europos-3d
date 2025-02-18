@tool

class_name DE_Meshes extends Node3D

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

var httpr = HTTPRequest.new()

#const get_buildings_query = """
#SELECT ?item ?itemLabel ?value
#{
##   wd:Q98930725 wdt:P3896 ?value .
  #?item p:P31 ?statement0.
  #?statement0 (ps:P31/(wdt:P279*)) wd:Q41176.
  #?item p:P361 ?statement1.
  #?statement1 (ps:P361/(wdt:P279*)) wd:Q464266.
  #SERVICE wikibase:label { bd:serviceParam wikibase:language "en,en"  }
#}
#LIMIT 1000"""


func make_and_await_request():
	pass

func request_alL_buildings():
	
	pass

func create_object(filename):
	var new_mesh : GeoJSON_Mesh = $geojson_mesh.duplicate()
	$test.add_child(new_mesh)
	new_mesh.json_path = filename
	new_mesh.refresh = true
	new_mesh.load_json_file(filename)
	new_mesh.generate_geojson_mesh()

func load_objects():
	var geojson_dir = DirAccess.open("res://assets/geojsons")
	if geojson_dir:
		geojson_dir.list_dir_begin()
		var json_filename = geojson_dir.get_next()
		while json_filename != "":
			#print(json_filename)
			create_object("res://assets/geojsons/" + json_filename)
			json_filename = geojson_dir.get_next()
			
			
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_objects()
	#var httpc = HTTPClient.new()
	#if httpr.get_parent() != self:
		#add_child(httpr)
		#
	#httpr.request_completed.connect(self._http_request_completed)

func _http_request_completed(result, response_code, headers, body):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
