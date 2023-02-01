#DRIVER DROWSINESS DETECTION PROJECT
from keras.models import Sequential
from keras.layers import Dense
from keras.layers import Conv2D
from keras.layers import MaxPooling2D

from keras.layers import Flatten, Dropout
from keras.utils.np_utils import to_categorical
from keras.models import load_model
from keras.preprocessing import image
from tensorflow.keras.callbacks import ModelCheckpoint,EarlyStopping, ReduceLROnPlateau

cnn_model=Sequential()

cnn_model.add(Conv2D(32,3,3,input_shape=(24,24,1),activation='relu'))

cnn_model.add(MaxPooling2D(pool_size=(1,1)))

cnn_model.add(Conv2D(32,3,3,activation='relu'))

cnn_model.add(MaxPooling2D(pool_size=(1,1)))

cnn_model.add(Conv2D(64,3,3, activation='relu'))

cnn_model.add(MaxPooling2D(pool_size=(1,1)))

cnn_model.add(Dropout(0.25))

cnn_model.add(Flatten())

cnn_model.add(Dense(128,activation="relu"))

cnn_model.add(Dropout(0.5))

cnn_model.add(Dense(4,activation="softmax"))
cnn_model.compile(optimizer="adam",loss="categorical_crossentropy",metrics=['accuracy'])

from keras.preprocessing.image import ImageDataGenerator

train_datagen = image.ImageDataGenerator(
rescale=1./255
)
test_datagen=image.ImageDataGenerator( rescale=1./255)

x_train = train_datagen.flow_from_directory(
'data/train',
target_size=(24, 24),
batch_size=32,
class_mode='categorical',
color_mode='grayscale',
shuffle=True
)
x_test = test_datagen.flow_from_directory(
'data/test',
target_size=(24, 24),
batch_size=32,
class_mode='categorical',
color_mode='grayscale',
shuffle=True
)

cnn_model.fit_generator(
x_train,
steps_per_epoch=77,
epochs=5,
validation_data=x_test,
validation_steps=12)

cnn_model.save("cnn.h5")

# -*- coding: utf-8 -*-
"""
Created on Thu Dec 16 15:56:33 2021

@author: racha
"""
import tensorflow as tf
from tensorflow.keras.applications import VGG16
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dropout,Input,Flatten,Dense,MaxPooling2D
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint,EarlyStopping, ReduceLROnPlateau
from datetime import datetime
import matplotlib.pyplot as plt

batchsize=32

train_datagen= ImageDataGenerator(rescale=1./255, rotation_range=0.2,shear_range=0.2,

zoom_range=0.2,width_shift_range=0.2,
height_shift_range=0.2, validation_split=0.2)

train_data= train_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\train',

target_size=(80,80),batch_size=batchsize,class_mode='categorical',subset='training' )

validation_data= train_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\train',target_size=(80,80),batch_size=batchsize,class_mode='categorical', subset='validation')

now = datetime.now()
current_time = now.strftime("%H:%M:%S")

test_datagen = ImageDataGenerator(rescale=1./255)

test_data = test_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\valid',
target_size=(80,80),batch_size=batchsize,class_mode='categorical')

bmodel = VGG16(include_top=False, weights='imagenet', input_tensor=Input(shape=(80,80,3)))
hmodel = bmodel.output
hmodel = Flatten()(hmodel)
hmodel = Dense(64, activation='relu')(hmodel)
hmodel = Dropout(0.5)(hmodel)
hmodel = Dense(4,activation= 'softmax')(hmodel)

model = Model(inputs=bmodel.input, outputs= hmodel)
for layer in bmodel.layers:
     layer.trainable = False

#model.summary()

checkpoint = ModelCheckpoint(r'C:\Users\racha\Downloads\data\data\models\model.h5',

monitor='val_loss',save_best_only=True,verbose=3)

earlystop = EarlyStopping(monitor = 'val_loss', patience=7, verbose= 3,
restore_best_weights=True)

learning_rate = ReduceLROnPlateau(monitor= 'val_loss', patience=3, verbose= 3, )

callbacks=[checkpoint,earlystop,learning_rate]

model.compile(optimizer='Adam', loss='categorical_crossentropy',metrics=['accuracy'])

print("Current Time =", current_time)
history = model.fit(train_data,steps_per_epoch=train_data.samples//batchsize,

validation_data=validation_data,
validation_steps=validation_data.samples//batchsize,
callbacks=callbacks,
epochs=15)

print("Current Time =", current_time)

acc_vr, loss_vr = model.evaluate_generator(validation_data)
print(acc_vr)

print(loss_vr)

acc_test, loss_test = model.evaluate_generator(test_data)
print(acc_test)
print(loss_test)

loss_train = history.history['loss']
loss_val = history.history['val_loss']
epochs = range(1,12)
plt.plot(epochs, loss_train, 'g', label='Training loss')
plt.plot(epochs, loss_val, 'b', label='validation loss')
plt.title('Training and Validation loss VGG16')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.legend()
plt.show()

import tensorflow as tf
from tensorflow.keras.applications import VGG16
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Dropout,Input,Flatten,Dense,MaxPooling2D
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.callbacks import ModelCheckpoint,EarlyStopping, ReduceLROnPlateau
from datetime import datetime
from keras.models import Sequential
from keras.layers import Dense

from keras.layers import LSTM
import matplotlib.pyplot as plt

batchsize=32

train_datagen= ImageDataGenerator(rescale=1./255, rotation_range=0.2,shear_range=0.2,
zoom_range=0.2,width_shift_range=0.2,
height_shift_range=0.2, validation_split=0.2)

train_data= train_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\train',

target_size=(80,80),batch_size=batchsize,class_mode='categorical',subset='training' )

