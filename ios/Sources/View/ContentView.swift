import SwiftUI
import UIKit

private enum KeyboardStorage {
    static let appGroup = "group.ca.vedla.kolt.keyboard"
    static let payloadKey = "keyboard.payload.v1"
    static let iCloudOptInKey = "icloud.sync.enabled.v1"
    static let onboardingKey = "onboarding.completed.v1"
    static let sourceURL = URL(string: "https://github.com/vedla/KoltKeyboard")!
}

private struct KeyboardPayload: Codable {
    var enabledSymbols: [String]
    var snippets: [Snippet]
    var updatedAt: Date
}

private struct Snippet: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var text: String
}

private struct SymbolItem: Identifiable, Hashable {
    let id: String
    let value: String
    let name: String
    let category: String
    var note: String? = nil
}

private enum SymbolCatalog {
    static let items: [SymbolItem] = [
        .init(id: "trademark", value: "™", name: "Trademark", category: "Legal"),
        .init(id: "registered", value: "®", name: "Registered", category: "Legal"),
        .init(id: "copyright", value: "©", name: "Copyright", category: "Legal"),
        .init(id: "service-mark", value: "℠", name: "Service mark", category: "Legal"),
        .init(id: "apple", value: "", name: "Apple logo", category: "Legal", note: "Apple-only private-use glyph; it may not display on non-Apple devices."),
        .init(id: "cent", value: "¢", name: "Cent", category: "Currency"),
        .init(id: "dollar", value: "$", name: "Dollar", category: "Currency"),
        .init(id: "euro", value: "€", name: "Euro", category: "Currency"),
        .init(id: "pound", value: "£", name: "Pound", category: "Currency"),
        .init(id: "yen", value: "¥", name: "Yen", category: "Currency"),
        .init(id: "won", value: "₩", name: "Won", category: "Currency"),
        .init(id: "rupee", value: "₹", name: "Rupee", category: "Currency"),
        .init(id: "bitcoin", value: "₿", name: "Bitcoin", category: "Currency"),
        .init(id: "degree", value: "°", name: "Degree", category: "Math"),
        .init(id: "plus-minus", value: "±", name: "Plus or minus", category: "Math"),
        .init(id: "multiply", value: "×", name: "Multiply", category: "Math"),
        .init(id: "divide", value: "÷", name: "Divide", category: "Math"),
        .init(id: "not-equal", value: "≠", name: "Not equal", category: "Math"),
        .init(id: "approx", value: "≈", name: "Approximately", category: "Math"),
        .init(id: "less-equal", value: "≤", name: "Less than or equal", category: "Math"),
        .init(id: "greater-equal", value: "≥", name: "Greater than or equal", category: "Math"),
        .init(id: "infinity", value: "∞", name: "Infinity", category: "Math"),
        .init(id: "sqrt", value: "√", name: "Square root", category: "Math"),
        .init(id: "sum", value: "∑", name: "Sum", category: "Math"),
        .init(id: "pi", value: "π", name: "Pi", category: "Math"),
        .init(id: "micro", value: "µ", name: "Micro", category: "Math"),
        .init(id: "percent", value: "%", name: "Percent", category: "Math"),
        .init(id: "per-mille", value: "‰", name: "Per mille", category: "Math"),
        .init(id: "left", value: "←", name: "Left arrow", category: "Arrows"),
        .init(id: "right", value: "→", name: "Right arrow", category: "Arrows"),
        .init(id: "up", value: "↑", name: "Up arrow", category: "Arrows"),
        .init(id: "down", value: "↓", name: "Down arrow", category: "Arrows"),
        .init(id: "both", value: "↔", name: "Left-right arrow", category: "Arrows"),
        .init(id: "return", value: "↩", name: "Return arrow", category: "Arrows"),
        .init(id: "double-right", value: "⇒", name: "Double right arrow", category: "Arrows"),
        .init(id: "bullet", value: "•", name: "Bullet", category: "Typography"),
        .init(id: "middle-dot", value: "·", name: "Middle dot", category: "Typography"),
        .init(id: "ellipsis", value: "…", name: "Ellipsis", category: "Typography"),
        .init(id: "en-dash", value: "–", name: "En dash", category: "Typography"),
        .init(id: "em-dash", value: "—", name: "Em dash", category: "Typography"),
        .init(id: "section", value: "§", name: "Section", category: "Typography"),
        .init(id: "paragraph", value: "¶", name: "Paragraph", category: "Typography"),
        .init(id: "dagger", value: "†", name: "Dagger", category: "Typography"),
        .init(id: "double-dagger", value: "‡", name: "Double dagger", category: "Typography"),
        .init(id: "left-double-quote", value: "“", name: "Left double quote", category: "Typography"),
        .init(id: "right-double-quote", value: "”", name: "Right double quote", category: "Typography"),
        .init(id: "left-single-quote", value: "‘", name: "Left single quote", category: "Typography"),
        .init(id: "right-single-quote", value: "’", name: "Right single quote", category: "Typography"),
        .init(id: "hash", value: "#", name: "Hash", category: "ASCII"),
        .init(id: "at", value: "@", name: "At", category: "ASCII"),
        .init(id: "ampersand", value: "&", name: "Ampersand", category: "ASCII"),
        .init(id: "asterisk", value: "*", name: "Asterisk", category: "ASCII"),
        .init(id: "caret", value: "^", name: "Caret", category: "ASCII"),
        .init(id: "tilde", value: "~", name: "Tilde", category: "ASCII"),
        .init(id: "pipe", value: "|", name: "Vertical bar", category: "ASCII"),
        .init(id: "backslash", value: "\\", name: "Backslash", category: "ASCII"),
        .init(id: "underscore", value: "_", name: "Underscore", category: "ASCII"),
        .init(id: "left-brace", value: "{", name: "Left brace", category: "ASCII"),
        .init(id: "right-brace", value: "}", name: "Right brace", category: "ASCII"),
        .init(id: "left-bracket", value: "[", name: "Left bracket", category: "ASCII"),
        .init(id: "right-bracket", value: "]", name: "Right bracket", category: "ASCII"),
        .init(id: "less-than", value: "<", name: "Less than", category: "ASCII"),
        .init(id: "greater-than", value: ">", name: "Greater than", category: "ASCII")
    ]

