# SPDX-License-Identifier: MIT
# QuickCheck-style property testing: generators + for-all + quickcheck.
# See https://en.wikipedia.org/wiki/QuickCheck

(def default-num-tests 100)

(defn seed-random
  "Seed RNG for reproducible QuickCheck runs (e.g. seed-random 42)."
  [x]
  (math/seedrandom x))

(defn- repr [x]
  (cond
    (string? x) (string "\"" x "\"")
    (number? x) (string x)
    (table? x) (string "@{...}")
    (tuple? x) (string "(tuple ...)")
    (array? x) (string "@[...]")
    true (string x)))

# ---- Generators (no-arg functions that return a random value) ----
(defn gen-int
  "Generator: random integer in [lo, hi] (inclusive)."
  [lo hi]
  (fn []
    (def r (math/random))
    (math/floor (+ lo (* r (- (+ hi 1) lo))))))

(defn gen-float
  "Generator: random float in [lo, hi)."
  [lo hi]
  (fn []
    (+ lo (* (math/random) (- hi lo)))))

(defn gen-one-of
  "Generator: random element of choices (array or tuple)."
  [choices]
  (fn []
    (in choices (math/floor (* (math/random) (length choices))))))

(defn gen-bool []
  (fn [] (< (math/random) 0.5)))

(defn gen-table
  "Generator: table with 0..max-entries random key-value pairs (int keys, int values in range)."
  [max-entries val-lo val-hi]
  (def gen-k (gen-int 0 999))
  (def gen-v (gen-int val-lo val-hi))
  (fn []
    (def n (math/floor (* (math/random) (+ max-entries 1))))
    (var t @{})
    (for i 0 n
      (put t (gen-k) (gen-v)))
    t))

(defn gen-pair
  "Generator: (tuple (gen-a) (gen-b))."
  [gen-a gen-b]
  (fn []
    (tuple (gen-a) (gen-b))))

# ---- QuickCheck: run property N times with generated input ----
(defn quickcheck
  "Run property N times with (generator). Fail on first counterexample; report input."
  [name num-tests generator pred]
  (for i 0 num-tests
    (def input (generator))
    (def ok (pred input))
    (when (not ok)
      (error (string name " failed after " i " tests; counterexample: " (repr input))))))

(defn quickcheck-pair
  "Run binary property N times. Generator returns (tuple a b)."
  [name num-tests generator pred]
  (for i 0 num-tests
    (def pair (generator))
    (def a (pair 0))
    (def b (pair 1))
    (def ok (pred a b))
    (when (not ok)
      (error (string name " failed after " i " tests; counterexample: " (repr a) " " (repr b))))))

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
