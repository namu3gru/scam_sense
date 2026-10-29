import SwiftUI

struct FamilyView: View {
    @Environment(AppModel.self) private var app
    @State private var content: FamilyContent? = ContentLoader.load("family", as: FamilyContent.self)
    @State private var showPaywall = false
    @State private var showSettings = false

    static let freeTemplates = 2

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    hero
                    if let content {
                        invite(content)
                        tips(content)
                        templates(content)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .background(Theme.bg.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape.fill").font(.title3) }
                        .accessibilityLabel(Text("Settings"))
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .feature) }
        .sheet(isPresented: $showSettings) { SettingsView() }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(app.audience == .me ? "Look out for each other" : "Protect a parent")
                .font(Theme.title())
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Scammers target people who are kind, trusting and polite. A few family habits stop most of them.")
                .font(.body)
                .foregroundStyle(Theme.subtle)
        }
        .padding(.top, 6)
    }

    private func inviteText(_ content: FamilyContent) -> String {
        var text = content.invite
        if let link = AppConfig.appStoreLink { text += "\n" + link }
        return text
    }

    private func invite(_ content: FamilyContent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.open.fill").font(.title2).foregroundStyle(Theme.gold)
                Text("Invite a parent or grandparent")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(.white)
            }
            Text(verbatim: content.invite)
                .font(.body)
                .foregroundStyle(.white.opacity(0.92))
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            ShareLink(item: inviteText(content)) {
                Label("Send the invite", systemImage: "paperplane.fill")
            }
            .buttonStyle(PrimaryButtonStyle(fill: Theme.gold, foreground: Theme.brandDeep))
        }
        .padding(18)
        .background(Theme.heroGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func tips(_ content: FamilyContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Family safety habits").sectionTitle()
            ForEach(Array(content.tips.enumerated()), id: \.element.id) { index, tip in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.icon)
                        .font(.title3)
                        .foregroundStyle(Theme.brand)
                        .frame(width: 44, height: 44)
                        .background(Theme.brand.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: "\(index + 1). \(tip.title)").font(.headline).foregroundStyle(Theme.ink)
                        Text(verbatim: tip.body).font(.body).foregroundStyle(Theme.subtle)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .card(padding: 14)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func templates(_ content: FamilyContent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Ready-to-send warnings").sectionTitle()
                Spacer()
                if !app.isPro {
                    Label("Pro", systemImage: "crown.fill")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Theme.gold.opacity(0.2), in: Capsule())
                        .foregroundStyle(Theme.warn)
                }
            }
            Text("Short, friendly alerts about scams going around. Send one to the family group chat.")
                .font(.subheadline).foregroundStyle(Theme.subtle)
            ForEach(Array(content.templates.enumerated()), id: \.element.id) { index, template in
                let locked = !app.isPro && index >= Self.freeTemplates
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: template.icon).foregroundStyle(Theme.scam)
                        Text(verbatim: template.title).font(.headline).foregroundStyle(Theme.ink)
                        Spacer()
                        if locked { Image(systemName: "lock.fill").foregroundStyle(Theme.subtle) }
                    }
                    Text(verbatim: template.message)
                        .font(.body)
                        .foregroundStyle(Theme.subtle)
                        .lineLimit(locked ? 2 : nil)
                        .blur(radius: locked ? 3 : 0)
                        .accessibilityHidden(locked)
                    if locked {
                        Button { showPaywall = true } label: {
                            Label("Unlock with Pro", systemImage: "crown.fill")
                        }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.warn))
                    } else {
                        ShareLink(item: template.message) {
                            Label("Send this warning", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .card(padding: 14)
            }
        }
    }
}