    static let defaultValues = ["™", "®", "©", "", "°", "±", "•", "…", "—", "→"]
    static let categories = ["Legal", "Currency", "Math", "Arrows", "Typography", "ASCII"]
}

@MainActor
private final class KeyboardSettingsStore: ObservableObject {
    @Published private(set) var enabledSymbols = Set(SymbolCatalog.defaultValues)
    @Published private(set) var snippets: [Snippet] = []
    @Published private(set) var lastSynced: Date?
    @Published private(set) var iCloudSyncEnabled: Bool
    private let cloud = NSUbiquitousKeyValueStore.default
    private var cloudObserver: NSObjectProtocol?

    init() {
        iCloudSyncEnabled = UserDefaults.standard.bool(forKey: KeyboardStorage.iCloudOptInKey)
        loadNewestPayload()
        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloud,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard self?.iCloudSyncEnabled == true else { return }
                self?.loadNewestPayload()
            }
        }
        if iCloudSyncEnabled { cloud.synchronize() }
    }

    deinit {
        if let cloudObserver { NotificationCenter.default.removeObserver(cloudObserver) }
    }

    func isEnabled(_ symbol: String) -> Bool { enabledSymbols.contains(symbol) }

    func toggle(_ symbol: String) {
        if enabledSymbols.contains(symbol) { enabledSymbols.remove(symbol) } else { enabledSymbols.insert(symbol) }
        save()
    }

    func setAll(in category: String, enabled: Bool) {
        let values = SymbolCatalog.items.filter { $0.category == category }.map(\.value)
        if enabled { enabledSymbols.formUnion(values) } else { enabledSymbols.subtract(values) }
        save()
    }

    func addSnippet(title: String, text: String) {
        snippets.append(Snippet(title: title.trimmingCharacters(in: .whitespacesAndNewlines), text: text))
        save()
    }

    func updateSnippet(_ snippet: Snippet, title: String, text: String) {
        guard let index = snippets.firstIndex(where: { $0.id == snippet.id }) else { return }
        snippets[index].title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        snippets[index].text = text
        save()
    }

    func deleteSnippets(at offsets: IndexSet) {
        snippets.remove(atOffsets: offsets)
        save()
    }

    func setICloudSyncEnabled(_ enabled: Bool) {
        iCloudSyncEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: KeyboardStorage.iCloudOptInKey)
        if enabled {
            cloud.synchronize()
            loadNewestPayload()
            save()
        } else {
            lastSynced = nil
        }
    }

    func deleteICloudCopy() {
        iCloudSyncEnabled = false
        UserDefaults.standard.set(false, forKey: KeyboardStorage.iCloudOptInKey)
        cloud.removeObject(forKey: KeyboardStorage.payloadKey)
        cloud.synchronize()
        lastSynced = nil
    }

    private func loadNewestPayload() {
        let sharedData = UserDefaults(suiteName: KeyboardStorage.appGroup)?.data(forKey: KeyboardStorage.payloadKey)
        let localData = UserDefaults.standard.data(forKey: KeyboardStorage.payloadKey)
        let cloudData = iCloudSyncEnabled ? cloud.data(forKey: KeyboardStorage.payloadKey) : nil
        let decoder = JSONDecoder()
        let payloads = [sharedData, localData, cloudData].compactMap { $0 }
            .compactMap { try? decoder.decode(KeyboardPayload.self, from: $0) }
        guard let newest = payloads.max(by: { $0.updatedAt < $1.updatedAt }) else { save(); return }
        enabledSymbols = Set(newest.enabledSymbols)
        snippets = newest.snippets
        lastSynced = iCloudSyncEnabled ? newest.updatedAt : nil
        mirror(newest)
    }

    private func save() {
        let symbols = SymbolCatalog.items.map(\.value).filter(enabledSymbols.contains)
        let payload = KeyboardPayload(enabledSymbols: symbols, snippets: snippets, updatedAt: .now)
        mirror(payload)
        guard iCloudSyncEnabled else { return }
        lastSynced = payload.updatedAt
        guard let data = try? JSONEncoder().encode(payload) else { return }
        cloud.set(data, forKey: KeyboardStorage.payloadKey)
        cloud.synchronize()
    }

    private func mirror(_ payload: KeyboardPayload) {
        guard let data = try? JSONEncoder().encode(payload) else { return }
        UserDefaults.standard.set(data, forKey: KeyboardStorage.payloadKey)
        UserDefaults(suiteName: KeyboardStorage.appGroup)?.set(data, forKey: KeyboardStorage.payloadKey)
    }
}

