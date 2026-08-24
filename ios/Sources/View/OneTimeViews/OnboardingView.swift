import SwiftUI

struct KoltOnboardingView: View {
    @State private var page = 0
    @State private var wantsICloud: Bool
    let setICloudSync: (Bool) -> Void
    let onCompletion: () -> Void

    init(iCloudEnabled: Bool, setICloudSync: @escaping (Bool) -> Void, onCompletion: @escaping () -> Void) {
        _wantsICloud = State(initialValue: iCloudEnabled)
        self.setICloudSync = setICloudSync
        self.onCompletion = onCompletion
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.17), Color(red: 0.20, green: 0.10, blue: 0.34)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("KOLT").font(.caption.bold()).tracking(3).foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    if page < 3 {
                        Button("Skip") { finish() }.foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                TabView(selection: $page) {
                    OnboardingPage(
                        icon: "character.cursor.ibeam",
                        eyebrow: "YOUR SHORTCUT PALETTE",
                        title: "The useful characters hiding behind menus.",
                        message: "Keep symbols like ™, ©, , arrows, currency, and your own phrases one tap away.",
                        bullets: ["Choose exactly which symbols appear", "Create reusable snippets", "Test the keyboard inside Kolt"]
                    ).tag(0)
                    OnboardingPage(
                        icon: "keyboard.fill",
                        eyebrow: "SETUP",
                        title: "Add Kolt as an iOS keyboard.",
                        message: "In Settings, add Kolt Keyboard. Use the globe key in any compatible text field to switch keyboards.",
                        bullets: ["Settings → General → Keyboard", "Keyboards → Add New Keyboard", "Select Kolt Keyboard"]
                    ).tag(1)
                    OnboardingPage(
                        icon: "checkmark.shield.fill",
                        eyebrow: "FULL ACCESS, EXPLAINED",
                        title: "Custom choices need a local bridge.",
                        message: "Without Full Access you get starter symbols. With it, the keyboard can read your chosen symbols and snippets from Kolt's local shared container.",
                        bullets: ["No keystroke collection", "No network requests from the keyboard", "No analytics, ads, accounts, or Kolt servers"]
                    ).tag(2)
                    iCloudPage.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                HStack(spacing: 7) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(index == page ? Color.white : Color.white.opacity(0.25))
                            .frame(width: index == page ? 24 : 7, height: 7)
                    }
                }
                .animation(.snappy, value: page)
                .padding(.bottom, 20)

                HStack(spacing: 12) {
                    if page > 0 {
                        Button { withAnimation { page -= 1 } } label: {
                            Image(systemName: "chevron.left").frame(width: 48, height: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                    }
                    Button(page == 3 ? "Start Using Kolt" : "Continue") {
                        if page == 3 { finish() } else { withAnimation { page += 1 } }
                    }
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.indigo)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var iCloudPage: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            Image(systemName: "icloud.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
            Text("YOUR CHOICE").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.65))
            Text("iCloud sync is optional.").font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text("Keep everything only on this device, or sync symbols and snippets through your private Apple iCloud account. Kolt cannot see that data.")
                .font(.title3).foregroundStyle(.white.opacity(0.78))
            Toggle(isOn: $wantsICloud) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Sync with iCloud").font(.headline)
                    Text(wantsICloud ? "Your private iCloud account" : "Off — data stays on this device")
                        .font(.caption).foregroundStyle(.white.opacity(0.65))
                }
            }
            .tint(.green)
            .padding(16)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .padding(.horizontal, 26)
    }

    private func finish() {
        setICloudSync(wantsICloud)
        onCompletion()
    }
}

private struct OnboardingPage: View {
    let icon: String
    let eyebrow: String
    let title: String
    let message: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 24))
            Text(eyebrow).font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.65))
            Text(title).font(.system(size: 38, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(message).font(.title3).foregroundStyle(.white.opacity(0.78))
            VStack(alignment: .leading, spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    Label(bullet, systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 26)
    }
}

#Preview {
    KoltOnboardingView(iCloudEnabled: false, setICloudSync: { _ in }, onCompletion: {})
}
