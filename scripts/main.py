from google.cloud import storage
import requests

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
    cloud_run_url = 'https://antisomnus-process-m3csmfreoa-uc.a.run.app'

    r = requests.post(
        cloud_run_url, 
        json={'file': file_name},
    )

    if r.status_code != 204:
        print(f"Failed to trigger Cloud Run service: {r.status_code}, {r.text}")
    else:
        print(f"Successfully triggered Cloud Run service for file {file_name}.")

