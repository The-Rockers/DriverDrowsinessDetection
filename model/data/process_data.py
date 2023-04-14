"""
Module: example_module.py

This module provides functionality for processing video files and extracting
frame images. The primary function, `process_video_files`, is responsible for
downloading video files, converting them to frame images, and uploading the
frames back to the specified storage location.

Functions:
    - process_video_files(bucket_name: str) -> None
    - splice_video_to_frames(bucket_name: str, video_blob: Blob) -> None

Author: Rohit Nair
License: MIT License
Date: 2023-03-22
Version: 1.0.0
"""

import os
import tempfile
import pickle
import numpy as np
import cv2
from google.cloud import storage

# Initialize Google Cloud Storage client
storage_client = storage.Client()

# Set the bucket name
BUCKET_NAME = "antisomnus-bucket"
bucket = storage_client.get_bucket(BUCKET_NAME)


class Image:
    def __init__(self,frame,dimensions:tuple):
        self.frame = frame
        self.height, self.width, self.depth = dimensions
    
    def load_and_prep_image(self,scale=False):
        frame_rgb = cv2.Color(self.frame,cv2.COLOR_BGR2RGB)
        _, encoded_frame = cv2.imencode('.png',frame_rgb)
        encoded_frame_bytes = encoded_frame.tobytes()
        tensor_frame = tf.io.decode_image(encoded_frame_bytes)
        tensor_frame = tf.image.resize(tensor_frame,(self.height,self.width))
        if scale:
            return tensor_frame/255.
        else:
            return tensor_frame


class DriverDrowsinessDataset:
    """
        DriverDrowsinessDataset
    """
    def __init__(self, _data_dir, _label_dir):
        self.data_dir = _data_dir
        self.label_dir = _label_dir

    def get_labels(self,vid_name):
        """
        retrieves the labels for a video file
        """
        vid_name = vid_name.split("/")[-1].split(".")[0]
        label_file_name = self.label_dir + "/" + vid_name +  "_drowsiness.txt"

        # get the blob
        label_blob = bucket.blob(label_file_name)

        # download the blob to a temporary file
        label_file = tempfile.NamedTemporaryFile(delete=False)
        label_blob.download_to_filename(label_file.name)

        # read the label file
        labels = np.genfromtxt(label_file.name,delimiter=1,dtype=int)

        # clean up
        label_file.close()
        os.unlink(label_file.name)

        return labels

    def unpkl_data(self):
        """get the pickled file with the data from the storage bucket and return the unpickled data"""
        # get the blob
        try:
            blob = bucket.blob("training_data/training_data.pkl")
            blob.download_to_filename("data.pkl")
        except Exception as download_error:
            print(download_error)
            return False

        return True

    def show_data(self,file):
        """
        shows data
        """
        with open(file, 'rb') as pkl:
            data_dict = pickle.load(pkl)
        return data_dict

    def get_all_data(self) -> bool:
        """
        retrieves all the data in the form of a dictionary mapping image names to
        their corresponding labels
        format: {image_name: (image, label)}
        """
        img_label_data = {}
        # get a list of all files in the folder that ends with .avi
        blobs = [blob for blob in
                storage_client.list_blobs(BUCKET_NAME, prefix=self.data_dir)
                if blob.name.endswith(".avi")]

        blob_count = len(blobs)

        if blob_count == 0:
            print("No video files found in the bucket.")
            return False
        else:
            print(f"Found {blob_count} video files in the bucket.")

        for blob in blobs:
            print(f"Processing video file {blob.name}...{blob_count} more to go")
            # Download the video to a temporary file
            video_file = tempfile.NamedTemporaryFile(delete=False)
            blob.download_to_filename(video_file.name)
            labels = self.get_labels(blob.name)

            # Read the video and split it into frames
            cap = cv2.VideoCapture(video_file.name)
            frame_number = 0
            while frame_number < len(labels):
                ret, frame = cap.read()
                if not ret:
                    break
                print(f"Processing frame {frame_number}...")

                # Save the frame in a dictionary
                img_label_data[frame_number] = (frame, labels[frame_number])
                frame_number += 1

            # Clean up
            video_file.close()
            os.unlink(video_file.name)
            cap.release()
            #cv2.destroyAllWindows()
            blob_count -= 1

            # Delete the video file from Google Cloud Storage
            # print(f"Deleting video file {blob.name}...")
            # blob.delete()
            # blob_count -= 1
        # save img_label_data as a pickle file to the bucket

        with open('data.pkl', 'wb') as file:
            pickle.dump(img_label_data, file, protocol=pickle.HIGHEST_PROTOCOL)
        img_label_data_blob = bucket.blob("training_data/training_data.pkl")
        img_label_data_blob.upload_from_filename('data.pkl')

        print("Done processing all video files.")

        return True


if __name__ == "__main__":
    data = DriverDrowsinessDataset('training_data','training_data/labels')
    data.get_all_data()