struct ContentView: View {
    @StateObject private var store = KeyboardSettingsStore()
    @AppStorage(KeyboardStorage.onboardingKey) private var completedOnboarding = false
    @State private var showsOnboarding = false

    var body: some View {
        TabView {
            Tab("Symbols", systemImage: "character.cursor.ibeam") { SymbolsView(store: store) }
            Tab("Snippets", systemImage: "text.quote") { SnippetsView(store: store) }
            Tab("Test", systemImage: "rectangle.and.pencil.and.ellipsis") { KeyboardTestView() }
            Tab("Settings", systemImage: "gearshape") {
                KoltSettingsView(store: store) { showsOnboarding = true }
            }
        }
        .tint(.indigo)
        .task {
            if !completedOnboarding { showsOnboarding = true }
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            KoltOnboardingView(
                iCloudEnabled: store.iCloudSyncEnabled,
                setICloudSync: store.setICloudSyncEnabled
            ) {
                completedOnboarding = true
                showsOnboarding = false
            }
        }
    }
}

private struct SymbolsView: View {
    @ObservedObject var store: KeyboardSettingsStore
    @State private var search = ""
    private var categories: [String] { search.isEmpty ? SymbolCatalog.categories : ["Results"] }
    private func items(in category: String) -> [SymbolItem] {
        if !search.isEmpty {
            return SymbolCatalog.items.filter {
                $0.name.localizedCaseInsensitiveContains(search) || $0.value.contains(search)
            }
        }
        return SymbolCatalog.items.filter { $0.category == category }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label("Choose the keys that appear in your custom keyboard.", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                ForEach(categories, id: \.self) { category in
                    Section {
                        ForEach(items(in: category)) { item in
                            Button { store.toggle(item.value) } label: {
                                SymbolRow(item: item, isEnabled: store.isEnabled(item.value))
                            }
                        }
                    } header: {
                        HStack {
                            Text(category)
                            Spacer()
                            if search.isEmpty {
                                Button("All") { store.setAll(in: category, enabled: true) }
                                Button("None") { store.setAll(in: category, enabled: false) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Symbols")
            .searchable(text: $search, prompt: "Find a symbol")
        }
    }
}

private struct SymbolRow: View {
    let item: SymbolItem
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 14) {
            symbolTile
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name).foregroundStyle(.primary)
                if let note = item.note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isEnabled ? Color.indigo : Color.secondary)
        }
    }

    private var symbolTile: some View {
        Text(item.value)
            .font(.title2)
            .frame(width: 42, height: 36)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SnippetsView: View {
    @ObservedObject var store: KeyboardSettingsStore
    @State private var editingSnippet: Snippet?
    @State private var showingNewSnippet = false

    var body: some View {
        NavigationStack {
            Group {
                if store.snippets.isEmpty {
                    ContentUnavailableView("No Snippets Yet", systemImage: "text.badge.plus",
                        description: Text("Add phrases, signatures, links, or anything you type often."))
                } else {
                    List {
                        ForEach(store.snippets) { snippet in
                            Button { editingSnippet = snippet } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(snippet.title.isEmpty ? "Untitled" : snippet.title)
                                        .font(.headline).foregroundStyle(.primary)
                                    Text(snippet.text).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
                                }.padding(.vertical, 3)
                            }
                        }.onDelete(perform: store.deleteSnippets)
                    }
                }
            }
            .navigationTitle("Snippets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewSnippet = true } label: { Label("Add Snippet", systemImage: "plus") }
                }
            }
            .sheet(isPresented: $showingNewSnippet) {
                SnippetEditor { title, text in store.addSnippet(title: title, text: text) }
            }
            .sheet(item: $editingSnippet) { snippet in
                SnippetEditor(snippet: snippet) { title, text in
                    store.updateSnippet(snippet, title: title, text: text)
                }
            }
        }
    }
}

