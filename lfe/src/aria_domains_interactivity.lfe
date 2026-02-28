;; SPDX-License-Identifier: MIT
;; Interactivity domain: operation mapping, predicates (GraphActive, SocketValue, NodeExecuted), math helper.
;; Phase 1 subset only.

(defmodule aria_domains_interactivity
  (export
   (spec_to_command 1)
   (command_to_spec 1)
   (graph_active_p 1)
   (graph_activate 1)
   (graph_deactivate 1)
   (socket_value_key 2)
   (socket_value_get 3)
   (socket_value_set 4)
   (node_executed_key 1)
   (node_executed_get 2)
   (node_executed_set 3)
   (apply_binary_op 3)
   (check_graph_active 1)
   (get_socket_value 3)
   (c_activate_graph 2)
   (c_math_add 5)
   (c_flow_sequence 2)))

;; ---- Operation mapping ----
(defun spec_to_command (operation)
  (let ((parts (string:tokens (if (is_list operation) operation (binary_to_list operation)) "/")))
    (case (length parts)
      (2 (lists:flatten (list "c_" (lists:nth 1 parts) "_" (string:lowercase (lists:nth 2 parts)))))
      (1 (lists:flatten (list "c_" (string:lowercase (lists:nth 1 parts)))))
      (_ operation))))

(defun command_to_spec (command)
  (let ((s (if (is_list command) command (binary_to_list command))))
    (case (string:prefix s "c_")
      ('nomatch command)
      (inner
       (let ((parts (string:tokens inner "_")))
         (if (>= (length parts) 2)
             (lists:flatten (list (lists:nth 1 parts) "/" (lists:nth 2 parts)))
             (if (=:= (length parts) 1) (lists:nth 1 parts) command)))))))

;; ---- GraphActive ----
(defun graph_active_p (state)
  (maps:get 'graph_active state 'false))

(defun graph_activate (state)
  (maps:put 'graph_active 'true state))

(defun graph_deactivate (state)
  (maps:put 'graph_active 'false state))

;; ---- SocketValue key: #(socket_value node-id socket-id) ----
(defun socket_value_key (node_id socket_id)
  (tuple 'socket_value node_id socket_id))

(defun socket_value_get (state node_id socket_id)
  (maps:get (socket_value_key node_id socket_id) state 'undefined))

(defun socket_value_set (state node_id socket_id value)
  (maps:put (socket_value_key node_id socket_id) value state))

;; ---- NodeExecuted key: #(node_executed node-id) ----
(defun node_executed_key (node_id)
  (tuple 'node_executed node_id))

(defun node_executed_get (state node_id)
  (maps:get (node_executed_key node_id) state 'false))

(defun node_executed_set (state node_id executed)
  (maps:put (node_executed_key node_id) executed state))

;; ---- apply_binary_op: scalar or tuple/list component-wise ----
(defun apply_binary_op (a b op)
  (cond
   ((and (is_number a) (is_number b)) (funcall op a b))
   ((and (is_list a) (is_list b) (=:= (length a) (length b)))
    (lists:zipwith op a b))
   ((and (is_tuple a) (is_tuple b) (=:= (tuple_size a) (tuple_size b)))
    (let ((n (tuple_size a)))
      (list_to_tuple (lists:zipwith op (tuple_to_list a) (tuple_to_list b)))))
   ('true (funcall op a b))))

(defun check_graph_active (state)
  (case (graph_active_p state)
    ('true 'ok)
    (_ (tuple 'error "Graph must be active to execute operations"))))

(defun get_socket_value (state node_id socket_id)
  (case (socket_value_get state node_id socket_id)
    ('undefined (tuple 'error (list_to_binary (lists:flatten (io_lib:format "Socket ~s on node ~s has no value" (list socket_id node_id))))))
    (v (tuple 'ok v))))

;; ---- Commands ----
(defun c_activate_graph (state graph_id)
  (let ((s (graph_activate state)))
    (tuple 'ok (maps:put (tuple 'active_graph graph_id) 'true s))))

(defun c_math_add (state node_id a_socket b_socket value_socket)
  (case (check_graph_active state)
    ('ok
     (case (get_socket_value state node_id a_socket)
       ((tuple 'ok a)
        (case (get_socket_value state node_id b_socket)
          ((tuple 'ok b)
           (let ((result (apply_binary_op a b (lambda (x y) (+ x y)))))
             (tuple 'ok (node_executed_set (socket_value_set state node_id value_socket result) node_id 'true))))
          (err err)))
       (err err)))
    (err err)))

(defun c_flow_sequence (state node_id)
  (case (check_graph_active state)
    ('ok (tuple 'ok (node_executed_set state node_id 'true)))
    (err err)))
