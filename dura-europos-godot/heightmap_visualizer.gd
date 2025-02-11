@tool
extends MeshInstance3D

@export var heightmap : Image

@export var material : Material

@export var refresh : bool:
	set(new_val):
		generate_mesh()
		refresh = false

@export var clear : bool:
	set(new_val):
		#mesh.clear()
		if is_instance_of(mesh, ArrayMesh):
			mesh.clear_surfaces()
		mesh = Mesh.new()
		clear = false

var st : SurfaceTool = SurfaceTool.new()

func generate_mesh():
	var size = heightmap.get_size()
	var data = heightmap.get_data()
	
	if is_instance_of(mesh, ArrayMesh):
		mesh.clear_surfaces()
	else:
		mesh = ArrayMesh.new()
	
	if st == null:
		st = SurfaceTool.new()
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	#var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	#var tangents = PackedVector3Array()
	
	#var min_val = 255
	#var max_val = 0
	
	for i in range(size.x):
		for j in range(size.y):
			
			
			#normals.append(Vector3(0.0, 1.0, 0.0))
			
			var index = j * size.x + i
			uvs.append(Vector2(2 * i / size.x - 1, 2 * j / size.y - 1))
			#if data[index] < min_val:
				#min_val = data[index]
			#if data[index] > max_val:
				#max_val = data[index]
			
			var height = 174.5 + 57.3 * data[index] / 255.0
			
			var location = Vector3(i, 0.0, j) * 3.92 + Vector3(-989.8, height, -989.8)
			if i != size.x - 1 and j != size.y - 1:
				indices.append_array([index, index + size.x + 1, index + 1, index, index + size.x, index + size.x + 1])
			
			vertices.append(location)

	# Initialize the ArrayMesh.
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	#arrays[Mesh.ARRAY_NORMAL] = normals
	
	st.create_from_arrays(arrays, Mesh.PRIMITIVE_TRIANGLES)
	st.generate_normals()
	var arrays_new = st.commit_to_arrays()
	
	#mesh = st.commit()
	arrays_new[Mesh.ARRAY_TEX_UV] = uvs
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays_new)
	
	mesh.surface_set_material(0, material)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
