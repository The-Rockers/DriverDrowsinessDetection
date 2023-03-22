import os
import cv2
import numpy as np
from keras.preprocessing import image
import warnings
warnings.filterwarnings('ignore')
#from keras.preprocessing.image import load_img, img_to_array
from keras.models import load_model
import matplotlib.pyplot as plt
import numpy as np
#from skimage import color

# load pre-trained model
model = load_model('Keras HDH5 file\cnnCat2.h5')

face_haar_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

emotions = ('drowsy','not drowsy')
cap = cv2.VideoCapture(0)

while True:
    ret, test_img = cap.read() # captures frame and returns boolean value and captured image
    if not ret:
        continue
    color_img = cv2.cvtColor(test_img, cv2.COLOR_BGR2RGB)
    gray_img = cv2.cvtColor(test_img, cv2.COLOR_BGR2GRAY)
    faces_detected = face_haar_cascade.detectMultiScale(gray_img, 1.05, 10)
    for (x, y, w, h) in faces_detected:
        cv2.rectangle(test_img, (x, y), (x+w,y+h), (255,0,0), thickness=7)
        roi_color = color_img[y:y+w, x:x+h] # crop face area
        roi_color = cv2.resize(roi_color, (224,224)) # shape should be matched with training images
        #roi_color = cv2.resize(roi_color, (48,48)) # shape should be matched with training images
        if np.sum([roi_color]) != 0:
            # color roi
            roi = roi_color.astype('float')/255.0
            #roi = image.img_to_array(roi)
            roi = np.expand_dims(roi,axis=0)
            predictions = model.predict(roi)
            # find max indexed array
            max_index = np.argmax(predictions[0])
            predicted_emotion = emotions[max_index]
            cv2.putText(test_img, predicted_emotion, (int(x), int(y)), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2)
    resized_img = cv2.resize(test_img, (1000, 700))
    cv2.imshow("Drowsiness analysis ", resized_img)
    if cv2.waitKey(10) == ord('q'): # wait until 'q' is pressed
        break
cap.release()
cv2.destroyAllWindows