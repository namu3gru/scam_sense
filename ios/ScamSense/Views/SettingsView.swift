import StoreKit
import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @Environment(SubscriptionStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var showManage = false
    @State private var showPaywall = false
    @State private var showConsentInfo = false
    @State private var restoreMessage: String?
    @State private var restoring = false

    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            Form {
                Section {
                    subscriptionRow
                    if !app.isPro {
                        Button { showPaywall = true } label: {
                            Label("Upgrade to Pro", systemImage: "crown.fill").font(.headline)
                        }
                        .frame(minHeight: 44)
                    }
                    Button { restore() } label: {
                        HStack {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                            if restoring { Spacer(); ProgressView() }
                        }
                    }
                    .frame(minHeight: 44)
                    .disabled(restoring)
                    Button { showManage = true } label: {
                        Label("Manage Subscription", systemImage: "creditcard")
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("Subscription")
                }

                Section {
                    Picker(selection: $app.country) {
                        ForEach(Country.allCases) { c in Text(c.label).tag(c) }
                    } label: {
                        Label("Country", systemImage: "globe.americas.fill")
                    }
                    .tint(Theme.subtle)  // value in gray like the other rows
                    .frame(minHeight: 44)
                    Toggle(isOn: $app.largeText.animation()) {
                        Label("Large text mode", systemImage: "textformat.size")
                    }
                    .frame(minHeight: 44)
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    } label: {
                        HStack {
                            Label("Language", systemImage: "character.bubble")
                            Spacer()
                            Text(verbatim: AppConfig.language == "ko" ? "한국어" : "English").foregroundStyle(Theme.subtle)
                        }
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("Preferences")
                } footer: {
                    Text("Country decides where we suggest reporting scams. The language follows your iPhone's settings.")
                }

                Section {
                    Toggle(isOn: $app.reminderOn) {
                        Label("Daily quiz reminder", systemImage: "bell.badge.fill")
                    }
                    .frame(minHeight: 44)
                    .onChange(of: app.reminderOn) { Task { await app.updateReminder() } }
                    if app.reminderOn {
                        DatePicker(selection: $app.reminderTime, displayedComponents: .hourAndMinute) {
                            Label("Time", systemImage: "clock")
                        }
                        .onChange(of: app.reminderTime) { Task { await app.updateReminder() } }
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    AIModelRow(live: app.quota?.aiModel)
                        .frame(minHeight: 44)
                    Button { showConsentInfo = true } label: {
                        Label("What we send to the AI", systemImage: "cpu")
                    }
                    .frame(minHeight: 44)
                    if app.consentGiven {
                        Button(role: .destructive) { app.consentGiven = false } label: {
                            Label("Withdraw AI consent", systemImage: "hand.raised.slash")
                                .labelStyle(.automatic)  // stays red
                        }
                        .frame(minHeight: 44)
                    }
                    Link(destination: AppConfig.privacyURL) {
                        Label("Privacy Policy", systemImage: "lock.doc")
                    }
                    .frame(minHeight: 44)
                    Link(destination: AppConfig.termsURL) {
                        Label("Terms of Use", systemImage: "doc.plaintext")
                    }
                    .frame(minHeight: 44)
                } header: {
                    Text("Privacy")
                }

                Section {
                    Button {
                        if let url = supportMailURL { openURL(url) }
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    .frame(minHeight: 44)
                    HStack {
                        Label("Version", systemImage: "info.circle")
                        Spacer()
                        Text(verbatim: version).foregroundStyle(Theme.subtle)
                    }
                } header: {
                    Text("Support")
                } footer: {
                    Text("ScamSense gives an AI second opinion and can be wrong. When in doubt, contact the company directly using its official number.")
                        .padding(.top, 8)
                }
            }
            .labelStyle(SettingsRowLabelStyle())
            .tint(Theme.brand)
            .scrollContentBackground(.hidden)
            .background(Theme.bg.ignoresSafeArea())
            .navigationTitle(Text("Settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(.headline)
                }
            }
        }
        .modifier(LargeTextModifier(on: app.largeText))
        .manageSubscriptionsSheet(isPresented: $showManage)
        .sheet(isPresented: $showPaywall) { PaywallView(reason: .settings) }
        .sheet(isPresented: $showConsentInfo) {
            NavigationStack {
                ScrollView { ConsentContent().padding(20) }
                    .background(Theme.bg.ignoresSafeArea())
                    .navigationTitle(Text("What we send"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showConsentInfo = false } } }
            }
            .presentationDetents([.large])
        }
        .alert(Text("Restore Purchases"), isPresented: Binding(get: { restoreMessage != nil }, set: { if !$0 { restoreMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(restoreMessage ?? "")
        }
        .task { await app.refreshQuota() }
    }

    @ViewBuilder private var subscriptionRow: some View {
        HStack(spacing: 14) {
            Image(systemName: app.isPro ? "crown.fill" : "gift.fill")
                .font(.title2)
                .foregroundStyle(app.isPro ? Theme.gold : Theme.brand)
                .frame(width: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(app.isPro ? "ScamSense Pro" : "Free plan").font(.headline)
                if app.isPro {
                    if let until = app.quota?.proUntil {
                        Text("Renews or ends \(Date(timeIntervalSince1970: until), format: .dateTime.month().day().year())")
                            .font(.subheadline).foregroundStyle(Theme.subtle)
                    } else {
                        Text("5 checks a day").font(.subheadline).foregroundStyle(Theme.subtle)
                    }
                } else if let q = app.quota {
                    Text("\(q.remaining) of \(q.limit) free checks left this week")
                        .font(.subheadline).foregroundStyle(Theme.subtle)
                } else {
                    Text("2 free checks every week").font(.subheadline).foregroundStyle(Theme.subtle)
                }
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    /// The privacy policy asks for the device ID on deletion requests, so the email carries it.
    private var supportMailURL: URL? {
        var c = URLComponents()
        c.scheme = "mailto"
        c.path = AppConfig.supportEmail
        c.queryItems = [URLQueryItem(name: "subject", value: "ScamSense \(version)"),
                        URLQueryItem(name: "body", value: "\n\n\n---\nDevice ID: \(DeviceID.value)")]
        return c.url
    }

    private func restore() {
        restoring = true
        Task {
            let ok = await store.restore()
            await app.refreshQuota()
            restoring = false
            restoreMessage = ok
                ? String(localized: "Your Pro subscription is active on this iPhone.")
                : String(localized: "We couldn't find an active subscription for this Apple Account.")
        }
    }
}

/// Settings row naming the AI model the server uses right now (updates by itself when the server switches models).
struct AIModelRow: View {
    var live: AIModelInfo?
    @AppStorage(AIModelInfo.cacheKey) private var cached = AIModelInfo.fallbackLabel

    var body: some View {
        HStack {
            Label("AI model", systemImage: "cpu")
            Spacer()
            Text(verbatim: live?.label ?? cached).foregroundStyle(Theme.subtle)
        }
        .onAppear { if let live { cached = live.label } }
        .onChange(of: live) { _, m in if let m { cached = m.label } }
    }
}

/// Every settings row looks the same: ink text, brand-blue icon (buttons and links would otherwise turn all blue).
struct SettingsRowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title.foregroundStyle(Theme.ink)
        } icon: {
            configuration.icon.foregroundStyle(Theme.brand)
        }
    }
}
