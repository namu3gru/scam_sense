import StoreKit
import SwiftUI

struct PaywallView: View {
    enum Reason { case onboarding, limit, banner, feature, settings }

    let reason: Reason
    var onClose: (() -> Void)?
    var onPurchased: (() -> Void)?

    @Environment(SubscriptionStore.self) private var store
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var yearlySelected = true
    @State private var restoring = false
    @State private var message: String?
    @State private var purchasedTick = 0
    @State private var restoredOK = false

    private var pricing: PlanPricing { PlanPricing.from(store: store) }
    private var trialAvailable: Bool { store.yearly == nil || (store.introEligible && store.yearly?.subscription?.introductoryOffer != nil) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.heroGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    features
                    plans
                    legal
                }
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .padding(.bottom, 16)
            }
            .safeAreaInset(edge: .bottom) { cta }
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.14), in: Circle())
            }
            .padding(.trailing, 16)
            .padding(.top, 4)
            .accessibilityLabel(Text("Close"))
        }
        .modifier(LargeTextModifier(on: app.largeText))
        .task {
            if store.products.isEmpty { await store.loadProducts() }
            if UserDefaults.standard.bool(forKey: "uiRestore") { restore() }
        }
        .sensoryFeedback(.success, trigger: purchasedTick)
        .alert(Text("ScamSense Pro"), isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) {
                if restoredOK { restoredOK = false; finishPurchase() }
            }
        } message: {
            Text(message ?? "")
        }
    }

    private var hero: some View {
        VStack(spacing: 10) {
            LogoMark(size: 52)
            if reason == .limit {
                Text("You've used this week's 3 free checks")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Theme.gold)
                    .multilineTextAlignment(.center)
            }
            Text("One scam can cost thousands.")
                .font(Theme.title(.title))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))
                .multilineTextAlignment(.center)
        }
    }

    private var subtitle: String {
        if pricing.currencyCode == "USD" && pricing.yearly / 12 < 3 {
            return String(localized: "Protect your family for less than $3/month.")
        }
        return String(localized: "Protect your family for just \(pricing.yearlyPerMonth)/month.")
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 11) {
            feature("checkmark.shield", "5 checks a day")
            feature("clock.arrow.circlepath", "Your full check history")
            feature("heart.text.square.fill", "Ready-made family warnings")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func feature(_ symbol: String, _ title: LocalizedStringResource) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.brandDeep)
                .frame(width: 30, height: 30)
                .background(Theme.gold, in: Circle())
                .accessibilityHidden(true)
            Text(title).font(.headline).foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var plans: some View {
        VStack(spacing: 12) {
            planButton(selected: yearlySelected, title: "Yearly",
                       price: String(localized: "\(pricing.yearlyText)/year"),
                       highlight: trialAvailable ? String(localized: "7-day free trial") : nil,
                       detail: String(localized: "\(pricing.yearlyPerMonth)/mo · \(pricing.yearlyPerWeek)/wk"),
                       badge: pricing.savingsPercent > 0 ? String(localized: "SAVE \(pricing.savingsPercent)%") : nil) {
                yearlySelected = true
            }
            planButton(selected: !yearlySelected, title: "Monthly",
                       price: String(localized: "\(pricing.monthlyText)/month"),
                       highlight: nil,
                       detail: String(localized: "Cancel anytime"), badge: nil) {
                yearlySelected = false
            }
        }
        .sensoryFeedback(.selection, trigger: yearlySelected)
    }

    private func planButton(selected: Bool, title: LocalizedStringResource, price: String, highlight: String?,
                            detail: String, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? Theme.gold : .white.opacity(0.6))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title).font(.system(.headline, design: .rounded)).foregroundStyle(.white)
                        if let badge {
                            Text(verbatim: badge)
                                .font(.system(.caption, design: .rounded, weight: .heavy))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.gold, in: Capsule())
                                .foregroundStyle(Theme.brandDeep)
                        }
                    }
                    if let highlight {
                        Text(verbatim: highlight).font(.subheadline.weight(.bold)).foregroundStyle(Theme.gold)
                    }
                    Text(verbatim: detail).font(.subheadline).foregroundStyle(.white.opacity(0.8))
                }
                Spacer(minLength: 4)
                Text(verbatim: price)
                    .font(.system(.headline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)
            .frame(minHeight: 74)
            .background(.white.opacity(selected ? 0.18 : 0.07), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(selected ? Theme.gold : .white.opacity(0.25), lineWidth: selected ? 2.5 : 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var cta: some View {
        VStack(spacing: 8) {
            Button(action: buy) {
                HStack(spacing: 10) {
                    if store.purchasing || store.loadState == .loading {
                        ProgressView().tint(Theme.brandDeep)
                    }
                    Text(yearlySelected && trialAvailable ? "Start my free week" : "Continue")
                }
            }
            .buttonStyle(PrimaryButtonStyle(fill: Theme.gold, foreground: Theme.brandDeep))
            .disabled(store.purchasing)

            Text(yearlySelected
                 ? (trialAvailable
                    ? String(localized: "Free for 7 days, then \(pricing.yearlyText) per year. Cancel anytime.")
                    : String(localized: "\(pricing.yearlyText) per year. Cancel anytime."))
                 : String(localized: "\(pricing.monthlyText) per month. Cancel anytime."))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)

            Button(reason == .onboarding ? "Not now, try it free" : "Not now", action: close)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .frame(minHeight: 32)
            HStack(spacing: 16) {
                Button("Restore Purchases", action: restore)
                Link("Terms of Use", destination: AppConfig.termsURL)
                Link("Privacy Policy", destination: AppConfig.privacyURL)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.75))
            .frame(minHeight: 30)
            .disabled(restoring)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .background {
            Color(hex: 0x2D55E4)
                .ignoresSafeArea(edges: .bottom)
                .shadow(color: .black.opacity(0.25), radius: 12, y: -4)
        }
        .overlay(alignment: .top) { Rectangle().fill(.white.opacity(0.12)).frame(height: 1) }
    }

    private var legal: some View {
        VStack(spacing: 12) {
            Text("Payment is charged to your Apple Account when you confirm (after the free trial, if any). The subscription renews automatically unless you cancel at least 24 hours before the end of the current period; renewal is charged within the 24 hours before it ends. Manage or cancel anytime in your App Store account settings.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func buy() {
        guard let product = yearlySelected ? store.yearly : store.monthly else {
            // Products not loaded yet (offline, or a simulator without StoreKit): try again.
            Task {
                await store.loadProducts()
                if store.yearly == nil {
                    message = String(localized: "Couldn't reach the App Store. Check your connection and try again.")
                }
            }
            return
        }
        Task {
            if await store.purchase(product) {
                purchasedTick += 1
                await app.refreshQuota()
                finishPurchase()
            } else if let error = store.lastError {
                message = error
            }
        }
    }

    private func restore() {
        restoring = true
        Task {
            let ok = await store.restore()
            await app.refreshQuota()
            restoring = false
            if ok {
                purchasedTick += 1
                restoredOK = true
                message = String(localized: "Your Pro subscription is active on this iPhone.")
            } else {
                message = String(localized: "We couldn't find an active subscription for this Apple Account.")
            }
        }
    }

    private func finishPurchase() {
        if let onPurchased { onPurchased() } else { close() }
    }
}
