# Dura Europos 3D

May 1st, 2025.

This project has started as Ali Hafez's senior thesis in Spring 2025, as a way to visually represent data from the [International (Digital) Dura-Europos Archive](https://duraeuroposarchive.org/) using the 3D open-source Godot game engine. In representing the archaeological site in 3D and allowing users to explore and add to the dataset, users and archaeologists will learn more about the site and its artifacts and history.



## Opening the project (in Godot)

Once you have Godot installed, you should open godot and simply be able to open/"Import" the godot project in the ~/dura-europos-godot directory of this repo.

## Build

Simply use Godot's build tools to create an executable for your preferred platform. Try to get a working export to Web working! Note that this will only work with Godot's *Compatibility* renderer, and the current set render is the *Forward* renderer.

 

# Documentation

I'm writing a temporary version of the documentation right here in the README, just to make sure it exists somewhere. Hopefully, this will be moved to a real documentation site later on. We'll go class-by-class.

## GeoJSON_Mesh

In *geojson_mesh.gd*, extends Area3D. This class is intended to generate a 3D mesh/structure from a geojson file or text input, though using just text is still untested.

##### load_json_file(filepath)

updates the **json_path** and loads the file's content into **json_contents** (as a JSON dictionary)

##### get_building_id()

returns the id of the building, calculated from the json filename

##### refresh

 when this bool is clicked in the editor, re-runs the functions in the setter (load_json_file, generates_mesh)

##### clear

bool clicked in editor that causes meshes to be cleared

##### generate_collisions (deprecated)

whether or not a collision should be generated that is identical to the mesh structure. Deprecated because it should really just be on all the time -- it has very little performance hit and is 100x better than the alternative (having it false).

##### (const) center_loc

the center location of the map, as latitude longitude. Used with haversine formula to get 3D locations from geoJSON lat/lon pairs

##### lat_lon_to_cartesian(loc)

 uses the (real!!) radius of the earth, the center_loc, and the Haversine (distance) formula to get a Euclidian, real-scale location on the flat plane

##### generate_geojson_mesh()

This function is kind of the meat of the class. It loops through each "feature" of the geoJSON, but for our purposes it should just have one -- the building. First, it loops through the geojson coordinates, converting each lat-lon coordinate to a point on the terrain plane. Then, using the heightmap and bilinear interpolation, places their heights exactly at the altitude they would be at in real life -- the map ranges from 174.5m to (174.5 + 57.3 = 231.3)meters in height, and so the heightmap result is interpolated to that range. The min/max was used for a simple bounding box collision, but that is not really used anymore.
Then, the locations -- now exactly corresponding to the map -- are looped through, and for every pair of points, some math is done to find out exactly how to stretch a cube along that axis to make a "wall" between those two points. The height of the wall is arbitrary, but there is a minimum so that it doesn't look weird. The collision shape is a cube generated the same way, so it perfectly matches the cube that's representing that wall and can thus be clicked on with a ray trace. These are added to the scene using *add_child()* -- the collisions must be added as a direct child to the Area3D, as far as I know, and the cubes are added to a *mesh_parent*, which is by default a child of the GeoJSON_Mesh.

## DE_Meshes

in *de\_geojson\_meshes.gd*, just a Node3D. This class loops through the folder of geojsons and loads meshes from them. In the future, these files should be downloaded and cached automatically from the wikidata, using the below incomplete functions:

##### request_all_buildings, load_objects_wikidata, httpr, _buildings_request_completed, and _geojson_request_completed

These functions are mostly implemented: request_all_buildings puts in a request that gets all buildings and the links to their geoJSONs. Load_objects_wikidata is sort of the master function that manages requests and calls. The other two functions handle HTTP requests from the wikidata site. The part that doesn't work is that every geojson_request returns a 303 error, even though if you click the links yourself, it'll take you to the building's geojson (if it exists). For a reference implementation that works, look at **picture_gallery.gd**.

##### object_list

A dictionary that maps from building_ids (e.g. Q1324....) to a Node that can be edited.

