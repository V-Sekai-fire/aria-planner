# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Minimal planner core: state representation and command dispatch.
# No HTN/lazy refinement in Phase 1.

(defn state-new
  "Create a new empty planner state (table)."
  []
  @{})

(def command-registry @{})

(defn command-register
  "Register a command name to a handler function (state, ...args) -> @{:ok state} | @{:error msg}."
  [name handler]
  (put command-registry (string name) handler))

(defn command-dispatch
  "Dispatch a command by name. Returns @{:ok new-state} or @{:error \"...\"}."
  [state command-name & args]
  (let [handler (get command-registry (string command-name))]
    (if handler
      (apply handler (tuple state ;args))
      @{:error (string "Unknown command: " command-name)})))

(defn c_noop
  "Trivial no-op command for smoke test."
  [state]
  @{:ok state})

(command-register "c_noop" c_noop)
