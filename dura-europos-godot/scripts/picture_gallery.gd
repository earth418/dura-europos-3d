class_name WikiGallery extends Control

var associated_pics = []
var pics_urls = {}
var httpr : HTTPRequest 

var loaded_picture : Image
var loaded_picture_info = {}

var custom_pictures = []

@export var building_id : String = "":
	set(new_id):
		#if httpr:
			#
		building_id = new_id

func clear_list():
	$ItemList.clear()

func add_customs():
	for i in custom_pictures:
		pass

func set_httpsignal(new_function):
	
	for c in httpr.request_completed.get_connections():
		httpr.request_completed.disconnect(c)
	httpr.request_completed.connect(new_function)

func add_custom_image(image_id):
	#Q122677095
	var image_query = "https://query.wikidata.org/sparql?query=SELECT%20%3Fitem%20%3Flabel%20%3FlabelAlt%20%3Fdescription"+\
	"%20%3Fimage%20%7B%0A%20%20BIND(wd%3A"+\
	image_id +\
	"%20AS%20%3Fitem)%0A%20%20%3Fitem%20wdt%3AP18%20%3Fimage.%0A%20%20SERVICE%20wikibase"+\
	"%3Alabel%20%7B%0A%20%20%20%20bd%3AserviceParam%20wikibase%3Alanguage%20%22en%2Car%22.%0A%20%20%20%20%3Fitem%20rdfs"+\
	"%3Alabel%20%3Flabel.%20%0A%20%20%20%20%3Fitem%20skos%3AaltLabel%20%3FlabelAlt.%0A%20%20%20%20%3Fitem%20schema%3Adescription%20%3Fdescription%0A%20%20%7D%0A%7D%0A"
	
	##if httpr.request_completed.is_connected(_building_request_completed):
		##httpr.request_completed.disconnect(_building_request_completed)
	#httpr.request_completed.disconnect
	set_httpsignal(_image_id_request_completed)
	
	httpr.request(image_query, ["Accept: application/sparql-results+json"], HTTPClient.METHOD_GET)

func _image_id_request_completed(a, b, c, result_body : PackedByteArray):
	
	var json = JSON.new()
	json.parse(result_body.get_string_from_utf8())
	var response = json.get_data()
	
	var response_body = response["results"]["bindings"]
	
	for image in response_body:
		if "image" in image:
			#associated_pics.append(image["object"]["value"])
			#pics_urls[image["object"]["value"]] = image["image"]["value"]
			$ItemList.add_item(image["objectLabel"]["value"])

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
	#print(result_body)
	
	loaded_picture = i
	($TextureRect.texture as ImageTexture).set_image(i)
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	httpr = HTTPRequest.new()
	add_child(httpr)
	
	#var sprql_query = "https://query.wikidata.org/sparql?query=SELECT%20%3Fobject%20%3FobjectLabel%20%3Fplace%20%3FplaceLabel%20%3Fcoordinate%20%3Fimage%20WHERE%20%7B%0ASERVICE%20wikibase%3Alabel%20%7B%20bd%3AserviceParam%20wikibase%3Alanguage%20%22%5BAUTO_LANGUAGE%5D%2Cen%22.%20%7D%0A%3Fobject%20wdt%3AP31%20wd%3AQ125191.%0A%3Fobject%20wdt%3AP5008%20wd%3AQ114241199.%0A%3Fobject%20wdt%3AP180%20%3Fplace.%0A%3Fplace%20wdt%3AP625%20%3Fcoordinate.%0AOPTIONAL%20%7B%20%3Fobject%20wdt%3AP18%20%3Fimage.%20%7D%0A%7D%0ALIMIT%2020"
	httpr.request_completed.connect(_building_request_completed)
	
	#get_pics_depicting_building("Q116950453")


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
	loaded_picture_info = associated_pics[index]
	print(loaded_picture_info)
	httpr.request(url)
	
	$info_eg.text = "" # set to english description of image
	$info_ar.text = "" # set to arabic description of image