validation_data= train_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\train',
target_size=(80,80),batch_size=batchsize,class_mode='categorical',
subset='validation')

now = datetime.now()
current_time = now.strftime("%H:%M:%S")

test_datagen = ImageDataGenerator(rescale=1./255)

test_data = test_datagen.flow_from_directory(r'C:\Users\racha\Downloads\data\data\valid',
target_size=(80,80),batch_size=batchsize,class_mode='categorical')

model = Sequential()
model.add(LSTM(100, input_shape=(80,80),return_sequences=True))
model.add(Dense(4))

model = Model(inputs=bmodel.input, outputs= hmodel)
for layer in bmodel.layers:
     layer.trainable = False

#model.summary()

checkpoint = ModelCheckpoint(r'C:\Users\racha\Downloads\data\data\models\modelh5',

monitor='val_loss',save_best_only=True,verbose=3)

earlystop = EarlyStopping(monitor = 'val_loss', patience=7, verbose= 3,
restore_best_weights=True)

learning_rate = ReduceLROnPlateau(monitor= 'val_loss', patience=3, verbose= 3, )

callbacks=[checkpoint,earlystop,learning_rate]

model.compile(optimizer='Adam', loss='categorical_crossentropy',metrics=['accuracy'])

print("Current Time =", current_time)
history = model.fit_generator(train_data,steps_per_epoch=train_data.samples//batchsize,

validation_data=validation_data,
validation_steps=validation_data.samples//batchsize,
callbacks=callbacks,

epochs=15)

print("Current Time =", current_time)

acc_vr, loss_vr = model.evaluate_generator(validation_data)
print(acc_vr)
print(loss_vr)

acc_test, loss_test = model.evaluate_generator(test_data)
print(acc_test)
print(loss_test)

loss_train = history.history['loss']
loss_val = history.history['val_loss']
epochs = range(1,9)
plt.plot(epochs, loss_train, 'g', label='Training loss')
plt.plot(epochs, loss_val, 'b', label='validation loss')
plt.title('Training and Validation loss LSTM')
plt.xlabel('Epochs')
plt.ylabel('Loss')
plt.legend()
plt.show()

#Code for Drowsiness Detection
import cv2

import os
from keras.models import load_model
import numpy as np
from pygame import mixer
import time

mixer.init()
sound = mixer.Sound('alarm.wav')

face = cv2.CascadeClassifier('haar cascade files\haarcascade_frontalface_alt.xml')
leye = cv2.CascadeClassifier('haar cascade files\haarcascade_lefteye_2splits.xml')
reye = cv2.CascadeClassifier('haar cascade files\haarcascade_righteye_2splits.xml')
lbl=['Close','Open']
model = load_model('models/cnn.h5')
path = os.getcwd()
cap = cv2.VideoCapture(0)
font = cv2.FONT_HERSHEY_COMPLEX_SMALL
count=0
score=0
thicc=2
rpred=[99]
lpred=[99]

while(True):
     ret, frame = cap.read()
     height,width = frame.shape[:2]

     gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

     faces = face.detectMultiScale(gray,minNeighbors=5,scaleFactor=1.1,minSize=(25,25))
     left_eye = leye.detectMultiScale(gray)
     right_eye = reye.detectMultiScale(gray)

     cv2.rectangle(frame, (0,height-50) , (200,height) , (0,0,0) , thickness=cv2.FILLED )

     for (x,y,w,h) in faces:
          cv2.rectangle(frame, (x,y) , (x+w,y+h) , (100,100,100) , 1 )

     for (x,y,w,h) in right_eye:
          r_eye=frame[y:y+h,x:x+w]
          count=count+1
          r_eye = cv2.cvtColor(r_eye,cv2.COLOR_BGR2GRAY)
          r_eye = cv2.resize(r_eye,(24,24))
          r_eye= r_eye/255
          r_eye= r_eye.reshape(24,24,-1)
          r_eye = np.expand_dims(r_eye,axis=0)
          rpred = model.predict_classes(r_eye)
          if(rpred[0]==1):
               lbl='Open'
          if(rpred[0]==0):
               lbl='Closed'
          break

     for (x,y,w,h) in left_eye:
          l_eye=frame[y:y+h,x:x+w]
          count=count+1
          l_eye = cv2.cvtColor(l_eye,cv2.COLOR_BGR2GRAY)
          l_eye = cv2.resize(l_eye,(24,24))
          l_eye= l_eye/255
          l_eye=l_eye.reshape(24,24,-1)
          l_eye = np.expand_dims(l_eye,axis=0)
          lpred = model.predict_classes(l_eye)
          if(lpred[0]==1):
               lbl='Open'
          if(lpred[0]==0):
               lbl='Closed'
          break

     if(rpred[0]==0 and lpred[0]==0):
          score=score+1
          cv2.putText(frame,"Closed",(10,height-20), font, 1,(255,255,255),1,cv2.LINE_AA)

     else:
          score=score-1
          cv2.putText(frame,"Open",(10,height-20), font, 1,(255,255,255),1,cv2.LINE_AA)

     if(score<0):
          score=0
          cv2.putText(frame,'Score:'+str(score),(100,height-20), font, 1,(255,255,255),1,cv2.LINE_AA)

     if(score>15):

          cv2.imwrite(os.path.join(path,'image.jpg'),frame)
          try:
               sound.play()

          except:
               pass
          if(thicc<16):
               thicc= thicc+2
          else:
               thicc=thicc-2
               if(thicc<2):
                    thicc=2
          cv2.rectangle(frame,(0,0),(width,height),(0,0,255),thicc)
          cv2.imshow('frame',frame)
          if cv2.waitKey(1) & 0xFF == ord('q'):
               break
cap.release()
cv2.destroyAllWindows()