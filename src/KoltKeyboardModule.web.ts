import { registerWebModule, NativeModule } from 'expo';

// KoltKeyboardModule is not available on the web platform.
class KoltKeyboardModule extends NativeModule<{}> {}

export default registerWebModule(KoltKeyboardModule, 'KoltKeyboardModule');
