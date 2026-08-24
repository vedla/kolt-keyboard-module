# Kolt Keyboard

An Expo native module that lets React Native define a custom keyboard's pages and keys while UIKit renders the actual iOS keyboard extension.

## Architecture

React Native does not run inside an iOS keyboard extension. The host app calls `setKeyboardConfiguration`, the Expo module writes a versioned JSON payload to an App Group, and the native extension reads and renders that payload. This keeps configuration UI in React Native and text insertion in native code.

## App configuration

Register one App Group in the Apple Developer portal for both the app and keyboard extension, then add the plugin:

```json
{
  "expo": {
    "plugins": [["kolt-keyboard", { "appGroupIdentifier": "group.com.example.myapp.keyboard" }]]
  }
}
```

The plugin configures the host app and generates `ios/KoltKeyboardExtension`, including the extension target, native renderer, App Group entitlement, Info.plist, and embedded `.appex`. Because the extension is generated from `plugin/ios`, it is safe to run `expo prebuild --clean`.

Keyboard extensions are native iOS targets and do not work in Expo Go. Use a development build (`npx expo run:ios`) on a device, then enable the keyboard under Settings > General > Keyboard > Keyboards.

## React Native API

```ts
import { createKeyboardConfiguration, setKeyboardConfiguration } from 'kolt-keyboard';

setKeyboardConfiguration(
  createKeyboardConfiguration({
    symbols: ['™', '©', '→'],
    snippets: [{ id: 'email', title: 'Email', text: 'hello@example.com' }],
  })
);
```

For a fully custom layout, pass pages directly:

```ts
setKeyboardConfiguration({
  brand: 'K',
  statusLabel: 'ON-DEVICE',
  pages: [
    {
      id: 'links',
      title: 'Links',
      layout: 'list',
      keys: [{ id: 'website', label: 'Website', text: 'https://example.com' }],
    },
  ],
});
```

The native bottom row (next-keyboard globe, space, and delete) remains native and is always available.

## Android status

The Expo module persists and reads the same configuration model on Android. An Android `InputMethodService` renderer is not included yet; iOS is the current end-to-end implementation.
