import cv2
import math
import random
import numpy as np
import mediapipe as mp

from scipy.spatial.distance import euclidean as dist
from sklearn.preprocessing import LabelEncoder, MinMaxScaler

# feature definitions


DIMS = (224,224,3) # dimensions of the image
RIGHT = [[33, 133], [160, 144], [159, 145], [158, 153]] # right eye landmark positions
LEFT = [[263, 362], [387, 373], [386, 374], [385, 380]] # left eye landmark positions
MOUTH = [[61, 291], [39, 181], [0, 17], [269, 405]] # mouth landmark coordinates

EYE_AR_THRESH = 0.45
PROB_THRESH = 0.3
EYE_AR_CONSEC_FRAMES = 15

MOUTH_AR_THRESH = 0.33
MOUTH_AR_CONSEC_FRAMES = 20

MP_FACE_DETECTION = mp.solutions.face_detection
MP_DRAWING = mp.solutions.drawing_utils
MP_DRAWING_STYLES = mp.solutions.drawing_styles
MP_FACE_MESH = mp.solutions.face_mesh
DRAWING_SPEC = MP_DRAWING.DrawingSpec(thickness=1, circle_radius=1)

def get_ear(landmarks,eye):
    ''' Calculate the ratio of the eye length to eye width. 
    :param landmarks: Face Landmarks returned from FaceMesh MediaPipe model
    :param eye: List containing positions which correspond to the eye
    :return: Eye aspect ratio value
    '''
    N1 = dist(landmarks[eye[1][0]], landmarks[eye[1][1]])
    N2 = dist(landmarks[eye[2][0]], landmarks[eye[2][1]])
    N3 = dist(landmarks[eye[3][0]], landmarks[eye[3][1]])
    D = dist(landmarks[eye[0][0]], landmarks[eye[0][1]])
    return (N1 + N2 + N3) / (3 * D)

def get_eye_feature(landmarks):
    ''' Calculate the eye feature as the average of the eye aspect ratio for the two eyes
    :param landmarks: Face Landmarks returned from FaceMesh MediaPipe model
    :return: Eye feature value
    '''
    return (get_ear(landmarks,LEFT) + get_ear(landmarks,RIGHT))

def get_mouth_feature(landmarks):
    ''' Calculate mouth feature as the ratio of the mouth length to mouth width
    :param landmarks: Face Landmarks returned from FaceMesh MediaPipe model
    :return: Mouth feature value
    '''
    n_1 = dist(landmarks[MOUTH[1][0]], landmarks[MOUTH[1][1]])
    n_2 = dist(landmarks[MOUTH[2][0]], landmarks[MOUTH[2][1]])
    n_3 = dist(landmarks[MOUTH[3][0]], landmarks[MOUTH[3][1]])
    dst = dist(landmarks[MOUTH[0][0]], landmarks[MOUTH[0][1]])
    return (n_1 + n_2 + n_3)/(3*dst)

# image processing


def process_mp_img(frame):
    """
    returns features and/or processed image
    """
    with MP_FACE_MESH.FaceMesh(
        min_detection_confidence=0.3,
        min_tracking_confidence=0.8) as face_mesh:
        # convert the img to RGB and process it with MediaPipe Face Detection
        results = face_mesh.process(cv2.cvtColor(frame,cv2.COLOR_BGR2RGB))

        if results.multi_face_landmarks is not None:
            landmark_pos = []
            for i, data in enumerate(results.multi_face_landmarks[0].landmark):
                landmark_pos.append([data.x, data.y, data.z])
            landmark_pos = np.array(landmark_pos)

            # draw face detections of each face
            annotated_img = frame.copy()
            for face_landmarks in results.multi_face_landmarks:
                # Calculate eye and mouth features
                eye_feature = get_eye_feature(landmark_pos)
                mouth_feature = get_mouth_feature(landmark_pos)

                # Binary classification: drowsy (1) or non-drowsy (0)
                drowsy = (eye_feature <= EYE_AR_THRESH) or (mouth_feature > MOUTH_AR_THRESH)       
                # face mesh
                MP_DRAWING.draw_landmarks(
                    image=annotated_img,
                    landmark_list=face_landmarks,
                    connections=MP_FACE_MESH.FACEMESH_TESSELATION,
                    landmark_drawing_spec=None,
                    connection_drawing_spec=MP_DRAWING_STYLES
                    .get_default_face_mesh_tesselation_style()
                )
                # eyes and mouth regions
                MP_DRAWING.draw_landmarks(
                    image=annotated_img,
                    landmark_list=face_landmarks,
                    connections=MP_FACE_MESH.FACEMESH_CONTOURS,
                    landmark_drawing_spec=None,
                    connection_drawing_spec=MP_DRAWING_STYLES
                    .get_default_face_mesh_contours_style()
                )
    return annotated_img, eye_feature, mouth_feature, drowsy



def mediapipe_process(frames):
    """
    Process all videos using MediaPipe and returns a 
    dictionary with the eye and mouth features in 
    the format {frame_number: {"eye_feature":0, "mouth_feature":0, "drowsy":0}}
    """
    mp_features = {}
    eye_features_all = []
    mouth_features_all = []
    # Extract eye and mouth features for all videos
    for frame in frames:
        mp_features[frame] = {"eye_feature": 0, "mouth_feature": 0, "drowsy": 0}
        _,eye_feature,mouth_feature,drowsy = process_mp_img(frame)
        mp_features[frame]["eye_feature"] = eye_feature
        mp_features[frame]["mouth_feature"] = mouth_feature
        mp_features[frame]["drowsy"] = drowsy
        eye_features_all.append(eye_feature)
        mouth_features_all.append(mouth_feature)

    # Calculate mean and standard deviation for normalization
    eye_mean, eye_std = np.mean(eye_features_all), np.std(eye_features_all)
    mouth_mean, mouth_std = np.mean(mouth_features_all), np.std(mouth_features_all)

    # Normalize eye and mouth features for all videos
    for frame,features in mp_features.items():
        features["eye_feature"] = (features["eye_feature"] - eye_mean) / eye_std
        features[frame]["mouth_feature"] = (features["mouth_feature"] - mouth_mean) / mouth_std

    return mp_features
