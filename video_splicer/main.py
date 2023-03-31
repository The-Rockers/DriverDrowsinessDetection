import os
import cv2
import tempfile
from google.cloud import storage


def splice_video(data, context):
    # Initialize Google Cloud Storage client
    storage_client = storage.Client()

    # Set the bucket name
    bucket_name = data["bucket"]
    bucket = storage_client.get_bucket(bucket_name)

    # Set the folder containing the training data
    training_data_folder = "training_data"

    # Get the video file path
    video_file_path = data["name"]

    if video_file_path.endswith(".avi"):
        # Download the video to a temporary file
        video_file = tempfile.NamedTemporaryFile(delete=False)
        blob = bucket.blob(video_file_path)
        blob.download_to_filename(video_file.name)

        # Read the video and split it into frames
        cap = cv2.VideoCapture(video_file.name)
        frame_number = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # Convert the frame to RGB format
            frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            # Save the frame as a PNG image
            _, png_buffer = cv2.imencode(".png", frame)

            # Upload the frame to Google Cloud Storage
            video_file_name = os.path.splitext(
                os.path.basename(video_file_path))[0]
            frame_blob_name = f"{training_data_folder}/{video_file_name}_frame_{frame_number}.png"
            frame_blob = bucket.blob(frame_blob_name)
            frame_blob.upload_from_string(
                png_buffer.tobytes(), content_type="image/png")

            frame_number += 1

        # Clean up
        video_file.close()
        os.unlink(video_file.name)
        cap.release()
