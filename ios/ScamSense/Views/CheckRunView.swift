import StoreKit
import SwiftUI

/// Full-screen flow for one check: waiting -> result (or paywall / friendly error).
struct CheckRunView: View {
    let draft: CheckDraft
    var onFinish: (CheckRecord?) -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.requestReview) private var requestReview

    enum Phase: Equatable {
        case waiting
        case result(CheckRecord)
        case limit
        case error(String, retry: Bool)
    }

    @State private var phase: Phase = .waiting
    @State private var attempt = 0
    @State private var finished: CheckRecord?

    var body: some View {
        ZStack {
            switch phase {
            case .waiting:
                WaitingView(hasImage: draft.image != nil) { onFinish(nil) }
                    .transition(.opacity)
            case .result(let record):
                ResultView(record: record, fresh: true)
                    .overlay(alignment: .topTrailing) {
                        Button { done(record) } label: {
                            Text("Done")
                                .font(.system(.headline, design: .rounded, weight: .bold))
                                .foregroundStyle(Theme.brandDeep)
                                .padding(.horizontal, 20)
                                .frame(minHeight: 44)
                                .background(.white, in: Capsule())
                                .shadow(color: .black.opacity(0.2), radius: 6, y: 2)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 2)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            case .limit:
                PaywallView(reason: .limit, onClose: { onFinish(nil) }, onPurchased: {
                    withAnimation { phase = .waiting }
                    attempt += 1
                })
                .transition(.opacity)
            case .error(let message, let retry):
                ErrorStateView(message: message, retry: retry ? {
                    withAnimation { phase = .waiting }
                    attempt += 1
                } : nil, close: { onFinish(nil) })
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: phase)
        .task(id: attempt) { await perform() }
    }

    /// Runs the check; if the server says "free limit" while StoreKit shows an active subscription,
    /// re-sends the entitlements once and retries.
    private func checkOnce(retryEntitlement: Bool) async throws -> CheckRecord {
        do {
            return try await app.performCheck(draft)
        } catch APIError.freeLimit(let status) where retryEntitlement && app.store.hasActiveSubscription {
            await app.store.refreshEntitlements()
            await app.refreshQuota()
            guard app.quota?.pro == true else { throw APIError.freeLimit(status) }
            return try await checkOnce(retryEntitlement: false)
        }
    }

    private func done(_ record: CheckRecord) {
        if app.checksCompleted == 3 || (record.result.verdict == .scam && app.checksCompleted >= 2),
           app.shouldAskForReview() {
            requestReview()
        }
        onFinish(record)
    }

    private func perform() async {
        guard phase == .waiting else { return }
        let started = Date()
        let outcome: Phase
        do {
            let record = try await checkOnce(retryEntitlement: true)
            outcome = .result(record)
        } catch is CancellationError {
            return
        } catch let error as APIError {
            switch error {
            case .freeLimit where app.store.hasActiveSubscription:
                // StoreKit says Pro but the server hasn't confirmed it (e.g. offline at purchase time).
                outcome = .error(String(localized: "We couldn't confirm your Pro subscription with our server yet. Open Settings and tap Restore Purchases, then try again."), retry: true)
            case .freeLimit: outcome = .limit
            case .proCap, .badToken, .invalidInput, .tooLarge:
                outcome = .error(error.localizedDescription, retry: false)
            default:
                outcome = .error(error.localizedDescription, retry: true)
            }
        } catch {
            outcome = .error(APIError.server(0).localizedDescription, retry: true)
        }
        // Let the staged messages breathe even when the answer is quick.
        let elapsed = Date().timeIntervalSince(started)
        if elapsed < app.minWait {
            try? await Task.sleep(for: .seconds(app.minWait - elapsed))
        }
        guard !Task.isCancelled else { return }
        withAnimation { phase = outcome }
    }
}

struct ErrorStateView: View {
    let message: String
    var retry: (() -> Void)?
    var close: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 64, weight: .semibold))
                .foregroundStyle(Theme.warn)
                .accessibilityHidden(true)
            Text("Hmm, that didn't work")
                .font(Theme.title(.title))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.subtle)
            Spacer()
            if let retry {
                Button("Try again", action: retry).buttonStyle(PrimaryButtonStyle())
            }
            Button("Close", action: close).buttonStyle(SecondaryButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg.ignoresSafeArea())
    }
}

