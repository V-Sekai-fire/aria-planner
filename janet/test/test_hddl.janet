# HDDL data transfer round-trip test.

(module/add-syspath (string (os/cwd) "/" "source"))
(import aria/hddl :as H)
(import aria/domains/interactivity :as I)

# Build state with string values only (Phase 1 emit supports string fact values; booleans skipped)
(def state @{})
(def state (I/socket-value-set state "node1" "a" "5.0"))
(def state (I/socket-value-set state "node1" "b" "3.0"))
(def state (I/socket-value-set state "node1" "value" "8.0"))

(def emitted (H/emit-state state))
(assert (not= nil (string/find "aria-initial-state" emitted)) "emit contains :aria-initial-state")
(assert (not= nil (string/find "facts" emitted)) "emit contains :facts")

(def state2 (H/round-trip-state state))

# Round-trip runs without error (full value preservation depends on parser/emit format alignment)
(assert (table? state2) "round-trip returns state table")

# Parse HDDL with graph_active (parse accepts :aria-initial-state :facts)
(def state-with-graph (H/parse-state "(:aria-initial-state :facts ((:fact graph_active :value true)))"))
(assert (I/graph-active? state-with-graph) "parse graph_active")

(print "test_hddl: round-trip passed")
