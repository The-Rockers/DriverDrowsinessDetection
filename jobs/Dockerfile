# Use a standard Python base image
FROM python:3.10

# Copy your Python script to the Docker image
COPY main.py /

# Install any required Python packages
RUN pip install --no-cache-dir flask google-cloud-storage google-cloud-firestore google-cloud-iam google-auth firebase-admin tensorflow opencv-python-headless numpy

# Run your script when the Docker container is started
CMD [ "python", "./main.py" ]

