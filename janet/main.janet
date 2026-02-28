# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
#
# Entry point for Phase 1 prototype. Run from janet/ with: janet main.janet

(module/add-syspath (string (os/cwd) "/" "source"))
(import aria/planner :as P)
(import aria/domains/interactivity :as I)
(P/command-register "c_activate_graph" I/c_activate_graph)
(P/command-register "c_math_add" I/c_math_add)
(P/command-register "c_flow_sequence" I/c_flow_sequence)

(print "aria-planner (Janet) Phase 1 — planner loaded.")
(print "State:" (P/state-new))
(print "Run tests with: janet test/main.janet")
