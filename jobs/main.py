from collections import namedtuple
from datetime import datetime
from flask import Flask, request
from google.cloud import storage,firestore
import firebase_admin
from firebase_admin import auth
import json
import os
import re
import random
import sys
import time
import cv2
import pickle
import tensorflow as tf
import numpy as np

# Retrieve Job-defined env vars
TASK_INDEX = os.getenv("CLOUD_RUN_TASK_INDEX", 0)
TASK_ATTEMPT = os.getenv("CLOUD_RUN_TASK_ATTEMPT", 0)
# Retrieve User-defined env vars
SLEEP_MS = os.getenv("SLEEP_MS", 0)
FAIL_RATE = os.getenv("FAIL_RATE", 0)

app = Flask(__name__)
db = firestore.Client()
firebase_admin.initialize_app()

storage_client = storage.Client()
bucket_name = 'antisomnus-bucket'
bucket = storage_client.get_bucket(bucket_name)

# Load the model
model_path = 'models/en_model_v0.h5'
model_blob = bucket.blob(model_path)
model_blob.download_to_filename('/tmp/en_model_v0.h5')
model = tf.keras.models.load_model('/tmp/en_model_v0.h5')



def add_user(user_id):
    """Gets the email, first name, and last name of a user.
    Args:
        userId: The ID of the user.
        Returns: A dictionary containing the user's email address, first name, and last name.
    """
    try:
        # Get the user's info from Firebase Authentication
        user_info = auth.get_user(user_id)
    except auth.UserNotFoundError:
        print("An error occurred while retrieving the user's info.")
        user_info = namedtuple('user_info', ['display_name', 'email'])
        user_info = user_info('John Doe', 'jdoe@gmail.com')

    # check if the userId is in the Firestore collection already
    user_ref = db.collection('users').document(user_id)
    user_doc = user_ref.get()
    if user_doc.exists:
        # Get the user's email, first name, and last name from the database
        user_info = user_doc.to_dict()
        return user_info
    else:
        user_info = {
            'FName': user_info.display_name.split(' ')[0],
            'LName': user_info.display_name.split(' ')[-1],
            'email': user_info.email,
            'id': user_id
        }
        # Add the user to the database
        user_ref.set(user_info)
        return user_info

def add_document(filename, drowsiness_events, drowsiness_summary, user_id):
    """Adds a document to the Firestore database."""
    pattern = r"(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})"
    matches = re.search(pattern, filename)
    if matches:
        year,month,day,hour,minute,second = matches.groups()
        timestamp = datetime(int(year),int(month),int(day),int(hour),int(minute),int(second))
        document_title = timestamp.strftime("%Y-%m-%d")

        doc_ref = db.collection('users').document(user_id).collection('data').document(document_title)
        doc_ref.collection('driver_sessions').add({
            'date': timestamp,
            'drowsiness_events': drowsiness_events,
            'drowsiness_summary': drowsiness_summary
        })
    else:
        return None
    
def video_to_frames(blob_name, drowsiness_events, drowsiness_summary, frame_dict,frame_number=0):
    """Extracts frames from a video and saves them to a local directory."""
    drowsy = 0
    not_drowsy = 0

    blob = bucket.blob(blob_name)
    filename = "/tmp/" + os.path.basename(blob_name)
    blob.download_to_filename(filename)

    cap = cv2.VideoCapture(filename)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        original_frame = frame.copy()

        # preprocessing to feed into your model
        frame = cv2.resize(frame, (224, 224), interpolation = cv2.INTER_AREA)
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame = frame / 255.0
        frame = np.expand_dims(frame, axis=0)  # for single prediction

        # predict
        prediction = model.predict(frame)
        label = prediction[0][0] < 0.5

        if label:
            drowsy+=1
            drowsiness_events.append(int(label))
            # drowsy_event = {
            #     'drowsy': True,
            #     'timestamp': firestore.SERVER_TIMESTAMP,
            #     'userID': user_id
            # }

            # # Add the drowsy event to the database
            # db.collection('users').add(drowsy_event)
        else:
            not_drowsy+=1

        drowsiness_summary["drowsy"] = drowsy
        drowsiness_summary["not_drowsy"] = not_drowsy
        frame_dict[frame_number] = (original_frame, label)
        frame_number += 1

    cap.release()

    # Remove the processed video file from the local file system
    os.remove(filename)

    return frame_number

def process_video(user_id, video_file):
    """Processes a video file and adds the drowsiness events to the database."""
    frame_data = {}
    frame_number = 0
    drowsiness_events = []
    drowsiness_summary = {"drowsy": 0, "not_drowsy": 0}
    frame_number = video_to_frames(video_file, drowsiness_events, drowsiness_summary, frame_data, frame_number)
    # Add the drowsiness events to the database
    add_document(video_file, drowsiness_events, drowsiness_summary, user_id)

    # Save and upload the pickle file
    with open(f"/tmp/training_data.pkl", 'wb') as output:
        pickle.dump(frame_data, output, pickle.HIGHEST_PROTOCOL)
    blob = bucket.blob(f'users/{user_id}/prediction_data/training_data.pkl')
    blob.upload_from_filename(f"/tmp/training_data.pkl")
    os.remove('/tmp/training_data.pkl')  # remove the local pickle file after uploading

    # Delete the processed video file from the bucket
    video_blob = bucket.blob(video_file)
    video_blob.delete()

@app.route('/', methods=['POST'])
def main():
    """Main entry point for the application. This function gets triggered
    when a text file signalling that a batch of video files (.avi files gathered 
    from the Pi from Mon-Fri) has been sent is uploaded to the Cloud Storage bucket.
    It reads the file, converts video to frames, runs the model on each frame 
    and stores the result in a dictionary.
    """
    data = request.get_json()
    print(f"Processing file: {data['file']}")
    file_path = data['file']
    
    if not file_path.startswith('users/'):
        print("File is not in a user directory, ignoring.")
        return ('', 204)

    user_id = file_path.split('/')[1]
    user_info = add_user(user_id)


    if file_path.endswith('signal.txt'):
        user_id = file_path.split('/')[1]
        # List all video files in the user's directory
        blobs = bucket.list_blobs(prefix=f'users/{user_id}/video_data/')
        video_files = [blob.name for blob in blobs if blob.name.endswith('.avi')]
        
        # Process each video file
        for video_file in video_files:
            process_video(user_id, video_file)
        
        # Delete the signal file
        #signal_blob = bucket.blob(file_path)
        #signal_blob.delete()

    return ('', 204)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
