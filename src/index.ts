import type {
  KoltKeyboardConfiguration,
  KoltKeyboardPreset,
  KoltKeyboardStorageOptions,
} from './KoltKeyboard.types'
import KoltKeyboardModule from './KoltKeyboardModule'

export * from './KoltKeyboard.types'

type StoredKeyboardConfiguration = KoltKeyboardConfiguration & {
  schemaVersion: 1
  updatedAt: number
}

function assertConfiguration(configuration: KoltKeyboardConfiguration): void {
  if (!configuration.pages.length) {
    throw new Error('KoltKeyboard requires at least one page.')
  }

  const pageIds = new Set<string>()
  for (const page of configuration.pages) {
    if (!page.id.trim() || !page.title.trim()) {
      throw new Error('Every keyboard page requires a non-empty id and title.')
    }
    if (pageIds.has(page.id)) {
      throw new Error(`Duplicate keyboard page id: ${page.id}`)
    }
    pageIds.add(page.id)

    if (page.layout !== 'grid' && page.layout !== 'list') {
      throw new Error(`Unsupported layout on page ${page.id}.`)
    }
    if (page.columns !== undefined && (!Number.isInteger(page.columns) || page.columns < 1)) {
      throw new Error(`Page ${page.id} must have a positive integer column count.`)
    }

    const sectionIds = new Set<string>()
    const keyIds = new Set<string>()
    const sectionKeys = (page.sections ?? []).flatMap((section) => {
      if (!section.id.trim() || !section.title.trim() || sectionIds.has(section.id)) {
        throw new Error(`Every section on page ${page.id} requires a unique id and title.`)
      }
      sectionIds.add(section.id)
      return section.keys
    })
    for (const key of [...page.keys, ...sectionKeys]) {
      if (!key.id.trim() || !key.label.trim() || !key.text) {
        throw new Error(`Every key on page ${page.id} requires an id, label, and text.`)
      }
      if (keyIds.has(key.id)) {
        throw new Error(`Duplicate key id on page ${page.id}: ${key.id}`)
      }
      keyIds.add(key.id)
    }
  }
}

/** Persist a React Native-defined keyboard UI for the native extension. */
export function setKeyboardConfiguration(
  configuration: KoltKeyboardConfiguration,
  options: KoltKeyboardStorageOptions = {}
): void {
  assertConfiguration(configuration)
  const payload: StoredKeyboardConfiguration = {
    ...configuration,
    schemaVersion: 1,
    updatedAt: Date.now(),
  }
  KoltKeyboardModule.setConfiguration(JSON.stringify(payload), options.appGroupIdentifier)
}

/** Read the last configuration written by the host app. */
export function getKeyboardConfiguration(
  options: KoltKeyboardStorageOptions = {}
): KoltKeyboardConfiguration | null {
  const json = KoltKeyboardModule.getConfiguration(options.appGroupIdentifier)
  if (!json) return null
  const {
    schemaVersion: _schemaVersion,
    updatedAt: _updatedAt,
    ...configuration
  } = JSON.parse(json) as StoredKeyboardConfiguration
  return configuration
}

export function clearKeyboardConfiguration(options: KoltKeyboardStorageOptions = {}): void {
  KoltKeyboardModule.clearConfiguration(options.appGroupIdentifier)
}

/** Convenience adapter for the common Symbols + Snippets keyboard. */
export function createKeyboardConfiguration(preset: KoltKeyboardPreset): KoltKeyboardConfiguration {
  return {
    brand: preset.brand ?? 'K',
    statusLabel: preset.statusLabel ?? 'ON-DEVICE',
    appearance: { theme: preset.theme ?? 'lavender' },
    frequentlyUsed: { enabled: preset.frequentlyUsed ?? true, maxKeys: 6 },
    pages: [
      {
        id: 'symbols',
        title: 'Symbols',
        layout: 'grid',
        keys: preset.symbols.map((symbol, index) => ({
          id: `symbol-${index}-${symbol}`,
          label: symbol,
          text: symbol,
        })),
        emptyState: 'Choose symbols in the app.',
      },
      {
        id: 'snippets',
        title: 'Snippets',
        layout: 'list',
        keys: (preset.snippets ?? []).map((snippet) => ({
          id: snippet.id,
          label: snippet.title || snippet.text,
          text: snippet.text,
        })),
        emptyState: 'Add snippets in the app.',
      },
    ],
  }
}

export default {
  setKeyboardConfiguration,
  getKeyboardConfiguration,
  clearKeyboardConfiguration,
  createKeyboardConfiguration,
}
