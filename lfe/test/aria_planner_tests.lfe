;; SPDX-License-Identifier: MIT
;; Planner core tests.

(defmodule aria_planner_tests
  (export all)
  (import
   (from aria_planner
     (state_new 0)
     (command_register 2)
     (command_dispatch 2))
   (from aria_domains_interactivity
     (c_activate_graph 2)
     (c_math_add 5)
     (c_flow_sequence 2)
     (socket_value_set 4)
     (socket_value_get 3)
     (node_executed_get 2)
     (graph_active_p 1))))

(defun state_new_returns_map_test (_)
  (let ((s (state_new)))
    (tuple 'ok (is_map s))))

(defun c_noop_preserves_state_test (_)
  (let ((s (state_new))
        (res (command_dispatch s "c_noop" ())))
    (case res
      ((tuple 'ok state) (tuple 'ok (andalso (is_map state) (=:= state s))))
      (_ (tuple 'fail res)))))

(defun dispatch_returns_ok_or_error_test (_)
  (let ((s (state_new))
        (res (command_dispatch s "c_noop" ())))
    (tuple 'ok (orelse (match res ((tuple 'ok _) 'true) (_ 'false))
                      (match res ((tuple 'error _) 'true) (_ 'false))))))

(defun e2e_activate_math_add_test (_)
  (aria_planner:command_register "c_activate_graph" (tuple 'aria_domains_interactivity 'c_activate_graph 2))
  (aria_planner:command_register "c_math_add" (tuple 'aria_domains_interactivity 'c_math_add 5))
  (aria_planner:command_register "c_flow_sequence" (tuple 'aria_domains_interactivity 'c_flow_sequence 2))
  (let ((state (state_new)))
    (case (command_dispatch state "c_activate_graph" (list "graph1"))
      ((tuple 'ok s1)
       (let ((s2 (aria_domains_interactivity:socket_value_set
                  (aria_domains_interactivity:socket_value_set s1 "node1" "a" 5.0) "node1" "b" 3.0)))
         (case (command_dispatch s2 "c_math_add" (list "node1" "a" "b" "value"))
           ((tuple 'ok st)
            (tuple 'ok (andalso (=:= (socket_value_get st "node1" "value") 8.0)
                                (node_executed_get st "node1"))))
           (other (tuple 'fail other)))))
      (other (tuple 'fail other)))))
