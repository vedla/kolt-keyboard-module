export type KoltKeyboardPageLayout = 'grid' | 'list'

/** A native key. `text` is inserted into the active text field when tapped. */
export type KoltKeyboardKey = {
  id: string
  label: string
  text: string
  accessibilityLabel?: string
}

export type KoltKeyboardSection = {
  id: string
  title: string
  keys: KoltKeyboardKey[]
  columns?: number
}
export type KoltKeyboardTheme = 'lavender' | 'midnight' | 'graphite' | 'ocean'

/** A page shown in the native keyboard's segmented control. */
export type KoltKeyboardPage = {
  id: string
  title: string
  layout: KoltKeyboardPageLayout
  keys: KoltKeyboardKey[]
  /** Number of columns for a grid page. Defaults to 7 on iPhone. */
  columns?: number
  emptyState?: string
  sections?: KoltKeyboardSection[]
}

/** The complete UI model consumed by the native keyboard extension. */
export type KoltKeyboardConfiguration = {
  pages: KoltKeyboardPage[]
  brand?: string
  statusLabel?: string
  appearance?: { theme: KoltKeyboardTheme }
  frequentlyUsed?: { enabled: boolean; maxKeys?: number }
}

export type KoltKeyboardStorageOptions = {
  /**
   * iOS App Group shared by the host app and keyboard extension. When omitted,
   * the module reads `KoltKeyboardAppGroup` from the host app's Info.plist.
   */
  appGroupIdentifier?: string
}

export type KoltSnippet = {
  id: string
  title: string
  text: string
}

export type KoltKeyboardPreset = {
  symbols: string[]
  snippets?: KoltSnippet[]
  brand?: string
  statusLabel?: string
  theme?: KoltKeyboardTheme
  frequentlyUsed?: boolean
}
