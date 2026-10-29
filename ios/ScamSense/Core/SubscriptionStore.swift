import Foundation
import StoreKit

/// StoreKit 2 subscriptions. The server stays the source of truth for the quota: every verified
/// transaction is posted to /entitlement, which marks this device as Pro there.
@MainActor
@Observable
final class SubscriptionStore {
    enum LoadState { case idle, loading, loaded, failed }

    private(set) var products: [Product] = []
    private(set) var loadState: LoadState = .idle
    private(set) var activeProductIDs: Set<String> = []
    private(set) var introEligible = true
    var purchasing = false
    var lastError: String?

    /// Called with each transaction's jwsRepresentation (AppModel posts it to the server).
    var onSignedTransaction: ((String) async -> Void)?

    private var updatesTask: Task<Void, Never>?

    var hasActiveSubscription: Bool { !activeProductIDs.isEmpty }

    var yearly: Product? { products.first { $0.id == AppConfig.yearlyID } }
    var monthly: Product? { products.first { $0.id == AppConfig.monthlyID } }

    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
        Task {
            await loadProducts()
            await refreshEntitlements()
        }
    }

    func loadProducts() async {
        guard loadState != .loading else { return }
        loadState = .loading
        do {
            let found = try await Product.products(for: AppConfig.productIDs)
            products = found.sorted { $0.price > $1.price }
            loadState = found.isEmpty ? .failed : .loaded
            if let sub = yearly?.subscription {
                introEligible = await sub.isEligibleForIntroOffer
            }
        } catch {
            loadState = .failed
        }
    }

    /// On launch and after restore: re-send every current entitlement to the server.
    func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result else { continue }
            if tx.revocationDate == nil, (tx.expirationDate ?? .distantFuture) > Date() {
                active.insert(tx.productID)
            }
            await onSignedTransaction?(result.jwsRepresentation)
        }
        activeProductIDs = active.union(await gracePeriodProductIDs())
    }

    /// Billing grace period: a renewal payment failed and Apple is retrying. The last transaction has
    /// already expired, but the subscription status is .inGracePeriod, so the subscriber keeps Pro.
    private func gracePeriodProductIDs() async -> Set<String> {
        var ids: Set<String> = []
        let product: Product?
        if let loaded = yearly ?? monthly {
            product = loaded
        } else {
            product = try? await Product.products(for: AppConfig.productIDs).first
        }
        guard let statuses = try? await product?.subscription?.status else { return ids }
        for status in statuses where status.state == .inGracePeriod {
            guard case .verified(let tx) = status.transaction, tx.revocationDate == nil,
                  AppConfig.productIDs.contains(tx.productID) else { continue }
            ids.insert(tx.productID)
        }
        return ids
    }

    /// Returns true when the purchase went through.
    func purchase(_ product: Product) async -> Bool {
        purchasing = true
        lastError = nil
        defer { purchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let tx) = verification else {
                    lastError = String(localized: "The purchase couldn't be verified.")
                    return false
                }
                await onSignedTransaction?(verification.jwsRepresentation)
                await tx.finish()
                activeProductIDs.insert(tx.productID)
                return true
            case .pending:
                lastError = String(localized: "Your purchase is waiting for approval.")
                return false
            case .userCancelled:
                return false
            @unknown default:
                return false
            }
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func restore() async -> Bool {
        purchasing = true
        defer { purchasing = false }
        do {
            try await AppStore.sync()
        } catch {
            lastError = error.localizedDescription
        }
        await refreshEntitlements()
        return hasActiveSubscription
    }

    private func handle(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let tx) = update else { return }
        await onSignedTransaction?(update.jwsRepresentation)
        await tx.finish()
        if tx.revocationDate == nil, (tx.expirationDate ?? .distantFuture) > Date() {
            activeProductIDs.insert(tx.productID)
        } else {
            await refreshEntitlements()  // expired or refunded: recompute (keeps grace-period access)
        }
    }
}

/// Prices to show when StoreKit can't load products (simulator without a StoreKit config,
/// offline). Buttons stay disabled until the real products arrive.
struct PlanPricing {
    let yearly: Decimal
    let monthly: Decimal
    let currencyCode: String
    let locale: Locale

    static var fallback: PlanPricing {
        let isKR = Locale.current.region?.identifier == "KR" || Locale.current.currency?.identifier == "KRW"
        return isKR
            ? PlanPricing(yearly: 44000, monthly: 6900, currencyCode: "KRW", locale: Locale(identifier: "ko_KR"))
            : PlanPricing(yearly: 29.99, monthly: 4.99, currencyCode: "USD", locale: Locale(identifier: "en_US"))
    }

    @MainActor static func from(store: SubscriptionStore) -> PlanPricing {
        guard let y = store.yearly, let m = store.monthly else { return fallback }
        return PlanPricing(yearly: y.price, monthly: m.price,
                           currencyCode: y.priceFormatStyle.currencyCode, locale: y.priceFormatStyle.locale)
    }

    func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = currencyCode
        f.locale = locale
        if currencyCode == "KRW" { f.maximumFractionDigits = 0 }
        return f.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    var yearlyText: String { format(yearly) }
    var monthlyText: String { format(monthly) }
    var yearlyPerMonth: String { format(rounded(yearly / 12)) }
    var yearlyPerWeek: String { format(rounded(yearly / 52)) }

    /// e.g. 49 for $29.99/yr vs $4.99/mo.
    var savingsPercent: Int {
        let full = (monthly * 12 as NSDecimalNumber).doubleValue
        guard full > 0 else { return 0 }
        return Int(((1 - (yearly as NSDecimalNumber).doubleValue / full) * 100).rounded(.down))
    }

    private func rounded(_ value: Decimal) -> Decimal {
        var v = value, out = Decimal()
        NSDecimalRound(&out, &v, currencyCode == "KRW" ? 0 : 2, .plain)
        return out
    }
}
