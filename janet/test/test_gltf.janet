# Minimal glTF JSON round-trip and behavior graph extraction.

(module/add-syspath (string (os/cwd) "/" "source"))
(import aria/gltf/state :as S)
(import aria/gltf/json :as J)
(import aria/gltf/graph :as G)

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

# Behavior graph extraction: no extension -> error
(def res-none (G/extract-behavior-graph (get state :json)))
(assert (and (table? res-none) (get res-none :error)) "no KHR_interactivity yields error")

# With KHR_interactivity and nodes -> {:ok (asset graph)}
(def with-graph "{\"asset\":{\"version\":\"2.0\"},\"extensions\":{\"KHR_interactivity\":{\"nodes\":[{\"id\":\"n1\",\"operation\":\"flow/sequence\"}]}}}")
(def state-g (J/load-json with-graph))
(def res-ok (G/extract-behavior-graph (get state-g :json)))
(assert (and (table? res-ok) (get res-ok :ok)) "extract returns :ok")
(def pair (get res-ok :ok))
(assert (and (tuple? pair) (= (length pair) 2)) "ok is (asset graph)")
(assert (get (pair 1) "nodes") "graph has nodes")

# load-gltf-json-extract-graph
(def res-load (G/load-gltf-json-extract-graph with-graph))
(assert (and (table? res-load) (get res-load :ok)) "load-gltf-json-extract-graph returns :ok")

(print "test_gltf: round-trip and graph extraction passed")
