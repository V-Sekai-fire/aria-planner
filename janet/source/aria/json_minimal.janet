# SPDX-License-Identifier: MIT
# Minimal JSON decode/encode for glTF and other data transfer. No external deps.

(def digit-map @{"0" 0 "1" 1 "2" 2 "3" 3 "4" 4 "5" 5 "6" 6 "7" 7 "8" 8 "9" 9})

(defn- parse-num [s]
  (var i 0)
  (def len (length s))
  (when (= len 0) (return nil))
  (def neg (and (< i len) (= (string/slice s i (inc i)) "-")))
  (when neg (set i (inc i)))
  (var n 0)
  (var frac 0)
  (var frac-div 1)
  (while (and (< i len) (get digit-map (string/slice s i (inc i))))
    (def d (get digit-map (string/slice s i (inc i))))
    (set n (+ (* n 10) d))
    (set i (inc i)))
  (when (and (< i len) (= (string/slice s i (inc i)) "."))
    (set i (inc i))
    (while (and (< i len) (get digit-map (string/slice s i (inc i))))
      (def d (get digit-map (string/slice s i (inc i))))
      (set frac (+ (* frac 10) d))
      (set frac-div (* frac-div 10))
      (set i (inc i))))
  (def out (+ n (/ frac frac-div)))
  (if neg (- 0 out) out))

(defn- skip-ws [s i]
  (var i i)
  (while (and (< i (length s)) (string/find " \t\n\r" (string (string/slice s i (inc i)))))
    (set i (inc i)))
  i)

(defn- decode-string [s i]
  (when (not= (string/slice s i (inc i)) "\"") (return nil))
  (var i (inc i))
  (var buf @[])
  (while (< i (length s))
    (def c (string/slice s i (inc i)))
    (cond
      (= c "\"") (break)
      (= c "\\")
        (do
          (set i (inc i))
          (when (>= i (length s)) (return nil))
          (def e (string/slice s i (inc i)))
          (def esc (get @{"n" "\n" "t" "\t" "r" "\r" "\\" "\\" "\"" "\"" "/" "/"} e))
          (array/push buf (if esc esc e))
          (set i (inc i)))
      true (do (array/push buf c) (set i (inc i)))))
  (when (>= i (length s)) (return nil))
  (tuple (string ;buf) (inc i)))

(defn- decode-number [s i]
  (var i i)
  (var start i)
  (when (string/find "-" (string (string/slice s i (inc i))))
    (set i (inc i)))
  (while (and (< i (length s)) (string/find "0123456789" (string (string/slice s i (inc i)))))
    (set i (inc i)))
  (when (and (< i (length s)) (= (string/slice s i (inc i)) "."))
    (set i (inc i))
    (while (and (< i (length s)) (string/find "0123456789" (string (string/slice s i (inc i)))))
      (set i (inc i))))
  (when (and (< i (length s)) (string/find "eE" (string (string/slice s i (inc i)))))
    (set i (inc i))
    (when (string/find "-+" (string (string/slice s i (inc i)))) (set i (inc i)))
    (while (and (< i (length s)) (string/find "0123456789" (string (string/slice s i (inc i)))))
      (set i (inc i))))
  (def slice (string/slice s start i))
  (when (= (length slice) 0) (return nil))
  (def n (parse-num slice))
  (if (number? n) (tuple n i) nil))

(var decode-value nil)

(defn- decode-array [s pos]
  (var p (skip-ws s (inc pos)))
  (var arr @[])
  (var out nil)
  (when (and (< p (length s)) (= (string/slice s p (inc p)) "]"))
    (set out (tuple arr (inc p))))
  (when (not out)
    (while true
      (def res (decode-value s p))
      (when (not res) (break))
      (def v (in res 0)) (set p (in res 1))
      (array/push arr v)
      (set p (skip-ws s p))
      (when (>= p (length s)) (break))
      (def c2 (string/slice s p (inc p)))
      (when (= c2 "]") (set out (tuple arr (inc p))) (break))
      (when (not= c2 ",") (break))
      (set p (inc p)))) out)

(defn- decode-object [s pos]
  (var p (skip-ws s (inc pos)))
  (var obj @{})
  (var out nil)
  (when (and (< p (length s)) (= (string/slice s p (inc p)) "}"))
    (set out (tuple obj (inc p))))
  (when (not out)
    (while true
      (def res (decode-value s p))
      (when (not res) (break))
      (def k (in res 0)) (set p (in res 1))
      (when (not (string? k)) (break))
      (set p (skip-ws s p))
      (when (or (>= p (length s)) (not= (string/slice s p (inc p)) ":")) (break))
      (set p (inc p))
      (def res2 (decode-value s p))
      (when (not res2) (break))
      (put obj k (in res2 0))
      (set p (in res2 1))
      (set p (skip-ws s p))
      (when (>= p (length s)) (break))
      (def c2 (string/slice s p (inc p)))
      (when (= c2 "}") (set out (tuple obj (inc p))) (break))
      (when (not= c2 ",") (break))
      (set p (inc p))))
  out)

(set decode-value (fn [s i]
  (var pos (skip-ws s i))
  (when (>= pos (length s)) (return nil))
  (def c (string/slice s pos (inc pos)))
  (cond
    (= c "\"") (decode-string s pos)
    (string/find "0123456789-" c) (decode-number s pos)
    (and (>= (length s) (+ pos 4)) (= (string/slice s pos (+ pos 4)) "true")) (tuple true (+ pos 4))
    (and (>= (length s) (+ pos 5)) (= (string/slice s pos (+ pos 5)) "false")) (tuple false (+ pos 5))
    (and (>= (length s) (+ pos 4)) (= (string/slice s pos (+ pos 4)) "null")) (tuple nil (+ pos 4))
    (= c "[") (decode-array s pos)
    (= c "{") (decode-object s pos)
    true nil)))

(defn decode [json-str]
  (def res (decode-value json-str 0))
  (if (not res)
    nil
    (do
      (def pos (skip-ws json-str (in res 1)))
      (if (not= pos (length json-str))
        nil
        (in res 0)))))

(defn- escape-str [v]
  (if (or (not (string? v)) (= (length v) 0))
    "\"\""
    (do
      (def s (string/replace-all v "\\" "\\\\"))
      (def s (string/replace-all s "\"" "\\\""))
      (string "\"" s "\""))))

(defn encode [v]
  (cond
    (= v nil) "null"
    (= v true) "true"
    (= v false) "false"
    (number? v) (string v)
    (string? v) (escape-str v)
    (tuple? v)
      (string "[" (string/join (map encode (tuple/slice v 0 (length v))) ",") "]")
    (array? v)
      (string "[" (string/join (map encode v) ",") "]")
    (table? v)
      (do
        (var parts @[])
        (each [k val] v
          (array/push parts (string (encode (string k)) ":" (encode val))))
        (string "{" (string/join parts ",") "}"))
    true "null"))
