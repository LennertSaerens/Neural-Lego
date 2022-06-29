(import ReacInfv2 :as reac)
(import numpy)
(import tensorflow [keras])
(import keras [layers])

(setv testexp `(define-network my-network
    (input input-shape)
    (conv2d 32 [3 3])
    (maxpooling [2 2])
    (dense num-classes)))

(defn print-name [exp]
    (let [name (get exp 1)]
        (print name)))

(defn print-part [exp part]
    (let [part (get exp part)]
        (print part)))

(defn print-layers [exp]
    (let [layers (cut exp 2 100)]
        (print layers)))

(defmacro print-hy []
    `(print "hy"))

(defmacro using-hy []
    `(do
        (print "Hello from ")
        (print-hy)))

; (setv my-model
;     (network
;         (input input-shape)
;         (conv2d 32 [3 3])
;         (maxpooling [2 2])
;         (dense num-classes)))

(setv testexp2
    `(network (
        (input input-shape)
        (conv2d 32 [3 3])
        (maxpooling [2 2])
        (dense num-classes))))

; (print (get testexp2 1))

(defn print-opt [#* opt]
    (if opt
        (print (get opt 0))
        (print "no args provided")))

(defclass animal []
    (defn __init__ [self legs]
        (setv self.legs legs))

    (defn print [self]
        (print "i'm an animal")))

(defclass dog [animal]
    (defn __init__ [self legs kind]
        (super.__init__ legs)
        (setv self.kind kind))

    (defn  print [self]
        (print "I'm a dog")))

; (setv input1 (layers.Input [16,]))
; (setv x1 ((layers.Dense 8) input1))

; (setv input2 (layers.Input [32,]))
; (setv x2 ((layers.Dense 8) input2))

; (setv added (layers.add [x1 x2]))

; (setv out ((layers.Dense 4) added))

; (setv layers [1 2 [3 4] 4 [6 7 8]])
; (print (lfor x layers (if (isinstance x list) (get x 0) x)))

; (setv input1 (layers.Input [16,]))
; (setv a ((layers.Dense 8) input1))
; (setv b ((layers.Dense 8) input1))
; (setv c (layers.add [a b]))

; (setv a (layers.Dense 8))
; (setv b (layers.Dense 8))

; (setv aa ((layers.Dense 8) input1))
; (setv ba ((layers.Dense 8) input1))

; (setv dict {})

; (setv (get dict a) aa)
; (setv (get dict b) ba)

; (setv c (layers.add [(get dict a) (get dict b)]))

; (print (.ref input1))

; (defmacro m [#*code]
;     (if False `(+ #* ~code) `(- #* ~code)))

; (print (m 1 2 3))

(setv normal `(kind a1 a2 a3 a4))
(setv named  `(let-layer name (kind a1 a2 a3 a4)))
(setv input  `(let-layer name (with-input (kind a1 a2 a3 a4) other)))

(setv expressions [normal named input])

(defn named? [expr] (= `let-layer (get expr 0)))
(defn input? [expr] (and (named? expr) (= `with-input (get (get expr 2) 0))))

(defn expr-kind [expr]
    (cond 
        [(input? expr) "input"]
        [(named? expr) "named"]
        [True "normal"]))

(defn layer-kind [layer-exp type]
        (cond
            [(= type "normal") (get layer-exp 0)]
            [(= type "named")  (get (get layer-exp 2) 0)]
            [(= type "input")  (get (get (get layer-exp 2) 1) 0)]
            [True (raise (Exception "Unknown kind"))]))

; (for [e expressions]
;     (print (layer-kind e (expr-kind e))))