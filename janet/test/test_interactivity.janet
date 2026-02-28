# QuickCheck-style property tests: interactivity operation mapping, predicates, math.

(module/add-syspath (string (os/cwd) "/" "source"))
(use aria/domains/interactivity)
(use aria/test_property)

(seed-random 43)

# Property: spec-to-command then command-to-spec round-trips for op names of form "x/y"
(def op-specs (array "math/add" "variable/get" "flow/sequence" "pointer/get"))
(for-all "spec-to-command round-trip" op-specs
  (fn [spec]
    (= (command-to-spec (spec-to-command spec)) spec)))

# Property: for any state s, graph not active initially; after graph-activate, graph active
(def states (array @{} @{:x 1}))
(for-all "graph-activate sets graph active" states
  (fn [s]
    (and (not (graph-active? s))
         (graph-active? (graph-activate s)))))

# Property: socket-value-set then socket-value-get returns the value
(def socket-inputs (array
  (tuple @{} "n1" "a" 5.0)
  (tuple (graph-activate @{}) "n2" "b" 3.14)
  (tuple @{} "node" "out" -1)))
(for-all "socket-value get after set" socket-inputs
  (fn [triple]
    (def s (triple 0))
    (def node (triple 1))
    (def socket (triple 2))
    (def v (triple 3))
    (= (socket-value-get (socket-value-set s node socket v) node socket) v)))

# Property: node-executed-set then node-executed-get returns the flag
(for-all-triples "node-executed get after set"
  (array (tuple @{} "n1" true) (tuple @{} "n2" false) (tuple (graph-activate @{}) "n" true))
  (fn [s node flag]
    (= (node-executed-get (node-executed-set s node flag) node) flag)))

# Property: apply-binary-op (+, numbers) equals numeric + (random pairs)
(quickcheck-pair "apply-binary-op scalar +" 100 (gen-pair (gen-int -50 50) (gen-int -50 50))
  (fn [a b]
    (= (apply-binary-op a b +) (+ a b))))

# Property: apply-binary-op component-wise on tuples (random 3-vectors)
(defn gen-vec3 []
  (def g (gen-float -10 10))
  (fn [] (tuple (g) (g) (g))))
(quickcheck-pair "apply-binary-op tuple component-wise" 50 (gen-pair (gen-vec3) (gen-vec3))
  (fn [a b]
    (def out (apply-binary-op a b +))
    (and (= (length out) 3)
         (= (in out 0) (+ (in a 0) (in b 0)))
         (= (in out 1) (+ (in a 1) (in b 1)))
         (= (in out 2) (+ (in a 2) (in b 2))))))

(print "test_interactivity: property checks passed")
