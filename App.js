import { StatusBar } from 'expo-status-bar';
import { StyleSheet, TextInput, View, Button, Text, Linking } from 'react-native';
//import { Camera, useCameraDevices } from 'react-native-vision-camera';
//import 'react-native-reanimated';

/* 
'react-native-vision-camera' && 'react-native-reanimated' dont seem to work with Expo.
Whenever I try to use them, it tells me that I need to use pod install. Additionally, I don't
think they're actually what I need. :(
*/

export default function App() {

  async function getCameraPermissionStatus() {
    const cameraPermission = await Camera.getCameraPermissionStatus()
      .catch((error) => {
        console.log(error);
      });
    console.log(cameraPermission);

    const devices = await Camera.getAvailableCameraDevices()
      .catch((error) => {
        console.log(error);
      });
    console.log(devices);
  }

  /*
  async function useCamera() {

    const newCameraPermission = await Camera.requestCameraPermission()
    const newMicrophonePermission = await Camera.requestMicrophonePermission()

    const cameraPermission = Camera.getCameraPermissionStatus()
    const microphonePermission = Camera.getMicrophonePermissionStatus()

    console.log(cameraPermission);

    const devices = useCameraDevices();
    const device = devices.back;

    const frameProcessor = useFrameProcessor((frame) => {
      'worklet'
      const isHotdog = detectIsHotdog(frame)
      console.log(isHotdog ? "Hotdog!" : "Not Hotdog.")
    }, [])

    return (
      <Camera
        {...cameraProps}
        frameProcessor={frameProcessor}
      />
    )

  }
  */

  return (
    <View style={styles.container}>
      <View>
        <TextInput style={styles.textStyling}
          placeholder="User Name"
        />
        <TextInput style={styles.textStyling}
          placeholder="Password"
        />
      </View>
      <View style={styles.userAccount}>
        <Button title="Log In" />
        <Button title="Log Out" />
      </View>
      <View style={styles.utilContainer}>
        <Button title="Activate Drowisness Detection" />
        <Button title="Deactivate Drowsiness Detection" />
        <Button onPress={() => getCameraPermissionStatus} title="Configure Settings" />
      </View>
      <View>
        {

        }
      </View>
    </View >
  );
}

const styles = StyleSheet.create({

  textStyling: {
    borderWidth: 1,
    borderColor: "blue",
    padding: 5,
    marginBottom: 5,
  },

  buttonStyling: {
    backgroundColor: 'black',
    color: "red",
  },

  container: {
    paddingTop: 35,
    paddingBottom: 35,

    flex: 1,
    flexDirection: "column",
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },

  userAccount: {
    flex: 1,
    flexDirection: "row",
    justifyContent: "space-between",
    alignItems: "center",
    marginBotton: 50,
  },

  utilContainer: {
    flex: 4,
  }
});
