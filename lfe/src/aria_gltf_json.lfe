;; SPDX-License-Identifier: MIT
;; glTF JSON load/save using jiffy. Preserves extensions and extras.

(defmodule aria_gltf_json
  (export (load_json 1) (save_json 1)))

(defun load_json (json_str)
  (let ((bin (if (is_binary json_str) json_str (list_to_binary json_str)))
        (data (case (jiffy:decode bin)
                ((tuple 'ok m) m)
                (_ (map)))))
    (state_from_data (aria_gltf_state:state_new) data)))

(defun state_from_data (state data)
  (let ((state (maps:put 'json data state)))
    (fold_opt state data
              (list (tuple <<"nodes">> 'nodes)
                    (tuple <<"buffers">> 'buffers)
                    (tuple <<"bufferViews">> 'buffer_views)
                    (tuple <<"accessors">> 'accessors)
                    (tuple <<"meshes">> 'meshes)
                    (tuple <<"materials">> 'materials)
                    (tuple <<"textures">> 'textures)
                    (tuple <<"images">> 'images)
                    (tuple <<"animations">> 'animations)
                    (tuple <<"skins">> 'skins)
                    (tuple <<"cameras">> 'cameras)
                    (tuple <<"extensionsUsed">> 'extensions_used)
                    (tuple <<"extensionsRequired">> 'extensions_required)
                    (tuple <<"scene">> 'root_nodes)))))

(defun fold_opt (state data kvs)
  (lists:foldl
   (lambda (pair st)
     (case pair
       ((tuple json_key state_key)
        (case (maps:find json_key data)
          ((tuple 'ok val) (maps:put state_key val st))
          (_ st))))
   state
   kvs))

(defun save_json (state)
  (let ((data (maps:get 'json state (map))))
    (data_to_json state data
                  (list (tuple 'nodes <<"nodes">>)
                        (tuple 'buffer_views <<"bufferViews">>)
                        (tuple 'accessors <<"accessors">>)
                        (tuple 'meshes <<"meshes">>)
                        (tuple 'materials <<"materials">>)
                        (tuple 'textures <<"textures">>)
                        (tuple 'images <<"images">>)
                        (tuple 'animations <<"animations">>)
                        (tuple 'skins <<"skins">>)
                        (tuple 'cameras <<"cameras">>)
                        (tuple 'extensions_used <<"extensionsUsed">>)
                        (tuple 'extensions_required <<"extensionsRequired">>)
                        (tuple 'root_nodes <<"scene">>)))))

(defun data_to_json (state data kvs)
  (let ((data (lists:foldl
               (lambda (pair d)
                 (case pair
                   ((tuple state_key json_key)
                    (case (maps:find state_key state)
                      ((tuple 'ok val) (maps:put json_key val d))
                      (_ d))))
               data
               kvs)))
    (jiffy:encode data)))
