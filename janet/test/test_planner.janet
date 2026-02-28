# SPDX-License-Identifier: MIT
# QuickCheck-style property tests: planner core.

(module/add-syspath (string (os/cwd) "/" "source"))
(use aria/planner)
(use aria/test_property)

(seed-random 42)

# Property: state-new always returns a table
(check "state-new returns table" (fn [] (= (type (state-new)) :table)))

# Property: for any state s, command-dispatch(s, c_noop) returns {:ok s} (random states)
(quickcheck "c_noop preserves state" 80 (gen-table 8 -100 100)
  (fn [s]
    (def res (command-dispatch s "c_noop"))
    (and (table? res)
         (get res :ok)
         (= (get res :ok) s))))

# Property: dispatch returns table with :ok or :error
(quickcheck "dispatch returns result table" 80 (gen-table 5 0 10)
  (fn [s]
    (def res (command-dispatch s "c_noop"))
    (and (table? res) (or (get res :ok) (get res :error)))))

(print "test_planner: property checks passed")