/// Reassuring, staged progress while the AI works (usually 15-25 s).
struct WaitingView: View {
    let hasImage: Bool
    var cancel: () -> Void

    @State private var stage = 0
    @State private var spin = false
    @State private var pulse = false
    @State private var tipIndex = 0
    @State private var progress = 0.04

    private var stages: [(String, LocalizedStringResource)] {
        var list: [(String, LocalizedStringResource)] = []
        if hasImage { list.append(("photo", "Reading your screenshot…")) }
        list += [("person.crop.circle.badge.questionmark", "Checking the sender…"),
                 ("link", "Looking at the link…"),
                 ("text.magnifyingglass", "Comparing with known scams…"),
                 ("text.bubble", "Writing it up in plain words…")]
        return list
    }

    private let tips: [LocalizedStringResource] = [
        "Real companies never ask for a code they sent you.",
        "Gift cards are for gifts. Nobody legit wants to be paid in them.",
        "When in doubt, hang up and call the number on the back of your card.",
        "Scammers rush you. It's always OK to slow down.",
        "A family safe word stops voice-clone calls cold.",
    ]

    var body: some View {
        ZStack {
            Theme.heroGradient.ignoresSafeArea()
            VStack(spacing: 26) {
                HStack {
                    Spacer()
                    Button("Cancel", action: cancel)
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(minHeight: 44)
                }
                Spacer(minLength: 0)
                radar
                VStack(spacing: 8) {
                    Text("Checking it for you")
                        .font(Theme.title(.title))
                        .foregroundStyle(.white)
                    Text("This usually takes 15–25 seconds.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                }
                .multilineTextAlignment(.center)
                stageList
                ProgressView(value: progress)
                    .tint(.white)
                    .padding(.horizontal, 8)
                    .accessibilityHidden(true)
                Spacer(minLength: 0)
                tipCard
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 12)
        }
        .onAppear {
            spin = true
            pulse = true
        }
        .task { await runStages() }
        .accessibilityElement(children: .contain)
    }

    private var radar: some View {
        ZStack {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(.white.opacity(0.18), lineWidth: 2)
                    .frame(width: 120 + CGFloat(i) * 46, height: 120 + CGFloat(i) * 46)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                    .animation(.easeInOut(duration: 1.6).repeatForever().delay(Double(i) * 0.25), value: pulse)
            }
            Circle()
                .trim(from: 0, to: 0.28)
                .stroke(AngularGradient(colors: [.white.opacity(0), .white], center: .center),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 166, height: 166)
                .rotationEffect(.degrees(spin ? 360 : 0))
                .animation(.linear(duration: 1.8).repeatForever(autoreverses: false), value: spin)
            LogoMark(size: 96)
                .shadow(color: .black.opacity(0.3), radius: 14, y: 6)
        }
        .frame(height: 230)
        .accessibilityHidden(true)
    }

    private var stageList: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(stages.enumerated()), id: \.offset) { index, item in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(.white.opacity(index <= stage ? 0.22 : 0.08)).frame(width: 36, height: 36)
                        if index < stage {
                            Image(systemName: "checkmark").font(.subheadline.weight(.heavy)).foregroundStyle(.white)
                        } else if index == stage {
                            ProgressView().tint(.white).controlSize(.small)
                        } else {
                            Image(systemName: item.0).font(.subheadline).foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    Text(item.1)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white.opacity(index <= stage ? 1 : 0.5))
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lightbulb.fill").foregroundStyle(Theme.gold)
            Text(tips[tipIndex])
                .font(.subheadline)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .id(tipIndex)
                .transition(.opacity)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.black.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func runStages() async {
        var tick = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(0.5))
            tick += 1
            withAnimation(.easeOut(duration: 0.5)) { progress += (0.95 - progress) * 0.035 }
            if tick % 7 == 0 && stage < stages.count - 1 {
                withAnimation(.spring(duration: 0.4)) { stage += 1 }
            }
            if tick % 12 == 0 {
                withAnimation { tipIndex = (tipIndex + 1) % tips.count }
            }
        }
    }
}
