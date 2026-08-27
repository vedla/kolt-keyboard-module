import {
  NativeModule,
  requireNativeModule,
} from 'expo'

declare class KoltKeyboardNativeModule extends NativeModule<Record<never, never>> {
  setConfiguration(json: string, appGroupIdentifier?: string): void
  getConfiguration(appGroupIdentifier?: string): string | null
  clearConfiguration(appGroupIdentifier?: string): void
}

export default requireNativeModule<KoltKeyboardNativeModule>('KoltKeyboard')
