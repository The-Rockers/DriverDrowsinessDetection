import {Camera, useCameraDevices} from 'react-native-vision-camera';

const cameraPermission = await Camera.getCameraPermissionStatus()
const microphonePermission = await Camera.getMicrophonePermissionStatus()

export default {cameraPermission, microphonePermission};