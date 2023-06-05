import tensorflow.keras.models as models

file_batch = []

def process_batch(bucket_name):
    frame_data = {}
    frame_number = 0
    for blob_name in file_batch:
        frame_number = video_to_frames(bucket_name, blob_name, frame_data,frame_number)
    del file_batch[:]

    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    signal_blob = bucket.blob('signal.txt')
    signal_blob.delete()

def video_to_frames(bucket_name, blob_name,frame_dict = {},frame_number=0):
    client = storage.Client()
    bucket = client.get_bucket(bucket_name)
    blob = bucket.blob(blob_name)

    filename = "/tmp/" + os.path.basename(blob_name)
    blob.download_to_filename(filename)

    # load model
    model_blob = bucket.blob("models/en_model_v0.h5")
    model_blob.download_to_filename("/tmp/en_model_v0.h5")
    model = models.load_model("/tmp/en_model_v0.h5")

    cap = cv2.VideoCapture(filename)

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        original_frame = frame.copy()

        # preprocessing to feed into your model
        frame = cv2.resize(frame, (224, 224))
        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        frame = frame / 255.0
        frame = np.expand_dims(frame, axis=0)  # for single prediction

        # predict
        prediction = model.predict(frame)
        label = np.argmax(prediction)

        frame_dict[frame_number] = (original_frame, label)
        frame_number += 1

    cap.release()
    cv2.destroyAllWindows()

    # save dictionary as a pickle file
    filename = os.path.splitext(os.path.basename(blob_name))[0]
    with open(f"/tmp/training_data.pkl", 'wb') as output:
        pickle.dump(frame_dict, output, pickle.HIGHEST_PROTOCOL)
    
    # upload back to the bucket under the videos/labels subdirectory
    blob = bucket.blob(f"videos/training_data.pkl")
    blob.upload_from_filename(f"/tmp/training_data.pkl")

    return frame_number

def process_file(data, context):
    """Background Cloud Function to be triggered by Cloud Storage.
       This function gets executed when a text file signalling that a batch of video files (.avi files gathered from the Pi from Mon-Fri) has been sent is uploaded to the Cloud Storage bucket.
       It reads the file, converts video to frames, runs the model on each frame and stores the result in a dictionary.
    """
    bucket_name = data['bucket']
    blob_name = data['name']

    # add the file to our batch
    file_batch.append(blob_name)

    # if this is the signal file, process the batch
    if blob_name.endswith('signal.txt'):
        process_batch(bucket_name)
