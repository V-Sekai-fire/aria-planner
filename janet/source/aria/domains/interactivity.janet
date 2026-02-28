# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Interactivity domain: operation mapping, predicates (GraphActive, SocketValue, NodeExecuted), math helper.
# Phase 1 subset only.

# ---- Operation mapping (spec <-> command name) ----

(defn spec-to-command
  "Maps spec operation name to internal command name. e.g. math/add -> c_math_add."
  [operation]
  (def parts (string/split "/" operation))
  (if (= (length parts) 2)
    (string "c_" (get parts 0) "_" (string/ascii-lower (get parts 1)))
    (if (= (length parts) 1)
      (string "c_" (string/ascii-lower (get parts 0)))
      operation)))

(defn command-to-spec
  "Maps internal command name back to spec. e.g. c_math_add -> math/add."
  [command]
  (if (= (string/slice command 0 2) "c_")
    (do
      (def inner (string/slice command 2))
      (def parts (string/split "_" inner))
      (if (>= (length parts) 2)
        (string (get parts 0) "/" (get parts 1))
        (if (= (length parts) 1) (get parts 0) command)))
    command))

# ---- GraphActive predicate ----

(defn graph-active?
  "Check if graph is active in state."
  [state]
  (get state :graph_active false))

(defn graph-activate
  "Set graph active in state. Returns new state (table)."
  [state]
  (put (table/clone state) :graph_active true))

(defn graph-deactivate
  "Set graph inactive in state. Returns new state (table)."
  [state]
  (put (table/clone state) :graph_active false))

# ---- SocketValue predicate (key: tuple :socket_value node-id socket-id) ----

(defn socket-value-key [node-id socket-id]
  (tuple :socket_value node-id socket-id))

(defn socket-value-get
  "Get socket value from state."
  [state node-id socket-id]
  (get state (socket-value-key node-id socket-id)))

(defn socket-value-set
  "Set socket value in state. Returns new state (table)."
  [state node-id socket-id value]
  (put (table/clone state) (socket-value-key node-id socket-id) value))

# ---- NodeExecuted predicate (key: tuple :node_executed node-id) ----

(defn node-executed-key [node-id]
  (tuple :node_executed node-id))

(defn node-executed-get
  "Get node executed flag from state."
  [state node-id]
  (get state (node-executed-key node-id) false))

(defn node-executed-set
  "Set node executed in state. Returns new state (table)."
  [state node-id executed]
  (put (table/clone state) (node-executed-key node-id) executed))

# ---- Math helper: apply-binary-op (scalar and tuple, component-wise) ----

(defn apply-binary-op
  "Apply binary op component-wise. a,b numbers -> op(a,b). a,b tuples/arrays -> component-wise. Phase 1: scalar and float2/3/4 only."
  [a b op]
  (cond
    (and (number? a) (number? b)) (op a b)
    (and (= (type a) (type b)) (= (length a) (length b))
         (or (tuple? a) (array? a)))
      (do
        (def n (length a))
        (def out @[])
        (for i 0 n (array/push out (op (in a i) (in b i))))
        (tuple ;out))
    true (op a b)))

# ---- Helpers for commands ----

(defn check-graph-active
  "Return :ok if graph active, else @{:error msg}."
  [state]
  (if (graph-active? state) :ok @{:error "Graph must be active to execute operations"}))

(defn get-socket-value
  "Return @{:ok value} or @{:error msg}."
  [state node-id socket-id]
  (def v (socket-value-get state node-id socket-id))
  (if (not= v nil) @{:ok v} @{:error (string "Socket " socket-id " on node " node-id " has no value")}))

# ---- Commands (return @{:ok state} or @{:error msg}) ----

(defn c_activate_graph
  "Activate behavior graph. state, graph-id -> @{:ok state}."
  [state graph-id]
  (def s (graph-activate state))
  (def s2 (put (table/clone s) (tuple :active_graph graph-id) true))
  @{:ok s2})

(defn c_math_add
  "math/add: value = a + b. state node-id a-socket b-socket value-socket -> @{:ok state} | @{:error msg}."
  [state node-id a-socket b-socket value-socket]
  (def check (check-graph-active state))
  (if (= check :ok)
    (do
      (def a-res (get-socket-value state node-id a-socket))
      (def b-res (get-socket-value state node-id b-socket))
      (if (and (table? a-res) (get a-res :ok))
        (if (and (table? b-res) (get b-res :ok))
          (do
            (def a (get a-res :ok))
            (def b (get b-res :ok))
            (def result (apply-binary-op a b +))
            (def s (socket-value-set state node-id value-socket result))
            (def s2 (node-executed-set s node-id true))
            @{:ok s2})
          b-res)
        a-res))
    check))

(defn c_flow_sequence
  "flow/sequence: mark node executed. state node-id -> @{:ok state} | @{:error msg}."
  [state node-id]
  (def check (check-graph-active state))
  (if (= check :ok)
    @{:ok (node-executed-set state node-id true)}
    check))
