# SPDX-License-Identifier: MIT
# Property-checking helpers: run predicates over many inputs, report first failure.

(defn- repr [x]
  (cond
    (string? x) (string "\"" x "\"")
    (number? x) (string x)
    (table? x) (string "@{...}")
    (tuple? x) (string "(tuple ...)")
    (array? x) (string "@[...]")
    true (string x)))

(defn for-all
  "Run predicate on each input. Fails with property name and first failing input."
  [name inputs pred]
  (each x inputs
    (def ok (pred x))
    (when (not ok)
      (error (string name " failed for input: " (repr x))))))

(defn for-all-pairs
  "Run binary predicate on each (a b) in input-pairs. Fails with name and first failing pair."
  [name input-pairs pred]
  (each pair input-pairs
    (def a (pair 0))
    (def b (pair 1))
    (def ok (pred a b))
    (when (not ok)
      (error (string name " failed for: " (repr a) " " (repr b))))))

(defn check
  "Run predicate once; fail with name if falsy."
  [name pred]
  (when (not (pred))
    (error (string name " failed"))))

(defn for-all-triples
  "Run ternary predicate on each (a b c) in input-triples."
  [name input-triples pred]
  (each triple input-triples
    (def ok (pred (triple 0) (triple 1) (triple 2)))
    (when (not ok)
      (error (string name " failed for: " (repr (triple 0)) " " (repr (triple 1)) " " (repr (triple 2)))))))

# Export for (def Prop (dofile "test/property.janet"))
(def _exports @{:check check :for-all for-all :for-all-pairs for-all-pairs :for-all-triples for-all-triples})
_exports
