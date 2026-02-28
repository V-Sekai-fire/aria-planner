;; SPDX-License-Identifier: MIT
;; Minimal planner core: state (map) and command dispatch.
;; No HTN/lazy refinement in Phase 1.

(defmodule aria_planner
  (export
   (state_new 0)
   (command_register 2)
   (command_dispatch 2)
   (c_noop 1)))

(defun state_new ()
  "Create a new empty planner state (map)."
  #m())

(defun init_registry ()
  (case (ets:whereis 'aria_planner_commands)
    ('undefined
     (let ((tid (ets:new 'aria_planner_commands '(public named_table))))
       (ets:insert tid #("c_noop" #(aria_planner c_noop 1)))
       tid))
    (tid tid)))

(defun ensure_registry ()
  (case (ets:whereis 'aria_planner_commands)
    ('undefined (init_registry))
    (_ 'ok)))

(defun command_register (name handler)
  "Register command name (string) to handler (tuple mod fun arity)."
  (ensure_registry)
  (ets:insert 'aria_planner_commands
              (tuple (if (is_list name) name (binary_to_list name)) handler))
  'ok)

(defun command_dispatch (state command_name args)
  "Dispatch command by name. args is a list. Returns #(ok new_state) or #(error msg)."
  (ensure_registry)
  (let ((key (if (is_list command_name) command_name (binary_to_list command_name))))
    (case (ets:lookup 'aria_planner_commands key)
      ((list (tuple _ (tuple mod fun arity)))
       (apply mod fun (cons state args)))
      (_
       (tuple 'error (list_to_binary (lists:flatten (io_lib:format "Unknown command: ~s" (list command_name)))))))))

(defun c_noop (state)
  "Trivial no-op command for smoke test."
  (tuple 'ok state))
