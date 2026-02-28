;; SPDX-License-Identifier: MIT
;; glTF state type. Data contract per docs/gltf_godot_data_schema.md.

(defmodule aria_gltf_state
  (export (state_new 0)))

(defun state_new ()
  (map 'nodes '()
       'buffers '()
       'buffer_views '()
       'accessors '()
       'meshes '()
       'materials '()
       'textures '()
       'images '()
       'animations '()
       'skins '()
       'cameras '()
       'lights '()
       'root_nodes '()
       'scene_mesh_instances #M()
       'scene_nodes #M()
       'extensions_used '()
       'extensions_required '()
       'additional_data #M()
       'json #M()))
