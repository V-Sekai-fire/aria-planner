# SPDX-License-Identifier: MIT
# Copyright (c) 2025-present K. S. Ernest (iFire) Lee
# Run with: jpm test (from janet/) or janet test/main.janet

(module/add-syspath (string (os/cwd) "/" "source"))
(dofile "test/test_planner.janet")
(dofile "test/test_interactivity.janet")
(dofile "test/test_e2e.janet")
(dofile "test/test_hddl.janet")
(dofile "test/test_gltf.janet")