private struct SnippetEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var text: String
    let onSave: (String, String) -> Void

    init(snippet: Snippet? = nil, onSave: @escaping (String, String) -> Void) {
        _title = State(initialValue: snippet?.title ?? "")
        _text = State(initialValue: snippet?.text ?? "")
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name (for example, Work signature)", text: $title)
                Section("Text inserted by the keyboard") { TextEditor(text: $text).frame(minHeight: 160) }
            }
            .navigationTitle("Snippet").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(title, text); dismiss() }.disabled(text.isEmpty)
                }
            }
        }
    }
}

private struct KeyboardTestView: View {
    @AppStorage("keyboard.testText") private var text = ""
    @FocusState private var isEditorFocused: Bool
    @State private var didCopy = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Test your keyboard here", systemImage: "keyboard.badge.ellipsis")
                        .font(.headline)
                    Text("Tap the field, then use the globe key to switch to Kolt Keyboard.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))

                TextEditor(text: $text)
                    .focused($isEditorFocused)
                    .font(.body)
                    .padding(10)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isEditorFocused ? Color.indigo : Color.secondary.opacity(0.3), lineWidth: isEditorFocused ? 2 : 1)
                    }
                    .overlay(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("Type symbols and snippets…")
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 15)
                                .padding(.vertical, 18)
                                .allowsHitTesting(false)
                        }
                    }

                HStack {
                    Button(role: .destructive) {
                        text = ""
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                    .disabled(text.isEmpty)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = text
                        didCopy = true
                        Task {
                            try? await Task.sleep(for: .seconds(1.5))
                            didCopy = false
                        }
                    } label: {
                        Label(didCopy ? "Copied" : "Copy", systemImage: didCopy ? "checkmark" : "doc.on.doc")
                    }
                    .disabled(text.isEmpty)

                    Button("Done") { isEditorFocused = false }
                        .buttonStyle(.borderedProminent)
                        .disabled(!isEditorFocused)
                }

                HStack {
                    Text("Characters")
                    Spacer()
                    Text(text.count, format: .number)
                        .monospacedDigit()
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Keyboard Test")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isEditorFocused = true
                    } label: {
                        Label("Start Typing", systemImage: "keyboard")
                    }
                }
            }
        }
    }
}

