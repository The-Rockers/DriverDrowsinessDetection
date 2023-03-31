"""
Module: data.py

This module provides functionality for processing video files and extracting
frame images. The primary function, `process_video_files`, is responsible for
downloading video files, converting them to frame images, and uploading the
frames back to the specified storage location.

Functions:
    - process_video_files(bucket_name: str) -> None
    - splice_video_to_frames(bucket_name: str, video_blob: Blob) -> None

Author: Rohit Nair
Email: john.doe@example.com
License: MIT License
Date: 2023-03-22
Version: 1.0.0
"""

# ... module code ...


import tempfile

from cv2 import cv2
from google.cloud import storage

# Initialize Google Cloud Storage client
#os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = 'antisomnus-credentials.json'
storage_client = storage.Client()

BUCKET_NAME = "antisomnus-bucket"
BUCKET = storage_client.get_bucket(BUCKET_NAME)

TRAIN = "training_data"
VALID = "validation_data"
TEST = "test_data"


def splice_avi_to_png(avi_blob):
    """
    Splices an .avi video file into individual .png frames and uploads them to
    Google Cloud Storage.
    """
    filename = avi_blob.name[:-4]  # Remove '.avi' extension

    # Download the video file to a temporary directory
    with tempfile.NamedTemporaryFile(suffix=".avi") as temp_video_file:
        avi_blob.download_to_filename(temp_video_file.name)

        # Read the video file
        cap = cv2.VideoCapture(temp_video_file.name)

        frame_number = 0
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # Save the frame as a .png file
            frame_filename = f"{filename}_frame_{frame_number:03d}.png"
            with tempfile.NamedTemporaryFile(suffix=".png") as temp_frame_file:
                cv2.imwrite(temp_frame_file.name, frame)
                frame_blob = BUCKET.blob(frame_filename)
                frame_blob.upload_from_filename(temp_frame_file.name)

            frame_number += 1
        cap.release()
        avi_blob.delete()


def process_avi_files():
    """
    Processes all .avi files in the training_data directory.
    """
    blobs = BUCKET.list_blobs(prefix=TRAIN, delimiter="/")
    avi_blobs = [blob for blob in blobs if blob.name.endswith(".avi")]

    for avi_blob in avi_blobs:
        splice_avi_to_png(avi_blob)


if __name__ == "__main__":
    process_avi_files()
