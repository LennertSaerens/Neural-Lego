(import numpy)
(import tensorflow [keras])
(import keras [layers])

(defmacro "#↻" [code]
    (setv op (get code -1)) 
    (setv params (list (cut code -1)))
    `(~op ~@params))

; (print #↻(1 2 3 +))

(defn my-print [arg] (print arg))

(defmacro test []
    `(my-print ~5))

(test)