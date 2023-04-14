from python:3.10.11-slim-bullseye
WORKDIR /app
COPY requirements.txt .
RUN apt-get update && apt-get upgrade -y
RUN pip install -r requirements.txt
RUN cd app
CMD ["gradio", "app.py"]
