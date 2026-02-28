;; SPDX-License-Identifier: MIT
;; HDDL (Aria extensions) as data transfer: parse/emit planner state.
;; Phase 1: :aria-initial-state with :facts only.

(defmodule aria_hddl
  (export
   (state_key_to_fact_name 1)
   (fact_name_to_state_key 1)
   (emit_state 1)
   (parse_state 1)
   (round_trip_state 1)))

(defun state_key_to_fact_name (k)
  (case k
    ('graph_active "graph_active")
    ((tuple 'socket_value node socket) (when (is_list node) (is_list socket))
     (lists:flatten (list "sv:" node ":" socket)))
    ((tuple 'node_executed node) (when (is_list node))
     (lists:flatten (list "ne:" node)))
    ((tuple 'active_graph id) (when (is_list id))
     (lists:flatten (list "ag:" id)))
    (_ 'undefined)))

(defun fact_name_to_state_key (name)
  (let ((s (if (and (is_list name) (=:= (hd name) 58)) (tl name) name)))
    (cond
     ((=:= s "graph_active") 'graph_active)
     ((lists:prefix "sv:" s)
      (case (string:tokens s ":")
        ((list _ n sock) (tuple 'socket_value n sock))
        (_ 'undefined)))
     ((lists:prefix "ne:" s)
      (case (string:tokens s ":")
        ((list _ n) (tuple 'node_executed n))
        (_ 'undefined)))
     ((lists:prefix "ag:" s)
      (case (string:tokens s ":")
        ((list _ id) (tuple 'active_graph id))
        (_ 'undefined)))
     ('true 'undefined))))

(defun value_to_str (v)
  (cond
   ((is_list v) v)
   ((is_atom v) 'undefined)
   ('true 'undefined)))

(defun quote_fact_name (name)
  (case (string:str name ":")
    (0 name)
    (_ (lists:flatten (list "\"" name "\"")))))

(defun emit_state (state)
  (let ((facts
         (maps:fold
          (lambda (k v acc)
            (case (state_key_to_fact_name k)
              ('undefined acc)
              (name
               (case (value_to_str v)
                 ('undefined acc)
                 (val-str
                  (let ((name-str (quote_fact_name name)))
                    (lists:append acc (list (lists:flatten (list "(:fact " name-str " :value " val-str ")")))))))))
          '()
          state)))
    (lists:flatten (list "(:aria-initial-state :facts (\n  " (string:join facts "\n  ") "\n))"))))

(defun parse_state (hddl_str)
  (case (lfe_io:read_string (lists:flatten (list hddl_str " ")))
    ((tuple 'ok (cons top _))
     (case top
       ((list 'aria-initial-state 'facts facts) (parse_facts facts #m()))
       (_ #m())))
    (_ #m())))

(defun parse_facts (facts state)
  (lists:foldl
   (lambda (f st)
     (case f
       ((list 'fact name 'value val)
        (case (fact_name_to_state_key (ensure_list name))
          ('undefined st)
          (k (maps:put k val st))))
       (_ st)))
   state
   (if (is_list facts) facts (list facts))))

(defun ensure_list (x)
  (if (is_list x) x (atom_to_list x)))

(defun round_trip_state (state)
  (parse_state (emit_state state)))
