from flask import Flask, request
from google.cloud import storage, firestore
import json
import os
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

storage_client = storage.Client()
bucket_name = 'antisomnus-bucket'
bucket = storage_client.get_bucket(bucket_name)

# Load the model
model_path = 'models/en_model_v0.h5'
model_blob = bucket.blob(model_path)
model_blob.download_to_filename('/tmp/en_model_v0.h5')
model = tf.keras.models.load_model('/tmp/en_model_v0.h5')

def process_video(bucket_name, user_id, video_file):
    frame_data = {}
    frame_number = 0
    frame_number = video_to_frames(bucket_name, video_file, user_id, frame_data, frame_number)

    # Save and upload the pickle file
    with open(f"/tmp/training_data.pkl", 'wb') as output:
        pickle.dump(frame_data, output, pickle.HIGHEST_PROTOCOL)
    blob = bucket.blob(f'users/{user_id}/prediction_data/training_data.pkl')
    blob.upload_from_filename(f"/tmp/training_data.pkl")
    os.remove('/tmp/training_data.pkl')  # remove the local pickle file after uploading

    # Delete the processed video file from the bucket
    video_blob = bucket.blob(video_file)
    video_blob.delete()



def video_to_frames(bucket_name,blob_name,user_id,frame_dict={},frame_number=0):
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
            drowsy_event = {
                'drowsy': True,
                'timestamp': firestore.SERVER_TIMESTAMP,
                'userID': user_id
            }

            # Add the drowsy event to the database
            db.collection('drowsiness_events').add(drowsy_event)

        frame_dict[frame_number] = (original_frame, label)
        frame_number += 1

    cap.release()
    cv2.destroyAllWindows()

    # Remove the processed video file from the local file system
    os.remove(filename)

    return frame_number

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


    if file_path.endswith('signal.txt'):
        user_id = file_path.split('/')[1]
        # List all video files in the user's directory
        blobs = bucket.list_blobs(prefix=f'users/{user_id}/video_data/')
        video_files = [blob.name for blob in blobs if blob.name.endswith('.avi')]
        
        # Process each video file
        for video_file in video_files:
            process_video(bucket_name, user_id, video_file)
        
        # Delete the signal file
        signal_blob = bucket.blob(file_path)
        signal_blob.delete()

    return ('', 204)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
