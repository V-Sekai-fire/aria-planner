# Property-style E2E: behavior graph (activate -> set sockets -> math_add) holds for scenarios.

(module/add-syspath (string (os/cwd) "/" "source"))
(use aria/planner)
(use aria/domains/interactivity)
(use aria/test_property)

(command-register "c_activate_graph" c_activate_graph)
(command-register "c_math_add" c_math_add)
(command-register "c_flow_sequence" c_flow_sequence)

# Property: for each scenario (graph-id node a b expected-sum), the pipeline yields expected socket and node executed
(def scenarios (array
  (tuple "graph1" "node1" 5.0 3.0 8.0)
  (tuple "g" "n" 0.0 0.0 0.0)
  (tuple "g2" "n2" 10.0 -2.0 8.0)))
(for-all "activate -> set sockets -> math_add -> result" scenarios
  (fn [sc]
    (def graph-id (sc 0))
    (def node (sc 1))
    (def a (sc 2))
    (def b (sc 3))
    (def expected (sc 4))
    (def state (state-new))
    (def res1 (command-dispatch state "c_activate_graph" graph-id))
    (if (not (get res1 :ok))
      false
      (do
        (def state (get res1 :ok))
        (def state (socket-value-set state node "a" a))
        (def state (socket-value-set state node "b" b))
        (def res2 (command-dispatch state "c_math_add" node "a" "b" "value"))
        (if (not (get res2 :ok))
          false
          (do
            (def state (get res2 :ok))
            (and (= (socket-value-get state node "value") expected)
                 (node-executed-get state node))))))))

(print "test_e2e: property checks passed")
