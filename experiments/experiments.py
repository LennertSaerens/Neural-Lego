import numpy as np
import tensorflow as tf
from tensorflow import keras

# Model / data parameters
num_classes = 10
input_shape = (28, 28, 1)

# the data, split between train and test sets
(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()

# Scale images to the [0, 1] range
x_train = x_train.astype("float32") / 255
x_test = x_test.astype("float32") / 255
# Make sure images have shape (28, 28, 1)
x_train = np.expand_dims(x_train, -1)
x_test = np.expand_dims(x_test, -1)
print("x_train shape:", x_train.shape)
print(x_train.shape[0], "train samples")
print(x_test.shape[0], "test samples")


# convert class vectors to binary class matrices
y_train = keras.utils.to_categorical(y_train, num_classes)
y_test = keras.utils.to_categorical(y_test, num_classes)


# model = keras.Sequential(
#     [
#         keras.layers.Dense(64, input_shape=input_shape),
#         keras.layers.Conv2D(32, kernel_size=(3, 3), activation="relu"),
#         keras.layers.MaxPooling2D(pool_size=(2, 2)),
#         keras.layers.Conv2D(64, kernel_size=(3, 3), activation="relu"),
#         keras.layers.MaxPooling2D(pool_size=(2, 2)),
#         keras.layers.Flatten(),
#         keras.layers.Dropout(0.5),
#         keras.layers.Dense(num_classes, activation="softmax"),
#     ]
# )