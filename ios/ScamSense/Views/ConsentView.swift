import SwiftUI

/// Guideline 5.1.2(i): exactly what is sent, to whom, and an explicit "Agree" before the first AI check.
struct ConsentContent: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            row("paperplane.fill", "What is sent",
                "Only what you choose to check: the text you typed or pasted, the screenshot you picked (if any), where it came from, your note, plus your language and country.")
            row("cpu.fill", "Who analyzes it",
                "Our server passes it to Anthropic's Claude AI, which looks for scam signs and writes the answer.")
            row("trash.fill", "What is kept",
                "Nothing. Your message and screenshot are not stored on our server after the answer comes back. We only count how many checks you've used.")
            row("hand.raised.fill", "Never for ads",
                "Your content is never sold, shared with advertisers or used to track you. Your history stays on this iPhone.")
            row("eye.slash.fill", "Tip",
                "You can cover or delete names, account numbers and other private details before checking.")
        }
    }

    private func row(_ symbol: String, _ title: LocalizedStringResource, _ text: LocalizedStringResource) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(Theme.brand)
                .frame(width: 40, height: 40)
                .background(Theme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(Theme.ink)
                Text(text).font(.body).foregroundStyle(Theme.subtle).fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct ConsentSheet: View {
    var onAgree: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(AppModel.self) private var app

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Before your first check")
                        .font(Theme.title(.title))
                        .foregroundStyle(Theme.ink)
                    ConsentContent()
                    Link(destination: AppConfig.privacyURL) {
                        Label("Read our Privacy Policy", systemImage: "doc.text")
                            .font(.headline)
                            .frame(minHeight: 44)
                    }
                }
                .padding(20)
            }
            .background(Theme.bg.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 10) {
                    Button("Agree and check") { onAgree() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Not now") { dismiss() }
                        .font(.headline)
                        .frame(minHeight: 44)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel(Text("Close"))
                }
            }
        }
        .modifier(LargeTextModifier(on: app.largeText))
        .interactiveDismissDisabled(false)
    }
}
