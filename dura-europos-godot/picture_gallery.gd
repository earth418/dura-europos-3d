class_name WikiGallery extends Control

var associated_pics = []
var pics_urls = {}
var httpr : HTTPRequest 

@export var building_id : String = "":
	set(new_id):
		#if httpr:
			#
		building_id = new_id

func clear_list():
	$ItemList.clear()

func get_pics_depicting_building(building_id):
	
	if httpr.request_completed.is_connected(_image_request_completed):
		httpr.request_completed.disconnect(_image_request_completed)
	httpr.request_completed.connect(_building_request_completed)
	
	var building_query = "https://query.wikidata.org/sparql?query=SELECT%20%3Fobject" + \
	"%20%3FobjectLabel%20%3Fplace%20%3FplaceLabel%20%3Fcoordinate" + \
	"%20%3Fimage%20WHERE%20%7B%0ASERVICE%20wikibase%3Alabel" + \
	"%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%" + \
	"5BAUTO_LANGUAGE%5D%2Cen%22.%20%7D%0A%3Fobject%20" + \
	"wdt%3AP31%20wd%3AQ125191.%0A%3Fobject%20wdt%3AP5008%20wd%3AQ114241199.%0A%3Fobject%20wdt%3AP180%20wd%3A" + \
	# Q116950453 + \
	building_id + \
	"%2C%20%3Fplace.%0A%3Fplace%20wdt%3AP625%20%3Fcoordinate.%0AOPTIONAL%20%7B%20%3Fobject%20wdt%3AP18%20%3Fimage.%20%7D%0A%7D%0ALIMIT%20100"

	httpr.request(building_query, ["Accept: application/sparql-results+json"], HTTPClient.METHOD_GET)


func _building_request_completed(a, b, c, result_body : PackedByteArray):
	var json = JSON.new()
	json.parse(result_body.get_string_from_utf8())
	var response = json.get_data()
	
	#print(response)
	var response_body = response["results"]["bindings"]
	
	# One object:
#	{ "object": { "type": "uri", "value": "http://www.wikidata.org/entity/Q110873191" }, 
#        "place": { "type": "uri", "value": "http://www.wikidata.org/entity/Q464266" }, 
#        "coordinate": { "datatype": "http://www.opengis.net/ont/geosparql#wktLiteral", "type": "literal", "value": "Point(40.73 34.7475)" }, 
#		 "image": { "type": "uri", "value": "http://commons.wikimedia.org/wiki/Special:FilePath/YUAG%20Accession%20Number%201929.385%2C%20Negative%20number%20dura-b55~01.jpg" },
# 		 "objectLabel": { "xml:lang": "en", "type": "literal", "value": "Dura-Europos archival photograph, YUAG Negative number: dura-b55~01" }, 
# 		 "placeLabel": { "xml:lang": "en", "type": "literal", "value": "Dura-Europos" } }
	
	for image in response_body:
		if "image" in image:
			associated_pics.append(image["object"]["value"])
			pics_urls[image["object"]["value"]] = image["image"]["value"]
			$ItemList.add_item(image["objectLabel"]["value"])


func _image_request_completed(a, b, c, result_body : PackedByteArray):
	
	# this one should be just an image
	var i = Image.new()
	i.load_jpg_from_buffer(result_body)
	print(result_body)
	
	($TextureRect.texture as ImageTexture).set_image(i)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	httpr = HTTPRequest.new()
	add_child(httpr)
	
	#var sprql_query = "https://query.wikidata.org/sparql?query=SELECT%20%3Fobject%20%3FobjectLabel%20%3Fplace%20%3FplaceLabel%20%3Fcoordinate%20%3Fimage%20WHERE%20%7B%0ASERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%2Cen%22.%20%7D%0A%3Fobject%20wdt%3AP31%20wd%3AQ125191.%0A%3Fobject%20wdt%3AP5008%20wd%3AQ114241199.%0A%3Fobject%20wdt%3AP180%20%3Fplace.%0A%3Fplace%20wdt%3AP625%20%3Fcoordinate.%0AOPTIONAL%20%7B%20%3Fobject%20wdt%3AP18%20%3Fimage.%20%7D%0A%7D%0ALIMIT%2020"
	httpr.request_completed.connect(_building_request_completed)
	
	#get_pics_depicting_building("Q116950453")
	
	#pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var id = associated_pics[index]
	var url = pics_urls[id]
	if httpr.request_completed.is_connected(_building_request_completed):
		httpr.request_completed.disconnect(_building_request_completed)
	httpr.request_completed.connect(_image_request_completed)
	
	print(url)
	httpr.request(url)
	
	#pass # Replace with function body.
