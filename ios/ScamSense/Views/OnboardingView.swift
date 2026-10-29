import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var app

    enum Step: Int, CaseIterable { case welcome, audience, textSize, demo, consent, paywall }

    @State private var step: Step = .welcome
    @State private var demoPhase = 0   // 0 message, 1 scanning, 2 result
    @State private var forward = true

    var body: some View {
        Group {
            if step == .paywall {
                PaywallView(reason: .onboarding, onClose: finish, onPurchased: finish)
                    .transition(.move(edge: .bottom))
            } else {
                VStack(spacing: 0) {
                    topBar
                    ScrollView {
                        content
                            .padding(.horizontal, 22)
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                            .id(step)
                            .transition(.asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                                                    removal: .opacity))
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    bottomBar
                }
                .background(Theme.bg.ignoresSafeArea())
            }
        }
        .animation(.spring(duration: 0.45), value: step)
        .onAppear {
            if let raw = UserDefaults.standard.object(forKey: "uiOnboardingStep") as? Int ?? Int(UserDefaults.standard.string(forKey: "uiOnboardingStep") ?? ""),
               let s = Step(rawValue: raw) {
                step = s
                if s == .demo, UserDefaults.standard.bool(forKey: "uiDemoResult") { demoPhase = 2 }
            }
        }
    }

    private var topBar: some View {
        HStack {
            if step != .welcome {
                Button { go(Step(rawValue: step.rawValue - 1) ?? .welcome, forward: false) } label: {
                    Image(systemName: "chevron.left").font(.headline.weight(.bold))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("Back"))
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
            Spacer()
            HStack(spacing: 6) {
                ForEach(0..<5) { i in
                    Capsule()
                        .fill(i <= step.rawValue ? Theme.brand : Theme.line)
                        .frame(width: i == step.rawValue ? 22 : 8, height: 8)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text("Step \(step.rawValue + 1) of 5"))
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
    }

    @ViewBuilder private var content: some View {
        switch step {
        case .welcome: welcome
        case .audience: audience
        case .textSize: textSize
        case .demo: demo
        case .consent: consent
        case .paywall: EmptyView()
        }
    }

    // MARK: Pages

    private var welcome: some View {
        VStack(spacing: 26) {
            LogoMark(size: 120)
                .padding(.top, 30)
                .shadow(color: Theme.brand.opacity(0.35), radius: 24, y: 12)
            VStack(spacing: 12) {
                Text("A second opinion before you tap")
                    .font(Theme.title())
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text("Paste any text, email, link or call script. ScamSense tells you in plain words if it's a scam, and what to do next.")
                    .font(.title3)
                    .foregroundStyle(Theme.subtle)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 10) {
                signal(.scam)
                signal(.suspicious)
                signal(.likelySafe)
            }
        }
    }

    private func signal(_ verdict: Verdict) -> some View {
        VStack(spacing: 6) {
            Image(systemName: verdict.symbol).font(.title2)
            Text(verdict.label).font(.system(.caption, design: .rounded, weight: .bold))
                .lineLimit(1).minimumScaleFactor(0.7)
        }
        .foregroundStyle(verdict.headerText)
        .frame(maxWidth: .infinity, minHeight: 74)
        .background(verdict.headerFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var audience: some View {
        VStack(alignment: .leading, spacing: 18) {
            pageTitle("Who are you protecting?", "We'll tailor tips and warnings to fit.")
            ForEach(Audience.allCases) { item in
                Button {
                    app.audience = item
                } label: {
                    HStack(spacing: 16) {
                        Image(systemName: item.symbol)
                            .font(.title2)
                            .foregroundStyle(app.audience == item ? .white : Theme.brand)
                            .frame(width: 56, height: 56)
                            .background(app.audience == item ? Theme.brandFill : Theme.brand.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(.system(.headline, design: .rounded)).foregroundStyle(Theme.ink)
                            Text(item.subtitle).font(.subheadline).foregroundStyle(Theme.subtle)
                                .multilineTextAlignment(.leading)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: app.audience == item ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(app.audience == item ? Theme.brand : Theme.line)
                    }
                    .card(padding: 14)
                    .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(app.audience == item ? Theme.brand : .clear, lineWidth: 2))
                }
                .buttonStyle(PressableStyle())
                .accessibilityAddTraits(app.audience == item ? .isSelected : [])
            }
        }
        .sensoryFeedback(.selection, trigger: app.audience)
    }

    private var textSize: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 18) {
            pageTitle("How big should text be?", "You can change this anytime in Settings.")
            sizeOption(large: false)
            sizeOption(large: true)
            Toggle(isOn: $app.largeText.animation()) {
                Label("Large text mode", systemImage: "textformat.size")
                    .font(.headline)
            }
            .toggleStyle(.switch)
            .tint(Theme.brand)
            .card(padding: 16)
        }
    }

    private func sizeOption(large: Bool) -> some View {
        Button {
            withAnimation { app.largeText = large }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(large ? "Large text" : "Standard")
                        .font(.system(.headline, design: .rounded))
                    Spacer()
                    Image(systemName: app.largeText == large ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(app.largeText == large ? Theme.brand : Theme.line)
                }
                Text("Don't tap links in texts about unpaid tolls.")
                    .font(.system(size: large ? 24 : 17))
                    .foregroundStyle(Theme.subtle)
                    .dynamicTypeSize(.large)
                    .multilineTextAlignment(.leading)
            }
            .foregroundStyle(Theme.ink)
            .card(padding: 16)
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(app.largeText == large ? Theme.brand : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(app.largeText == large ? .isSelected : [])
    }

    private var demo: some View {
        VStack(alignment: .leading, spacing: 18) {
            pageTitle("Try it on a real-looking scam", "This example is built in, so nothing is sent anywhere.")
            if demoPhase < 2 {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill").font(.title2).foregroundStyle(.gray)
                        Text(verbatim: AppConfig.language == "ko" ? "010-0000-4821" : "+44 7412 555093")
                            .font(.subheadline.weight(.semibold)).foregroundStyle(Theme.subtle)
                    }
                    Text(verbatim: CheckView.demoText)
                        .font(.body)
                        .foregroundStyle(Theme.ink)
                        .padding(14)
                        .background(Theme.bubbleGray, in: BubbleShape())
                        .frame(maxWidth: 320, alignment: .leading)
                }
                .card(padding: 16)
                if demoPhase == 1 {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Checking the sender, the link and known scams…")
                            .font(.headline)
                            .foregroundStyle(Theme.ink)
                    }
                    .card(padding: 16)
                    .transition(.opacity)
                }
            } else if let sample = ScamResult.bundledSample() {
                DemoResultCard(result: sample)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
    }

    private var consent: some View {
        VStack(alignment: .leading, spacing: 20) {
            pageTitle("Your privacy comes first", "Here's exactly what happens when you check something.")
            ConsentContent()
                .card(padding: 18)
            Link(destination: AppConfig.privacyURL) {
                Label("Read our Privacy Policy", systemImage: "doc.text").font(.headline).frame(minHeight: 44)
            }
        }
    }

    private func pageTitle(_ title: LocalizedStringResource, _ subtitle: LocalizedStringResource) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.title(.title)).foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.body).foregroundStyle(Theme.subtle)
        }
        .padding(.top, 8)
    }

    // MARK: Bottom

    @ViewBuilder private var bottomBar: some View {
        VStack(spacing: 8) {
            switch step {
            case .welcome:
                Button("Get started") { go(.audience) }.buttonStyle(PrimaryButtonStyle())
            case .audience:
                Button("Continue") { go(.textSize) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(app.audience == nil)
            case .textSize:
                Button("Continue") { go(.demo) }.buttonStyle(PrimaryButtonStyle())
            case .demo:
                if demoPhase == 0 {
                    Button { runDemo() } label: { Label("Check this message", systemImage: "magnifyingglass") }
                        .buttonStyle(PrimaryButtonStyle())
                } else {
                    Button("Continue") { go(.consent) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(demoPhase == 1)
                }
            case .consent:
                Button("Agree and continue") {
                    app.consentGiven = true
                    afterConsent()
                }
                .buttonStyle(PrimaryButtonStyle())
                Button("Not now") { afterConsent() }
                    .font(.headline)
                    .frame(minHeight: 44)
            case .paywall:
                EmptyView()
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func go(_ next: Step, forward: Bool = true) {
        self.forward = forward
        withAnimation(.spring(duration: 0.45)) { step = next }
    }

    private func runDemo() {
        withAnimation { demoPhase = 1 }
        Task {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.spring(duration: 0.5)) { demoPhase = 2 }
        }
    }

    /// Subscribers (e.g. after reinstalling) skip the soft paywall.
    private func afterConsent() {
        if app.isPro { finish() } else { go(.paywall) }
    }

    private func finish() {
        app.launchScreen = nil
        app.onboarded = true
    }
}

/// Compact result preview for the onboarding "aha" moment.
struct DemoResultCard: View {
    let result: ScamResult
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VerdictHeader(result: result, animate: false, compact: true)
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(result.redFlags.prefix(3).enumerated()), id: \.offset) { _, flag in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: ResultView.icon(flag: flag.flag, why: flag.why))
                            .foregroundStyle(Theme.scam)
                            .frame(width: 26)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: flag.flag).font(.headline).foregroundStyle(Theme.ink)
                            Text(verbatim: flag.why).font(.subheadline).foregroundStyle(Theme.subtle)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                Label("Plus: what to do, what to do if you already tapped, where to report, and a warning to send your family.",
                      systemImage: "sparkles")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.brand)
            }
            .padding(16)
            .background(Theme.card)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        .sensoryFeedback(.warning, trigger: appeared)
        .onAppear { appeared = true }
    }
}

