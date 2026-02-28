# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee

(declare-project
  :name "aria-planner"
  :version "0.1.0"
  :description "Phase 1 prototype: minimal planner core and interactivity subset (Janet)"
  :authors ["K. S. Ernest (iFire) Lee"]
  :license "MIT")

(set source-path (or (dyn :source-path) "source"))

# Ensure source path is on the module path for scripts run from project root
(defn add-source-path []
  (when (not (string/find (dyn :path) source-path))
    (setdyn :path (tuple/splice (dyn :path) 0 0 source-path))))
