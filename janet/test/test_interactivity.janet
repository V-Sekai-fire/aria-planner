# QuickCheck-style property tests: interactivity operation mapping, predicates, math.

(module/add-syspath (string (os/cwd) "/" "source"))
(use aria/domains/interactivity)
(use aria/test_property)

(seed-random 43)

# Property: spec-to-command then command-to-spec round-trips for op names of form "x/y"
(def op-specs (array "math/add" "math/sub" "math/mul" "math/div" "variable/get" "flow/sequence" "pointer/get"))
(for-all "spec-to-command round-trip" op-specs
  (fn [spec]
    (= (command-to-spec (spec-to-command spec)) spec)))

# Operation mapping helpers (Phase 2)
(assert (is-spec-format? "math/add") "math/add is spec format")
(assert (not (is-spec-format? "c_math_add")) "c_math_add is not spec format")
(assert (= (get-domain "math/add") "math") "get-domain math/add")
(assert (= (get-operation "math/add") "add") "get-operation math/add")
(assert (= (get-domain "variable/get") "variable") "get-domain variable/get")

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

# Phase 2: c_math_sub, c_math_mul, c_math_div (scalar)
(defn make-math-state [a b]
  (def base (graph-activate @{}))
  (def s (socket-value-set base "n" "a" a))
  (socket-value-set s "n" "b" b))

(quickcheck-pair "c_math_sub scalar" 80 (gen-pair (gen-int -40 40) (gen-int -40 40))
  (fn [a b]
    (def s (make-math-state a b))
    (def res (c_math_sub s "n" "a" "b" "out"))
    (and (table? res) (get res :ok)
         (= (socket-value-get (get res :ok) "n" "out") (- a b))
         (node-executed-get (get res :ok) "n"))))

(quickcheck-pair "c_math_mul scalar" 80 (gen-pair (gen-int -20 20) (gen-int -20 20))
  (fn [a b]
    (def s (make-math-state a b))
    (def res (c_math_mul s "n" "a" "b" "out"))
    (and (table? res) (get res :ok)
         (= (socket-value-get (get res :ok) "n" "out") (* a b))
         (node-executed-get (get res :ok) "n"))))

(quickcheck-pair "c_math_div scalar" 60 (gen-pair (gen-float -10 10) (gen-float 0.5 10))
  (fn [a b]
    (when (not= b 0)
      (def s (make-math-state a b))
      (def res (c_math_div s "n" "a" "b" "out"))
      (and (table? res) (get res :ok)
           (let [out (socket-value-get (get res :ok) "n" "out")]
             (and (number? out) (< (math/abs (- out (/ a b))) 1e-6)))
           (node-executed-get (get res :ok) "n")))))

# VariableValue predicate and variable/get, variable/set (Phase 2)
(assert (= (variable-value-get (variable-value-set @{} "x" 42) "x") 42) "variable-value set then get")
(def s-var (graph-activate (socket-value-set (socket-value-set @{} "n" "name" "myVar") "n" "value" 100)))
(def s-var (socket-value-set s-var "n" "name" "myVar"))
(def s-var (socket-value-set s-var "n" "value" 100))
(def res-set (c_variable_set s-var "n" "name" "value"))
(assert (and (table? res-set) (get res-set :ok)) "c_variable_set ok")
(assert (= (variable-value-get (get res-set :ok) "myVar") 100) "variable set to 100")
(def s-get (variable-value-set (graph-activate @{}) "v" 7))
(def s-get (socket-value-set s-get "n" "name" "v"))
(def res-get (c_variable_get s-get "n" "name" "out"))
(assert (and (table? res-get) (get res-get :ok)) "c_variable_get ok")
(assert (= (socket-value-get (get res-get :ok) "n" "out") 7) "variable get writes to out socket")

# flow/branch: condition socket present -> node executed
(def s-branch (graph-activate (socket-value-set @{} "n" "condition" true)))
(def res-branch (c_flow_branch s-branch "n" "condition" "true" "false"))
(assert (and (table? res-branch) (get res-branch :ok) (node-executed-get (get res-branch :ok) "n")) "c_flow_branch ok")

(print "test_interactivity: property checks passed")
