# Minimal glTF JSON round-trip test.

(module/add-syspath (string (os/cwd) "/" "source"))
(import aria/gltf/state :as S)
(import aria/gltf/json :as J)

# Minimal glTF: asset, scene index, nodes array, scenes array
(def minimal-gltf "{\"asset\":{\"version\":\"2.0\"},\"scene\":0,\"nodes\":[{\"name\":\"Root\"}],\"scenes\":[{\"nodes\":[0]}]}")

(def state (J/load-json minimal-gltf))
(assert (get state :json) "state has json")
(assert (table? (get state :json)) "state.json is table")

(def out (J/save-json state))
(assert (string? out) "save returns string")
(assert (>= (length out) 2) "output non-empty")

# When decode populated nodes, round-trip preserves them
(when (get state :nodes)
  (def state2 (J/load-json out))
  (assert (get state2 :nodes) "round-trip has nodes"))

(print "test_gltf: round-trip passed")
