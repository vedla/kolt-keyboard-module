import { NativeModule, registerWebModule } from 'expo';

class KoltKeyboardWebModule extends NativeModule<Record<never, never>> {
  private configuration: string | null = null;

  setConfiguration(json: string): void {
    this.configuration = json;
  }

  getConfiguration(): string | null {
    return this.configuration;
  }

  clearConfiguration(): void {
    this.configuration = null;
  }
}

export default registerWebModule(KoltKeyboardWebModule, 'KoltKeyboard');
