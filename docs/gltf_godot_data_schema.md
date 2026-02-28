# glTF Godot Importer/Exporter — Data Schema Reference

Data contract for the Janet glTF implementation. Describes the in-memory shape of types used by the Godot glTF pipeline so Janet can hold equivalent data without Godot APIs. Reference: Godot `modules/gltf/` and scene types.

## GLTFState

Logical fields (not C++ types):

- **json** — Parsed glTF JSON root (map/table)
- **nodes** — Array of GLTFNode
- **buffers** — Array of GLTFBuffer
- **buffer_views** — Array of GLTFBufferView
- **accessors** — Array of GLTFAccessor
- **meshes** — Array of GLTFMesh
- **materials** — Array of GLTFMaterial
- **textures** — Array of GLTFTexture
- **images** — Array of GLTFImage
- **animations** — Array of GLTFAnimation
- **skins** — Array of GLTFSkin
- **cameras** — Array of GLTFCamera
- **lights** — Array of GLTFLight
- **root_nodes** — Array of node indices (integers)
- **scene_mesh_instances** — Map: node index → ImporterMeshInstance3D data
- **scene_nodes** — Map or array of scene node data
- **extensions_used** — Array of extension identifier strings
- **extensions_required** — Array of extension identifier strings
- **additional_data** — Map for extra keys (extras, custom)

Mapping: State is the single object that glTF document parse/serialize reads and writes. JSON/GLB is the serialized form.

## GLTFNode

- **name** — String
- **parent** — Parent node index (-1 or integer)
- **children** — Array of child node indices
- **transform** — 4×4 matrix or position/rotation/scale
- **mesh** — Mesh index (-1 or integer)
- **skin** — Skin index (-1 or integer)
- **camera** — Camera index (-1 or integer)
- **light** — Light index (-1 or integer)
- **skeleton_path** — String (path to skeleton node)
- **extensions** — Map of extension name → extension payload

Mapping: glTF JSON `nodes` array element; node index = array index.

## GLTFMesh

- **name** — String
- **primitives** — Array of mesh primitive (attributes, indices, material index, mode)
- **weights** — Array of morph target weights (optional)

Mapping: glTF JSON `meshes` array element.

## GLTFAccessor

- **buffer_view** — Buffer view index (-1 or integer)
- **byte_offset** — Integer
- **component_type** — Integer (e.g. 5126 for FLOAT)
- **count** — Integer
- **type** — String (e.g. "VEC3", "SCALAR")
- **min** — Array of numbers (optional)
- **max** — Array of numbers (optional)

Mapping: glTF JSON `accessors` array element.

## GLTFBufferView

- **buffer** — Buffer index
- **byte_offset** — Integer
- **byte_length** — Integer
- **byte_stride** — Integer (optional)
- **target** — Integer (e.g. 34962 ARRAY_BUFFER)

Mapping: glTF JSON `bufferViews` array element.

## GLTFBuffer

- **byte_length** — Integer
- **uri** — String or nil (embedded when nil in GLB)

Mapping: glTF JSON `buffers` array element.

## ImporterMesh (Godot scene type — data only)

Logical content used for mesh serialization (from Godot `scene/resources/3d/importer_mesh.h`):

- **surfaces** — Array of surface data: primitive type, arrays (vertices, normals, uvs, etc.), blend_shape_data, lods, material ref, name, flags
- **blend_shapes** — Array of blend shape names
- **blend_shape_mode** — Integer/mode
- **lightmap_size_hint** — Vector2 or (x, y)
- **name** — String

Mapping: Equivalent to glTF mesh primitives + accessors; surface arrays map to glTF attributes and index buffer.

## ImporterMeshInstance3D (Godot scene type — data only)

Logical content written to glTF nodes (from Godot `scene/3d/importer_mesh_instance_3d.h`):

- **mesh** — Reference to mesh (mesh index or id)
- **skin** — Reference to skin (skin index or id)
- **skeleton_path** — String
- **surface_materials** — Array or map of surface index → material override
- **layer_mask** — Integer
- **shadow_visibility_range_begin** — Float
- **shadow_visibility_range_end** — Float
- **visibility_range_begin** — Float
- **visibility_range_end** — Float
- **name** — String (Node3D)
- **transform** — 4×4 or position/rotation/scale (Node3D)
- **visible** — Boolean (VisualInstance3D)

Mapping: One glTF node + mesh index + optional skin index; transform and name go to the node.

## GLTFAnimation

- **name** — String
- **tracks** — Array of track data (sampler indices, target node, path, etc.)

Mapping: glTF JSON `animations` array element; samplers and channels.

## GLTFTexture, GLTFImage, GLTFMaterial, GLTFSkin, GLTFCamera, GLTFLight

Minimal fields needed to round-trip JSON: same key names as glTF 2.0 spec; indices reference arrays in state. Material: base_color, metallic, roughness, etc. Image: uri, mime_type, buffer_view index. Texture: sampler index, source image index.

## Extension hooks

- **Import:** For each node/material/mesh etc., parse known extensions (e.g. KHR_interactivity); store in state or in node/mesh `extensions` map.
- **Export:** When serializing, write back `extensions` and `extras` so behavior graphs and custom data are preserved.

## Janet implementation notes

- Use tables/structs with the field names above; no Godot types.
- Parse: JSON string or GLB bytes → state (decode JSON; for GLB, strip chunk header and parse JSON chunk).
- Serialize: state → JSON string (or GLB with length-prefixed chunks).
- KHR_interactivity: Preserve `extensions.KHR_interactivity` (or equivalent) in state so behavior graph data can be read/written without full engine port.