/// Incoming message bubble with a small tail.
struct BubbleShape: Shape {
    var outgoing = false

    func path(in rect: CGRect) -> Path {
        var p = Path(roundedRect: rect, cornerRadius: 18, style: .continuous)
        let tail = Path { t in
            if outgoing {
                t.move(to: CGPoint(x: rect.maxX - 14, y: rect.maxY - 2))
                t.addQuadCurve(to: CGPoint(x: rect.maxX + 5, y: rect.maxY + 2), control: CGPoint(x: rect.maxX - 2, y: rect.maxY + 2))
                t.addQuadCurve(to: CGPoint(x: rect.maxX - 2, y: rect.maxY - 12), control: CGPoint(x: rect.maxX - 2, y: rect.maxY - 4))
            } else {
                t.move(to: CGPoint(x: rect.minX + 14, y: rect.maxY - 2))
                t.addQuadCurve(to: CGPoint(x: rect.minX - 5, y: rect.maxY + 2), control: CGPoint(x: rect.minX + 2, y: rect.maxY + 2))
                t.addQuadCurve(to: CGPoint(x: rect.minX + 2, y: rect.maxY - 12), control: CGPoint(x: rect.minX + 2, y: rect.maxY - 4))
            }
        }
        p.addPath(tail)
        return p
    }
}
