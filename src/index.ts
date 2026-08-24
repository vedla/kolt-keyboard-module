// Reexport the native module. On web, it will be resolved to KoltKeyboardModule.web.ts
// and on native platforms to KoltKeyboardModule.ts
export { default } from './KoltKeyboardModule';
export * from './KoltKeyboard.types';
