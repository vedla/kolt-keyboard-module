import React, { useState } from 'react';

import {
  SafeAreaView,
  ScrollView,
  Text,
  TextInput,
  View,
} from 'react-native';

export default function App() {
  const [text, setText] = useState('');
  return (
    <SafeAreaView style={styles.container}>
      <ScrollView style={styles.container}>
        <Text style={styles.header}>Module API Example</Text>
        <TextInput
          style={styles.textArea}
          placeholder="Type your long message here..."
          placeholderTextColor="#888"
          multiline={true}
          numberOfLines={4} // Sets initial height on Android
          onChangeText={(value) => setText(value)}
          value={text}
        />
      </ScrollView>
    </SafeAreaView>
  );
}

function Group(props: { name: string; children: React.ReactNode }) {
  return (
    <View style={styles.group}>
      <Text style={styles.groupHeader}>{props.name}</Text>
      {props.children}
    </View>
  );
}

const styles = {
  header: { fontSize: 30, margin: 20 },
  groupHeader: { fontSize: 20, marginBottom: 20 },
  group: { margin: 20, backgroundColor: '#fff', borderRadius: 10, padding: 20 },
  container: { flex: 1, backgroundColor: '#eee' },
  view: { flex: 1, height: 200 },

  textArea: {
    height: 150,
    justifyContent: 'flex-start',
    textAlignVertical: 'top', // Critical for Android to align text at the top
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
  },
};
