"""
    app.py
"""
import os
import sys
from pathlib import Path
import gradio as gr
import numpy as np
import mediapipe as mp
import tensorflow as tf
import cv2

# Add the path to the model directory
path = Path(os.getcwd())
sys.path.insert(0,str(path.parent.absolute())+"/model/data")
from mp_process import process_mp_img


model = tf.keras.models.load_model(str(path.parent.absolute())+"/model/training/saved_models/en_model_v0.h5")

def preprocess_frame(frame):
    """
    Preprocess the frame to be compatible with the model
    """
    frame = cv2.resize(frame, (224,224), interpolation = cv2.INTER_AREA)
    frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    frame = frame / 255.0
    return np.expand_dims(frame, axis=0)


def detect_drowsiness(frame):
    """
    returns features and/or processed image
    """
    annotated_img, eye_feature, mouth_feature, mp_drowsy = process_mp_img(frame)
    # Preprocess the frame
    preprocessed_frame = preprocess_frame(frame)
    # Make predictions using the model
    prediction = model.predict(preprocessed_frame)
    # Threshold the prediction to classify drowsiness
    model_drowsy = prediction[0][0] >= 0.5

    # Return the result
    return annotated_img, "Drowsy" if not model_drowsy else "Awake", "Drowsy" if mp_drowsy else "Awake",eye_feature, mouth_feature




# Define the input component as an Image component
input_image = gr.inputs.Image(shape=(480, 640), source="webcam", label="live feed")

# Define the output components as an Image and a Label component
output_image = gr.components.Image(label="Drowsiness Detection")
output_model = gr.components.Label(label="Drowsiness Status - en_model_v0.h5")
output_mp = gr.components.Label(label="Drowsiness Status - MediaPipe")
output_eye = gr.components.Textbox(label="Eye Aspect Ratio")
output_mouth = gr.components.Textbox(label="Mouth Aspect Ratio")


iface = gr.Interface(
    fn=detect_drowsiness,
    inputs=input_image,
    title="antisomnus - driver drowsiness detection",
    outputs=[output_image,output_model, output_mp, output_eye, output_mouth],
    capture_session=True,
)

# Launch the Gradio interface
iface.launch()
