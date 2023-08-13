import os
from google.cloud import storage
import requests
import tensorflow as tf

def convert_to_tflite(data, context):
    # Get the file details
    bucket_name = data['bucket']
    file_name = data['name']
    file_path = f"gs://{bucket_name}/{file_name}"

    # Check if the file is in the 'models' subdirectory
    if not file_name.startswith('models/'):
        return

    # Load the .h5 model
    model = tf.keras.models.load_model(file_path)

    # Convert to TFLite
    tflite_model = tf.keras.models.load_model(file_path)
    converter = tf.lite.TFLiteConverter.from_keras_model(tflite_model)
    tflite_model = converter.convert()

    # Upload the TFLite model
    tflite_blob_name = os.path.join('models', os.path.splitext(file_name)[0] + '.tflite')
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    tflite_blob = bucket.blob(tflite_blob_name)
    tflite_blob.upload_from_string(tflite_model, content_type='application/octet-stream')

    print(f"Converted and uploaded {tflite_blob_name}")

def trigger_on_upload(data, context):
    """Background Cloud Function to be triggered by Cloud Storage.
    This function sends a POST request to the Cloud Run service whenever a file is uploaded to the bucket.
    """
    file_name = data['name']
    bucket_name = data['bucket']

    if not file_name.startswith('users/'):
        print("File is not in a user directory, ignoring.")
        return

    print(f"File {file_name} uploaded to {bucket_name}.")

    # Replace with the URL of your Cloud Run service
    cloud_run_url = 'https://antisomnus-m3csmfreoa-uc.a.run.app'

    r = requests.post(
        cloud_run_url, 
        json={'file': file_name},
    )

    if r.status_code != 204:
        print(f"Failed to trigger Cloud Run service: {r.status_code}, {r.text}")
    else:
        print(f"Successfully triggered Cloud Run service for file {file_name}.")

