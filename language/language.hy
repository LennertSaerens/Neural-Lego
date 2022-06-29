(import helpers *
        reacinf :as reac
        numpy
        tensorflow [keras]
        keras [layers])

;;
;; Constants
;;

(setv named-layers {})
(setv merging #{"concat" "avg" "max" "min" "add" "sub" "mul" "dot"})

;;
;; Step 1: Parsing the network
;;

(defn parse-network [layers]
    (setv named-layers {})
    (setv curr-idx 0)
    (setv parsed [])
    (for [layer layers]
        (setv parsed (+ parsed [(process-layer layer curr-idx)]))
        (setv curr-idx (+ curr-idx 1)))
    (build-network parsed))

(defn process-layer [layer idx]
    ; If the layer has a name
    (if (isinstance layer tuple)
        (let [name (get layer 0)]
            (setv (get named-layers name) idx)
            (setv layer (get layer 1))))
    ; If the layer has a specified input
    (if (with-input? layer)
        (let [actual-layer (get layer 1)
              input (get layer 2)]
            (+ [(kind->layer actual-layer)] [input]))
        ; If the layer has no specified input
        (kind->layer layer)))

(defn kind->layer [layer]
    (let [kind (layer-kind layer)]
        (cond
            ; Core layers 
            [(= kind "input") (layers.Input (shape layer))]
            [(= kind "dense") (layers.Dense (dense-units layer))]
            ; Convnet layers
            [(= kind "conv2d") (layers.Conv2D (conv2d-filters layer) (conv2d-kernel layer))]
            [(= kind "maxpooling2d") (layers.MaxPooling2D (maxpool-size layer))]
            ; Operation layers
            [(= kind "dropout") (layers.Dropout (dropout-val layer))]
            [(= kind "flatten") (layers.Flatten)]
            ; Merging layers
            [(in kind merging) layer])))

;; 
;; Step 2: Building the network
;;

(defn build-network [layers]
    (global DAG-data)
    (setv DAG-data [])
    (setv input (get layers 0))
    (setv previous-layer input)
    (setv DAG-data (+ DAG-data [input.name]))
    (setv idx 1)
    (for [layer (except-first layers)]
        ; Merging layers or layers with a specified input are present as lists
        (if (isinstance layer list)
            ; Check wheter the layer is a merging layer
            (if (in (get layer 0) merging)
                (do (setv applied (create-merge layer layers))
                    (setv DAG-data (+ DAG-data [(create-int-merge-data applied layer)]))
                    (setv previous-layer applied)
                    (setv (get layers idx) applied))
                ; Otherwise it is a layer with a specified input
                (let [actual-layer (get layer 0)
                      input (name->layer (get layer 1) layers)]
                    (do (setv applied (actual-layer input))
                        (setv DAG-data (+ DAG-data [[applied.name (get named-layers (get layer 1))]]))
                        (setv previous-layer applied)
                        (setv (get layers idx) applied))))
            ; Unnamed layer, no specified input -> use previous layer as input
            (do (setv applied (layer previous-layer))
                (setv DAG-data (+ DAG-data [applied.name]))
                (setv previous-layer applied)
                (setv (get layers idx) applied)))
        (setv idx (+ idx 1)))
    (setv DAG-data (cut-names DAG-data))
    (print DAG-data)
    (keras.Model input previous-layer))

(defn name->layer [name layers]
    (setv idx (get named-layers name))
    (setv layer (get layers idx))
    ; if layer had specified input it is a list [layer input]
    (if (isinstance layer list)
        (get layer 0)
        layer))

(defn create-merge [merge layers]
    (setv to-merge [])
    (for [name (except-first merge)]
        (setv to-merge (+ to-merge [(name->layer name layers)])))
    (let [kind (merge-kind merge)]
        (cond
            [(= kind "concat") ((keras.layers.Concatenate) to-merge)]
            [(= kind "avg") ((keras.layers.Average) to-merge)]
            [(= kind "max") ((keras.layers.Maximum) to-merge)]
            [(= kind "min") ((keras.layers.Minimum) to-merge)]
            [(= kind "add") ((keras.layers.Add) to-merge)]
            [(= kind "sub") ((keras.layers.Subtract) to-merge)]
            [(= kind "mul") ((keras.layers.Multiply) to-merge)]
            [(= kind "dot") ((keras.layers.Dot) to-merge)])))

(defn create-int-merge-data [merge layer-data]
    (setv idxs [])
    (for [name (except-first layer-data)]
        (setv idxs (+ idxs [(get named-layers name)])))
    (+ [merge.name] idxs))

(defn transform-name [name]
    (get (.partition name "/") 0))

(defn cut-names [data]
    (setv idx 0)
    (while (< idx (len data))
        (let [current (get data idx)]
            (if (isinstance current list)
                (setv (get data idx) (+ [(transform-name (get current 0))] (except-first current)))
                (setv (get data idx) (transform-name current))))
        (setv idx (+ idx 1)))
    data)

;;
;; Step 3: Creating the DAG
;;

(defn create-source [layer network name] 
    (reac.r-node layer [] name network))

(defn idxs->nodes [idxs node-dict]
    (setv nodes [])
    (for [idx idxs]
        (let [found (get DAG-data idx)]
            (if (isinstance found list)
                (setv nodes (+ nodes [(get node-dict (get found 0))]))
                (setv nodes (+ nodes [(get node-dict found)])))))
    nodes)

(defn lookup-depcies [name node-dict prev]
    (setv idx 0)
    (while (< idx (len DAG-data))
        (setv cur (get DAG-data idx))
        (if (and (isinstance cur list) (= (get cur 0) name))
            (return (idxs->nodes (except-first cur) node-dict))
            (if (= cur name) (return [prev])))
        (setv idx (+ idx 1))))

(defn dagify [network]
    (setv name->node {})
    (setv l network.layers)
    (setv input (get l 0))
    (setv source (create-source input network input.name))
    (setv (get name->node input.name) source)
    (setv previous-node source)
    (for [layer (except-first l)]
        (let [depcies (lookup-depcies layer.name name->node previous-node)]
            ; (print "----------------------------------------")
            ; (for [depcy depcies] (print depcy.name))
            (setv new-node (reac.r-node layer depcies layer.name))
            (setv (get name->node layer.name) new-node)
            (setv previous-node new-node)))
    source)

;;
;; DAG manipulation
;;

(defn update-layers [model layers]
    (cond
        [(and layers model.depants)
         (do (setv model.callable (get layers 0))
             (update-layers (get model.depants 0) (except-first layers)))]
        [layers (setv model.callable (get layers 0))]))

;;
;; Layers Macro'soutput
;;

; Core layers
(defmacro input [shape]
    `["input" ~shape])
(defmacro dense [units]
    `["dense" ~units])

; Convnet layers
(defmacro conv2d [filters kernel-size]
    `["conv2d" ~filters ~kernel-size])
(defmacro conv3d []
    `["conv3d"])
(defmacro maxpool2d [pool-size]
    `["maxpooling2d" ~pool-size])

; Operation layers
(defmacro flat []
    `["flatten"])
(defmacro dropout [val]
    `["dropout" ~val])

; Merging layers
(defmacro concatenate [#*layers]
    `(+ ["concat"] ~layers))
(defmacro average [#*layers]
    `(+ ["avg"] ~layers))
(defmacro maximum [#*layers]
    `(+ ["max"] ~layers))
(defmacro minimum [#*layers]
    `(+ ["min"] ~layers))
(defmacro multiply [#*layers]
    `(+ ["mul"] ~layers))
(defmacro dot [#*layers]
    `(+ ["dot"] ~layers))
(defmacro add [#*layers]
    `(+ ["add"] ~layers))
(defmacro subtract [#*layers]
    `(+ ["sub"] ~layers))  

;;
;; Network creation
;;

(eval-when-compile
    (defn named? [expr] (= `let-layer (get expr 0)))
    (defn with-input? [expr] (and (named? expr) (= `with-input (get (get expr 2) 0))))
    (defn input? [expr] (= `input (layer-kind expr (expr-kind expr))))

    (setv incompatibilities #{"conv1dconv2d" "conv2dconv1d" "conv2dconv3d" "conv3dconv2d"})

    (setv name->kind {})

    (defn expr-kind [expr]
        (cond 
            [(with-input? expr) "input"]
            [(named? expr) "named"]
            [True "normal"]))

    (defn layer-kind [layer-exp type]
            (cond
                [(= type "normal") (get layer-exp 0)]
                [(= type "named")  (get (get layer-exp 2) 0)]
                [(= type "input")  (get (get (get layer-exp 2) 1) 0)]
                [True (raise (Exception "Unknown kind"))]))

    (defn check-incompatibility [le1 le2]
        (let [k1 (layer-kind le1 (expr-kind le1))
              k2 (layer-kind le2 (expr-kind le2))]
            (if (in (+ k1 k2) incompatibilities)
                (raise (Exception f"Layers {k1} and {k2} are incompatible")))))

    (defn add-name-kind [named-exp]
        (let [name (get named-exp 1)
              kind (layer-kind named-exp "named")]
            (setv (get name->kind name) kind)))

    (defn check-w-input-incompatibility [w-input-exp]
        (let [own-kind (layer-kind w-input-exp "input")
              inp-kind (get name->kind (get (get w-input-exp 2) 2))]
            (if (in (+ own-kind inp-kind) incompatibilities)
                (raise (Exception f"Layer {own-kind} cannot use a {inp-kind} layer as a compatible input.")))))

    (defn check-incompatibilities [layer-exps]
        (setv idx 0)
        (while (< idx (- (len layer-exps) 1))
            ; Get current and next layer
            (setv cur-exp (get layer-exps idx))
            (setv nxt-exp (get layer-exps (+ idx 1)))
            (let [ek (expr-kind cur-exp)]
                (cond
                    ; Layer has some layer specified as its input
                    [(= ek "input") (check-w-input-incompatibility cur-exp)]
                    ; Layer has a name --> may later be used as input to other layer --> save name-kind kv-pair
                    [(= ek "named") (do (add-name-kind cur-exp) (check-incompatibility cur-exp nxt-exp))]
                    [True (check-incompatibility cur-exp nxt-exp)]))
            (setv idx (+ idx 1))))

    (defn check-input [layer-exps]
        (setv fst (get layer-exps 0))
        (if (not (input? fst))
            (raise (Exception "First layer must be an input layer."))))

    (defn check-ammount [layer-exps]
        (if (< (len code) 2)
            (raise (Exception "Cannot create a network with less than 2 layers.")))))

(defmacro network [#*code]
    (check-ammount code)
    (check-input code)
    (check-incompatibilities code)
    `(parse-network ~code))

(defmacro model [network [optimizer "adam"] [loss "categorical_crossentropy"] [metrics ["accuracy"]]]
    `(if (isinstance ~network reac.r-node)
         (raise (Exception "A model cannot be compiled more than once."))
         (do (.compile ~network ~optimizer ~loss ~metrics)
             (dagify ~network))))

(defmacro fit [model x y batch-size epochs validation-split]
    (if (not (= shape input-dimension))
        (raise (Exception "Networks input shape and data shape need to be the same.")))
    `(if (not (isinstance ~model reac.r-node))
         (raise (Exception "Fit can only be called on a model."))
         (do (setv keras-network (. ~model network))
             (.fit keras-network ~x ~y ~batch-size ~epochs ~validation-split))))
            ;  (setv layers (. keras-network layers))
            ;  (update-layers ~model layers))))

(defmacro let-layer [layer-name layer]
    (setv str-name (str layer-name))
    `(do (setv ~layer-name ~str-name)
         (, ~str-name ~layer)))

(defmacro with-input [layer input-layer]
    `["with-input" ~layer ~input-layer])