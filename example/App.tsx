import React, {
  useEffect,
  useState,
} from 'react';

import {
  createKeyboardConfiguration,
  type KoltSnippet,
  setKeyboardConfiguration,
} from 'kolt-keyboard';
import {
  Alert,
  Pressable,
  SafeAreaView,
  ScrollView,
  Text,
  TextInput,
  View,
} from 'react-native';

const APP_GROUP = 'group.ca.vedla.kolt.keyboard';
const AVAILABLE_SYMBOLS = ['™', '®', '©', '', '°', '±', '•', '…', '—', '→', '€', '∞'];

export default function App() {
  const [text, setText] = useState('');
  const [symbols, setSymbols] = useState(AVAILABLE_SYMBOLS.slice(0, 10));
  const [snippetTitle, setSnippetTitle] = useState('Email');
  const [snippetText, setSnippetText] = useState('hello@example.com');
  const [snippets, setSnippets] = useState<KoltSnippet[]>([]);

  useEffect(() => {
    setKeyboardConfiguration(createKeyboardConfiguration({ symbols, snippets }), {
      appGroupIdentifier: APP_GROUP,
    });
  }, [snippets, symbols]);

  const toggleSymbol = (symbol: string) => {
    setSymbols((current) =>
      current.includes(symbol) ? current.filter((item) => item !== symbol) : [...current, symbol]
    );
  };

  const addSnippet = () => {
    if (!snippetText.trim()) {
      Alert.alert('Snippet text is required');
      return;
    }
    setSnippets((current) => [
      ...current,
      { id: `${Date.now()}`, title: snippetTitle.trim(), text: snippetText },
    ]);
    setSnippetTitle('');
    setSnippetText('');
  };

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.content}>
        <Text style={styles.header}>Kolt Keyboard</Text>
        <Text style={styles.help}>
          This screen is React Native. Changes are rendered by the native keyboard.
        </Text>

        <Group name="Available keys">
          <View style={styles.symbolGrid}>
            {AVAILABLE_SYMBOLS.map((symbol) => (
              <Pressable
                key={symbol}
                onPress={() => toggleSymbol(symbol)}
                style={[styles.symbol, symbols.includes(symbol) && styles.symbolSelected]}>
                <Text style={styles.symbolText}>{symbol}</Text>
              </Pressable>
            ))}
          </View>
        </Group>

        <Group name="Snippets">
          <TextInput
            style={styles.input}
            placeholder="Button label"
            onChangeText={setSnippetTitle}
            value={snippetTitle}
          />
          <TextInput
            style={styles.input}
            placeholder="Text to insert"
            onChangeText={setSnippetText}
            value={snippetText}
          />
          <Pressable onPress={addSnippet} style={styles.addButton}>
            <Text style={styles.addButtonText}>Add snippet</Text>
          </Pressable>
          {snippets.map((snippet) => (
            <Pressable
              key={snippet.id}
              onPress={() =>
                setSnippets((items) => items.filter((item) => item.id !== snippet.id))
              }>
              <Text style={styles.snippet}>{snippet.title || snippet.text} · tap to remove</Text>
            </Pressable>
          ))}
        </Group>

        <Group name="Test the keyboard">
          <TextInput
            style={styles.textArea}
            placeholder="Enable Kolt Keyboard in Settings, then type here…"
            placeholderTextColor="#888"
            multiline
            onChangeText={setText}
            value={text}
          />
        </Group>
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
  container: { flex: 1, backgroundColor: '#f2f0fa' },
  content: { padding: 20, gap: 16 },
  header: { fontSize: 32, fontWeight: '800' as const, marginTop: 12 },
  help: { color: '#565064', fontSize: 15, lineHeight: 21 },
  groupHeader: { fontSize: 19, fontWeight: '700' as const, marginBottom: 14 },
  group: { backgroundColor: '#fff', borderRadius: 16, padding: 16 },
  symbolGrid: { flexDirection: 'row' as const, flexWrap: 'wrap' as const, gap: 8 },
  symbol: {
    width: 46,
    height: 46,
    borderRadius: 12,
    backgroundColor: '#eceaf0',
    alignItems: 'center' as const,
    justifyContent: 'center' as const,
  },
  symbolSelected: { backgroundColor: '#7259df' },
  symbolText: { fontSize: 20 },
  input: {
    borderWidth: 1,
    borderColor: '#d8d4df',
    borderRadius: 10,
    padding: 12,
    marginBottom: 10,
  },
  addButton: {
    backgroundColor: '#7259df',
    borderRadius: 10,
    padding: 13,
    alignItems: 'center' as const,
  },
  addButtonText: { color: '#fff', fontWeight: '700' as const },
  snippet: { paddingVertical: 12, color: '#514a5c' },
  textArea: {
    height: 150,
    textAlignVertical: 'top' as const,
    borderWidth: 1,
    borderColor: '#d8d4df',
    borderRadius: 10,
    padding: 12,
    fontSize: 16,
  },
};
