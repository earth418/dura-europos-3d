# Dura Europos 3D



This project started as Ali Hafez's senior thesis in Spring 2025, as a way to visually represent data from the [International (Digital) Dura-Europos Archive](https://duraeuroposarchive.org/) using the 3D open-source Godot game engine. In representing the archaeological site in 3D and allowing users to explore and add to the dataset, users and archaeologists will learn more about the site and its artifacts and history.



## Opening the project (in Godot)

Once you have Godot installed, you should open godot and simply be able to open/"Import" the godot project in the ~/dura-europos-godot directory of this repo.

## Build

Simply use Godot's build tools.

## 

# Documentation (Scripts)

I'm writing a temporary version of the documentation right here in the README, just to make sure it exists somewhere. Hopefully, this will be moved to a real documentation site later on. We'll go class-by-class.

## GeoJSON_Mesh

In *geojson_mesh.gd*, extends Area3D. This class is intended to generate a 3D mesh/structure from a geojson file or text input, though using just text is still untested.

###### load_json_file(filepath)

updates the **json_path** and loads the file's content into **json_contents** (as a JSON dictionary)

###### get_building_id()

returns the id of the building, calculated from the json filename

###### refresh

 when this bool is clicked in the editor, re-runs the functions in the setter (load_json_file, generates_mesh)

###### clear

bool clicked in editor that causes meshes to be cleared

###### generate_collisions (deprecated)

whether or not a collision should be generated that is identical to the mesh structure. Deprecated because it should really just be on all the time -- it has very little performance hit and is 100x better than the alternative (having it false).

###### (const) center_loc

the center location of the map, as latitude longitude. Used with haversine formula to get 3D locations from geoJSON lat/lon pairs

###### lat_lon_to_cartesian(loc)

 uses the (real!!) radius of the earth, the center_loc, and the Haversine (distance) formula to get a Euclidian, real-scale location on the flat plane

###### generate_geojson_mesh()

This function is kind of the meat of the class. It loops through each "feature" of the geoJSON, but for our purposes it should just have one -- the building. First, it loops through the geojson coordinates, converting each lat-lon coordinate to a point on the terrain plane. Then, using the heightmap and bilinear interpolation, places their heights exactly at the altitude they would be at in real life -- the map ranges from 174.5m to (174.5 + 57.3 = 231.3)meters in height, and so the heightmap result is interpolated to that range. The min/max was used for a simple bounding box collision, but that is not really used anymore.
Then, the locations -- now exactly corresponding to the map -- are looped through, and for every pair of points, some math is done to find out exactly how to stretch a cube along that axis to make a "wall" between those two points. The height of the wall is arbitrary, but there is a minimum so that it doesn't look weird. The collision shape is a cube generated the same way, so it perfectly matches the cube that's representing that wall and can thus be clicked on with a ray trace. These are added to the scene using *add_child()* -- the collisions must be added as a direct child to the Area3D, as far as I know, and the cubes are added to a *mesh_parent*, which is by default a child of the GeoJSON_Mesh.

## DE_Meshes

in *de\_geojson\_meshes.gd*, just a Node3D. This class loops through the folder of geojsons and loads meshes from them. In the future, these files should be downloaded and cached automatically from the wikidata, using the below incomplete functions:

###### request_all_buildings, load_objects_wikidata, httpr, _buildings_request_completed, and _geojson_request_completed

These functions are mostly implemented: request_all_buildings puts in a request that gets all buildings and the links to their geoJSONs. Load_objects_wikidata is sort of the master function that manages requests and calls. The other two functions handle HTTP requests from the wikidata site. The part that doesn't work is that every geojson_request returns a 303 error, even though if you click the links yourself, it'll take you to the building's geojson (if it exists). For a reference implementation that works, look at **picture_gallery.gd**.

###### object_list

A dictionary that maps from building_ids (e.g. Q1324....) to a Node that can be edited.

###### load_objects

Loops through every geojson in the assets/geojsons directory and creates a geoJSON mesh with it. 



# Documentation (Scenes)

Some scenes are hard to understand, because my structure is kind of confusing. I'll try to explain it here.


