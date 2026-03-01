#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Generate rope.glb and minecraft_buildhouse.glb for C executor tests.
Run from c_src/fixtures: python gen_fixtures.py
No Elixir required."""
import json
import struct
import os

GLB_MAGIC = 0x46546C67
GLB_VERSION = 2
CHUNK_TYPE_JSON = 0x4E4F534A

def to_glb(gltf_dict):
    json_str = json.dumps(gltf_dict, separators=(',', ':'))
    json_bin = json_str.encode('utf-8')
    json_len = len(json_bin)
    pad = (4 - json_len % 4) % 4
    chunk_data = json_bin + b' ' * pad
    chunk_len = len(chunk_data)
    total_len = 12 + 8 + chunk_len
    header = struct.pack('<III', GLB_MAGIC, GLB_VERSION, total_len)
    chunk_header = struct.pack('<II', chunk_len, CHUNK_TYPE_JSON)
    return header + chunk_header + chunk_data

def rope_gltf():
    return {
        "asset": {"version": "2.0"},
        "extensionsUsed": ["KHR_interactivity"],
        "extensions": {
            "KHR_interactivity": {
                "graphs": [{
                    "types": [{"signature": "float"}],
                    "declarations": [
                        {"op": "flow/sequence"},
                        {"op": "math/add"}
                    ],
                    "nodes": [
                        {"declaration": 0, "flows": {"0": {"node": 1, "socket": "in"}}},
                        {"declaration": 1, "values": {"a": {"type": 0, "value": [1.0]}, "b": {"type": 0, "value": [2.0]}}}
                    ]
                }],
                "graph": 0
            }
        },
        "scene": 0,
        "scenes": [{"nodes": []}]
    }

def minecraft_buildhouse_gltf():
    nodes = [
        {"declaration": 0, "flows": {str(i): {"node": i + 1, "socket": "in"} for i in range(6)}}
    ]
    for i in range(1, 7):
        nodes.append({
            "declaration": 1,
            "values": {"a": {"type": 0, "value": [0.0]}, "b": {"type": 0, "value": [float(i)]}}
        })
    return {
        "asset": {"version": "2.0"},
        "extensionsUsed": ["KHR_interactivity"],
        "extensions": {
            "KHR_interactivity": {
                "graphs": [{
                    "types": [{"signature": "float"}],
                    "declarations": [{"op": "flow/sequence"}, {"op": "math/add"}],
                    "nodes": nodes
                }],
                "graph": 0
            }
        },
        "scene": 0,
        "scenes": [{"nodes": []}]
    }

def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    for name, gltf in [("rope.glb", rope_gltf()), ("minecraft_buildhouse.glb", minecraft_buildhouse_gltf())]:
        with open(name, "wb") as f:
            f.write(to_glb(gltf))
        print("Wrote", name)

if __name__ == "__main__":
    main()
