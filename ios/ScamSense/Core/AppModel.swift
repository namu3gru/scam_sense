import Foundation
import SwiftUI

enum AppTab: Hashable { case check, history, quiz, learn, family }

/// Screens the test hooks can open directly: `-uiScreen paywall`.
enum LaunchScreen: String {
    case onboarding, check, waiting, result, quiz, quizHome, quizAnswered, quizResult, history, historyDetail, paywall,
         settings, learn, learnDetail, family, consent, shareCard
}

struct CheckDraft: Identifiable, Hashable {
    var id = UUID()
    var text: String
    var image: Data?
    var thumbnail: Data?
    var channel: Channel?
    var context: String
}

@MainActor
@Observable
final class AppModel {
    let api = APIClient()
    let store = SubscriptionStore()
    let history = HistoryStore()
    let quiz = QuizStore()

    var tab: AppTab = .check
    var quota: QuotaStatus?
    var quotaLoading = false

    private let defaults = UserDefaults.standard

    var onboarded: Bool { didSet { defaults.set(onboarded, forKey: "onboarded") } }
    var consentGiven: Bool { didSet { defaults.set(consentGiven, forKey: "aiConsent") } }
    var largeText: Bool { didSet { defaults.set(largeText, forKey: "largeText") } }
    var audience: Audience? { didSet { defaults.set(audience?.rawValue, forKey: "audience") } }
    var country: Country { didSet { defaults.set(country.rawValue, forKey: "country") } }
    var reminderOn: Bool { didSet { defaults.set(reminderOn, forKey: "reminderOn") } }
    var reminderTime: Date { didSet { defaults.set(reminderTime.timeIntervalSince1970, forKey: "reminderTime") } }
    var checksCompleted: Int { didSet { defaults.set(checksCompleted, forKey: "checksCompleted") } }
    var lastReviewAsk: Double { didSet { defaults.set(lastReviewAsk, forKey: "lastReviewAsk") } }
    var bannerDismissed = false

    // Test hooks (launch arguments)
    var launchScreen: LaunchScreen?
    var prefill: String?
    var autoCheck = false
    var minWait: Double = 3.5

    init() {
        let d = UserDefaults.standard
        if d.bool(forKey: "uiReset") {
            for key in ["onboarded", "aiConsent", "largeText", "audience", "country", "reminderOn",
                        "reminderTime", "checksCompleted", "lastReviewAsk", "quizProgress.v1"] {
                d.removeObject(forKey: key)
            }
        }
        onboarded = d.bool(forKey: "onboarded")
        consentGiven = d.bool(forKey: "aiConsent")
        largeText = d.bool(forKey: "largeText")
        audience = d.string(forKey: "audience").flatMap(Audience.init(rawValue:))
        country = d.string(forKey: "country").flatMap(Country.init(rawValue:)) ?? .fromLocale
        reminderOn = d.bool(forKey: "reminderOn")
        let savedTime = d.double(forKey: "reminderTime")
        reminderTime = savedTime > 0 ? Date(timeIntervalSince1970: savedTime)
            : (Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date())
        checksCompleted = d.integer(forKey: "checksCompleted")
        lastReviewAsk = d.double(forKey: "lastReviewAsk")
        applyLaunchHooks()
    }

    private func applyLaunchHooks() {
        let d = defaults
        if d.bool(forKey: "uiReset") {
            history.clear()
            quiz.reset()
        }
        if d.object(forKey: "uiOnboarded") != nil { onboarded = d.bool(forKey: "uiOnboarded") }
        if d.object(forKey: "uiConsent") != nil { consentGiven = d.bool(forKey: "uiConsent") }
        if d.object(forKey: "uiLargeText") != nil { largeText = d.bool(forKey: "uiLargeText") }
        if let c = d.string(forKey: "uiCountry").flatMap(Country.init(rawValue:)) { country = c }
        if d.bool(forKey: "uiDemo") { seedDemo() }
        if d.bool(forKey: "uiNoBanner") { bannerDismissed = true }
        if let raw = d.string(forKey: "uiScreen") { launchScreen = LaunchScreen(rawValue: raw) }
        prefill = d.string(forKey: "uiPrefill")
        autoCheck = d.bool(forKey: "uiAutoCheck")
        if d.object(forKey: "uiMinWait") != nil { minWait = d.double(forKey: "uiMinWait") }
        switch launchScreen {
        case .history, .historyDetail: tab = .history
        case .quiz, .quizHome, .quizAnswered, .quizResult, .shareCard: tab = .quiz
        case .learn, .learnDetail: tab = .learn
        case .family: tab = .family
        default: break
        }
    }

    var isPro: Bool { (quota?.pro ?? false) || store.hasActiveSubscription }

    /// Free users get a gentle banner after their 2nd check.
    var showUpgradeBanner: Bool { !isPro && checksCompleted >= 2 && !bannerDismissed }

    func start() async {
        store.onSignedTransaction = { [weak self] jws, renewal in
            guard let self else { return }
            if let status = try? await self.api.redeem(signedTransaction: jws, signedRenewalInfo: renewal) { self.quota = status }
        }
        store.start()
        quiz.ensureToday()
        await refreshQuota()
    }

    func refreshQuota() async {
        quotaLoading = true
        defer { quotaLoading = false }
        if let status = try? await api.status() { quota = status }
    }

    func performCheck(_ draft: CheckDraft) async throws -> CheckRecord {
        let text = draft.text.trimmed
        let note = draft.context.trimmed
        let payload = RunRequest(
            imageBase64: draft.image?.base64EncodedString(),
            text: text.isEmpty ? nil : String(text.prefix(6000)),
            channel: draft.channel?.rawValue ?? "unknown",
            context: note.isEmpty ? nil : String(note.prefix(500)),
            language: AppConfig.language,
            country: country.rawValue)
        do {
            let response = try await api.run(payload)
            quota = response.status
            let record = CheckRecord(text: text.isEmpty ? nil : text, thumbnail: draft.thumbnail,
                                     channel: draft.channel, context: note.isEmpty ? nil : note,
                                     result: response.result)
            history.add(record)
            checksCompleted += 1
            return record
        } catch let error as APIError {
            switch error {
            case .freeLimit(let status?), .proCap(let status?): quota = status
            default: break
            }
            throw error
        }
    }

    /// Ask for a rating after a success moment, at most every ~4 months (Apple caps it at 3/yr too).
    func shouldAskForReview() -> Bool {
        let now = Date().timeIntervalSince1970
        guard now - lastReviewAsk > 120 * 86400 else { return false }
        guard checksCompleted >= 1 || quiz.progress.daysCompleted >= 2 else { return false }
        lastReviewAsk = now
        return true
    }

    func updateReminder() async {
        if reminderOn {
            let c = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let ok = await Reminders.enable(hour: c.hour ?? 19, minute: c.minute ?? 0)
            if !ok { reminderOn = false }
        } else {
            Reminders.disable()
        }
    }

    // MARK: Demo data for screenshots (`-uiDemo YES`)

    private struct DemoRecord: Decodable {
        var text: String
        var channel: Channel?
        var minutesAgo: Double
        var result: ScamResult
    }

    private func seedDemo() {
        guard let demo = ContentLoader.load("demo_history", as: [DemoRecord].self) else { return }
        history.replaceAll(demo.map {
            CheckRecord(date: Date().addingTimeInterval(-$0.minutesAgo * 60), text: $0.text,
                        channel: $0.channel, result: $0.result, isDemo: true)
        })
        quiz.seedDemo()
        checksCompleted = max(checksCompleted, 2)
    }
}
