(defn except-first [list]
    (+ (cut list 1 -1) [(get list -1)]))

(defn layer-kind [layer] (get layer 0))
(defn shape [input] (get input 1))
(defn conv2d-filters [conv2d] (get conv2d 1))
(defn conv2d-kernel [conv2d] (get conv2d 2))
(defn maxpool-size [maxpool] (get maxpool 1))
(defn dense-units [dense] (get dense 1))
(defn dropout-val [dropout] (get dropout 1))
(defn merge-layers [merge] (except-first merge))
(defn merge-kind [merge] (get merge 0))
(defn with-input? [layer] (= "with-input" (get layer 0)))