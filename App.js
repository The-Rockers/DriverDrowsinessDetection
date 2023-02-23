import { StatusBar } from 'expo-status-bar';
import { StyleSheet, Text, View, Button } from 'react-native';

export default function App() {
  return (
    <View style={styles.container}>
      <View style={styles.headerContainer}>
        <Button title="Log In" />
        <Button title="Log Out" />
      </View>
      <View style={styles.utilContainer}>
        <Button title="Activate Drowisness Detection" />
        <Button title="Deactivate Drowsiness Detection" />
        <Button title="Configure Settings" />
      </View>
    </View >
  );
}

const styles = StyleSheet.create({
  container: {
    paddingTop: 35,
    paddingBottom: 35,

    flex: 1,
    flexDirection: "column",
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
  },

  headerContainer: {
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
