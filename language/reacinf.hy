(import queue [PriorityQueue])

;;
;; Constants
;;

(setv pq (PriorityQueue))
(setv default-val 0)

;;
;; Helper functions
;;

(defn process-pq! []
    (while (not (.empty pq))
        ; Gets node from (priority, node)-pair
        (setv to-be-updated (get (.get pq) 1))
        ; Node and all nodes that depend on it should be updated
        (.update-value! to-be-updated)
        (.update-dependants to-be-updated)
        (process-pq!)))

;;
;; Reactive node class
;;

(defclass r-node []
    (defn __init__ [self callable depcies name #* network]
        (setv self.depcies depcies)
        (setv self.callable callable)
        (setv self.depants [])
        (if network 
            (setv self.network (get network 0))
            (setv self.network False))
        (setv self.name name)
        (setv self.val default-val)
        (setv self.h (.set-correct-height! self))
        (for [dependency depcies]
            (dependency.add-dependant!  self)))

    (defn __lt__ [self other]
        (<= (len self.depcies) (len other.depcies)))

    (defn add-dependant! [self dependant]
        (setv self.depants (+ self.depants [dependant])))
        
    ; Calculates max height of dependencies and adds one
    (defn set-correct-height! [self]
        (setv cur-max 0)
        (for [dependency self.depcies]
            (setv cur-h dependency.h)
            (when (> cur-h cur-max)
                (setv cur-max cur-h)))
        (+ 1 cur-max))

    (defn update-value! [self]
        (setv args (self.get-args))
        (setv self.val ((fn [input] (self.callable.call #* input)) args)))

    (defn set-value! [self val]
        (setv self.val val)
        (self.update-dependants))

    (defn get-args [self]
        (setv args [])
        (for [dependency self.depcies]
            (.append args dependency.val))
        args)

    (defn update-dependants [self]
        (for [dependant self.depants]
            (.put pq (, dependant.h dependant)))
        (process-pq!))

    (defn print-network [self]
        (self.print)
        (if self.depants
            (for [dependant self.depants] (.print-network dependant))
            (print "DONE PRINTING NETWORK")))

    (defn print [self]
        (print "----------------------------------")
        (print (+ "name    " self.name))
        (print (+ "val:    " (str self.val)))
        (print (+ "depants " (str self.depants)))
        (print (+ "depcies " (str self.depcies)))
        (print (+ "height  " (str self.h)))))

;;
;; Callable class 
;;

(defclass callable []
    (defn __init__ [self op]
        (setv self.call op)))

;;
;; Testing
;;

; (setv defaultop (fn [x] x))
; (setv testop1 (fn [x] (* x x)))
; (setv testop2 (fn [x] (* x 3)))
; (setv testop3 (fn [x y] (+ x y)))

; (setv testcall0 (callable defaultop))
; (setv testcall1 (callable testop1))
; (setv testcall2 (callable testop2))
; (setv testcall3 (callable testop3))

; (setv testnode0 (r-node testcall0 [] "0"))
; (setv testnode1 (r-node testcall1 [testnode0] "1"))
; (setv testnode2 (r-node testcall2 [testnode0] "2"))
; (setv testnode3 (r-node testcall3 [testnode1 testnode2] "3"))

; (.set-value! testnode0 2)

; (.print-network testnode0)

; (print (isinstance testnode0 r-node))