##### load_objects

Loops through every geojson in the assets/geojsons directory and creates a geoJSON mesh with it, using **create_object**.

##### create_object

Create_object (and its companion **create_object_from_json**) create a geoJSON mesh with the specified JSON file/JSON content and add it to the scene tree, returning it from the function.

## WikiGallery

In *picture_gallery.gd*, extends *Control* (meaning it's a UI class). Has to have at least children: **ItemList**, which is used as the picture list; a **TextureRect**, which displays the clicked picture; a **info_eg** which displays the picture description. Also planned is the **info_ar**, for Arabic text, but unfortunately I did not fin da way to easily request two languages at once from the WikiData.

##### set_httpsignal()

A helper function to simplify HTTP callback function management

##### sparql_request()

Another helper function to simplify making a SPARQL query.

##### add_custom_image()

Searches for an image typed into the "add-image" box in a SPARQL query. The HTTP calls **_image_id_request_completed** which adds it to the photo list if successful.

##### get_pics_depicting_building(building_id)

Makes a SPARQL query returning all pictures tagged as depicting a specified building ID. **_building_request_completed** adds all these pictures to the photo list and stores their information and descriptions.

##### _on_item_clicked(index, ...)

Callback function for the **ItemList** when an item is clicked. It gets the URL of the image from the associated array, sets the **info_eg** box to display the image's info (since that doesn't need any new requests), and makes an HTTP request: the callback **_image_request_completed** loads the image into the **TextureRect.** 

## Player

in *player.gd*, extends Node3D. Handles inputs, looking around, and interaction with UI.

##### get_pointed_object()

Returns the object that the camera ray is pointing at

##### save_to_file(obj, path)

Takes an object and uses godot's API to save the object to a file path. Used when the user uses CTRL+S to save a clicked object.

##### _input(event)

Handles inputs and calls functions depending on each function. For the case of saving, also opens the file dialog to pick a location to save to.  

##### focus/defocus_on_object(obj)

Focuses on an object and switches between the free and orbiting camera, and updates the WikiGallery.

## UVEditorWindow

in *uv_editor.gd*, extends *Window*. This is a separate UI window, split in half between a sub-viewport looking at the world and centered on an object, and the other half with a texture. This is used for UV painting. On _ready, the class sets up variables and loads any previous decals on the building. 

##### uv_pos_list

A complete dictionary of all UV "paintings" in the session, organized by building ID.

##### polygon

A 2D polygon rendered over the texture, displaying the subsection of the texture you're picking.

##### state (PickState: {Tex, Viewport, Done})

The class functions with a finite state machine, that is in the "Tex" state until it gets all four clicked points on the texture, all four clicked points on the 3D model, and then it's done and displays the texture. The **working_uvs** and **working_pos** arrays are counters of how many tex points and model points you have clicked, respectively. The information about clicks is obtained by **_on_texture_input** (essentially _input but just for just the tex display/right half of the screen) and **_on_viewport_container_input** (same thing but just for the viewport/left half of the screen).

##### apply_texture()

Uses the saved info in **working_uvs** and **working_pos** to create a plane using the four three points, set the UVs to the declared UVs, and creates a procedural mesh with those characteristics. It also creates a new material (and if necessary a new visualmesh) and copies the displayed texture onto its albedo texture, so that the image is displayed according to the specified UVs. It checks if the triangles are oriented correctly and otherwise flips them, then creates the mesh and saves it to the **uv_pos_list**.

##### list_item_clicked() and list_item_input()

Manages the selection of previously created decals from the list, and allows you to delete them as well.

## Other classes

##### heightmap_visualizer.gd

This is a quick class I whipped up to, at runtime, turn the downloaded heightmap into a 3D mesh. This was just to make sure that any changes would be reflected in the software and both the structure placement and the visual mesh.

##### freelook_orbit_camera.gd

I copied the code for both of these cameras and threw them into one class. I changed a couple of things here and there, but overall the functionality is the same. Their code is cited in the file.


