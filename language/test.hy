;;;;;;;;;;;;;
;; TESTING ;;
;;;;;;;;;;;;;

(require language *)
(import language *
        numpy
        tensorflow [keras]
        keras [layers])

;;
;; Constants
;;

(setv num-classes 10)
(setv input-shape [28, 28, 1])
(setv batch-size 128)
(setv epochs 1)

;;
;; Preparing test data
;;

(setv [[x-train y-train] [x-test y-test]] (keras.datasets.mnist.load_data))

(setv x-train (/ (.astype x-train "float32") 255))
(setv x-test (/ (.astype x-test "float32") 255))

(setv x-train (numpy.expand_dims x-train -1))
(setv x-test (numpy.expand_dims x-test -1))

(setv y-train (keras.utils.to_categorical y-train num_classes))
(setv y-test (keras.utils.to_categorical y-test num_classes))

;;
;; Creating networks
;;

; (setv simple 
;     (network
;         (input [16,])
;         (dense 16)
;         (dense 8)))

; (setv my-network
;     (network
;         (input [28, 28, 1])
;         (conv2d 32 [3, 3])
;         (maxpool2d [2, 2])
;         (let-layer f1 (flat))
;         (let-layer d1 (dense 16))
;         (let-layer d2 (with-input (dense 16) f1))
;         (add d1 d2)
;         (dropout 0.5)
;         (dense num-classes)))

; (setv my-other-network
;     (network
;         (let-layer in (input [28, 28, 1]))
;         (let-layer x1 (dense 8))
;         (let-layer x2 (with-input (dense 8) in))
;         (add x1 x2)
;         (dense 4)))

; (print my-other-network)

; (setv empty-network (network))

; (keras.utils.plot_model my-network)
; (keras.utils.plot_model my-other-network)

;;
;; Creating models
;;

; (setv my-model (model my-network))
; (.print-network my-model)
; (setv my-other-model (model my-other-network))

; (setv my-twice-compiled-model (model my-other-model))

;;
;; Fitting models
;;

; (fit my-model x-train y-train batch-size epochs 0.1)

;;
;; Evaluating models
;;

; (setv score (.evaluate my-model.network x-test y-test 0))
; (print "Test loss:" (get score 0))
; (print "Test accuracy:" (get score 1))