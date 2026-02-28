# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# HDDL (with Aria extensions) as data transfer: parse/emit planner state.
# Phase 1: :aria-initial-state with :facts only. No full HDDL planning.

# State key <-> fact name encoding for :facts
# :graph_active -> "graph_active"
# @{:socket_value node socket} -> "sv:node:socket"
# @{:node_executed node} -> "ne:node"
# @{:active_graph id} -> "ag:id"

(defn tostr [x]
  (cond (string? x) x (keyword? x) (if x "true" "false") true nil))

(defn state-key-to-fact-name [k]
  (def res (cond
    (= k :graph_active) "graph_active"
    (and (tuple? k) (= (length k) 3) (= (in k 0) :socket_value)
         (string? (in k 1)) (string? (in k 2)))
      (string "sv:" (in k 1) ":" (in k 2))
    (and (tuple? k) (= (length k) 2) (= (in k 0) :node_executed) (string? (in k 1)))
      (string "ne:" (in k 1))
    (and (tuple? k) (= (length k) 2) (= (in k 0) :active_graph) (string? (in k 1)))
      (string "ag:" (in k 1))
    true nil))
  (if (string? res) res nil))

(defn fact-name-to-state-key [name]
  (def raw (string name))
  (def s (if (string/has-prefix? raw ":") (string/slice raw 1) raw))
  (cond
    (= s "graph_active") :graph_active
    (string/has-prefix? s "sv:")
      (do
        (def parts (string/split ":" s))
        (if (>= (length parts) 3) (tuple :socket_value (get parts 1) (get parts 2)) nil))
    (string/has-prefix? s "ne:")
      (do (def parts (string/split ":" s)) (if (>= (length parts) 2) (tuple :node_executed (get parts 1)) nil))
    (string/has-prefix? s "ag:")
      (do (def parts (string/split ":" s)) (if (>= (length parts) 2) (tuple :active_graph (get parts 1)) nil))
    true nil))

# Phase 1: emit only string values; numbers/booleans are skipped (parse still accepts them)
(defn value-to-str [v]
  (cond
    (string? v) v
    (keyword? v) nil
    (not (or (string? v) (number? v) (keyword? v) (tuple? v) (table? v) (array? v))) nil
    true nil))

(defn quote-fact-name [name]
  (if (and (string? name) (string/find name ":")) (string "\"" name "\"") (string name)))

# Emit state to HDDL string (:aria-initial-state :facts (...))
(defn emit-state [state]
  (def facts @[])
  (each [k v] state
    (def name (state-key-to-fact-name k))
    (when (and name (string? name))
      (def val-str (value-to-str v))
      (def name-str (quote-fact-name name))
      (when (and (string? val-str) (string? name-str))
        (def safe-val (if (string? val-str) val-str "false"))
        (def fact-str (string "(:fact " name-str " :value " safe-val ")"))
        (when (string? fact-str) (array/push facts fact-str)))))
  (string "(:aria-initial-state :facts (\n  " (string/join facts "\n  ") "\n))"))

# Parse HDDL string (Janet s-expr) and return state table.
# Expects top-level (:aria-initial-state :facts ((:fact name :value val) ...))
(defn parse-state [hddl-str]
  (def p (parser/new))
  (parser/consume p hddl-str)
  (parser/eof p)
  (def parsed (parser/produce p))
  (var state @{})
  (def top (if (and (tuple? parsed) (= (length parsed) 1) (tuple? (in parsed 0)))
              (in parsed 0) parsed))
  (when (and (tuple? top) (>= (length top) 3)
             (= (in top 0) :aria-initial-state) (= (in top 1) :facts))
    (def facts (in top 2))
    (when (tuple? facts)
      (each f facts
        (when (and (tuple? f) (>= (length f) 4) (= (in f 0) :fact) (= (in f 2) :value))
          (def name (in f 1))
          (def val (in f 3))
          (def k (fact-name-to-state-key (string name)))
          (when k (set state (put state k val)))))))
  state)

# Round-trip: state -> emit -> parse -> state'. Returns state' (facts we support).
(defn round-trip-state [state]
  (parse-state (emit-state state)))
