import { NativeModule, requireNativeModule } from 'expo';

declare class KoltKeyboardModule extends NativeModule<{}> {}

export default requireNativeModule<KoltKeyboardModule>('KoltKeyboard');
