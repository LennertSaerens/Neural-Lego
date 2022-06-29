(import numpy)
(import tensorflow [keras])
(import keras [layers])

(setv num-classes 10)
(setv input-shape [28, 28, 1])

;;
;; Preparing the data
;;

(setv [[x-train y-train] [x-test y-test]] (keras.datasets.mnist.load_data))

(setv x-train (/ (.astype x-train "float32") 255))
(setv x-test (/ (.astype x-test "float32") 255))

(setv x-train (numpy.expand_dims x-train -1))
(setv x-test (numpy.expand_dims x-test -1))

(print "x_train shape:" x_train.shape)
(print (get x-train.shape 0) "train samples")
(print (get x-test.shape 0) "train samples")

(setv y-train (keras.utils.to_categorical y-train num_classes))
(setv y-test (keras.utils.to_categorical y-test num_classes))

;;
;; Creating Model
;;

(setv model (keras.Sequential 
    [(keras.Input input-shape)
     (layers.Conv2D 32 [3, 3])
     (layers.MaxPooling2D [2, 2])
     (layers.Conv2D 64 [3, 3])
     (layers.MaxPooling2D [2, 2])
     (layers.Flatten)
     (layers.Dropout 0.5)
     (layers.Dense num-classes "softmax")]))

(.summary model)

;;
;; Training Model
;;

(setv batch-size 128)
(setv epochs 5)

(.compile model "adam" "categorical_crossentropy" ["accuracy"])
(.fit model x-train y-train batch-size epochs 0.1)

;;
;; Evaluate model
;;

(setv score (.evaluate model x-test y-test 0))
(print "Test loss:" (get score 0))
(print "Test accuracy:" (get score 1))
