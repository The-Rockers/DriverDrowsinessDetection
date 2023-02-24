import {StatusBar} from 'expo-status-bar';
import {StyleSheet, Text, TextInput, View, Button, Linking} from 'react-native';
import * as tf from '@tensorflow/tfjs'
import * as FileSystem from 'expo-file-system';
import {bundleResourceIO, decodeJpeg} from '@tensorflow/tfjs-react-native';

export default function App() {
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
                <Button onPress={() => console.log("press")} title="Deactivate Drowsiness Detection" />
                <Button onPress={() => getCameraPermissionStatus} title="Configure Settings" />
                <Text> This works fine for now</Text>
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