private struct KoltSettingsView: View {
    @ObservedObject var store: KeyboardSettingsStore
    let showOnboarding: () -> Void
    @State private var confirmsCloudDeletion = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        KeyboardAccessView()
                    } label: {
                        SettingsRow(icon: "keyboard", color: .indigo, title: "Keyboard Access", subtitle: "Enable Kolt and understand Full Access")
                    }
                    Button("Open iOS Keyboard Settings") {
                        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                    }
                } header: {
                    Text("Keyboard")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { store.iCloudSyncEnabled },
                        set: store.setICloudSyncEnabled
                    )) {
                        SettingsRow(icon: "icloud", color: .blue, title: "iCloud Sync", subtitle: "Optional — off until you choose it")
                    }
                    if store.iCloudSyncEnabled, let lastSynced = store.lastSynced {
                        LabeledContent("Last synced", value: lastSynced.formatted(date: .abbreviated, time: .shortened))
                    }
                    if store.iCloudSyncEnabled {
                        Button("Turn Off & Delete iCloud Copy", role: .destructive) {
                            confirmsCloudDeletion = true
                        }
                    }
                } header: {
                    Text("Your Data")
                } footer: {
                    Text(store.iCloudSyncEnabled
                         ? "Symbols and snippets sync through your private iCloud account. Kolt has no server and cannot see them."
                         : "Everything stays on this device. The keyboard reads a local shared copy only when Full Access is enabled.")
                }

                Section {
                    NavigationLink {
                        PrivacyPromiseView()
                    } label: {
                        SettingsRow(icon: "hand.raised.fill", color: .green, title: "Privacy Promise", subtitle: "What Kolt can — and cannot — access")
                    }
                    NavigationLink {
                        AboutKoltView()
                    } label: {
                        SettingsRow(icon: "info.circle.fill", color: .purple, title: "About Kolt", subtitle: "Our principles and open-source code")
                    }
                    Button { showOnboarding() } label: {
                        Label("Replay Onboarding", systemImage: "sparkles")
                    }
                } header: {
                    Text("About")
                }

                Section("iOS Limitations") {
                    Text("Custom keyboards do not appear in secure password fields or phone-pad fields, and apps can choose to block third-party keyboards.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Delete the iCloud copy?", isPresented: $confirmsCloudDeletion, titleVisibility: .visible) {
                Button("Turn Off & Delete", role: .destructive) { store.deleteICloudCopy() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your symbols and snippets will remain on this device. This removes Kolt's settings from your private iCloud key-value store.")
            }
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundStyle(.primary)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct KeyboardAccessView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TrustHero(icon: "keyboard.fill", title: "You choose the access", message: "Kolt works as a basic symbol keyboard without Full Access. Full Access is only needed to carry your choices and snippets from this app into the keyboard.")
                TrustCard(title: "Without Full Access", icon: "lock.fill", color: .orange, points: [
                    "Use Kolt's built-in starter symbols",
                    "No custom symbol selection",
                    "No personal snippets"
                ])
                TrustCard(title: "With Full Access", icon: "checkmark.shield.fill", color: .green, points: [
                    "Use the symbols you enabled in the app",
                    "Insert your saved snippets",
                    "Read a local App Group snapshot — not your typing history"
                ])
                Text("Apple's “Full Access” label also grants keyboards network capability. Kolt's keyboard extension does not make network requests. iCloud, if you opt in, is handled by the main app through your Apple account.")
                    .font(.footnote).foregroundStyle(.secondary)
                Button {
                    UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                } label: {
                    Label("Open iOS Settings", systemImage: "arrow.up.forward.app")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Keyboard Access")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PrivacyPromiseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                TrustHero(icon: "hand.raised.fill", title: "Your words are yours", message: "Kolt does not collect, analyze, sell, or send your typing to us. There are no analytics, ads, accounts, or Kolt servers.")
                TrustCard(title: "What stays private", icon: "eye.slash.fill", color: .green, points: [
                    "What you type and the document around the cursor",
                    "Your enabled symbols and personal snippets",
                    "Your usage habits and identity"
                ])
                TrustCard(title: "Optional iCloud", icon: "icloud.fill", color: .blue, points: [
                    "Off by default",
                    "Uses your private Apple iCloud account",
                    "Can be turned off or deleted from Settings"
                ])
                Text("Because Kolt is open source, this promise is inspectable rather than something you simply have to trust.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Privacy Promise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AboutKoltView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "character.cursor.ibeam")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 72, height: 72)
                        .background(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
                    Text("Kolt").font(.largeTitle.bold())
                    Text("Symbols and snippets, one tap away.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            Section("Built on trust") {
                Text("Kolt is designed around informed consent: local by default, optional iCloud sync, and a clear explanation before asking for Full Access.")
                NavigationLink("Read the Privacy Promise") { PrivacyPromiseView() }
                NavigationLink("Understand Full Access") { KeyboardAccessView() }
            }
            Section("Open Source") {
                Link(destination: KeyboardStorage.sourceURL) {
                    Label("View Project on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Text("You can inspect how the keyboard stores data, contribute improvements, or build it yourself.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("About Kolt")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TrustHero: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon).font(.title).foregroundStyle(.white)
            Text(title).font(.title.bold()).foregroundStyle(.white)
            Text(message).foregroundStyle(.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 22))
    }
}

private struct TrustCard: View {
    let title: String
    let icon: String
    let color: Color
    let points: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon).font(.headline).foregroundStyle(color)
            ForEach(points, id: \.self) { point in
                Label(point, systemImage: "checkmark").font(.subheadline)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview { ContentView() }
