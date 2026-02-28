# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# glTF state type and constructor. Data contract per docs/gltf_godot_data_schema.md.

(defn state-new []
  @{
    :nodes @[]
    :buffers @[]
    :buffer_views @[]
    :accessors @[]
    :meshes @[]
    :materials @[]
    :textures @[]
    :images @[]
    :animations @[]
    :skins @[]
    :cameras @[]
    :lights @[]
    :root_nodes @[]
    :scene_mesh_instances @{}
    :scene_nodes @{}
    :extensions_used @[]
    :extensions_required @[]
    :additional_data @{}
    :json @{}})
